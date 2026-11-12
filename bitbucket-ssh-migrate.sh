#!/usr/bin/env bash
# Rewrites Bitbucket SSH remotes from bitbucket.org to ssh.bitbucket.org
# for every git repo found under a folder (recursively).
#
# Usage: bitbucket-ssh-migrate.sh [-n|--dry-run] <folder>
#
# Handles scp-style (git@bitbucket.org:ws/repo.git) and ssh:// URLs, for both
# remote.<name>.url and remote.<name>.pushurl. HTTPS remotes are left alone.

set -euo pipefail

OLD_HOST="bitbucket.org"
NEW_HOST="ssh.bitbucket.org"
dry_run=0

usage() { echo "Usage: ${0##*/} [-n|--dry-run] <folder>" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) dry_run=1; shift ;;
    -h|--help) usage ;;
    -*) echo "Unknown option: $1" >&2; usage ;;
    *) break ;;
  esac
done
[[ $# -eq 1 && -d "$1" ]] || usage
root="$1"

rewrite() {
  # prints the new URL, or nothing if the URL isn't a Bitbucket SSH URL
  local url="$1" new
  new=$(printf '%s' "$url" | sed -E \
    -e "s#^([^@/:]+@)${OLD_HOST//./\\.}:#\\1${NEW_HOST}:#" \
    -e "s#^(ssh://([^@/]+@)?)${OLD_HOST//./\\.}([:/])#\\1${NEW_HOST}\\3#")
  [[ "$new" != "$url" ]] && printf '%s' "$new"
  return 0
}

repos=0 changed=0

# .git may be a directory (normal repo) or a file (worktree/submodule).
while IFS= read -r -d '' gitpath; do
  repo=$(dirname "$gitpath")
  repos=$((repos + 1))

  while IFS=$'\t' read -r key url; do
    [[ -n "$key" ]] || continue
    new=$(rewrite "$url")
    [[ -n "$new" ]] || continue
    changed=$((changed + 1))
    if (( dry_run )); then
      echo "[dry-run] $repo: $key"
    else
      git -C "$repo" config "$key" "$new"
      echo "[updated] $repo: $key"
    fi
    echo "    $url -> $new"
  done < <(git -C "$repo" config --local --null --get-regexp '^remote\..*\.(url|pushurl)$' 2>/dev/null \
            | tr '\0\n' '\n\t' | sed '/^$/d' || true)
done < <(find "$root" -name .git -prune -print0)

echo
echo "Scanned $repos repo(s); $changed URL(s) $( ((dry_run)) && echo 'would be' || echo 'were' ) changed."
