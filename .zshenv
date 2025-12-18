export ZDOTDIR="$HOME/.config/zsh"

# PATH & ENV EXPORTS
export PATH="$HOME/.local/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Node version manager (n)
export N_PREFIX="$HOME/n"
[[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"

# XCode
export PATH="/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH"

# Ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="$PATH:$(gem environment home)/bin"

# Deno
[ -s "$HOME/.deno/env" ] && . "$HOME/.deno/env"

# Golang GOPATH/bin
export PATH="$PATH:$(/opt/homebrew/bin/go env GOPATH)/bin"

# Android / Java
export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# Colima (Docker)
# export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"

# Bob
[ -s "$HOME/.local/share/bob/env/env.sh" ] && . "$HOME/.local/share/bob/env/env.sh"

# FZF
export FZF_DEFAULT_OPTS="\
--height=60% \
--margin=15%,15%,0% \
--pointer=' ' \
--prompt=' ' \
--color=gutter:-1 \
--border \
--layout=reverse \
--no-scrollbar \
--no-info \
--highlight-line"

# GLOBAL DEFAULTS
export TERM="xterm-256color"
export EDITOR="nvim"
export SUDO_EDITOR="nvim"
export READER="zathura"
export MANPAGER="nvim +Man!"
export LESSHISTFILE=-

# LOAD PERSONAL ENVIRONMENT VARIABLES

# Source all secret env files from ~/.secrets
if [ -d "$HOME/.secrets" ]; then
  for file in "$HOME/.secrets"/*; do
    [ -f "$file" ] && source "$file"
  done
fi

# COMPLETION PATH (safe at the end)

# Add deno / custom completions directory to FPATH
case ":$FPATH:" in
  *":$HOME/.config/zsh/completions:"*) ;;
  *) FPATH="$HOME/.config/zsh/completions:$FPATH" ;;
esac

# Bun completions (safe)
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# SVU completions
[ -s "$HOME/.config/zsh/completions/svu" ] && source "$HOME/.config/zsh/completions/svu"
