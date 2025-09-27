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
export FZF_DEFAULT_OPTS="--height=40% --margin=33%,33%,0% --pointer=' ' --prompt=' ' --color=gutter:-1 --border --layout=reverse --no-scrollbar --no-info --highlight-line"

# XCode
export PATH="/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH"
