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

#General Key-bindings
bindkey -s '^f' 'tmux-sessionizer\n'

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

# Prompt
eval "$(starship init zsh)"

# bun completions
[ -s "/Users/sdk/.bun/_bun" ] && source "/Users/sdk/.bun/_bun"
. "/Users/sdk/.deno/env"

# Add deno completions to search path
if [[ ":$FPATH:" != *":/Users/sdk/.config/zsh/completions:"* ]]; then export FPATH="/Users/sdk/.config/zsh/completions:$FPATH"; fi
