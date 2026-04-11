import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { resolve } from "node:path";
import { DEFAULT_MODE_SETTINGS, normalizeMode, normalizeShortcuts } from "./config";
import type { ModeSettings } from "./protocol";

type RawPiSettings = {
	agentModes?: {
		defaultMode?: unknown;
		shortcuts?: unknown;
		notifyOnChange?: unknown;
	};
};

function readJson(path: string): RawPiSettings | undefined {
	if (!existsSync(path)) return undefined;
	try {
		return JSON.parse(readFileSync(path, "utf8")) as RawPiSettings;
	} catch {
		return undefined;
	}
}

export function loadModeSettings(cwd = process.cwd()): ModeSettings {
	const globalSettings = readJson(resolve(homedir(), ".pi/agent/settings.json"));
	const projectSettings = readJson(resolve(cwd, ".pi/settings.json"));
	const merged = {
		...(globalSettings?.agentModes ?? {}),
		...(projectSettings?.agentModes ?? {}),
	};
	const defaultMode = normalizeMode(typeof merged.defaultMode === "string" ? merged.defaultMode : undefined);
	const shortcuts = merged.shortcuts === undefined ? DEFAULT_MODE_SETTINGS.shortcuts : normalizeShortcuts(merged.shortcuts);
	return {
		defaultMode,
		shortcuts,
		notifyOnChange: typeof merged.notifyOnChange === "boolean" ? merged.notifyOnChange : DEFAULT_MODE_SETTINGS.notifyOnChange,
	};
}
