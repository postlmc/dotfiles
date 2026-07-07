# AI Tool Configuration

This document describes how this chezmoi repo manages configuration for AI coding assistants and what a new system setup requires.

## Tools

### Claude Code

Files deployed to `~/.claude/`:

| Source                                            | Target                                      | Purpose                                                       |
|---------------------------------------------------|---------------------------------------------|---------------------------------------------------------------|
| `home/dot_claude/CLAUDE.md`                       | `~/.claude/CLAUDE.md`                       | Stub pointing to `rules/` for behavioral guidelines           |
| `home/dot_claude/rules/general-behavior.md`       | `~/.claude/rules/general-behavior.md`       | Behavioral guidelines and writing voice; applies to all files |
| `home/dot_claude/rules/better-comments.md`        | `~/.claude/rules/better-comments.md`        | Commenting guidelines; scoped to source code files            |
| `home/dot_claude/rules/markdown.md`               | `~/.claude/rules/markdown.md`               | Markdown formatting rules; scoped to `**/*.md`                |
| `home/dot_claude/rules/python.md`                 | `~/.claude/rules/python.md`                 | Python best practices; scoped to `**/*.py`, `**/*.pyi`        |
| `home/dot_claude/rules/terraform.md`              | `~/.claude/rules/terraform.md`              | Terraform code style; scoped to `**/*.tf`, `**/*.tfvars`      |
| `home/dot_claude/commands/git-commit.md`          | `~/.claude/commands/git-commit.md`          | Slash command: review staged changes and commit               |
| `home/dot_claude/commands/import-from-copilot.md` | `~/.claude/commands/import-from-copilot.md` | Slash command: sync new Copilot files into Claude Code        |
| `home/dot_claude/commands/import-from-cursor.md`  | `~/.claude/commands/import-from-cursor.md`  | Slash command: sync new Cursor rules into Claude Code         |

Rules use frontmatter (`description`, `paths`) recognized by Claude Code. Commands use frontmatter (`description`, `allowed-tools`).

### GitHub Copilot

Files deployed to `~/.copilot/instructions/`:

| Source                                                           | Target                                                     | Purpose                                            |
|------------------------------------------------------------------|------------------------------------------------------------|----------------------------------------------------|
| `home/dot_copilot/instructions/general-behavior.instructions.md` | `~/.copilot/instructions/general-behavior.instructions.md` | Behavioral guidelines; applies to all files        |
| `home/dot_copilot/instructions/better-comments.instructions.md`  | `~/.copilot/instructions/better-comments.instructions.md`  | Commenting guidelines; scoped to source code files |
| `home/dot_copilot/instructions/markdown.instructions.md`         | `~/.copilot/instructions/markdown.instructions.md`         | Markdown formatting rules                          |
| `home/dot_copilot/instructions/python.instructions.md`           | `~/.copilot/instructions/python.instructions.md`           | Python best practices                              |
| `home/dot_copilot/instructions/terraform.instructions.md`        | `~/.copilot/instructions/terraform.instructions.md`        | Terraform code style                               |
| `home/dot_copilot/instructions/git-commit.prompt.md`             | `~/.copilot/instructions/git-commit.prompt.md`             | Prompt: create a git commit                        |
| `home/dot_copilot/instructions/import-from-claude.prompt.md`     | `~/.copilot/instructions/import-from-claude.prompt.md`     | Prompt: sync new Claude Code files into Copilot    |
| `home/dot_copilot/instructions/import-from-cursor.prompt.md`     | `~/.copilot/instructions/import-from-cursor.prompt.md`     | Prompt: sync new Cursor rules into Copilot         |

VS Code also needs its terminal profile configured so that Copilot agent sessions set `ACTIVE_AGENT=Copilot` — this skips shell
history, plugins, and interactive features that interfere with agent execution. This is handled automatically by a chezmoi script
(see below).

### Cursor

Files deployed to `~/.cursor/rules/` (user-level rules, `.mdc` format):

| Source                                       | Target                                 | Purpose                                                  |
|----------------------------------------------|----------------------------------------|----------------------------------------------------------|
| `home/dot_cursor/rules/general-behavior.mdc` | `~/.cursor/rules/general-behavior.mdc` | Behavioral guidelines and writing voice; always applied  |
| `home/dot_cursor/rules/better-comments.mdc`  | `~/.cursor/rules/better-comments.mdc`  | Commenting guidelines; scoped to source code files       |
| `home/dot_cursor/rules/markdown.mdc`         | `~/.cursor/rules/markdown.mdc`         | Markdown formatting rules; scoped to `**/*.md`           |
| `home/dot_cursor/rules/python.mdc`           | `~/.cursor/rules/python.mdc`           | Python best practices; scoped to `**/*.py`, `**/*.pyi`   |
| `home/dot_cursor/rules/terraform.mdc`        | `~/.cursor/rules/terraform.mdc`        | Terraform code style; scoped to `**/*.tf`, `**/*.tfvars` |

Files deployed to `~/.cursor/skills/` (user-level skills):

| Source                                                | Target                                          | Purpose                                          |
|-------------------------------------------------------|-------------------------------------------------|--------------------------------------------------|
| `home/dot_cursor/skills/import-from-claude/SKILL.md`  | `~/.cursor/skills/import-from-claude/SKILL.md`  | Skill: sync new Claude Code rules into Cursor    |
| `home/dot_cursor/skills/import-from-copilot/SKILL.md` | `~/.cursor/skills/import-from-copilot/SKILL.md` | Skill: sync new Copilot instructions into Cursor |

Cursor `.mdc` frontmatter uses `globs` (comma-separated string) and `alwaysApply` instead of the `paths` array used by Claude Code.

Other Cursor behaviour:

- **Agents**: Cursor reads `~/.claude/agents/` natively; no `~/.cursor/agents/` needed.
- **Commands**: Cursor also reads `~/.claude/commands/` natively, so slash commands like `/git-commit` need no Cursor copy — a
  duplicate skill would show up twice in the command picker.
- **Project-level instructions**: `AGENTS.md` in a project root is read natively by Cursor.
- **User Rules** (global instructions set in the UI): stored in a SQLite database at `~/Library/Application
  Support/Cursor/User/globalStorage/state.vscdb` under the key `aicontext.personalContext`. Not a plain file; not managed by
  chezmoi. Set once via **Cursor Settings → Rules** after a new install. Paste the content of `~/.claude/rules/general-behavior.md`
  as a baseline.

## Supporting tools

`home/dot_local/bin/executable_align-tables` deploys to `~/.local/bin/align-tables`. It reformats Markdown tables to the MD060
aligned style the markdown rule requires, padding cells to display width and skipping fenced code blocks. Agents run it after
editing a table, then lint. It is stdlib-only Python invoked through a uv-run shebang.

## Cross-tool sync

Rules and instructions are kept in sync manually across all three tools. `AGENTS.md` requires a rule to exist for Claude Code,
Cursor, and Copilot together unless it is explicitly tool-specific. None of these commands overwrite existing files; all are
additive only.

| Command / Skill        | Tool           | Pulls from                                | Pushes to                                 |
|------------------------|----------------|-------------------------------------------|-------------------------------------------|
| `/import-from-copilot` | Claude Code    | `~/.copilot/instructions/`                | `~/.claude/rules/`, `~/.claude/commands/` |
| `/import-from-cursor`  | Claude Code    | `~/.cursor/rules/`                        | `~/.claude/rules/`                        |
| `import-from-claude`   | Copilot prompt | `~/.claude/rules/`, `~/.claude/commands/` | `~/.copilot/instructions/`                |
| `import-from-cursor`   | Copilot prompt | `~/.cursor/rules/`                        | `~/.copilot/instructions/`                |
| `import-from-claude`   | Cursor skill   | `~/.claude/rules/`                        | `~/.cursor/rules/`                        |
| `import-from-copilot`  | Cursor skill   | `~/.copilot/instructions/`                | `~/.cursor/rules/`                        |

All commands stage results in chezmoi and run `chezmoi apply` for the affected directory.

### Known asymmetry: per-command model selection

The Copilot `git-commit.prompt.md` uses `model: claude-haiku-4-5` in its frontmatter to run commits against a cheaper model.
Claude Code command frontmatter only supports `description` and `allowed-tools` — there is no `model` key. Cursor reads
`~/.claude/commands/` using the same format and has the same limitation. Until Claude Code adds per-command model selection,
the Haiku optimization exists only in the Copilot context.

## Chezmoi scripts

Scripts run automatically during `chezmoi apply` when their trigger condition is met:

| Script                                                        | Trigger                         | Effect                                                           |
|---------------------------------------------------------------|---------------------------------|------------------------------------------------------------------|
| `home/.chezmoiscripts/run_onchange_mklinks.sh.tmpl`           | `enabled/mklinks.sh` changes    | Rebuilds `enabled/` symlinks for shell module loader             |
| `home/run_onchange_after_install-packages.sh.tmpl`            | Brewfile changes                | Installs Homebrew packages from the Brewfile                     |
| `home/run_onchange_configure-vscode-copilot-terminal.sh.tmpl` | Copilot terminal script changes | Writes the Copilot terminal profile into VS Code `settings.json` |
| `home/run_once_init-devbox-local.sh.tmpl`                     | Never re-runs after first apply | Initializes the devbox local environment                         |

## New system setup

1. Install chezmoi and clone this repo as the source directory.
2. Run `chezmoi apply`. This deploys all managed files and runs the scripts above in dependency order.
3. Open Cursor → **Settings → Rules** and paste the content of `~/.claude/rules/general-behavior.md` as User Rules.

No additional steps are required for Claude Code or Copilot; `chezmoi apply` handles both completely.
