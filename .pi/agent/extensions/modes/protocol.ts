export type Mode = "read-only" | "plan" | "yolo";

export type ModeState = {
	activeMode: Mode;
	pendingMode?: Mode;
};

export const MODE_STATE_EVENT = "agent-mode:state";
export const MODE_REQUEST_STATE_EVENT = "agent-mode:request-state";
