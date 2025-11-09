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
. "/Users/sdk/.local/share/bob/env/env.sh"

# Ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="$PATH:$(gem environment home)/bin"

# JAVA_HOME for Android Studio
export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Golang
export PATH="$PATH:$(/opt/homebrew/bin/go env GOPATH)/bin"

export PATH="$PATH:$(gem environment home)/bin"

# opencode
export PATH=/Users/sdk/.opencode/bin:$PATH

# Colima - Docker
export DOCKER_HOST=unix:///Users/sdk/.colima/default/docker.sock
