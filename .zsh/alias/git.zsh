alias git-cleanup-branches='
  git fetch --prune
  remote_branches=$(git branch -r | awk "{print \$1}" | sed "s|origin/||")
  local_branches=$(git branch --format="%(refname:short)")

  for branch in $local_branches; do
    if ! echo "$remote_branches" | grep -qx "$branch"; then
      git branch -D "$branch"
    fi
  done
'
