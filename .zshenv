if [[ $OSTYPE == darwin* ]]; then
  if (( $+commands[brew] )); then
    eval "$(brew shellenv)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

export LESSCHARSET='utf-8'
export LESS='-R'
export GNUPGHOME="$HOME/.gnupg"
export BC_ENV_ARGS=~/.bc
