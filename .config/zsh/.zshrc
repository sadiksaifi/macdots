#	 _______| |__  _ __ ___
#	|_  / __| '_ \| '__/ __|
#	 / /\__ \ | | | | | (__
#	/___|___/_| |_|_|  \___|

# Zap plugin manager - https://www.zapzsh.com
[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"

# Completion paths
fpath=(
  /opt/homebrew/share/zsh/site-functions
  $HOME/.config/zsh/completions
  $fpath
)

# Plugins (load before compinit so plugin completions are registered)
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-syntax-highlighting"
plug "esc/conda-zsh-completion"
plug "zap-zsh/supercharge"
plug "zap-zsh/fzf"
plug "sadiksaifi/zsh-keybindings"

# Mise
eval "$(mise activate zsh)"

# Initialize completion system
autoload -Uz compinit
compinit

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

# General Key-bindings
bindkey -s '^o' 'tmux-sessionizer\n'
bindkey -s '^y' 'y\n'

# Aliases
alias cp='cp -ivr'
alias mv='mv -iv'
alias rm='safe-rm'
alias ls='eza -lh --color=auto --group-directories-first --icons'
alias ll='eza -lah --color=auto --group-directories-first --icons'
alias mkdir='mkdir -pv'
alias grep='grep --color=auto'
alias dots='/usr/bin/git --git-dir=$HOME/.macdots.git --work-tree=$HOME'
alias dots-sync-nvim='dots submodule update --remote .config/nvim && dots add -f .config/nvim && dots commit -m "chore: update nvim submodule"'
alias gitlog='git log --all --decorate --graph'
alias rmn='find . -type d -name "node_modules" -prune -exec \rm -rf {} +'
alias confetti='open raycast://extensions/raycast/raycast/confetti'
alias ccd='claude --model "sonnet" --effort high --dangerously-skip-permissions'
alias ccda='claude --model "sonnet" --effort high --dangerously-skip-permissions --agent ask'
alias cx='codex -m gpt-5.5 -c model_reasoning_effort="high" --dangerously-bypass-approvals-and-sandbox'
alias gc='gemini --model gemini-3.1-pro-preview --yolo'
alias oc='opencode'
alias pi='PI_PERMISSIONS_AUDIT=1 mise x node@24 -- pi'
alias lg='lazygit'

function y() {
	local tmp cwd
	tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || return 1
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	\rm -f -- "$tmp"
}

lninfo() {
  local path="${1:-.}"
  echo "${path:a} -> ${path:A}"
}

eval "$(trench shell-init zsh)"

# prompt
eval "$(starship init zsh)"
