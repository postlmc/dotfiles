# Agent Configuration

## Repository structure

- `.chezmoiroot` points to `home/` — all managed dotfiles live under `home/`
- File naming: `dot_` prefix → `.` in target; `.tmpl` suffix → processed as Go template; `run_once_` → script runs once ever;
  `run_onchange_` → script re-runs when its rendered content (including hashed includes) changes; an optional `before_`/`after_`
  segment orders scripts relative to file application
- `.rulesync/` (repo root, outside `home/`) is source material for [rulesync](https://github.com/dyoshikawa/rulesync), not a
  dotfile itself — see "Agent rules and instructions" below

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

## Package management: devbox vs Homebrew

devbox global (`home/dot_local/share/devbox/global/default/modify_devbox.json.tmpl`) is the primary package manager;
Homebrew is minimized. A package stays on Homebrew only when at least one of these holds:

1. It's a Mac GUI app (cask) — devbox/nix doesn't manage these.
2. It isn't available in nixpkgs at all.
3. It has some other complication that blocks a clean migration — e.g. no cached binary on `cache.nixos.org`, forcing an
   expensive from-source build (seen with `azure-functions-core-tools`, which pulls in the full dotnet SDK).

Use `gbox-add`/`gbox-rm` (defined in `available/devbox.sh`) to add or remove global devbox packages — they keep the modify
script source in sync with the live install. Run `bin/brew-devbox-overlap` periodically to find Homebrew formulas whose
binaries are now also provided by devbox global; anything that overlaps and isn't covered by the exceptions above should
migrate off Homebrew.

## Agent rules and instructions

Rules are managed by [rulesync](https://github.com/dyoshikawa/rulesync) from a single source, `.rulesync/rules/*.md`, for
**Claude Code and Copilot only**. `home/.chezmoiscripts/run_onchange_rulesync-generate.sh.tmpl` runs `rulesync generate`
on every `chezmoi apply` where `.rulesync/` changed, writing `~/.claude/rules/*.md` and `~/.copilot/instructions/*.instructions.md`.
To change a rule, edit `.rulesync/rules/<name>.md` and run `chezmoi apply` — don't hand-edit the generated files, they get
overwritten.

**Cursor is the exception**: rulesync doesn't support global-scope rules for Cursor (checked against v16.5.0's source —
`rules-processor.ts` declares `cursor: { supportsGlobal: false }`), so `home/dot_cursor/rules/*.mdc` stays entirely
hand-maintained, kept in sync by hand with `.rulesync/rules/` content.

Commands work the same way for the one real command, `git-commit`: `.rulesync/commands/git-commit.md` generates
`~/.claude/commands/git-commit.md`. Copilot's version is hand-maintained at
`home/dot_copilot/instructions/git-commit.prompt.md` — rulesync doesn't support global-scope commands for Copilot either
(`commands-processor.ts`: `copilot: { supportsGlobal: false }`, and there's no `copilotcli` command target at all). There's
no Cursor command surface to mirror.

`rulesync` isn't in nixpkgs, so it isn't a devbox package — it runs via `npx rulesync@<pinned version>`, pinned in the
run_onchange script itself. Update the pin deliberately (never `@latest`); rulesync ships breaking changes roughly monthly.
