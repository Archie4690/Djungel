# Archie's zsh config built from scratch

# Insert .zsh_history
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

# Set zsh history settings
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS

# Load secrets from a private file instead of committing them here
[[ -r "$HOME/.config/zsh/secrets.zsh" ]] && source "$HOME/.config/zsh/secrets.zsh"

# Launch Tmux on start
if [ -z "$TMUX" ]; then
  exec tmux new-session -A -s general
fi

# Prompt
git_branch() {
  local branch
  branch=$(git branch --show-current 2>/dev/null)
  [[ -n "$branch" ]] && echo " %F{5}($branch)%f"
}
setopt PROMPT_SUBST

# vi mode
bindkey -v
export KEYTIMEOUT=1
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M vicmd '^R' history-incremental-search-backward

function zle-keymap-select {
  case $KEYMAP in
    vicmd) VI_MODE="%F{1}❯%f" ;;
    *)     VI_MODE="%F{2}❯%f" ;;
  esac
  zle reset-prompt
}
zle -N zle-keymap-select

function zle-line-init {
  zle -K viins
}
zle -N zle-line-init

function _vi_mode_reset {
  VI_MODE="%F{2}❯%f"
}
precmd_functions+=(_vi_mode_reset)

PROMPT='%F{3}[%D{%H:%M}]%f %F{7}%~%f$(git_branch) ${VI_MODE} %f'

# Aliases
alias connectmusic="~/.config/hypr/Scripts/speakerconnect.sh"
alias swapaudiooutput="~/.config/hypr/Scripts/swapAudioOutput.sh"
alias testserver="~/.config/scripts/testserver.sh"
alias cobblemon="~/.config/scripts/cobblemon.sh"
alias workMount="~/.config/scripts/mount-servers.sh"
alias console="~/.config/scripts/console.sh"
alias ..='cd ..'
alias ...='cd ../..'

# Only show Neofetch on local interactive terminals
if [[ $- == *i* ]] && [ -t 1 ] && [ -z "$TMUX" ] && [ -z "$SSH_CONNECTION" ]; then
  neofetch
fi

# Syntax highlighting (must be last or near-last)
if [[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Autosuggestions (can be before highlighting)
if [[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Keybinds
bindkey '^[[1;5D' backward-word   # Ctrl + Left
bindkey '^[[1;5C' forward-word    # Ctrl + Right

# fzf keybindings
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# fzf settings/exclusions
export FZF_DEFAULT_COMMAND='fd --type f --hidden \
  --exclude .git \
  --exclude .venv \
  --exclude venv \
  --exclude __pycache__ \
  --exclude .cache \
  --exclude node_modules \
  --exclude .steam \
  --exclude Steam \
  --exclude steamapps'

bindkey -r '^T'
bindkey '^F' fzf-file-widget

export FZF_ALT_C_COMMAND='fd --type d --hidden \
  --exclude .git \
  --exclude .venv \
  --exclude venv \
  --exclude .cache \
  --exclude node_modules \
  --exclude .steam \
  --exclude Steam \
  --exclude steamapps'

export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"
