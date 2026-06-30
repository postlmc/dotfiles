---
description: Sync ~/.cursor/rules/ files to Claude Code rules
allowed-tools: Bash
---

# Sync Cursor Rules to Claude Code

Promote new Cursor rules into Claude Code's user-level rules directory.

## Steps

### 1. Identify new rules

1. List all `*.mdc` files in `~/.cursor/rules/`.
2. For each, derive the base name by stripping the `.mdc` suffix.
3. Skip any where `~/.local/share/chezmoi/home/dot_claude/rules/<name>.md` already exists.

### 2. Convert and write

For each file that needs conversion:

1. Read the source file.
2. Convert frontmatter:
   - Keep `description` unchanged.
   - If `alwaysApply: true`, set `paths: ["**/*"]` and omit `globs`.
   - Otherwise convert `globs` (comma-separated string) to a `paths` YAML array, one entry per glob.
   - Drop `globs` and `alwaysApply`.
3. Preserve the body verbatim.
4. Write to `~/.local/share/chezmoi/home/dot_claude/rules/<name>.md`.

### 3. Deploy

1. For each file written, run:
   `git -C ~/.local/share/chezmoi add home/dot_claude/rules/<name>.md`
2. Run `chezmoi apply ~/.claude/rules/` to deploy.
3. Report which files were converted and which were skipped.
