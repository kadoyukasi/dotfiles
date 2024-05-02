HISTFILE=~/.zsh_history_test
HISTSIZE=10000
SAVEHIST=10000
setopt append_history
setopt share_history
setopt hist_ignore_all_dups

stty -ixon

bindkey -e
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
bindkey '^P' history-beginning-search-backward
bindkey '^N' history-beginning-search-forward

eval "$(sheldon source)"
eval "$(mise activate zsh)"
source "$HOME/.cargo/env"
source $HOME/.wasmedge/env
