# Setting ZDOTDIR
export ZDOTDIR="$HOME/.config/zsh"

# Setting Paths
export PATH="$HOME/.local/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Setting Defaults
export TERM="xterm-256color"
export EDITOR="nvim"
export SUDO_EDITOR="nvim"
export READER="zathura"
export MANPAGER="nvim +Man!"
export LESSHISTFILE=-

# N - Node version maanger
export N_PREFIX="$HOME/n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"

# FZF Exports
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview-window=right:60% --preview 'if [ -d {} ]; then fd --color=always . {} | bat --color=always --style=header,grid --line-range :500; else bat --color=always --style=header,grid --line-range :500 {}; fi'"
