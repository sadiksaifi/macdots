import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { DEFAULT_MODE_STATE, MODE_REQUEST_STATE_EVENT, MODE_STATE_EVENT, type ModeState } from "./protocol";
import { renderRow1, renderRow2 } from "./render";

export default function statuslineExtension(pi: ExtensionAPI) {
	let modeState: ModeState = DEFAULT_MODE_STATE;
	let requestRender: (() => void) | undefined;

	const rerender = () => {
		requestRender?.();
	};

	pi.events.on(MODE_STATE_EVENT, (data) => {
		const next = data as ModeState;
		if (!next?.activeMode) return;
		modeState = next;
		rerender();
	});

	pi.on("session_start", async (_event, ctx) => {
		ctx.ui.setFooter((tui, _theme, footerData) => {
			requestRender = () => tui.requestRender();
			const disposeBranch = footerData.onBranchChange(() => tui.requestRender());
			return {
				dispose() {
					requestRender = undefined;
					disposeBranch();
				},
				invalidate() {},
				render(width: number): string[] {
					return [renderRow1(width, ctx, pi, footerData.getGitBranch()), renderRow2(width, ctx, modeState)];
				},
			};
		});
		pi.events.emit(MODE_REQUEST_STATE_EVENT, {});
		rerender();
	});

	pi.on("agent_end", async () => {
		rerender();
	});
	pi.on("model_select", async () => {
		rerender();
	});
	pi.on("message_end", async () => {
		rerender();
	});
	pi.on("session_shutdown", async () => {
		requestRender = undefined;
	});
}
