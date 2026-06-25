---
name: import-from-claude
description: >
  Sync Claude Code files to their Copilot/VSCode equivalents.
  Converts .md files not yet in ~/.copilot/instructions/ from ~/.claude/commands/
  into .prompt.md files, and from ~/.claude/rules/ into .instructions.md files.
  Adds all results to the chezmoi source and applies.
---

# Sync Copilot Instructions and Prompts

Sync Claude Code command and rules files to Copilot/VSCode equivalents.

## Steps

### 1. Convert ~/.claude/commands/ → .prompt.md

1. List all `*.md` files in `~/.local/share/chezmoi/home/dot_claude/commands/`.
2. For each, derive the prompt name by appending `.prompt.md` to the stem.
3. Skip `import-from-copilot` — it is a CC-side tool with no Copilot equivalent.
4. Skip any where `~/.local/share/chezmoi/home/dot_copilot/instructions/<name>.prompt.md` already exists.
5. For files that need conversion:
   - Keep `description` from frontmatter
   - Add `mode: agent`
   - Strip CC-specific fields (`allowed-tools`)
   - Preserve the body unchanged
6. Write to `~/.local/share/chezmoi/home/dot_copilot/instructions/<name>.prompt.md`.

### 2. Convert ~/.claude/rules/ → .instructions.md

1. List all `*.md` files in `~/.local/share/chezmoi/home/dot_claude/rules/`.
2. For each, derive the instructions name by appending `.instructions.md` to the stem.
3. Skip any where `~/.local/share/chezmoi/home/dot_copilot/instructions/<name>.instructions.md` already exists.
4. For files that need conversion:
   - Keep `description` from frontmatter
   - Convert `paths` (YAML array) to `applyTo` (comma-separated string)
   - Preserve the body unchanged
5. Write to `~/.local/share/chezmoi/home/dot_copilot/instructions/<name>.instructions.md`.

### 3. Deploy

1. For each file written to the chezmoi source in steps 1 and 2, run:
   `git -C ~/.local/share/chezmoi add <relative-path-from-chezmoi-root>`
   to stage it for the next commit.
2. Run `chezmoi apply ~/.copilot/instructions/` to deploy all new files.
3. Report which files were converted (and staged) and which were skipped.
