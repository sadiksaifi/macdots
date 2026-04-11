import type { Mode } from "./protocol";

export function buildModeInstructions(mode: Mode): string {
	if (mode === "read-only") {
		return `
## Active Mode: Read-Only

You are in Read-Only mode.
- Inspect, analyze, search, explain, review.
- Do NOT modify files.
- Do NOT claim you changed anything.
- Bash is available only for safe non-mutating inspection commands.
- If the user asks for implementation or edits, explain that this mode is read-only and suggest switching to Yolo mode.
- Keep responses direct and useful.
`;
	}

	if (mode === "plan") {
		return `
## Active Mode: Plan

You are in Plan mode.
- Inspect, analyze, and design only.
- Do NOT modify files.
- Do NOT claim you changed anything.
- Bash is available only for safe non-mutating inspection commands.
- Ask clarifying questions only when ambiguity materially affects the plan; otherwise proceed and state assumptions.
- Produce a structured implementation plan.
- Prefer this response shape when appropriate:
  1. Summary / assumptions
  2. Files or areas likely affected
  3. Numbered implementation steps
  4. Risks / edge cases
  5. Tests / validation
- If the user asks you to implement, explain that Plan mode is planning-only and suggest switching to Yolo mode.
`;
	}

	return `
## Active Mode: Yolo

You are in Yolo mode.
- Full tool access is allowed.
- You may inspect, edit, write, and run commands as needed.
- Execute changes directly while still following project instructions and keeping scope tight.
- Validate changes where appropriate.
`;
}
