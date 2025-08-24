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
  local patch_file="/tmp/git-diff-$$.patch"

  # Get git diff output and save to patch file
  if ! git diff "$@" --no-color > "$patch_file"; then
    echo "Error: git diff failed"
    return 1
  fi

  # Check if there are any changes
  if [[ ! -s "$patch_file" ]]; then
    echo "No changes to display"
    rm -f "$patch_file"
    return 0
  fi

  # Open patch file in VS Code
  code "$patch_file"
}
