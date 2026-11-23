# Prefer Homebrew's GNU tools when present.
(( $+commands[ggrep] )) && alias grep='ggrep --color=auto'
(( $+commands[gls] )) && alias ls='gls --color=auto --show-control-chars'
