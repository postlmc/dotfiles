---
name: import-from-cursor
description: >
  Sync ~/.cursor/rules/ files to their Copilot/VSCode equivalents.
  Converts .mdc files not yet in ~/.copilot/instructions/ to
  .instructions.md format and deploys via chezmoi.
mode: agent
model: claude-sonnet-4-6
tools:
  - changes
  - codebase
  - terminalLastCommand
---

# Sync Cursor Rules to Copilot

Promote new Cursor rules into Copilot's user-level instructions directory.

## Steps

### 1. Identify new rules

1. List all `*.mdc` files in `~/.cursor/rules/`.
2. For each, derive the base name by stripping the `.mdc` suffix.
3. Skip `import-from-claude` and `import-from-copilot` — these are Cursor-side tools with no Copilot equivalent.
4. Skip any where `~/.local/share/chezmoi/home/dot_copilot/instructions/<name>.instructions.md` already exists.

### 2. Convert and write

For each file that needs conversion:

1. Read the source file.
2. Convert frontmatter:
   - Keep `description` unchanged, wrapped in single quotes.
   - If `alwaysApply: true`, set `applyTo: '**/*'`.
   - Otherwise convert `globs` (comma-separated string) to `applyTo` with the same value, adding a space after each comma.
   - Drop `globs` and `alwaysApply`.
3. Preserve the body verbatim.
4. Write to `~/.local/share/chezmoi/home/dot_copilot/instructions/<name>.instructions.md`.

### 3. Deploy

1. For each file written, run:
   `git -C ~/.local/share/chezmoi add home/dot_copilot/instructions/<name>.instructions.md`
2. Run `chezmoi apply ~/.copilot/instructions/` to deploy.
3. Report which files were converted and which were skipped.
