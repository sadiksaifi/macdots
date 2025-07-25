#	 _______| |__  _ __ ___
#	|_  / __| '_ \| '__/ __|
#	 / /\__ \ | | | | | (__
#	/___|___/_| |_|_|  \___|

# Zap plugin manager - https://www.zapzsh.com
[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"

# Plugins
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-syntax-highlighting"
plug "esc/conda-zsh-completion"
plug "zap-zsh/supercharge"
plug "zap-zsh/fzf"
plug "sadiksaifi/zsh-keybindings" ## Checkout https://github.com/sadiksaifi/zsh-keybindings

#General Key-bindings
bindkey -s '^o' 'tmux-sessionizer\n'
bindkey -s '^y' 'y\n'

#Aliases
alias cp='cp -ivr'
alias mv='mv -iv'
alias rm="trash"
alias ls='eza -lh --color=auto --group-directories-first --icons'
alias ll='eza -lah --color=auto --group-directories-first --icons'
alias mkdir='mkdir -pv'
alias grep='grep --color=auto'
alias dots='/usr/bin/git --git-dir=$HOME/.macdots.git --work-tree=$HOME'
alias gitlog='git log --all --decorate --graph'
alias rmn='find . -type d -name "node_modules" -prune -exec \rm -rf {} +'

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Prompt
eval "$(starship init zsh)"

# bun completions
[ -s "/Users/sdk/.bun/_bun" ] && source "/Users/sdk/.bun/_bun"
. "/Users/sdk/.deno/env"

# Add deno completions to search path
if [[ ":$FPATH:" != *":/Users/sdk/.config/zsh/completions:"* ]]; then export FPATH="/Users/sdk/.config/zsh/completions:$FPATH"; fi
