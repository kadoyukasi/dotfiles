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

should_unlink_item() {
    local item="$1"
    if [ "$item" = "Scoopfile" ]; then
        return 1
    fi

    return 0
}

remove_link() {
    local target="$1"
    if [ -L "$target" ]; then
        rm "$target"
        echo "Removed $target."
    else
        echo "No symlink found for $target. Skipping."
    fi
}

# Remove dotfile links from home directory
source "$DOTFILES_DIR/install_targets.sh"
for item in "${INSTALL_TARGETS[@]}"; do
    if ! should_unlink_item "$item"; then
        continue
    fi

    target="$HOME/$item"
    remove_link "$target"
done
echo "Dotfiles have been uninstalled."

# Remove global hooksPath if it points to this repository
CURRENT_HOOKS_PATH="$(git config --file "$GIT_LOCAL_CONFIG" --get core.hooksPath 2>/dev/null || true)"
CURRENT_HOOKS_DIR=""
if [ -n "$CURRENT_HOOKS_PATH" ] && [ -d "$CURRENT_HOOKS_PATH" ]; then
    CURRENT_HOOKS_DIR="$(cd "$CURRENT_HOOKS_PATH" && pwd -P)"
fi

if [ "$CURRENT_HOOKS_DIR" = "$DOTFILES_DIR/.githooks" ]; then
    git config --file "$GIT_LOCAL_CONFIG" --unset core.hooksPath
    echo "Unset global git hooks path ($DOTFILES_DIR/.githooks)."
fi
