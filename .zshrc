HISTFILE=~/.zsh_history_test
HISTSIZE=10000
SAVEHIST=10000
setopt AUTO_PARAM_SLASH
setopt CORRECT
setopt EXTENDED_GLOB
setopt GLOB_DOTS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt IGNORE_EOF
setopt INTERACTIVE_COMMENTS
setopt MARK_DIRS
setopt PRINT_EIGHT_BIT
setopt PROMPT_SUBST
setopt SHARE_HISTORY

stty -ixon

bindkey -e
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
bindkey '^P' history-beginning-search-backward
bindkey '^N' history-beginning-search-forward
bindkey "^[[3~" delete-char
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line

eval "$(sheldon source)"
eval "$(mise activate zsh)"
source "$HOME/.cargo/env"
source $HOME/.wasmedge/env
