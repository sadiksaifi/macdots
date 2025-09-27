local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.automatically_reload_config = true
config.font_size = 20
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.color_scheme = "rose-pine-moon"
config.use_fancy_tab_bar = false
config.window_background_opacity = 0.7
config.macos_window_background_blur = 100
config.window_decorations = "RESIZE"
config.enable_tab_bar = false
config.colors ={background = "#000000"}
config.window_close_confirmation = "NeverPrompt"

config.window_frame = {
  border_left_width = '2px',
  border_right_width = '2px',
  border_bottom_height = '2px',
  border_top_height = '2px',
  border_left_color = '#444444',
  border_right_color = '#444444',
  border_bottom_color = '#444444',
  border_top_color = '#444444',
}

config.window_padding = {
  top = 10,
  right = 0,
  bottom = 0,
  left = 0,
}

config.prefer_egl = true

return config
