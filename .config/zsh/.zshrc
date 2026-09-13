#
#       _______| |__  _ __ ___
#      |_  / __| '_ \| '__/ __|
#       / /\__ \ | | | | | (__
#      /___|___/_| |_|_|  \___|
#

# Zap plugin manager
[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"

# Completion paths
fpath=(
  /opt/homebrew/share/zsh/site-functions
  "$ZDOTDIR/completions"
  $fpath
)

# Plugins
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-syntax-highlighting"
plug "esc/conda-zsh-completion"
plug "zap-zsh/supercharge"
plug "zap-zsh/fzf"
plug "sadiksaifi/zsh-keybindings"

# Mise
eval "$(mise activate zsh)"

# Completion system
autoload -Uz compinit
compinit

# Custom functions
for file in "$ZDOTDIR/functions"/*.zsh(N); do
  source "$file"
done

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

# General keybindings
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
alias confetti='open raycast-x://extensions/raycast/raycast/confetti'
alias ccd='claude --effort high --allow-dangerously-skip-permissions'
alias cx='codex -m gpt-5.6-sol -c model_reasoning_effort="high" --dangerously-bypass-approvals-and-sandbox'
alias gc='gemini --model gemini-3.1-pro-preview --yolo'
alias oc='opencode'
alias pi='mise x node@lts -- pi'
alias lg='lazygit'

# Trench
eval "$(trench shell-init zsh)"

# Prompt
eval "$(starship init zsh)"
