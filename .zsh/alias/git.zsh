# expect olets/zsh-abbr
alias git-cleanup-branches='
  git fetch --prune
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  remote_branches=$(git branch -r | sed "s|origin/||" | grep -v "HEAD")
  local_branches=$(git branch --format="%(refname:short)")

  echo "$local_branches" | while read branch; do
    if [ "$branch" != "$current_branch" ]; then
      if ! echo "$remote_branches" | grep -qx "$branch"; then
        echo "Deleting local branch: $branch"
        git branch -D "$branch"
      fi
    else
      echo "Skipping current branch: $branch"
    fi
  done
'

git-vscode-diff() {
  local diff_output

  # Get the diff output
  diff_output=$(git diff "$@" --no-color 2>/dev/null)

  # Check if there are any changes
  if [[ -z "$diff_output" ]]; then
    echo "No changes to display"
    return 0
  fi

  # Check if we can create a meaningful file-based comparison
  # This handles cases like: git-vscode-diff file.txt, git-vscode-diff HEAD file.txt, etc.
  local target_file=""
  local base_commit="HEAD"

  # Parse arguments to find file and commit
  if [[ $# -eq 1 ]]; then
    if [[ -f "$1" ]]; then
      # Single file argument
      target_file="$1"
    else
      # Commit argument (like HEAD~~)
      base_commit="$1"
    fi
  elif [[ $# -eq 2 ]]; then
    # Two arguments: could be commit + file or two commits
    if [[ -f "$2" ]]; then
      base_commit="$1"
      target_file="$2"
    fi
  fi

  # If we have a specific file to compare, show side-by-side diff
  if [[ -n "$target_file" ]]; then
    local before_file after_file
    before_file=$(mktemp)
    after_file=$(mktemp)

    # Cleanup function
    cleanup() {
      [[ -f "$before_file" ]] && rm -f "$before_file"
      [[ -f "$after_file" ]] && rm -f "$after_file"
    }
    trap cleanup EXIT

    # Create before and after versions
    git show "${base_commit}:${target_file}" > "$before_file" 2>/dev/null || touch "$before_file"
    cp "$target_file" "$after_file" 2>/dev/null || touch "$after_file"

    # Open in VS Code diff view
    code --wait --diff "$before_file" "$after_file"
  else
    # For commit comparisons or multiple files, create a patch file
    local patch_file patch_file_with_ext
    patch_file=$(mktemp)
    patch_file_with_ext="${patch_file}.patch"

    echo "$diff_output" > "$patch_file_with_ext"

    # Cleanup function for patch file
    cleanup_patch() {
      [[ -f "$patch_file" ]] && rm -f "$patch_file"
      [[ -f "$patch_file_with_ext" ]] && rm -f "$patch_file_with_ext"
    }
    trap cleanup_patch EXIT

    # Open the patch file in VS Code with syntax highlighting
    code --wait "$patch_file_with_ext"
  fi
}
