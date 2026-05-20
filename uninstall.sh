#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

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
