import type { Mode } from "./protocol";

export const DEFAULT_MODE: Mode = "read-only";
export const MODE_ORDER: Mode[] = ["read-only", "plan", "yolo"];
export const MODE_TITLES: Record<Mode, string> = {
	"read-only": "Read-Only",
	plan: "Plan",
	yolo: "Yolo",
};
export const MODE_DESCRIPTIONS: Record<Mode, string> = {
	"read-only": "inspect/search/explain, no writes",
	plan: "investigate + produce implementation plan, no writes",
	yolo: "full access, execute changes",
};
export const MODE_TOOLS: Record<Mode, string[]> = {
	"read-only": ["read", "bash", "grep", "find", "ls"],
	plan: ["read", "bash", "grep", "find", "ls"],
	yolo: ["read", "bash", "edit", "write", "grep", "find", "ls"],
};

export function normalizeMode(input?: string): Mode | undefined {
	if (!input) return undefined;
	const value = input.trim().toLowerCase();
	if (value === "read-only" || value === "readonly" || value === "read_only" || value === "ro") {
		return "read-only";
	}
	if (value === "plan") return "plan";
	if (value === "yolo") return "yolo";
	return undefined;
}

export function nextMode(mode: Mode): Mode {
	const index = MODE_ORDER.indexOf(mode);
	return MODE_ORDER[(index + 1) % MODE_ORDER.length];
}
