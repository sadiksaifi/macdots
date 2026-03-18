#!/usr/bin/env bun
// ─────────────────────────────────────────────────────────────
// Claude Code Statusline Hook (TypeScript reference)
//
// Reads JSON from stdin (piped by Claude Code) and outputs a
// single-line statusline with Nerd Font icons and ANSI colors.
//
// Compile (most performant):
//   bun build --compile --bytecode --minify \
//     --compile-exec-argv="--smol" \
//     --no-compile-autoload-dotenv \
//     --no-compile-autoload-bunfig \
//     statusline.ts --outfile statusline-bun
//
// Run interpreted:
//   echo '<json>' | bun statusline.ts
//
// NOTE: The Zig version (statusline.zig) is the active binary.
//       This file is kept as a readable reference.
// ─────────────────────────────────────────────────────────────

interface StatusInput {
  model?: { display_name?: string };
  workspace?: { current_dir?: string };
  context_window?: { used_percentage?: number };
  session_id?: string;
}

const RESET = "\x1b[0m";
const DIM = "\x1b[2m";
const ICON_MODEL = "\u{ee0d}"; // nf-fa-robot
const ICON_BRANCH = "\u{e0a0}";
const ICON_DIR = "\u{f07c}";
const ICON_TIME = "\u{f017}";

async function main() {
  const input: StatusInput = await Bun.stdin.json();

  const modelName = input.model?.display_name ?? "Claude";
  const usedPct = input.context_window?.used_percentage ?? 0;
  const dir = input.workspace?.current_dir ?? "";
  const sessionId = input.session_id ?? "";

  // Model color
  const ml = modelName.toLowerCase();
  const modelColor = ml.includes("opus")
    ? "\x1b[35m"
    : ml.includes("sonnet")
      ? "\x1b[34m"
      : ml.includes("haiku")
        ? "\x1b[32m"
        : "\x1b[37m";

  // Tilde-contract directory
  const home = Bun.env.HOME ?? "";
  const displayDir = home && dir.startsWith(home) ? "~" + dir.slice(home.length) : dir;

  // Parallel I/O: git branch + session elapsed
  const [branch, elapsed] = await Promise.all([
    readGitBranch(dir),
    sessionElapsed(sessionId),
  ]);

  // Context bar
  const filledRaw = Math.round((usedPct / 100) * 10);
  const filled = usedPct > 0 && filledRaw === 0 ? 1 : filledRaw;
  const barColor = usedPct < 50 ? "\x1b[32m" : usedPct < 80 ? "\x1b[33m" : "\x1b[31m";
  const bar = `${barColor}${"█".repeat(filled)}${RESET}${"░".repeat(10 - filled)}`;

  const segments: string[] = [
    `${modelColor}${ICON_MODEL}  ${modelName}${RESET}`,
    `${bar} ${usedPct}%`,
    ...(branch ? [`${ICON_BRANCH} ${branch}`] : []),
    `${DIM}${ICON_DIR} ${displayDir}${RESET}`,
    ...(elapsed ? [`${ICON_TIME} ${elapsed}`] : []),
  ];

  await Bun.write(Bun.stdout, segments.join(" | ") + "\n");
}

main();

// ── Helpers ──────────────────────────────────────────────────

async function readGitBranch(dir: string): Promise<string> {
  if (!dir) return "";
  try {
    const text = await Bun.file(`${dir}/.git/HEAD`).text();
    const prefix = "ref: refs/heads/";
    if (text.startsWith(prefix)) return text.slice(prefix.length).trim();
  } catch {}
  return "";
}

async function sessionElapsed(sessionId: string): Promise<string> {
  if (!sessionId) return "";
  const path = `/tmp/claude-sl-${sessionId}`;
  const f = Bun.file(path);
  if (await f.exists()) {
    const start = parseInt(await f.text());
    const secs = Math.floor((Date.now() - start) / 1000);
    const mins = Math.floor(secs / 60);
    const hrs = Math.floor(mins / 60);
    return hrs > 0 ? `${hrs}h${mins % 60}m` : mins > 0 ? `${mins}m` : `${secs}s`;
  }
  await Bun.write(path, Date.now().toString());
  return "0s";
}
