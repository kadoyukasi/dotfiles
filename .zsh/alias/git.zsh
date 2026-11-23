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

_git-vscode-patch() {
  local git_command="$1"
  shift
  local patch_dir patch_file result
  patch_dir="$(mktemp -d)" || return
  patch_file="$patch_dir/$git_command.patch"
  git "$git_command" "$@" > "$patch_file" && code --wait "$patch_file"
  result=$?
  rm -f -- "$patch_file"
  rmdir -- "$patch_dir"
  return "$result"
}

git-vscode-diff() {
  _git-vscode-patch diff "$@"
}

git-vscode-show() {
  _git-vscode-patch show "$@"
}
