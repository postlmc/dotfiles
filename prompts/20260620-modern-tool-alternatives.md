# Modern Tool Alternatives — Findings and Decisions

Work done 2026-06-20, based on the `NEW_TOOLS.md` audit of `available/` and `home/` shell scripts.

## Approach

All replacements use `command -v` guards so the classic tool remains in effect on any system where the modern alternative is not
installed. Tools already in devbox global (`bat`, `ripgrep`, `xh`) were usable immediately; the rest (`eza`, `fd`, `neovim`, `dog`,
`duf`) were added to devbox global to guarantee presence everywhere devbox runs.

## What was implemented

| Swap           | Files                      | Notes                                                                                    |
|----------------|----------------------------|------------------------------------------------------------------------------------------|
| `ls` → `eza`   | `core.sh`                  | `lso` replaced by `eza -la --octal-permissions`; `eza -la --git` available interactively |
| `grep` → `rg`  | `core.sh`                  | Interactive alias only; bare `grep` remains in PATH for scripts                          |
| `dig` → `dog`  | `core.sh`                  | `digs` alias points to `dog`; falls back to `dig +short`                                 |
| `df` → `duf`   | `core.sh`                  | Global `df` alias; usage bars and cleaner output                                         |
| `vim` → `nvim` | `core.sh`                  | `EDITOR` preference order: nvim → vim → vi                                               |
| `less` → `bat` | `core.sh`, `kubernetes.sh` | `PAGER`/`MANPAGER` set globally; `ke()` uses bat with yaml highlighting                  |
| `find` → `fd`  | `kubernetes.sh`, `git.sh`  | `kcfg()`, `git-remotes()`, `getgit()` prefer fd; find fallback retained                  |
| `curl` → `xh`  | `git.sh`, `docker.sh`      | `ghostars()`, `docker-tags()`, `docker-rl()` prefer xh; curl fallback retained           |

## What was passed on

`ps` in `ssh-agent.sh` — background process check in a script context; no meaningful benefit from `procs` here.
