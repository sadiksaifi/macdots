import type { ExtensionAPI, ExtensionContext, ToolCallEvent } from "@earendil-works/pi-coding-agent";

type PermissionMode = "default" | "full-access";
type PermissionDecision = "allow" | "ask" | "blocked";

const STATUS_KEY = "permission-state";
const FULL_ACCESS_LABEL = "Full Access (Unrestricted)";

// Edit these arrays directly when you want different behavior.
const ALLOWED_TOOLS_IN_DEFAULT = [
  "read",
  "grep",
  "find",
  "web_search",
  "code_search",
  "fetch_content",
  "get_search_content",
  "mcp",
];

const BLOCKED_BASH_COMMANDS: RegExp[] = [
  /(^|[;&|()])\s*rm\s+-(?:[^\s-]*[rf][^\s-]*|[^\s-]*[fr][^\s-]*)\s+(?:\/(?:\s|$)|~(?:\s|\/|$)|\$HOME(?:\s|\/|$))/i,
  /(^|[;&|()])\s*rm\s+-(?:[^\s-]*[rf][^\s-]*|[^\s-]*[fr][^\s-]*)\s+(?:~\/\.pi(?:\s|\/|$)|\$HOME\/\.pi(?:\s|\/|$))/i,
  /(^|[;&|()])\s*rm\s+-(?:[^\s-]*[rf][^\s-]*|[^\s-]*[fr][^\s-]*)\s+(?:~\/\.ssh(?:\s|\/|$)|\$HOME\/\.ssh(?:\s|\/|$))/i,
  /(^|[;&|()])\s*sudo\s+rm\s+-(?:[^\s-]*[rf][^\s-]*|[^\s-]*[fr][^\s-]*)\s+\//i,
];

const READONLY_BASH_COMMANDS: RegExp[] = [
  // Pulled from the old pi-permissions safe-inspection profile.
  /^\s*(pwd|whoami|id|date|uname|hostname|uptime|locale|groups|nproc|arch|cal)(?:\s|$)/i,
  /^\s*(which|type|command\s+-v)(?:\s|$)/i,
  /^\s*(ls|tree|du|df|stat|file|realpath|readlink)(?:\s|$)/i,
  /^\s*(cat|head|tail|wc|nl|strings|hexdump|od|diff|cmp)(?:\s|$)/i,
  /^\s*(sha256sum|sha1sum|md5sum)(?:\s|$)/i,
  /^\s*(sort|uniq|cut|column|paste|fold|fmt|comm|tac|rev|tr|echo|printf|basename|dirname)(?:\s|$)/i,
  /^\s*(grep|egrep|fgrep|rg|fd|fdfind|find|locate)(?:\s|$)/i,
  /^\s*git(?:\s+-C\s+\S+)?\s+(status|diff|log|show|branch|rev-parse|ls-files|grep|blame|describe|remote|tag|stash\s+list)(?:\s|$)/i,

  // Common read-only project checks.
  /^\s*(npm|pnpm|yarn|bun)\s+(?:run\s+)?(?:test|typecheck|check-types|lint|check|fmt|fmt:check|format|format:check)(?:\s|$)/i,
  /^\s*(npm|pnpm|yarn|bun)\s+exec\s+(tsc|tsx|vitest|eslint|prettier|oxlint|oxfmt|biome)(?:\s|$)/i,
  /^\s*(pnpx|npx|bunx)\s+(tsc|tsx|vitest|eslint|prettier|oxlint|oxfmt|biome)(?:\s|$)/i,
  /^\s*(pnpm|yarn)\s+dlx\s+(tsc|tsx|vitest|eslint|prettier|oxlint|oxfmt|biome)(?:\s|$)/i,
  /^\s*bun\s+x\s+(tsc|tsx|vitest|eslint|prettier|oxlint|oxfmt|biome)(?:\s|$)/i,
  /^\s*(bun|npm|pnpm|yarn)\s+(install|i)\s+(--frozen-lockfile|--immutable|--dry-run)(?:\s|$)/i,
  /^\s*(node|python|python3|ruby|go|cargo|rustc|tsc|tsx|vitest|eslint|prettier|oxlint|oxfmt|biome)\s+.*(?:--help|-h|--version|-v|version)(?:\s|$)/i,

  // Common read-only inspection tools agents use a lot.
  /^\s*gh\s+(pr|issue|repo|run)\s+(view|list|status|diff|checks)(?:\s|$)/i,
  /^\s*(ps|top|htop|pgrep|lsof|netstat|ss)(?:\s|$)/i,
];

export default function permissionExtension(pi: ExtensionAPI) {
  let mode: PermissionMode = "default";
  let loadedCliFlag = false;
  let lastCtx: ExtensionContext | undefined;
  let plannedToolBatch = new Map<string, { index: number; total: number }>();
  let promptChain = Promise.resolve();

  pi.registerFlag("permission", {
    description: "Set permission mode: default or full-access",
    type: "string",
    default: "default",
  });

  pi.registerShortcut("alt+p", {
    description: "Toggle permission mode",
    handler: async (ctx) => {
      loadCliFlagOnce();
      lastCtx = ctx;
      mode = mode === "full-access" ? "default" : "full-access";
      renderStatus(ctx);
      if (ctx.hasUI) ctx.ui.notify(`Permission mode: ${modeLabel(mode)}`, "info");
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    loadCliFlagOnce();
    lastCtx = ctx;
    renderStatus(ctx);
  });

  pi.on("message_end", (event) => {
    plannedToolBatch = extractPromptBatchPositions(event.message, decideToolCall);
  });

  pi.on("tool_call", async (event, ctx) => {
    loadCliFlagOnce();
    lastCtx = ctx;

    const decision = decide(event);
    if (decision === "allow") return undefined;

    if (!ctx.hasUI) {
      return {
        block: true,
        reason:
          decision === "blocked"
            ? `Blocked by permission guard: ${describeToolCall(event)}`
            : "Permission required but no interactive UI is available",
      };
    }

    const prompt = buildPrompt(event, decision, plannedToolBatch.get(event.toolCallId));
    const allowed = await enqueuePrompt(() => askPermission(ctx, prompt));
    if (allowed) return undefined;

    return {
      block: true,
      reason:
        decision === "blocked"
          ? `Blocked by permission guard: ${describeToolCall(event)}`
          : `Permission denied by user for ${event.toolName}`,
    };
  });

  function loadCliFlagOnce(): void {
    if (loadedCliFlag) return;
    loadedCliFlag = true;
    const value = pi.getFlag("permission");
    if (value === undefined || value === "default") {
      mode = "default";
      return;
    }
    if (value === "full-access") {
      mode = "full-access";
      return;
    }
    throw new Error(`Invalid --permission value: ${String(value)}. Expected default or full-access.`);
  }

  function decide(event: ToolCallEvent): PermissionDecision {
    return decideToolCall(event.toolName, event.input);
  }

  function decideToolCall(toolName: string, input: unknown): PermissionDecision {
    if (toolName === "bash") {
      const command = getBashCommandFromInput(input);
      if (matchesAny(BLOCKED_BASH_COMMANDS, command)) return "blocked";
      if (mode === "full-access") return "allow";
      if (matchesAny(READONLY_BASH_COMMANDS, command)) return "allow";
      return "ask";
    }

    if (mode === "full-access") return "allow";
    if (ALLOWED_TOOLS_IN_DEFAULT.includes(toolName)) return "allow";
    return "ask";
  }

  function renderStatus(ctx = lastCtx): void {
    if (!ctx?.hasUI) return;
    ctx.ui.setStatus(
      STATUS_KEY,
      mode === "full-access" ? ctx.ui.theme.fg("error", FULL_ACCESS_LABEL) : undefined,
    );
  }

  async function enqueuePrompt<T>(run: () => Promise<T>): Promise<T> {
    const previous = promptChain;
    let release!: () => void;
    promptChain = new Promise<void>((resolve) => {
      release = resolve;
    });
    await previous;
    try {
      return await run();
    } finally {
      release();
    }
  }
}

async function askPermission(ctx: ExtensionContext, prompt: string): Promise<boolean> {
  const choice = await ctx.ui.select(prompt, ["Yes", "No"]);
  return choice === "Yes";
}

function buildPrompt(
  event: ToolCallEvent,
  decision: PermissionDecision,
  queuePosition?: { index: number; total: number },
): string {
  const prefix =
    queuePosition !== undefined && queuePosition.total > 1
      ? `(${queuePosition.index}/${queuePosition.total}) `
      : "";
  const lines = [`${prefix}Do you want to ${describeToolCall(event)}?`];
  if (decision === "blocked") lines.push("", "This matches BLOCKED_BASH_COMMANDS.");
  return lines.join("\n");
}

function describeToolCall(event: ToolCallEvent): string {
  if (event.toolName === "bash") return "run this bash command";
  return `run ${event.toolName}`;
}

function getBashCommand(event: ToolCallEvent): string {
  return getBashCommandFromInput(event.input);
}

function getBashCommandFromInput(input: unknown): string {
  const record = input as { command?: unknown };
  return typeof record.command === "string" ? record.command : "";
}

function matchesAny(patterns: readonly RegExp[], value: string): boolean {
  return patterns.some((pattern) => pattern.test(value));
}

function modeLabel(mode: PermissionMode): string {
  return mode === "full-access" ? FULL_ACCESS_LABEL : "default";
}

function extractPromptBatchPositions(
  message: unknown,
  decide: (toolName: string, input: unknown) => PermissionDecision,
): Map<string, { index: number; total: number }> {
  const content = getRecord(message).content;
  if (!Array.isArray(content)) return new Map();

  const ids = content.flatMap((block) => {
    const record = getRecord(block);
    if (record.type !== "toolCall") return [];
    const id = typeof record.id === "string" ? record.id : undefined;
    const name = typeof record.name === "string" ? record.name : undefined;
    if (id === undefined || name === undefined) return [];
    return decide(name, record.arguments) === "allow" ? [] : [id];
  });

  if (ids.length <= 1) return new Map();
  return new Map(ids.map((id, index) => [id, { index: index + 1, total: ids.length }]));
}

function getRecord(value: unknown): Record<string, unknown> {
  return typeof value === "object" && value !== null ? (value as Record<string, unknown>) : {};
}
