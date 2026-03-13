export ZDOTDIR="$HOME/.config/zsh"

export EDITOR="nvim"
export SUDO_EDITOR="nvim"
export LESSHISTFILE=-

# Load personal environment variables (API keys, tokens)
if [ -d "$HOME/.secrets" ]; then
  for file in "$HOME/.secrets"/*; do
    [ -f "$file" ] && . "$file"
  done
fi
