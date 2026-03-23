# Global Rules

## File Operations
- **Delete:** `safe-rm` only — never `rm`
- **Search:** `rg` only — never `grep`
- **Find:** `fd` only — never `find`

## JS/TS
- **Always TypeScript** — never plain JS unless told
- **Always `bun`** — never `npm`, `npx`, `pnpm`, `yarn`, `node`, `python`
  - `bun install` / `bun add` / `bun remove` / `bun run` / `bunx` / `bun -e "..."`

## Python
- **Always `uv`** — never `pip`, `pip3`, `python`, `python3`, `pipx`, `virtualenv`, `conda`
  - `uv run` / `uv add` / `uv remove` / `uv sync` / `uv venv` / `uv pip` / `uvx`

## Plan Mode
- Be extremely concise — sacrifice grammar for brevity
- End with unresolved questions (if any)

## Deviation Policy
Only deviate from any rule above if explicitly instructed.
