#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

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
if [ "$OS_TYPE" = "windows" ]; then
    echo "Windows is managed with PowerShell in this repository."
    echo "Please run ./uninstall.ps1 from PowerShell."
    exit 1
fi

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
CURRENT_HOOKS_PATH="$(git config --global --get core.hooksPath || true)"
if [ "$CURRENT_HOOKS_PATH" = "$DOTFILES_DIR/.githooks" ]; then
    git config --global --unset core.hooksPath
    echo "Unset global git hooks path ($DOTFILES_DIR/.githooks)."
fi
