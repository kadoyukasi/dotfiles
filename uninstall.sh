#!/bin/bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd -P)"
GIT_LOCAL_CONFIG="$HOME/.gitconfig.local"

detect_os() {
    case "$(uname -s)" in
        Darwin)
            echo "macos"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

OS_TYPE="$(detect_os)"
case "$OS_TYPE" in
    macos)
        ;;
    windows)
        echo "Windows is managed with PowerShell in this repository."
        echo "Please run ./uninstall.ps1 from PowerShell."
        exit 1
        ;;
    *)
        echo "Unsupported operating system: $(uname -s). This script supports macOS only."
        exit 1
        ;;
esac

remove_link() {
    local mode="$1" source="$2" target="$3"
    if [ "$mode" = link ] && ! has_linked_parent "$target" &&
       [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        rm "$target"
        echo "Removed $target."
    fi
}

source "$DOTFILES_DIR/install_targets.sh"
visit_dotfiles remove_link

if [ -f "$GIT_LOCAL_CONFIG" ] && [ ! -L "$GIT_LOCAL_CONFIG" ] &&
   [ "$(git config --file "$GIT_LOCAL_CONFIG" --get-all core.hooksPath || true)" = "$DOTFILES_DIR/.githooks" ]; then
    git config --file "$GIT_LOCAL_CONFIG" --unset core.hooksPath
    echo "Unset global git hooks path ($DOTFILES_DIR/.githooks)."
fi

if [ -e "$DOTFILES_DIR/.git" ] &&
   [ "$(git -C "$DOTFILES_DIR" config --local --get filter.codex-config.clean || true)" = .githooks/clean-codex-config ]; then
    git -C "$DOTFILES_DIR" config --local --remove-section filter.codex-config
    echo "Removed the repository-local Codex config filter."
fi
