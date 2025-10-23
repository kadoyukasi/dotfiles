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
  git diff "$@" > "$patch_file"
  code "$patch_file"
}

git-vscode-show() {
  local patch_file="/tmp/git-show-$$.patch"
  git show "$@" > "$patch_file"
  code "$patch_file"
}
