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

if [[ -t 0 ]]; then
  stty -ixon
fi

bindkey -e
bindkey "^@" undefined-key  # free Ctrl+Space (^@/NUL) for Japanese IME switching
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down
bindkey "^[[3~" delete-char
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line

zstyle ':completion:*' completer _complete _history
zstyle ':completion:*' menu select=1
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes

(( $+commands[sheldon] )) && eval "$(sheldon source)"
(( $+commands[mise] )) && eval "$(mise activate zsh)"
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -r "$HOME/.wasmedge/env" ]] && source "$HOME/.wasmedge/env"
[[ -r "$HOME/.rye/env" ]] && source "$HOME/.rye/env"

# pnpm
if [[ -z $PNPM_HOME && $OSTYPE == darwin* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
fi
if [[ -n $PNPM_HOME ]]; then
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
fi
# pnpm end

# pure prompt with clover
export PURE_PROMPT_SYMBOL='🍀'

# cache zshrc
if [[ ! -e "$HOME/.zshrc.zwc" || "$HOME/.zshrc" -nt "$HOME/.zshrc.zwc" ]]; then
  zcompile "$HOME/.zshrc"
fi
