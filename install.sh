#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

link_files() {
    local source="$1"
    local target="$2"
    if [ -e "$target" ]; then
        echo "File $target already exists in home directory. Skipping."
    else
        ln -s "$source" "$target"
        echo "Linked $source to home directory."
    fi
}

# Link dotfiles to home directory
source "$DOTFILES_DIR/install_targets.sh"
for item in "${INSTALL_TARGETS[@]}"; do
    if [ -e "$DOTFILES_DIR/$item" ]; then
        link_files "$DOTFILES_DIR/$item" "$HOME/$item"
    else
        echo "File or directory $item not found in dotfiles directory. Skipping."
    fi
done
echo "Dotfiles have been linked to your home directory."

# Install Homebrew packages
brew bundle --file="$DOTFILES_DIR/Brewfile"
echo "Homebrew packages have been installed."
