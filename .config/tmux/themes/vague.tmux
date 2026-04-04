#!/usr/bin/env bash
# Vague - a tmux theme

# -- Palette --
bg="#141415"
fg="#cdcdcd"
gray="#252530"
black4="#606079"
magenta="#bb9dbd"
pink="#c9b1ca"
red="#d8647e"
green="#7fa563"
yellow="#f3be7c"
blue="#6e94b2"
cyan="#aeaed1"

# -- Special characters (hex-encoded to survive file writes) --
sep=$'\xe2\x96\x88'             # U+2588 FULL BLOCK
icon_folder=$'\xef\x81\xbb'    # U+F07B nf-fa-folder
icon_zoom=$'\xef\x94\x9e'      # U+F51E nf-md-magnify-scan

# -- Window formats --
win_default="#[fg=$bg,bg=$bg,nobold,nounderscore,noitalics]${sep}#[fg=$fg,bg=$bg]#I #[fg=$fg,bg=$bg,nobold,nounderscore,noitalics]#[fg=$fg,bg=$bg] #W #{?window_zoomed_flag, ${icon_zoom},}#[fg=$bg,bg=$bg]${sep}"

win_current="#[fg=$magenta,bg=$bg]${sep}#[fg=$gray,bg=$magenta]#I #[fg=$magenta,bg=$gray,nobold,nounderscore,noitalics]#[fg=$fg,bg=$gray] #W #{?window_zoomed_flag, ${icon_zoom},}#[fg=$gray,bg=$bg,nobold,nounderscore,noitalics]${sep}"

# -- Status right: directory + session modules --
mod_directory="#[fg=$blue,bg=$bg,nobold,nounderscore,noitalics]${sep}#[fg=$bg,bg=$blue,nobold,nounderscore,noitalics]${icon_folder} #[fg=$fg,bg=$gray] #{b:pane_current_path}#[fg=$gray,bg=$gray,nobold,nounderscore,noitalics]${sep}"

mod_session="#[fg=#{?client_prefix,$red,$green},bg=$gray,nobold,nounderscore,noitalics]${sep}#[fg=$bg,bg=#{?client_prefix,$red,$green},nobold,nounderscore,noitalics]session #[fg=$fg,bg=$gray] #S#[fg=$gray,bg=$gray,nobold,nounderscore,noitalics]${sep}"

# -- Apply --
tmux \
  set-option -gq status on \;\
  set-option -gq status-bg "$bg" \;\
  set-option -gq status-justify left \;\
  set-option -gq status-left-length 100 \;\
  set-option -gq status-right-length 100 \;\
\
  set-option -gq message-style "fg=$cyan,bg=$gray,align=centre" \;\
  set-option -gq message-command-style "fg=$cyan,bg=$gray,align=centre" \;\
\
  set-window-option -gq pane-active-border-style "fg=$magenta" \;\
  set-window-option -gq pane-border-style "fg=$gray" \;\
\
  set-window-option -gq window-status-activity-style "fg=$fg,bg=$bg,none" \;\
  set-window-option -gq window-status-separator "" \;\
  set-window-option -gq window-status-style "fg=$fg,bg=$bg,none" \;\
\
  set-window-option -gq window-status-format "$win_default" \;\
  set-window-option -gq window-status-current-format "$win_current" \;\
\
  set-option -gq status-left "" \;\
  set-option -gq status-right "${mod_directory}" \;\
\
  set-window-option -gq clock-mode-colour "$blue" \;\
  set-window-option -gq mode-style "fg=$pink bg=$black4 bold" \;\
\
  bind -n MouseDown1StatusRight choose-tree -Zs
