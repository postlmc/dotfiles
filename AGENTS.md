# Agent Configuration

## Repository Structure

- `.chezmoiroot` points to `home/` — all managed dotfiles live under `home/`
- File naming: `dot_` prefix → `.` in target, `.tmpl` suffix → processed as Go template, `run_once_before_` prefix → script runs
  once before apply

## Modular Shell Configuration

`available/` and `enabled/` implement Apache/Nginx-style modular shell config:

- `available/`: Shell config modules (aliases, functions, env vars) grouped by tool
- `enabled/`: Symlinks into `available/` with numeric prefixes controlling load order

Shell init files (`dot_zshrc`, `dot_bashrc`) source all `enabled/??-*` files. `enabled/mklinks.sh` auto-creates symlinks based on
installed tools.

Load order:

- `00-09`: Bootstrap (`prepend_path`/`append_path` path helpers)
- `10-19`: Core tools (openssl, ssh)
- `20-29`: OS-specific (homebrew, darwin, linux)
- `30-39`: Dev tools (git, docker)
- `40-49`: Languages (python, go, rust)
- `60-79`: Cloud/platform (azure, gcloud, kubernetes, terraform)
- `99`: Host-specific overrides

## Key Conventions

- `ACTIVE_AGENT` env var: when set, shell configs skip history, plugins, and interactive features — set this in agent/LLM contexts
- Templates reference `.chezmoi.hostname`, `.chezmoi.os`, and custom data from `~/.config/chezmoi/chezmoi.toml`
- Host-specific configs live in `~/.dotfiles.local/<hostname>-*` (gitignored, not managed by chezmoi)
- `prepend_path` / `append_path` (defined in `00-bootstrap`) handle idempotent PATH modifications
