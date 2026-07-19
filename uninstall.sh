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
    local source="$1"
    local target="$2"
    local link_source
    if [ -L "$target" ]; then
        link_source="$(readlink "$target")"
        if [ "$link_source" = "$source" ]; then
            rm "$target"
            echo "Removed $target."
        else
            echo "$target points outside this dotfiles clone. Skipping."
        fi
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

    source_path="$DOTFILES_DIR/$item"
    target="$HOME/$item"
    remove_link "$source_path" "$target"
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

if git -C "$DOTFILES_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$DOTFILES_DIR" config --remove-section filter.codex-config 2>/dev/null || true
    echo "Removed the repository-local Codex config filter."
fi
