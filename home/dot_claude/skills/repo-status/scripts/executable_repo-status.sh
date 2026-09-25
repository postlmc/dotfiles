#!/usr/bin/env bash
# Deterministic git/forge checks for the repo-status skill. Emits labeled sections for
# Claude to read and format into a table -- this script only gathers data, it doesn't
# format output for a human, since the presentation belongs in SKILL.md.

set -u
cd "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || {
    echo "ERROR: not inside a git repository"
    exit 1
}

fetch_err_file=$(mktemp) || exit 1
trap 'rm -f "$fetch_err_file"' EXIT

echo "## repo"
git rev-parse --show-toplevel
current_branch=$(git branch --show-current)
if [ -z "$current_branch" ]; then
    echo "branch: (detached HEAD at $(git rev-parse --short HEAD))"
else
    echo "branch: ${current_branch}"
fi

echo
echo "## repo-state"
# In-progress operations are real leftover work in their own right, distinct from
# anything checked below -- worth a hard stop before touching anything else.
git_dir=$(git rev-parse --git-dir)
state=""
[ -f "${git_dir}/MERGE_HEAD" ] && state="${state}merge-in-progress "
{ [ -d "${git_dir}/rebase-merge" ] || [ -d "${git_dir}/rebase-apply" ]; } && state="${state}rebase-in-progress "
[ -f "${git_dir}/CHERRY_PICK_HEAD" ] && state="${state}cherry-pick-in-progress "
[ -f "${git_dir}/BISECT_LOG" ] && state="${state}bisect-in-progress "
[ -z "$current_branch" ] && state="${state}detached-HEAD "
if [ -n "$state" ]; then
    echo "$state"
else
    echo "clean"
fi

echo
echo "## remote-fetch"
# GIT_TERMINAL_PROMPT=0 so a credential prompt fails fast instead of hanging the whole
# check forever. --prune so a branch deleted on the remote actually shows up as gone
# below -- plain fetch leaves stale remote-tracking refs sitting around indefinitely.
if GIT_TERMINAL_PROMPT=0 git fetch --quiet --prune --all 2>"$fetch_err_file"; then
    echo "ok"
else
    echo "FAILED (remote-tracking refs below may be stale):"
    sed 's/^/  /' "$fetch_err_file"
fi

echo
echo "## default-branch"
# Never hardcode "main" -- detect it. origin/HEAD's symbolic ref is fast and local (set at
# clone time); a direct query to the remote is the fallback for a clone where it's missing.
default_branch=""
if ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null); then
    default_branch="${ref#refs/remotes/origin/}"
elif ref=$(git ls-remote --symref origin HEAD 2>/dev/null | awk '/^ref:/{print $2}' | sed 's#refs/heads/##'); then
    default_branch="$ref"
fi
if [ -z "$default_branch" ]; then
    default_branch="main"
    echo "${default_branch} (detection failed -- no origin/HEAD and origin unreachable -- this is an assumption, say so)"
else
    echo "$default_branch"
fi

# One status call, filtered two ways below, so untracked-files and uncommitted-changes
# can't disagree with each other and this only has to hit the index once.
# --untracked-files=normal is explicit so a repo (or global config) with
# status.showUntrackedFiles=no can't silently hide real untracked work.
status_output=$(git status --untracked-files=normal --porcelain=v1)

echo
echo "## untracked-files"
printf '%s\n' "$status_output" | awk '/^\?\?/ {print substr($0,4)}'

echo
echo "## uncommitted-changes"
printf '%s\n' "$status_output" | awk '!/^\?\?/ {print}'

echo
echo "## stashes"
git stash list

echo
echo "## unpushed-commits"
# Current branch only, on purpose -- this is a "help me resume" tool, not a full-repo audit.
# A failed @{u} lookup still prints the literal "@{u}" to stdout alongside its non-zero
# exit -- checking the exit status, not just whether the captured string is non-empty, is
# what stops a branch with broken tracking config from masquerading as having a real one.
if upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null); then
    :
else
    upstream=""
fi
if [ -n "$upstream" ]; then
    echo "upstream=${upstream}"
    git log --format='%h %ai %s' "${upstream}..HEAD" 2>/dev/null
else
    echo "no upstream configured for ${current_branch:-<detached HEAD>}"
fi

echo
echo "## sync-status"
if [ -n "$upstream" ]; then
    if ahead=$(git rev-list --count "${upstream}..HEAD" 2>/dev/null) \
        && behind=$(git rev-list --count "HEAD..${upstream}" 2>/dev/null); then
        echo "branch=${current_branch} upstream=${upstream} ahead=${ahead} behind=${behind}"
    else
        # A failed rev-list (e.g. the upstream ref doesn't actually resolve) must never
        # collapse into ahead=0 behind=0 -- that reads as "perfectly in sync" when the
        # truth is "couldn't tell." Say so plainly instead of guessing.
        echo "branch=${current_branch} upstream=${upstream}: could not compute ahead/behind"
    fi
else
    echo "branch=${current_branch:-<detached HEAD>}: no upstream configured"
fi

echo
echo "## stale-branches"
# Two independent stale signals, either one is enough to list a branch: [gone] (its
# upstream was deleted on the remote -- the standard PR-merge-and-delete case) or already
# merged into the default branch locally. A branch matching neither is active, not stale,
# and is correctly left off this list entirely -- this is not "every non-default branch."
merged_list=$(git branch --format='%(refname:short)' --merged "$default_branch")
git for-each-ref refs/heads/ --format='%(refname:short)|%(committerdate:iso-strict)|%(upstream:track)' |
    while IFS='|' read -r name date track; do
        [ "$name" = "$default_branch" ] && continue
        reasons=""
        [ "$track" = "[gone]" ] && reasons="gone"
        if printf '%s\n' "$merged_list" | grep -qxF "$name"; then
            if [ -n "$reasons" ]; then
                reasons="${reasons},merged"
            else
                reasons="merged"
            fi
        fi
        [ -n "$reasons" ] && echo "${name}|${date}|${reasons}"
    done

echo
echo "## remote-branches"
# Excludes every configured remote's HEAD symbolic ref, not just origin's -- a second
# remote's HEAD (its shortname can render as "<remote>/HEAD" or bare "<remote>" depending
# on git version) would otherwise leak into this list looking like a real branch.
remotes=$(git remote)
git for-each-ref refs/remotes/ --format='%(refname:short)|%(committerdate:iso-strict)' |
    while IFS='|' read -r name date; do
        is_head=0
        [ "$name" = "origin/${default_branch}" ] && is_head=1
        for r in $remotes; do
            [ "$name" = "$r" ] && is_head=1
            [ "$name" = "${r}/HEAD" ] && is_head=1
        done
        [ "$is_head" = 0 ] && echo "${name}|${date}"
    done

echo
echo "## forge-prs"
# Sniff the remote URL to try the matching tool first (github.com -> gh, anything else ->
# tea), but still fall through to the other if the preferred one isn't available or fails
# -- a self-hosted Gitea on a non-obvious domain, or a GitHub Enterprise host, shouldn't
# be mistaken for the wrong forge. Either tool exits non-zero (or returns nothing
# parseable) when it can't authenticate against this specific remote, so a successful
# call is real evidence it's usable here, not just that the binary exists on PATH.
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if printf '%s' "$remote_url" | grep -qi 'github\.com'; then
    order="gh tea"
else
    order="tea gh"
fi
found=""
for tool in $order; do
    if [ "$tool" = "gh" ] && command -v gh >/dev/null 2>&1 \
        && prs=$(gh pr list --json number,title,headRefName,state,isDraft,reviewDecision --limit 50 2>/dev/null); then
        echo "tool=gh"
        count=$(printf '%s' "$prs" | jq 'length' 2>/dev/null)
        [ "${count:-0}" -ge 50 ] && echo "note: hit the 50-result limit, there may be more"
        printf '%s\n' "$prs"
        found=1
        break
    elif [ "$tool" = "tea" ] && command -v tea >/dev/null 2>&1 \
        && prs=$(tea pulls list --output json 2>/dev/null); then
        echo "tool=tea"
        printf '%s\n' "$prs"
        found=1
        break
    fi
done
[ -z "$found" ] && echo "tool=none (no gh/tea available, or neither is usable against this remote)"

# Without this, the script's own exit status is whatever the last internal test
# happened to evaluate to (the [ -z "$found" ] above, say) -- accidental and
# meaningless. A completed check is a successful run regardless of what it found.
exit 0
