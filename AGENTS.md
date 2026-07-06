# Agent Configuration

## Repository structure

- `.chezmoiroot` points to `home/` — all managed dotfiles live under `home/`
- File naming: `dot_` prefix → `.` in target; `.tmpl` suffix → processed as Go template; `run_once_` → script runs once ever;
  `run_onchange_` → script re-runs when its rendered content (including hashed includes) changes; an optional `before_`/`after_`
  segment orders scripts relative to file application

## Modular shell configuration

`available/` and `enabled/` implement modular shell config:

- `available/`: Shell config modules (aliases, functions, env vars) grouped by tool
- `enabled/`: Symlinks into `available/` with numeric prefixes controlling load order

Shell init files (`dot_zshrc`, `dot_bashrc`) source all `enabled/??-*` files. `enabled/mklinks.sh` auto-creates symlinks based on
installed tools. Never commit symlinks from `enabled/` to git.

Load order:

- `00-09`: Bootstrap and universal tools
- `10-19`: Core tools
- `20-29`: Package managers and OS-specific
- `30-39`: Dev tools
- `40-49`: Languages and linting
- `50-59`: Identity and secrets
- `60-79`: Cloud/platform
- `80-89`: AI tools

## Key conventions

- `ACTIVE_AGENT` env var: when set, shell configs skip history, plugins, and interactive features — set this in agent/LLM contexts
- Templates reference `.chezmoi.hostname` (case-preserved), `.chezmoi.os`, and custom data from `~/.config/chezmoi/chezmoi.toml`
- Host-specific configs live in `~/.config/local/` (gitignored, not managed by chezmoi)
- `prepend_path` / `append_path` (defined in `00-bootstrap`) handle idempotent PATH modifications
- `dot_zshenv` sets XDG base directory variables on macOS (Linux gets these from PAM/systemd)

## Direnv layouts

`home/dot_config/direnv/direnvrc` defines reusable layouts for `.envrc` files:

- `layout devbox` — activates a project devbox environment and restores Homebrew to PATH afterward
- `layout dotenv` — loads `.env.<name>` selected by `.env.choice`, falls back to `.env`; reloads on change
- `layout uv` — creates/activates a Python venv via uv

Project `.envrc` files should use these layouts rather than raw `eval "$(devbox ...)"` calls.

## Agent rules and instructions

Rules and instructions must be published for all three supported tools unless a rule is explicitly tool-specific. When adding or
updating a rule, update all three variants together:

| Tool        | Path                             | Extension          |
|-------------|----------------------------------|--------------------|
| Claude Code | `home/dot_claude/rules/`         | `.md`              |
| Cursor      | `home/dot_cursor/rules/`         | `.mdc`             |
| Copilot     | `home/dot_copilot/instructions/` | `.instructions.md` |

Content bodies are identical across all three; only frontmatter differs. A rule that intentionally omits one or two tools must
include a comment in that rule file explaining the reason.
