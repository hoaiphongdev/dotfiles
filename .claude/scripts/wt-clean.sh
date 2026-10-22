#!/usr/bin/env bash
# Remove git worktrees under <repo>/.claude/worktrees that no Claude desktop session holds.
# Default is a dry run. --apply removes only clean worktrees whose HEAD is on a branch.
# --apply --include-dirty also removes worktrees with uncommitted changes (asks per worktree).
set -euo pipefail

REPO="${WT_REPO:-$HOME/Documents/workspaces/lumin/lumin-platform}"
SESSIONS_DIR="$HOME/Library/Application Support/Claude/claude-code-sessions"
APPLY=0
INCLUDE_DIRTY=0
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --include-dirty) INCLUDE_DIRTY=1 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

LOCK_DIR="${TMPDIR:-/tmp}/wt-clean.lock"
MIN_AGE_SECONDS=7200
mkdir "$LOCK_DIR" 2>/dev/null || { echo "wt-clean already running"; exit 0; }
held_file=$(mktemp)
trap 'rm -f "$held_file"; rmdir "$LOCK_DIR"' EXIT
find "$SESSIONS_DIR" -type f -name 'local_*.json' -print0 2>/dev/null \
  | xargs -0 grep -ho '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null \
  | sed -E 's/.*"cwd"[[:space:]]*:[[:space:]]*"([^"]*)"/\1/' \
  | sort -u > "$held_file" || true

[[ -s "$held_file" ]] || { echo "No session records found in $SESSIONS_DIR; refusing to continue." >&2; exit 1; }

cd "$REPO"
git worktree prune

removable=()
dirty=()
while IFS= read -r wt; do
  [[ "$wt" == "$REPO/.claude/worktrees/"* ]] || continue
  if grep -qxF "$wt" "$held_file"; then continue; fi
  [[ -d "$wt" ]] || continue
  # A session's record can land after its worktree exists; never touch a fresh one.
  (( $(date +%s) - $(stat -f %m "$wt/.git") < MIN_AGE_SECONDS )) && continue

  name=$(basename "$wt")
  changes=$(git -C "$wt" status --porcelain --untracked-files=no | wc -l | tr -d ' ')
  untracked=$(git -C "$wt" ls-files --others --exclude-standard | { grep -v '^node_modules$' || true; } | wc -l | tr -d ' ')
  on_branch=$(git -C "$wt" branch -a --contains HEAD 2>/dev/null | grep -vc 'HEAD detached' || true)
  size=$(du -sh "$wt" 2>/dev/null | cut -f1)
  printf '%-45s %6s  changes=%-6s untracked=%-4s on_branch=%s\n' "$name" "$size" "$changes" "$untracked" "$on_branch"

  if [[ "$changes" == 0 && "$untracked" == 0 && "$on_branch" != 0 ]]; then
    removable+=("$wt")
  else
    dirty+=("$wt")
  fi
done < <(git worktree list --porcelain | sed -n 's/^worktree //p')

echo
echo "Clean, safe to remove: ${#removable[@]}   With changes or unreachable commits: ${#dirty[@]}"
[[ $APPLY == 1 ]] || { echo "Dry run. Re-run with --apply to remove the clean ones."; exit 0; }

remove_wt() {
  find "$1" -maxdepth 3 -type l -name node_modules -delete
  git worktree remove --force "$1" && echo "removed $(basename "$1")"
}

for wt in "${removable[@]}"; do remove_wt "$wt"; done

if [[ $INCLUDE_DIRTY == 1 ]]; then
  for wt in "${dirty[@]}"; do
    read -r -p "Remove $(basename "$wt") and LOSE its uncommitted changes? [y/N] " ans </dev/tty
    [[ "$ans" == y ]] && remove_wt "$wt"
  done
fi

git worktree prune
df -h / | tail -1
