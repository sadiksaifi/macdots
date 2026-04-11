import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Key } from "@mariozechner/pi-tui";
import { isSafeBashCommand } from "./bash-guard";
import { DEFAULT_MODE, MODE_DESCRIPTIONS, MODE_ORDER, MODE_TITLES, MODE_TOOLS, nextMode, normalizeMode } from "./config";
import { buildModeInstructions } from "./instructions";
import { MODE_REQUEST_STATE_EVENT, MODE_STATE_EVENT, type Mode, type ModeState } from "./protocol";

export default function modesExtension(pi: ExtensionAPI) {
	let activeMode: Mode = DEFAULT_MODE;
	let pendingMode: Mode | undefined;

	const emitModeState = () => {
		const payload: ModeState = { activeMode };
		if (pendingMode && pendingMode !== activeMode) payload.pendingMode = pendingMode;
		pi.events.emit(MODE_STATE_EVENT, payload);
	};

	const applyMode = (mode: Mode, ctx: ExtensionContext, notify = true, persist = true) => {
		activeMode = mode;
		pendingMode = undefined;
		pi.setActiveTools(MODE_TOOLS[mode]);
		if (persist) pi.appendEntry("mode-state", { mode });
		emitModeState();
		if (notify) ctx.ui.notify(`mode: ${MODE_TITLES[mode]}`, "info");
	};

	const queueMode = (mode: Mode, ctx: ExtensionContext) => {
		if (mode === activeMode) {
			pendingMode = undefined;
			emitModeState();
			ctx.ui.notify(`mode stays: ${MODE_TITLES[activeMode]}`, "info");
			return;
		}
		pendingMode = mode;
		emitModeState();
		ctx.ui.notify(`queued mode: ${MODE_TITLES[mode]}`, "info");
	};

	const requestMode = (mode: Mode, ctx: ExtensionContext) => {
		if (ctx.isIdle()) {
			if (mode === activeMode && !pendingMode) return;
			applyMode(mode, ctx);
			return;
		}
		queueMode(mode, ctx);
	};

	const restoreMode = (ctx: ExtensionContext): Mode => {
		const flagValue = normalizeMode(String(pi.getFlag("agent-mode") ?? ""));
		if (flagValue) return flagValue;

		const entry = ctx.sessionManager
			.getEntries()
			.filter((e: { type: string; customType?: string }) => e.type === "custom" && e.customType === "mode-state")
			.pop() as { data?: { mode?: string } } | undefined;

		return normalizeMode(entry?.data?.mode) ?? DEFAULT_MODE;
	};

	const selectMode = async (ctx: ExtensionContext) => {
		if (!ctx.hasUI) {
			ctx.ui.notify(`current mode: ${MODE_TITLES[pendingMode ?? activeMode]}`, "info");
			return;
		}

		const effectiveMode = pendingMode ?? activeMode;
		const items = MODE_ORDER.map((mode) => {
			const marker = mode === effectiveMode ? " (selected)" : "";
			return `${MODE_TITLES[mode]}${marker} — ${MODE_DESCRIPTIONS[mode]}`;
		});
		const picked = await ctx.ui.select("Select mode", items);
		if (!picked) return;
		const matched = MODE_ORDER.find((mode) => picked.startsWith(MODE_TITLES[mode]));
		if (matched) requestMode(matched, ctx);
	};

	pi.registerFlag("agent-mode", {
		description: "Start in a specific agent mode: read-only, plan, yolo",
		type: "string",
	});

	pi.events.on(MODE_REQUEST_STATE_EVENT, emitModeState);

	pi.registerCommand("mode", {
		description: "Switch agent mode: read-only, plan, yolo",
		getArgumentCompletions(prefix) {
			const values = MODE_ORDER.filter((mode) => mode.startsWith(prefix.toLowerCase()));
			return values.length > 0 ? values.map((value) => ({ value, label: MODE_TITLES[value] })) : null;
		},
		handler: async (args, ctx) => {
			const input = args?.trim();
			if (!input) return selectMode(ctx);
			const mode = normalizeMode(input);
			if (!mode) {
				ctx.ui.notify("Unknown mode. Use: read-only, plan, yolo", "error");
				return;
			}
			requestMode(mode, ctx);
		},
	});

	pi.registerShortcut(Key.alt("m"), {
		description: "Cycle agent mode",
		handler: async (ctx) => requestMode(nextMode(pendingMode ?? activeMode), ctx),
	});

	pi.on("session_start", async (_event, ctx) => {
		applyMode(restoreMode(ctx), ctx, false, false);
		emitModeState();
	});

	pi.on("tool_call", async (event) => {
		if (activeMode === "yolo" || event.toolName !== "bash") return;
		const command = String((event.input as { command?: string }).command ?? "");
		if (isSafeBashCommand(command)) return;
		return {
			block: true,
			reason: `Mode ${MODE_TITLES[activeMode]} only allows safe non-mutating bash commands. Blocked: ${command}`,
		};
	});

	pi.on("before_agent_start", async (event) => ({
		systemPrompt: `${event.systemPrompt}\n${buildModeInstructions(activeMode)}`,
	}));

	pi.on("agent_end", async (_event, ctx) => {
		if (pendingMode) applyMode(pendingMode, ctx);
	});
}
