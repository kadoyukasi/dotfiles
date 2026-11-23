#!/bin/bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd -P)"
GIT_LOCAL_CONFIG="$HOME/.gitconfig.local"
HOOKS_PATH="$DOTFILES_DIR/.githooks"

if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != --no-packages ]; }; then
    echo "Usage: $0 [--no-packages]" >&2
    exit 2
fi

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

install_packages() {
    if command -v brew >/dev/null 2>&1; then
        brew bundle --file="$DOTFILES_DIR/Brewfile"
        echo "Homebrew packages have been installed."
    else
        echo "Homebrew is not installed. Skipping package installation."
    fi
}

install_file() {
    local mode="$1" source="$2" target="$3"
    if has_linked_parent "$target"; then
        return
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "Already exists. Skipping $target."
        return
    fi

    (umask 077; mkdir -p "${target%/*}")
    if [ "$mode" = copy ]; then
        (umask 077; set -o noclobber; cat "$source" > "$target")
        echo "Initialized $target."
    else
        ln -s "$source" "$target"
        echo "Linked $source to home directory."
    fi
}

install_global_hook() {
    local global_path local_path
    global_path="$(git config --global --includes --get core.hooksPath || true)"
    local_path="$(git config --file "$GIT_LOCAL_CONFIG" --get-all core.hooksPath || true)"
    if [ -L "$GIT_LOCAL_CONFIG" ]; then
        echo "Leaving symlinked $GIT_LOCAL_CONFIG untouched." >&2
    elif { [ -n "$global_path" ] && [ "$global_path" != "$HOOKS_PATH" ]; } ||
         { [ -n "$local_path" ] && [ "$local_path" != "$HOOKS_PATH" ]; }; then
        echo "Leaving existing core.hooksPath unchanged." >&2
    else
        git config --file "$GIT_LOCAL_CONFIG" core.hooksPath "$HOOKS_PATH"
        if [ "$(git config --global --includes --get core.hooksPath || true)" = "$HOOKS_PATH" ]; then
            echo "Global Git hooks enabled via $GIT_LOCAL_CONFIG."
        else
            echo "Global Git hooks are inactive. Include ~/.gitconfig.local in your global Git config." >&2
        fi
    fi
}

source "$DOTFILES_DIR/install_targets.sh"
visit_dotfiles install_file
install_global_hook
if [ -e "$DOTFILES_DIR/.git" ]; then
    git -C "$DOTFILES_DIR" config --local filter.codex-config.clean .githooks/clean-codex-config
    git -C "$DOTFILES_DIR" config --local filter.codex-config.smudge cat
    git -C "$DOTFILES_DIR" config --local filter.codex-config.required true
    echo "Enabled the repository-local Codex config filter."
fi
if [ "$#" -eq 0 ]; then
    install_packages
fi
