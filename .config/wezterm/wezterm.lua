local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.automatically_reload_config = true
config.font_size = 20
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.color_scheme = "rose-pine-moon"
config.use_fancy_tab_bar = false
config.window_background_opacity = 1
config.macos_window_background_blur = 100
config.enable_tab_bar = false
config.colors ={background = "#141415"}
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.native_macos_fullscreen_mode = false -- Optional: Ensures macOS doesn't apply native styling

config.window_padding = {
  top = 0,
  right = 0,
  bottom = 0,
  left = 0,
}
config.adjust_window_size_when_changing_font_size = false

config.prefer_egl = true

return config
