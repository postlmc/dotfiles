---
name: import-from-claude
description: >-
  Sync ~/.claude/rules/ files to Cursor rules. Converts Claude Code .md rule
  files not yet in ~/.cursor/rules/ to .mdc format and deploys via chezmoi.
  Use when new rules have been added to Claude Code and should be mirrored to Cursor.
---

# Sync Claude Code Rules to Cursor

Promote new Claude Code rules into Cursor's user-level rules directory.

## Steps

### 1. Identify new rules

1. List all `*.md` files in `~/.claude/rules/`.
2. For each, derive the base name by stripping the `.md` suffix.
3. Skip any where `~/.local/share/chezmoi/home/dot_cursor/rules/<name>.mdc` already exists.

### 2. Convert and write

For each file that needs conversion:

1. Read the source file.
2. Convert frontmatter:
   - Keep `description` unchanged.
   - If `paths` contains only `**/*`, set `alwaysApply: true` and omit `globs`.
   - Otherwise set `alwaysApply: false` and set `globs` to the `paths` values joined as a comma-separated string (no spaces after
     commas).
   - Drop the `paths` key.
3. Preserve the body verbatim.
4. Write to `~/.local/share/chezmoi/home/dot_cursor/rules/<name>.mdc`.

### 3. Deploy

1. For each file written, run: `git -C ~/.local/share/chezmoi add home/dot_cursor/rules/<name>.mdc`
2. Run `chezmoi apply ~/.cursor/rules/` to deploy.
3. Report which files were converted and which were skipped.
