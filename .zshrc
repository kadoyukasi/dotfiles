HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# https://zsh.sourceforge.io/Doc/Release/Options.html
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
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down
bindkey "^[[3~" delete-char
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line

zstyle ':completion:*' completer _complete _history
zstyle ':completion:*' menu select=1
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes

eval "$(sheldon source)"
eval "$(mise activate zsh)"
source "$HOME/.cargo/env"
source $HOME/.wasmedge/env
source "$HOME/.rye/env"

# pnpm
export PNPM_HOME="/Users/kyasu/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# pure prompt with clover
export PURE_PROMPT_SYMBOL='🍀'

# cache zshrc
if [ ! -e $HOME/.zshrc.zwc -o $HOME/.zshrc -nt $HOME/.zshrc.zwc ]; then
  zcompile $HOME/.zshrc
fi
