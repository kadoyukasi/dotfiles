dotfile_destination() {
    case "$1" in
        .codex/*) printf '%s/%s\n' "${CODEX_HOME:-$HOME/.codex}" "${1#.codex/}" ;;
        .config/gh/*)
            printf '%s/%s\n' "${GH_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/gh}" "${1#.config/gh/}"
            ;;
        .config/*) printf '%s/%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}" "${1#.config/}" ;;
        *) printf '%s/%s\n' "$HOME" "$1" ;;
    esac
}

has_linked_parent() {
    local parent="${1%/*}"
    while [ -n "$parent" ] && [ "$parent" != "$HOME" ]; do
        if [ -L "$parent" ]; then
            echo "Skipping $1: parent directory $parent is a symlink." >&2
            return 0
        fi
        case "$parent" in
            */*) parent="${parent%/*}" ;;
            *) break ;;
        esac
    done
    return 1
}

visit_dotfiles() {
    local action="$1" mode item
    while read -r mode item; do
        "$action" "$mode" "$DOTFILES_DIR/$item" "$(dotfile_destination "$item")"
    done < "$DOTFILES_DIR/install_targets.txt"
    "$action" link "$DOTFILES_DIR/Brewfile" "$HOME/Brewfile"
}
