# Agent Configuration

## Repository structure

- `.chezmoiroot` points to `home/` — all managed dotfiles live under `home/`
- File naming: `dot_` prefix → `.` in target, `.tmpl` suffix → processed as Go template, `run_once_before_` prefix → script runs
  once before apply

## Modular shell configuration

`available/` and `enabled/` implement Apache/Nginx-style modular shell config:

- `available/`: Shell config modules (aliases, functions, env vars) grouped by tool
- `enabled/`: Symlinks into `available/` with numeric prefixes controlling load order

Shell init files (`dot_zshrc`, `dot_bashrc`) source all `enabled/??-*` files. `enabled/mklinks.sh` auto-creates symlinks based on
installed tools. Never commit symlinks from `enabled/` to git.

Load order:

- `00-09`: Bootstrap and universal tools (`prepend_path`/`append_path` helpers, core, chezmoi, eza)
- `10-19`: Core tools (openssl, ssh, ssh-agent on Linux)
- `20-29`: Package managers and OS-specific (homebrew, devbox, linux, rpi, tailscale, darwin)
- `30-39`: Dev tools (git, docker)
- `40-49`: Languages and linting (python, go, rust, nodejs, markdownlint)
- `50-59`: Identity and secrets (1Password op)
- `60-79`: Cloud/platform (azure, gcloud, kubernetes, terraform)

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

## Notable managed configs

- `home/dot_config/eza/theme.yml` — Dracula palette eza theme; `available/eza.sh` sets `EZA_CONFIG_DIR`
- `home/dot_config/ghostty/config.tmpl` — per-host font weight via `.chezmoi.hostname`
- `home/dot_config/direnv/direnvrc` — direnv stdlib extensions (layouts above)
- `home/dot_local/share/devbox/global/default/devbox.json.tmpl` — global devbox packages, conditionally includes kubernetes, rust,
  python, terraform tooling based on chezmoi data

## Session resumption

`.ccid` in the repo root contains the current Claude Code session ID. `.envrc` adds `.bin/` to PATH, which provides a `clr`
command that runs `claude --resume $(cat .ccid)`.
