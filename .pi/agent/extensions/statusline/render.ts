import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import type { Mode, ModeState } from "./protocol";

type AssistantUsageMessage = {
	usage?: {
		input?: number;
		output?: number;
	};
};

const ICON_MODEL = "󰚩";
const ICON_BRANCH = "";
const ICON_DIR = "";
const SEP_RAW = " | ";
const BAR_FULL = "█";
const BAR_EMPTY = "░";
const BAR_WIDTH = 10;
const MODE_PREFIX = "▶▶";

function formatTokenCount(value: number): string {
	if (value < 1000) return `${Math.round(value)}`;
	if (value < 1_000_000) return `${(value / 1000).toFixed(value >= 10_000 ? 0 : 1)}k`;
	return `${(value / 1_000_000).toFixed(value >= 10_000_000 ? 0 : 1)}m`;
}

function getTokenDisplay(input: number, output: number, compactLevel: 0 | 1 | 2): string | undefined {
	if (compactLevel === 2) return undefined;
	const inText = formatTokenCount(input);
	const outText = formatTokenCount(output);
	return compactLevel === 1 ? `${inText}/${outText}` : `↑${inText} ↓${outText}`;
}

function collapseHome(path: string): string {
	const home = process.env.HOME;
	return home && path.startsWith(home) ? `~${path.slice(home.length)}` : path;
}

function middleTruncate(text: string, maxWidth: number): string {
	if (maxWidth <= 0) return "";
	if (visibleWidth(text) <= maxWidth) return text;
	if (maxWidth <= 1) return "…";
	if (maxWidth <= 3) return truncateToWidth(text, maxWidth, "");
	const chars = [...text];
	const keep = maxWidth - 1;
	const leftCount = Math.ceil(keep / 2);
	const rightCount = Math.floor(keep / 2);
	return `${chars.slice(0, leftCount).join("")}…${chars.slice(chars.length - rightCount).join("")}`;
}

function getModelDisplayName(ctx: ExtensionContext): string {
	const model = ctx.model as { name?: string; id?: string } | undefined;
	return model?.name ?? model?.id ?? "no-model";
}

function getThinkingDisplay(pi: ExtensionAPI): string {
	return pi.getThinkingLevel();
}

function getModeColor(mode: Mode): "warning" | "accent" | "error" {
	if (mode === "read-only") return "warning";
	if (mode === "plan") return "accent";
	return "error";
}

function renderModeText(ctx: ExtensionContext, modeState: ModeState): string {
	const theme = ctx.ui.theme;
	const prefix = theme.fg("dim", `${MODE_PREFIX} `);
	const active = theme.fg(getModeColor(modeState.activeMode), theme.bold(modeState.activeMode));
	if (modeState.pendingMode && modeState.pendingMode !== modeState.activeMode) {
		const arrow = theme.fg("dim", " → ");
		const pending = theme.fg(getModeColor(modeState.pendingMode), theme.bold(modeState.pendingMode));
		return `${prefix}${active}${arrow}${pending}`;
	}
	return `${prefix}${active}`;
}

function getTokenTotals(ctx: ExtensionContext): { input: number; output: number } {
	let input = 0;
	let output = 0;
	for (const entry of ctx.sessionManager.getBranch()) {
		if (entry.type !== "message" || entry.message.role !== "assistant") continue;
		const message = entry.message as AssistantUsageMessage;
		input += message.usage?.input ?? 0;
		output += message.usage?.output ?? 0;
	}
	return { input, output };
}

export function renderRow1(width: number, ctx: ExtensionContext, pi: ExtensionAPI, branch: string | null): string {
	const theme = ctx.ui.theme;
	const sep = theme.fg("dim", SEP_RAW);
	const modelName = getModelDisplayName(ctx);
	const thinking = getThinkingDisplay(pi);
	const modelText = `${ICON_MODEL} ${modelName} (${thinking})`;
	const contextUsage = ctx.getContextUsage();
	const rawPercent = contextUsage?.percent;
	const knownPercent = rawPercent != null;
	const percent = knownPercent ? Math.max(0, Math.min(100, Math.round(rawPercent))) : 0;
	const filledRaw = Math.round((percent / 100) * BAR_WIDTH);
	const filled = percent > 0 && filledRaw === 0 ? 1 : filledRaw;
	const barColor = percent < 50 ? "success" : percent < 80 ? "warning" : "error";
	const percentText = knownPercent ? `${percent}%` : "?%";
	const barText = `${theme.fg(barColor, BAR_FULL.repeat(filled))}${theme.fg("dim", BAR_EMPTY.repeat(BAR_WIDTH - filled))} ${theme.fg("muted", percentText)}`;
	const branchRaw = branch ? `${ICON_BRANCH} ${branch}` : undefined;
	const { input, output } = getTokenTotals(ctx);
	const tokenCandidates = [
		getTokenDisplay(input, output, 0),
		getTokenDisplay(input, output, 1),
		getTokenDisplay(input, output, 2),
	];

	for (const tokenDisplay of tokenCandidates) {
		for (const includeBranch of branchRaw ? [true, false] : [false]) {
			const rightParts = [tokenDisplay].filter(Boolean) as string[];
			const right = rightParts.map((part) => theme.fg("muted", part)).join(sep);
			const rightWidth = visibleWidth(right);
			const gap = rightWidth > 0 ? 1 : 0;
			const availableLeft = width - rightWidth - gap;
			if (availableLeft <= 0) continue;

			const modelMin = 10;
			const cwdMin = 12;
			const fixedSegments = [modelText, `${BAR_FULL.repeat(BAR_WIDTH)} ${percentText}`, includeBranch ? branchRaw : undefined].filter(
				Boolean,
			) as string[];
			const fixedWidth = fixedSegments.reduce((sum, item) => sum + visibleWidth(item), 0);
			const separatorWidth = Math.max(0, fixedSegments.length) * visibleWidth(SEP_RAW);
			const availableCwd = availableLeft - fixedWidth - separatorWidth;
			if (availableCwd < cwdMin) continue;

			const modelWidth = Math.min(visibleWidth(modelText), Math.max(modelMin, availableLeft / 3));
			const thinkingSuffix = ` (${thinking})`;
			const iconWidth = visibleWidth(`${ICON_MODEL} `);
			const thinkingWidth = visibleWidth(thinkingSuffix);
			const modelNameWidth = Math.max(1, Math.round(modelWidth) - iconWidth - thinkingWidth);
			const truncatedModel = truncateToWidth(modelName, modelNameWidth, "…");
			const renderedModel = `${theme.fg("muted", `${ICON_MODEL} `)}${theme.fg("accent", theme.bold(truncatedModel))}${theme.fg("dim", thinkingSuffix)}`;
			const renderedBranch = includeBranch && branchRaw ? `${theme.fg("dim", `${ICON_BRANCH} `)}${theme.fg("muted", branch)}` : undefined;
			const cwdWidth = Math.max(
				cwdMin,
				availableLeft - visibleWidth(renderedModel) - visibleWidth(barText) - (renderedBranch ? visibleWidth(renderedBranch) : 0) - separatorWidth,
			);
			const cwdBodyWidth = Math.max(1, cwdWidth - visibleWidth(`${ICON_DIR} `));
			const renderedCwd = `${theme.fg("dim", `${ICON_DIR} `)}${theme.fg("muted", middleTruncate(collapseHome(ctx.cwd), cwdBodyWidth))}`;
			const left = [renderedModel, barText, renderedBranch, renderedCwd].filter(Boolean).join(sep);
			const padding = rightWidth > 0 ? " ".repeat(Math.max(1, width - visibleWidth(left) - rightWidth)) : "";
			const candidate = rightWidth > 0 ? `${left}${padding}${right}` : left;
			if (visibleWidth(candidate) <= width) return candidate;
		}
	}

	return truncateToWidth(
		`${theme.fg("muted", `${ICON_MODEL} `)}${theme.fg("accent", theme.bold(modelName))}${theme.fg("dim", ` (${thinking})`)}` + sep + barText,
		width,
	);
}

export function renderRow2(width: number, ctx: ExtensionContext, modeState: ModeState): string {
	return truncateToWidth(renderModeText(ctx, modeState), width);
}
