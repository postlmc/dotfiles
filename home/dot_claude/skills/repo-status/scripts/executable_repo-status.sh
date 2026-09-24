#!/usr/bin/env bash
# Deterministic git hygiene checks for the repo-status skill. Emits labeled sections
# for Claude to read and format into a table -- this script only gathers data, it
# doesn't format output for a human, since the presentation belongs in SKILL.md.

set -u
cd "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || {
    echo "ERROR: not inside a git repository"
    exit 1
}

echo "## repo"
git rev-parse --show-toplevel
echo "branch: $(git branch --show-current)"

echo
echo "## remote-fetch"
# A failed fetch (auth issues, offline) shouldn't kill the whole check -- report it
# and let everything downstream fall back to whatever remote-tracking refs are
# already cached locally, clearly labeled as possibly stale.
if git fetch --quiet --all 2>/tmp/repo-status-fetch-err; then
    echo "ok"
else
    echo "FAILED (remote-tracking refs below may be stale):"
    sed 's/^/  /' /tmp/repo-status-fetch-err
fi
rm -f /tmp/repo-status-fetch-err

echo
echo "## untracked-files"
git status --porcelain=v1 | awk '/^\?\?/ {print substr($0,4)}'

echo
echo "## uncommitted-changes"
git status --porcelain=v1 | awk '!/^\?\?/ {print}'

echo
echo "## stashes"
git stash list

echo
echo "## dangling-commits"
# --no-reflog excludes anything still protected by reflog (recent resets/amends,
# routine and recoverable) -- what's left is headed for gc on its own schedule.
# In a rebase/amend-heavy workflow this is *never* zero and almost never means
# anything: every amend and every rebase leaves its pre-rewrite commit unreachable,
# by design, harmlessly, forever (or until gc). Listing all of them by age buries
# the signal in months of routine churn, so only recent ones are worth a human
# actually looking at -- older ones are reported as a count only.
dangling_all=$(git fsck --no-reflog --unreachable --no-progress 2>/dev/null | awk '$2=="commit"{print $3}')
dangling_total=0
dangling_recent=""
cutoff=$(date -u -v-2d +%s 2>/dev/null || date -u -d '2 days ago' +%s)
for sha in $dangling_all; do
    dangling_total=$((dangling_total + 1))
    ts=$(git log -1 --format='%at' "$sha" 2>/dev/null)
    if [ -n "$ts" ] && [ "$ts" -ge "$cutoff" ]; then
        dangling_recent="${dangling_recent}$(git log -1 --format='%h %ai %s' "$sha" 2>/dev/null)
"
    fi
done
echo "total=${dangling_total} (routine amend/rebase byproduct in this repo's workflow; git gc reclaims these on its own schedule, no action needed)"
if [ -n "$dangling_recent" ]; then
    echo "recent (last 2 days, worth a look):"
    printf '%s' "$dangling_recent" | sed 's/^/  /'
fi

echo
echo "## local-branches"
git for-each-ref refs/heads/ --format='%(refname:short)|%(committerdate:iso-strict)|%(upstream:short)|%(upstream:track)' \
    | awk -F'|' '$1 != "main"'

echo
echo "## remote-branches"
# origin/HEAD's shortname can render as bare "origin" depending on git version,
# so both spellings are excluded alongside the real default branch.
git for-each-ref refs/remotes/ --format='%(refname:short)|%(committerdate:iso-strict)' \
    | awk -F'|' '$1 != "origin/main" && $1 != "origin/HEAD" && $1 != "origin"'

echo
echo "## main-sync"
if git rev-parse origin/main >/dev/null 2>&1; then
    ahead=$(git rev-list --count origin/main..main 2>/dev/null)
    behind=$(git rev-list --count main..origin/main 2>/dev/null)
    echo "ahead=${ahead:-0} behind=${behind:-0}"
else
    echo "no origin/main ref available"
fi
