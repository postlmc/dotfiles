# AI Tool Configuration

This document describes how this chezmoi repo configures AI coding assistants and what a new system
setup requires. [AGENTS.md](../AGENTS.md) holds the maintenance rules; this is the map.

## Where the Content Comes From

Rules, the `git-commit` command, and skills have one source each:

| Content  | Source                      | Delivered by                                     |
|----------|-----------------------------|--------------------------------------------------|
| Rules    | `.rulesync/rules/*.md`      | rulesync, from `run_onchange_rulesync-generate`  |
| Commands | `.rulesync/commands/*.md`   | rulesync, from `run_onchange_rulesync-generate`  |
| Skills   | `home/dot_claude/skills/*/` | chezmoi for Claude Code; rulesync for the others |

`.rulesync/rules/AGENTS.md` is the root rule (`root: true`). Each tool receives it under its own
root file name. `.rulesync/skills/*/` are symlinks back to `home/dot_claude/skills/*/`.

The rulesync script reruns on any `chezmoi apply` where a file under `.rulesync/` or
`home/dot_claude/skills/` changed. Never edit generated files; edit the source and apply.

## Claude Code

| Target                             | Source                                               | Notes                                                      |
|------------------------------------|------------------------------------------------------|------------------------------------------------------------|
| `~/.claude/CLAUDE.md`              | `.rulesync/rules/AGENTS.md`                          | Generated root rule                                        |
| `~/.claude/rules/*.md`             | `.rulesync/rules/*.md`                               | Generated                                                  |
| `~/.claude/rules/environment.md`   | `home/dot_claude/rules/encrypted_environment.md.age` | Age-encrypted; deployed only where the personal key exists |
| `~/.claude/commands/git-commit.md` | `.rulesync/commands/git-commit.md`                   | Generated                                                  |
| `~/.claude/skills/*/`              | `home/dot_claude/skills/*/`                          | Plain chezmoi files                                        |
| `~/.claude/settings.json`          | `home/dot_claude/modify_private_settings.json`       | Merges `ACTIVE_AGENT`, status line, vim mode, rtk hook     |
| `~/.claude/statusline-command.sh`  | `home/dot_claude/executable_statusline-command.sh`   | Status line script                                         |

The settings script only edits the keys it owns. The rtk `PreToolUse` hook is added when `rtk` is on
`PATH` and removed when it is not.

## GitHub Copilot

| Target                                         | Source                                                        | Notes                       |
|------------------------------------------------|---------------------------------------------------------------|-----------------------------|
| `~/.copilot/copilot-instructions.md`           | `.rulesync/rules/AGENTS.md`                                   | Generated root rule         |
| `~/.copilot/instructions/*.instructions.md`    | `.rulesync/rules/*.md`                                        | Generated                   |
| `~/.copilot/instructions/git-commit.prompt.md` | `home/dot_copilot/instructions/git-commit.prompt.md`          | Hand-maintained (see below) |
| `~/.copilot/skills/*/`                         | `home/dot_claude/skills/*/`                                   | Generated                   |
| VS Code terminal profile                       | `home/run_onchange_configure-vscode-copilot-terminal.sh.tmpl` | Sets `ACTIVE_AGENT=Copilot` |

rulesync has no global-scope command support for Copilot, so its `git-commit` prompt is maintained by
hand. It sets `model: claude-haiku-4-5` to run commits on a cheaper model; Claude Code and OpenCode
command files have no per-command model setting.

## Cursor

| Target                  | Source                        | Notes                       |
|-------------------------|-------------------------------|-----------------------------|
| `~/.cursor/rules/*.mdc` | `home/dot_cursor/rules/*.mdc` | Hand-maintained (see below) |
| `~/.cursor/skills/*/`   | `home/dot_claude/skills/*/`   | Generated                   |

rulesync has no global-scope rule support for Cursor, so `home/dot_cursor/rules/*.mdc` is kept in
sync with `.rulesync/rules/` by hand. Cursor `.mdc` frontmatter uses `globs` and `alwaysApply`.

Cursor also reads these natively, with no copies needed:

- **Commands**: `~/.claude/commands/`, so `/git-commit` works without a Cursor copy.
- **Agents**: `~/.claude/agents/`.
- **Project instructions**: `AGENTS.md` in a project root.

Cursor's global **User Rules** live in a SQLite database
(`~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`, key
`aicontext.personalContext`), not a file chezmoi can manage. Set them once under **Cursor Settings →
Rules** by pasting `~/.claude/rules/general-behavior.md`.

## OpenCode

| Target                                       | Source                                             | Notes                                              |
|----------------------------------------------|----------------------------------------------------|----------------------------------------------------|
| `~/.config/opencode/AGENTS.md`               | `.rulesync/rules/AGENTS.md`                        | Generated root rule, with an index of the rules    |
| `~/.config/opencode/memories/*.md`           | `.rulesync/rules/*.md`                             | Generated                                          |
| `~/.config/opencode/opencode.jsonc`          | `.rulesync/rules/*.md`                             | rulesync writes `instructions`; other keys survive |
| `~/.config/opencode/commands/git-commit.md`  | `.rulesync/commands/git-commit.md`                 | Generated                                          |
| `~/.config/opencode/skills/*/`               | `home/dot_claude/skills/*/`                        | Generated                                          |
| `~/.config/opencode/plugins/active-agent.ts` | `home/dot_config/opencode/plugins/active-agent.ts` | Sets `ACTIVE_AGENT`, `PAGER`, `GIT_PAGER`          |
| `~/.config/opencode/plugins/rtk.ts`          | `home/dot_config/opencode/plugins/rtk.ts.tmpl`     | Deployed only when `rtk` is on `PATH`              |
| `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1`      | `available/opencode.sh`                            | Shell module, enabled when `opencode` is installed |

OpenCode is installed through devbox global on every host.

- **Instructions list**: rulesync replaces the whole `instructions` array in `opencode.jsonc` on
  every run, so add instruction files through `.rulesync/rules/`, not by editing that array.
- **Pager variables**: `opencode run` shells do not read `.zshrc` and inherit the launching
  terminal's pager, so the plugin sets `PAGER` and `GIT_PAGER` itself instead of relying on the
  agent branch of `.zshrc`.
- **Skills**: OpenCode also loads skills from `~/.claude/skills/`, including claude.ai-synced skills
  that need Claude-only tools. The shell module turns that off. Skills in `~/.agents/skills/` still
  load, so install third-party skills there (or with `--agent opencode`) to keep them visible.
- **Encrypted rule**: the environment rule reaches Claude Code only.

## Agent Shells

Each tool sets `ACTIVE_AGENT` so `.zshrc`/`.bashrc` take the minimal branch: no history, plugins,
completions, prompt, or pager.

| Tool        | Set by                             |
|-------------|------------------------------------|
| Claude Code | `env` in `~/.claude/settings.json` |
| Copilot     | VS Code terminal profile           |
| OpenCode    | `plugins/active-agent.ts`          |
| Cursor      | Not set by this repo               |

## Chezmoi Scripts

| Script                                                        | Runs when                       | Effect                                                    |
|---------------------------------------------------------------|---------------------------------|-----------------------------------------------------------|
| `home/.chezmoiscripts/run_onchange_rulesync-generate.sh.tmpl` | `.rulesync/` or a skill changes | Generates rules, commands, and skills for all targets     |
| `home/.chezmoiscripts/run_onchange_mklinks.sh.tmpl`           | `enabled/mklinks.sh` changes    | Rebuilds `enabled/` symlinks for the shell module loader  |
| `home/run_onchange_after_install-packages.sh.tmpl`            | Brewfile changes                | Installs Homebrew packages from the Brewfile              |
| `home/run_onchange_configure-vscode-copilot-terminal.sh.tmpl` | The script changes              | Writes the Copilot terminal profile into VS Code settings |
| `home/run_onchange_configure-macos-defaults.sh`               | The script changes              | Applies macOS system defaults                             |
| `home/run_once_init-devbox-local.sh.tmpl`                     | First apply only                | Initializes the devbox local environment                  |

## Supporting Tools

`home/dot_local/bin/executable_align-tables` deploys to `~/.local/bin/align-tables`. It reformats
Markdown tables to the MD060 aligned style the markdown rule requires, padding cells to display
width and skipping fenced code blocks. Agents run it after editing a table, then lint. It is
stdlib-only Python invoked through a uv-run shebang.

## New System Setup

1. Install chezmoi and clone this repo as the source directory.
2. Run `chezmoi apply`. This deploys all managed files, installs packages, and runs the scripts
   above, including rulesync generation.
3. Cursor: paste `~/.claude/rules/general-behavior.md` into **Cursor Settings → Rules**.
4. OpenCode: run `opencode auth login` and choose a provider, then set a default `model` in
   `~/.config/opencode/opencode.jsonc` if wanted. Restart OpenCode to load the plugins.
