import type { KeyId } from "@mariozechner/pi-tui";
import type { Mode, ModeSettings } from "./protocol";

export const DEFAULT_MODE: Mode = "read-only";
export const DEFAULT_MODE_SETTINGS: ModeSettings = {
	shortcuts: ["alt+m"],
	notifyOnChange: true,
};
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

export function normalizeShortcut(input?: unknown): KeyId | undefined {
	if (typeof input !== "string") return undefined;
	const value = input.trim().toLowerCase();
	if (!value || value === "off" || value === "none" || value === "false") return undefined;
	return value as KeyId;
}

export function normalizeShortcuts(input?: unknown): KeyId[] {
	if (Array.isArray(input)) return [...new Set(input.map((value) => normalizeShortcut(value)).filter(Boolean) as KeyId[])];
	const shortcut = normalizeShortcut(input);
	return shortcut ? [shortcut] : [];
}
