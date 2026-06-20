# Shell Module Loader Refactor — Findings and Decisions

Work done 2026-06-20, based on the `LOAD_CHANGE.md` design document.

## Problem

`mklinks.sh` is not part of chezmoi's managed lifecycle. A fresh `chezmoi apply` leaves `enabled/` nearly empty — the entire module
system is silent until `mklinks.sh` is run manually. Tool availability is also frozen at mklinks-run-time: installing a new tool
after the last run silently skips its module until `mklinks.sh` is run again.

## What was considered

**Full refactor** — Rename all `available/*.sh` files with load-order number prefixes (e.g., `core.sh` → `02-core.sh`), add OS
guards to `misc-darwin.sh` and `misc-linux.sh`, change the loader glob in `.zshrc`/`.bashrc` from `enabled/??-*` to
`available/??-*`, and delete `enabled/` and `mklinks.sh` entirely. Solves the problem permanently but requires renaming 22 files and
the `LOAD_CHANGE.md` numbering table was already stale (predated mklinks.sh numbering fixes, missing `op.sh` and `tailscale.sh`).

**`run_onchange_` script** — Add a chezmoi script that re-runs `mklinks.sh` automatically whenever mklinks.sh changes. Minimal
churn, keeps current structure intact, covers new-machine bootstrap and future additions.

## What was implemented

**`run_onchange_` chezmoi script** — `home/.chezmoiscripts/run_onchange_mklinks.sh.tmpl` embeds a sha256 hash of `mklinks.sh`
content in a comment. Chezmoi re-runs the script on `chezmoi apply` whenever that hash changes, which covers both initial setup on a
new machine and any future additions to mklinks.sh.

**Removed `99-misc` from mklinks.sh** — `.zshrc` already loads host-local shell config explicitly in the interactive-shell block
(`~/.config/dotfiles.local/shell/<hostname>`). The `99-misc` symlink created by mklinks.sh pointed to the same file, causing it to
be sourced twice in interactive shells. Removing the symlink creation fixes the double-source and also stops agent shells from
loading host-local config via the unconditional module loop.
