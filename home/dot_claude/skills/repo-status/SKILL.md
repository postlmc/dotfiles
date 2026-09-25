---
name: repo-status
description: Check a git repo for leftover work -- untracked files (never gitignored ones), uncommitted changes, an in-progress merge/rebase/cherry-pick/bisect, unpushed commits on the current branch, stale branches (gone from the remote or already merged), sync status against the current branch's upstream, and open PRs when gh or tea can reach the remote -- then read any TODO*.md and HANDOFF*.md files for planned work items, ordered by what can actually be worked next given their blockers and dependencies. Prints two tables, one for repo status and one for open work items with stable, per-host item numbers. Use this at the start of a session to answer "what's outstanding here?", "anything left over from last time?", or "is there anything I should clean up before starting?" -- also trigger on requests to check for stale branches, unpushed commits, or open PRs specifically, even without the phrase "repo status".
---

# Repo Status

A quick "what's left over" check for a git repo, meant to run at the start of a session before
diving into new work -- specifically to help resume after shifting focus elsewhere, not to audit the
whole repo end to end. It has two halves: a deterministic git/forge sweep, and a judgment-based read
of any TODO/HANDOFF notes lying around.

## Step 1: Run the git/forge sweep

Run `scripts/repo-status.sh` from the skill directory against the current repo (it finds the repo
root itself via `git rev-parse --show-toplevel`, so it works from any subdirectory). It prints
labeled sections. The script does the data-gathering; formatting the human-facing table is your job
(see Step 4). A few things worth understanding before you present it:

- **The default branch is detected, never assumed to be "main."** A repo using `master`, `trunk`, or
  anything else is handled the same way. If detection genuinely fails (no `origin/HEAD` and `origin`
  unreachable), the script falls back to `main` but says so explicitly in its own output -- pass
  that caveat through to the table rather than presenting the fallback as a confirmed value.
- **An in-progress merge, rebase, cherry-pick, or bisect is checked first**, and so is a detached
  HEAD. Any of these is real leftover work in its own right, and worth knowing about before anything
  else in the table even makes sense to interpret.
- **Untracked files always show real untracked work**, regardless of local config.
  `status.showUntrackedFiles` can be set to hide them entirely at the repo or global level; the
  script passes `--untracked-files=normal` explicitly so that can't silently suppress something this
  check exists to catch. Ignored files are still correctly excluded -- that part *is* git's default
  behavior, and stays that way.
- **Unpushed commits are current-branch only, on purpose.** This is a "help me resume" tool, not a
  full-repo audit -- commits sitting on some other local branch you're not standing on aren't what
  this check is for.
- **Sync status never reports a false "in sync."** A failed `rev-list` (the upstream ref doesn't
  actually resolve, say) is reported as "could not compute," never silently coerced to `ahead=0
  behind=0` -- that would read as confirmed-synced when the truth is "couldn't tell."
- **"Stale branch" means gone from the remote, or already merged -- not just "not the default
  branch."** A branch is only listed if its upstream shows `[gone]` (the standard signal after a PR
  merges and the remote branch gets deleted) or it's already merged into the default branch locally
  (catches a merge that never went through a delete-on-merge remote workflow). A branch matching
  neither is active, not stale, and is correctly left off the list entirely.
- **A fetch failure doesn't stop the check.** If the remote is unreachable (an SSH agent hiccup, no
  network), the script says so and falls back to whatever remote-tracking refs are already cached
  locally. Note this in the table rather than silently presenting possibly-stale remote data as
  current.
- **Open PRs only appear when gh or tea can actually reach the remote.** The script picks whichever
  of the two matches the remote URL and tries that one first, falling back to the other if the
  preferred one isn't available or fails -- and only counts a tool as usable after it actually
  returns data, not just because the binary exists on PATH. If neither works, the script says so
  explicitly; report that plainly rather than omitting the row, so it's clear the check was
  considered and skipped, not forgotten. If a PR list hits the 50-result cap, the script flags that
  there may be more -- pass that through too rather than presenting 50 as a confirmed total.
- **Dangling/unreachable commits are deliberately not checked.** `git gc` reclaims those on its own
  schedule regardless of whether anyone looks, so there's nothing actionable in surfacing them here.

## Step 2: Find and read TODO/HANDOFF files

Search the filesystem for `TODO*.md` and `HANDOFF*.md`, anchored at the repo root (not wherever your
current directory happens to be) and excluding `.git` and common dependency/vendor directories,
since a third-party package's own TODO.md is not this repo's work: `find "$(git rev-parse
--show-toplevel)" \( -path '*/.git' -o -path '*/node_modules' -o -path '*/vendor' \) -prune -o \(
-iname 'TODO*.md' -o -iname 'HANDOFF*.md' \) -print`. Not `git ls-files` or similar -- files like
`HANDOFF*.md` are often deliberately gitignored (an informal, untracked note-passing channel between
sessions or collaborators), so a git-tracked-file search would silently miss exactly the files this
step exists to find. A repo-local `.git/info/exclude` entry can do the same for `TODO*.md`
specifically; that's fine and expected, it just means Table 1 won't list the file as untracked
clutter while this step still finds and reads it.

Read whatever turns up. These files have no fixed schema -- they're free-form notes, not structured
data -- so extracting work items is a judgment call, not a parse. If the same item plainly appears
in more than one file -- a persistent `TODO.md` and a one-off `HANDOFF-*.md` both mentioning the
same task, say -- treat it as one row, merging whatever detail each file adds, rather than listing
it twice.

For each item:

- **Name**: a short label for the item, however the note phrases it.
- **Status**: infer from context and render as one emoji, this legend and no other:
    - ⚪️ not started
    - 🟡 in progress
    - 🟢 done, but not yet committed or merged
    - 🔴 blocked -- stuck on something external, still wanted
    - 🔵 waiting on input -- needs a decision or an action from whoever owns the repo before it can
  move If the note doesn't say, ⚪️ (not started) is the reasonable default rather than leaving it
  blank.
- **Issue**: a tracking-system reference (Jira, GitHub Issues, Linear, whatever the note itself
  names), only when the note actually mentions one. Leave it blank otherwise -- report only what the
  file says, never query an external tracker to find or verify one. Querying one on every run would
  mean live credentials and a network call for a check that's meant to be quick, just to confirm
  something the note already told you.
- **Effort**: a rough size, spelled out in full -- Small, Medium, or Large -- based on what the note
  describes, not a time estimate. Leave it blank, the same way Issue does, if the note gives no real
  signal of size -- a fake-precise guess is worse than an honest blank.
- **Notes**: one sentence describing the item, enough for someone with no other context to know what
  it is.

**Dependencies** go in Notes, not their own column -- "depends on <item>" when the note says or
clearly implies one item blocks another, or "blocked on <issue>" when a *different* issue than the
one in this row's own Issue column is what's holding it up. An item can never be blocked on its own
Issue: the ticket tracking the work can't also be the thing the work is waiting on, so if the only
issue reference a note gives is the item's own tracking ticket, that belongs in the Issue column,
not restated as a dependency. Don't invent a dependency that isn't there just to have something to
say -- most items are independent.

Occasionally two items depend on each other: item A's note says it can't move until item B is done,
and B's note says it can't move until A is done. Neither can legitimately come first, because each
is the other's blocker -- that's a cycle. The same thing can happen through a longer chain instead
of a direct pair (A depends on B, B depends on C, C depends on A), with the same result. When that
happens there is no order that puts every dependency before its dependent, so don't force one: say
so in a line before Table 2, name the items involved, and order the rest of the table normally
around them. A cycle almost always means the notes themselves need fixing, not the table.

If no TODO*/HANDOFF* files exist, say so plainly rather than presenting an empty table as if
something went wrong.

## Step 3: Assign stable item numbers

Table 2's `#` column has to mean the same item run over run, not just be freshly counted off top to
bottom each time -- otherwise a note written today saying "depends on #2" is worthless the next time
this runs and the list has changed shape. `scripts/resolve-item-numbers.py` handles the persistence;
your job is generating the right key per item and calling it correctly:

1. Decide Table 2's final row order first (per Step 2's ordering rule: workable items before
   whatever depends on them). Numbers are assigned in this order, so decide the order before you ask
   for numbers, not after.
2. For each item, in that order, generate a stable key: `issue:<ISSUE-ID>` if it has an Issue
   reference (normalized -- uppercase, no internal spaces), otherwise `text:<normalized-name>` where
   normalized-name is the item's Name lowercased, whitespace-collapsed, and truncated to roughly 60
   characters.
3. Feed the keys to the script, one per line, in row order: `printf '%s\n' "${keys[@]}" |
   scripts/resolve-item-numbers.py`. It
   prints `<key><tab><number>` per line, in the same order, and updates the state file for next
   time. A key repeated more than once in the same list reuses the number from its first occurrence,
   so it's safe to feed the same key twice if that ever happens.
4. Use the returned numbers as the `#` column.

This makes numbers durable across runs for an item whose identity doesn't change, at a real cost
worth stating plainly: identity is the Issue reference when there is one, or a snippet of the item's
own wording when there isn't. Reword a no-Issue item significantly and it looks like a new item to
this script -- it gets a new number, and the old number simply stops appearing (numbers are never
reused, so nothing else claims it either). Appending detail to a note without changing its core
wording keeps the key, and the number, stable.

Numbers are also deliberately **per-host, not synced anywhere** -- state lives at
`.git/repo-status-state.json`, which never travels with a clone, so a second machine (or a `git
worktree`) keeps its own independent counter. That's an accepted tradeoff for what this tool is (a
personal aid for picking work back up), not an oversight.

## Step 4: Print both tables

Print exactly two tables, in this order, with no other commentary before or between them beyond
what's needed to explain a genuinely surprising finding (an in-progress merge, a failed fetch, a
dependency cycle, no forge tool reaching the remote).

**Table 1 -- Repo Status**, one row per category from the script's output:

| Category                | Finding                                                                                                          |
|-------------------------|------------------------------------------------------------------------------------------------------------------|
| Repo state              | "clean", or the in-progress operation(s) found (merge/rebase/cherry-pick/bisect/detached HEAD)                   |
| Untracked files         | count, or "none"                                                                                                 |
| Uncommitted changes     | count, or "clean"                                                                                                |
| Stashes                 | count and a one-line summary of each, or "none"                                                                  |
| Unpushed commits        | short hash + subject for each, on the current branch only, or "none"                                             |
| Stale branches          | name, age, and why (gone / merged / both) for each, or "none"                                                    |
| Remote branches (other) | list with age, or "none"                                                                                         |
| Sync with upstream      | ahead/behind for the current branch, or a note that it couldn't be computed or the fetch failed                  |
| Open PRs                | number, title, branch, and state for each, or "none open" -- or a note that no forge tool could reach the remote |

**Table 2 -- Open Work Items**, one row per item found in TODO/HANDOFF files, numbered per Step 3
and ordered so a dependency appears before whatever depends on it (cyclic items excepted, per Step
2) -- items with no dependency relationship to anything else can go in any order:

| # | Item | Status | Issue | Effort | Notes |
|:-:|------|:------:|-------|--------|-------|

Follow the table with a single legend line decoding the Status emoji, since nothing else in the
printed output explains them: `⚪️ not started · 🟡 in progress · 🟢 done, uncommitted · 🔴 blocked ·
🔵 waiting on input`.

If Table 2 has no rows, print it with a "no open work items found" note instead of an empty table.
