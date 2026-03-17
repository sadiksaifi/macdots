#!/usr/bin/env bun
// ─────────────────────────────────────────────────────────────
// Claude Code Statusline Hook
// Reads JSON from stdin (piped by Claude Code) and outputs a
// single-line statusline with Nerd Font icons and ANSI colors.
//
// Example output:
//   󰇼 Opus 4.6 | ████░░░░░░ 40% |  3m |  main |  ~/projects/foo
//
// Segments:
//   1. Model       — colored by model family (purple/blue/green)
//   2. Context bar — █/░ usage bar, green <50%, yellow <80%, red 80%+
//   3. Session time— elapsed since session start, persisted in /tmp
//   4. Git branch  — current branch, hidden outside git repos
//   5. Directory   — tilde-contracted working dir, dimmed
//
// Requires: Bun, Nerd Font
// ─────────────────────────────────────────────────────────────
import { $ } from "bun";

interface StatusInput {
  model?: { display_name?: string };
  workspace?: { current_dir?: string };
  context_window?: { used_percentage?: number };
  cost?: { total_cost_usd?: number };
  session_id?: string;
  version?: string;
}

const input: StatusInput = await Bun.stdin.json();

const modelName = input.model?.display_name ?? "Claude";
const usedPct = input.context_window?.used_percentage ?? 0;
const dir = input.workspace?.current_dir ?? "";
const sessionId = input.session_id ?? "";

// ANSI codes
const RESET = "\x1b[0m";
const DIM = "\x1b[2m";

// Model color based on name
const modelLower = modelName.toLowerCase();
const modelColor = modelLower.includes("opus")
  ? "\x1b[35m"   // purple
  : modelLower.includes("sonnet")
    ? "\x1b[34m" // blue
    : modelLower.includes("haiku")
      ? "\x1b[32m" // green
      : "\x1b[37m"; // white

// Tilde-contract directory
const home = Bun.env.HOME ?? "";
const displayDir = home && dir.startsWith(home) ? "~" + dir.slice(home.length) : dir;

// Git branch
const gitResult = await $`git -C ${dir || "."} branch --show-current`.nothrow().quiet();
const branch = gitResult.exitCode === 0 ? gitResult.text().trim() : "";

// Session elapsed time
let elapsed = "";
if (sessionId) {
  const tmpFile = `/tmp/claude-sl-${sessionId}`;
  const file = Bun.file(tmpFile);
  if (await file.exists()) {
    const start = parseInt(await file.text());
    const secs = Math.floor((Date.now() - start) / 1000);
    const mins = Math.floor(secs / 60);
    const hrs = Math.floor(mins / 60);
    elapsed = hrs > 0 ? `${hrs}h${mins % 60}m` : mins > 0 ? `${mins}m` : `${secs}s`;
  } else {
    await Bun.write(tmpFile, Date.now().toString());
    elapsed = "0s";
  }
}

// Nerd Font icons
const ICON_MODEL = "\u{f01fc}";
const ICON_BRANCH = "\u{e0a0}";
const ICON_DIR = "\u{f07c}";
const ICON_TIME = "\u{f017}";
const SEP = "|";

// Context usage bar (color-coded)
const BAR_WIDTH = 10;
const filled = Math.max(1, Math.round((usedPct / 100) * BAR_WIDTH));
const barColor = usedPct < 50 ? "\x1b[32m" : usedPct < 80 ? "\x1b[33m" : "\x1b[31m";
const contextBar = `${barColor}${"█".repeat(filled)}${RESET}${"░".repeat(BAR_WIDTH - filled)}`;

// Build segments: Model | Context Bar | Session Time | Git Branch | Directory
const segments: string[] = [
  `${modelColor}${ICON_MODEL} ${modelName}${RESET}`,
  `${contextBar} ${usedPct}%`,
  ...(branch ? [`${ICON_BRANCH} ${branch}`] : []),
  `${DIM}${ICON_DIR} ${displayDir}${RESET}`,
  ...(elapsed ? [`${ICON_TIME} ${elapsed}`] : []),
];

await Bun.write(Bun.stdout, segments.join(` ${SEP} `) + "\n");
