if [[ -f /opt/homebrew/bin/brew ]]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export LESSCHARSET='utf-8'
export LESS='-R'
export GNUPGHOME="$HOME/.gnupg"
export BC_ENV_ARGS=~/.bc
