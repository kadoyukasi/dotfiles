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
        echo "Please run ./install.ps1 from PowerShell."
        exit 1
        ;;
    *)
        echo "Unsupported operating system: $(uname -s). This script supports macOS only."
        exit 1
        ;;
esac

should_link_item() {
    local item="$1"
    if [ "$item" = "Scoopfile" ]; then
        return 1
    fi

    return 0
}

install_packages() {
    if command -v brew >/dev/null 2>&1; then
        brew bundle --file="$DOTFILES_DIR/Brewfile"
        echo "Homebrew packages have been installed."
    else
        echo "Homebrew is not installed. Skipping package installation."
    fi
}

link_files() {
    local source="$1"
    local target="$2"
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "File $target already exists in home directory. Skipping."
    else
        ln -s "$source" "$target"
        echo "Linked $source to home directory."
    fi
}

# Link dotfiles to home directory
source "$DOTFILES_DIR/install_targets.sh"
for item in "${INSTALL_TARGETS[@]}"; do
    if ! should_link_item "$item"; then
        continue
    fi

    if [ -e "$DOTFILES_DIR/$item" ]; then
        link_files "$DOTFILES_DIR/$item" "$HOME/$item"
    else
        echo "File or directory $item not found in dotfiles directory. Skipping."
    fi
done
echo "Dotfiles have been linked to your home directory."

# Enable machine-wide git hooks (applies to all repositories unless overridden)
if git -C "$DOTFILES_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    git config --file "$GIT_LOCAL_CONFIG" core.hooksPath "$DOTFILES_DIR/.githooks"
    echo "Global git hooks path has been set to $DOTFILES_DIR/.githooks."

    git -C "$DOTFILES_DIR" config filter.codex-config.clean .githooks/clean-codex-config
    git -C "$DOTFILES_DIR" config filter.codex-config.smudge cat
    git -C "$DOTFILES_DIR" config filter.codex-config.required true
    echo "Codex machine-local config state will be excluded from Git blobs."
fi

install_packages
