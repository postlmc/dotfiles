---
name: import-from-copilot
description: >
  Sync ~/.copilot/instructions/ files to their Claude Code equivalents.
  Converts .prompt.md files not yet in ~/.claude/commands/ into CC slash
  commands, and .instructions.md files not yet in ~/.claude/rules/ into CC
  rules files. Adds all results to the chezmoi source and applies.
---

# Sync Prompt Commands and Rules

Sync Copilot instruction and prompt files to Claude Code equivalents.

## Steps

### 1. Convert .prompt.md → ~/.claude/commands/

1. List all `*.prompt.md` files in `~/.copilot/instructions/`.
2. For each, derive the command name by stripping the `.prompt.md` suffix.
3. Skip `import-from-claude` — it is a Copilot-side tool with no CC equivalent.
4. Skip any where `~/.local/share/chezmoi/home/dot_claude/commands/<name>.md` already exists.
5. For files that need conversion:
   - Keep `description` from frontmatter
   - Add `allowed-tools: Bash` as a default
   - Strip Copilot-specific fields (`mode`, `model`, `tools`)
   - Preserve the body unchanged
6. Write to `~/.local/share/chezmoi/home/dot_claude/commands/<name>.md`.

### 2. Convert .instructions.md → ~/.claude/rules/

1. List all `*.instructions.md` files in `~/.copilot/instructions/`.
2. For each, derive the rule name by stripping the `.instructions.md` suffix.
3. Skip any where `~/.local/share/chezmoi/home/dot_claude/rules/<name>.md` already exists.
4. For files that need conversion:
   - Keep `description` from frontmatter
   - Convert `applyTo` (comma-separated string) to `paths` (YAML array), splitting on `, `
   - Preserve the body unchanged
5. Write to `~/.local/share/chezmoi/home/dot_claude/rules/<name>.md`.

### 3. Deploy

1. For each file written to the chezmoi source in steps 1 and 2, run:
   `git -C ~/.local/share/chezmoi add <relative-path-from-chezmoi-root>`
   to stage it for the next commit.
2. Run `chezmoi apply ~/.claude/commands/ ~/.claude/rules/` to deploy all new files.
3. Report which files were converted (and staged) and which were skipped.
