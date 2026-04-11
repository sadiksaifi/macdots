# modes extension

agent-mode state machine for pi.

## public interface

- command: `/mode [read-only|plan|yolo]`
- command: `/mode-cycle`
- flag: `--agent-mode <mode>`
- event: `agent-mode:state`
- event request: `agent-mode:request-state`

## user config

pi has no first-class extension keybinding ids yet.
so this extension keeps:
- **pi built-in keybindings** in `~/.pi/agent/keybindings.json`
- **extension config** in `~/.pi/agent/settings.json` or `.pi/settings.json`

use `agentModes` namespace:

```json
{
  "agentModes": {
    "defaultMode": "read-only",
    "shortcuts": ["alt+m"],
    "notifyOnChange": true
  }
}
```

notes:
- project `.pi/settings.json` overrides global `~/.pi/agent/settings.json`
- set `"shortcuts": []` to disable extension shortcuts
- shortcut strings use pi key format, e.g. `"shift+tab"`, `"alt+m"`, `"ctrl+shift+m"`

## using shift+tab for modes

if you want `shift+tab` for mode cycling, free it in pi built-in keybindings first:

`~/.pi/agent/keybindings.json`

```json
{
  "app.thinking.cycle": ["alt+t"]
}
```

then set extension shortcut:

`~/.pi/agent/settings.json`

```json
{
  "agentModes": {
    "shortcuts": ["shift+tab"]
  }
}
```

then run `/reload`.
