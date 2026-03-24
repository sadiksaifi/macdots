# Deduplicate PATH
typeset -U PATH

# Brew shellenv
eval "$(/opt/homebrew/bin/brew shellenv)"

# OrbStack
source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || :

# PATH
export PATH="$HOME/.local/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Xcode
export PATH="/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH"

# Ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# Android / Java
export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools"

# Rust toolchain
. "$HOME/.cargo/env"

# Interactive defaults
export TERM="xterm-256color"
export READER="zathura"
export MANPAGER="nvim +Man!"
export PATH="/Users/sdk/.lmstudio/bin:$PATH"
