---
name: repo-status
description: Check a git repo for leftover work and hygiene issues -- untracked files, uncommitted changes, stashes, dangling commits, and branches that should have been deleted after merging -- then review any TODO*.md and HANDOFF*.md files for open work items. Prints two tables, one showing repo status and one showing open work items ordered by dependency. Use this at the start of a session to answer "what's outstanding here?", "anything left over from last time?", or "is there anything I should clean up before starting?" -- also trigger on requests to check for stale branches, leftover stashes, or dangling commits specifically, even without the phrase "repo status".
---

# Repo Status

A quick "what's left over" check for a git repo, meant to run at the start of a session before diving into
new work. It has two halves: a deterministic git hygiene sweep, and a judgment-based read of any TODO/HANDOFF
notes lying around.

## Step 1: Run the hygiene sweep

Run `scripts/repo-status.sh` from the skill directory against the current repo (it finds the repo root itself
via `git rev-parse --show-toplevel`, so it works from any subdirectory). It prints labeled sections --
untracked files, uncommitted changes, stashes, dangling commits, local and remote branches other than main,
and whether the current branch is ahead/behind its upstream.

The script does the data-gathering; formatting the human-facing table is your job (see Step 3). A few things
the script's output already accounts for that are worth understanding before you present it:

- **Dangling commits are reported as a count, not a full list.** In any repo that uses `git commit --amend`
  or `git rebase` (this one does, heavily), every amend and every rebase leaves its pre-rewrite commit
  unreachable -- by design, harmlessly, forever until `git gc` eventually reclaims it. Listing all of them
  buries anything actually worth noticing under months of routine churn. The script only itemizes ones from
  the last 2 days; older ones are just a count. Don't editorialize the count as a problem -- it isn't one.
- **A fetch failure doesn't stop the check.** If the remote is unreachable (an SSH agent hiccup, no network),
  the script says so and falls back to whatever remote-tracking refs are already cached locally. Note this
  in the table rather than silently presenting possibly-stale remote branch/sync data as current.
- **Any branch other than main showing up at all is the finding**, not its age. If this repo's workflow is
  short-lived branches that get deleted immediately after merging (check `AGENTS.md` if one exists -- this
  convention is common but not universal), a branch that still exists is itself the anomaly worth flagging,
  regardless of how old it is.

## Step 2: Find and read TODO/HANDOFF files

Search the filesystem directly for `TODO*.md` and `HANDOFF*.md` anywhere in the repo -- `find . -iname
'TODO*.md' -o -iname 'HANDOFF*.md'`, not `git ls-files` or similar. Files like `HANDOFF*.md` are often
deliberately gitignored (an informal, untracked note-passing channel between sessions or collaborators), so
a git-tracked-file search will silently miss exactly the files this step exists to find.

Read whatever turns up. These files have no fixed schema -- they're free-form notes, not structured data --
so extracting work items is a judgment call, not a parse:

- **Name**: a short label for the item, however the note phrases it.
- **Status**: infer from context and render as one emoji, this legend and no other:
    - ⚪️ not started
    - 🟡 in progress
    - 🟢 done, but not yet committed or merged
    - 🔴 blocked -- stuck on something external, still wanted
    - ⛔️ won't do -- deliberately abandoned, not just stalled
  If the note doesn't say, ⚪️ (not started) is the reasonable default rather than leaving it blank.
- **Issue**: a tracking-system reference (Jira, GitHub Issues, Linear, whatever the note itself names), only
  when the note actually mentions one. Leave it blank otherwise -- don't invent a ticket number, and don't go
  looking one up in an external tracker. This column exists so one is visible when a note happens to cite one,
  not to drive a lookup.
- **Effort**: a rough size, spelled out in full -- Small, Medium, or Large -- based on what the note describes,
  not a time estimate. These notes rarely contain enough detail for anything more precise, and a fake-precise
  estimate is worse than an honest rough one.
- **Note**: one sentence, enough for someone with no other context to know what the item is.
- **Dependencies**: only when the note says or clearly implies one item blocks another. Don't invent
  dependencies that aren't there just to fill the column -- most items are independent.

If no TODO*/HANDOFF* files exist, say so plainly rather than presenting an empty table as if something went
wrong.

## Step 3: Print both tables

Print exactly two tables, in this order, with no other commentary before or between them beyond what's needed
to explain a genuinely surprising finding (a failed fetch, for instance).

**Table 1 -- Repo Status**, one row per category from the script's output:

| Category                   | Finding                                                                    |
|----------------------------|----------------------------------------------------------------------------|
| Untracked files            | count, or "none"                                                           |
| Uncommitted changes        | count, or "clean"                                                          |
| Stashes                    | count and a one-line summary of each, or "none"                            |
| Dangling commits           | the count line from the script, plus any recent ones it itemized           |
| Local branches (non-main)  | list with age, or "none"                                                   |
| Remote branches (non-main) | list with age, or "none"                                                   |
| Sync with origin           | ahead/behind counts, or a note that the fetch failed and this may be stale |

**Table 2 -- Open Work Items**, one row per item found in TODO/HANDOFF files, **ordered so a dependency
appears before whatever depends on it** -- items with no dependency relationship to anything else can go in
any order:

| Item | Status | Issue | Effort | Depends On | Note |
|------|--------|-------|--------|------------|------|

If Table 2 has no rows, print it with a "no open work items found" note instead of an empty table.
