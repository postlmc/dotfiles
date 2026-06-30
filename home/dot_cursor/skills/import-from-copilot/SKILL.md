---
name: import-from-copilot
description: >-
  Sync ~/.copilot/instructions/ files to Cursor rules. Converts Copilot
  .instructions.md files not yet in ~/.cursor/rules/ to .mdc format and deploys
  via chezmoi. Use when new instruction files have been added to Copilot and
  should be mirrored to Cursor.
---

# Sync Copilot Instructions to Cursor

Promote new Copilot instruction files into Cursor's user-level rules directory.

## Steps

### 1. Identify new rules

1. List all `*.instructions.md` files in `~/.copilot/instructions/`.
2. For each, derive the base name by stripping the `.instructions.md` suffix.
3. Skip `import-from-claude` — it is a Copilot-side tool with no Cursor equivalent.
4. Skip any where `~/.local/share/chezmoi/home/dot_cursor/rules/<name>.mdc` already exists.

### 2. Convert and write

For each file that needs conversion:

1. Read the source file.
2. Convert frontmatter:
   - Keep `description` unchanged.
   - If `applyTo` is `**/*`, set `alwaysApply: true` and omit `globs`.
   - Otherwise set `alwaysApply: false` and set `globs` to the `applyTo` value with spaces after commas removed.
   - Drop the `applyTo` key.
3. Preserve the body verbatim.
4. Write to `~/.local/share/chezmoi/home/dot_cursor/rules/<name>.mdc`.

### 3. Deploy

1. For each file written, run: `git -C ~/.local/share/chezmoi add home/dot_cursor/rules/<name>.mdc`
2. Run `chezmoi apply ~/.cursor/rules/` to deploy.
3. Report which files were converted and which were skipped.
