# Zsh Startup Performance — Findings and Decisions

Work done 2026-06-20, following up on the initial measurement prompt from 2026-04-08.

## Baseline (measured 2026-04-08, Darwin 25.4.0, arm64, zsh 5.9)

| Shell type                              | Wall-clock |
|-----------------------------------------|------------|
| Interactive (`zsh -i -c exit`)          | ~226ms     |
| Agent (`ACTIVE_AGENT=1 zsh -i -c exit`) | ~186ms     |
| Non-interactive (`zsh -c exit`)         | ~5ms       |

### Subprocess cost breakdown

| Call                                 | Location         | Cost      |
|--------------------------------------|------------------|-----------|
| `devbox global shellenv --init-hook` | unconditional    | **132ms** |
| `brew shellenv`                      | unconditional    | 17ms      |
| `ssh-alias` (two awk subprocesses)   | module load      | 15ms      |
| `compinit` (including compaudit)     | interactive only | 15ms      |
| `direnv hook zsh`                    | unconditional    | 4ms       |
| `starship init zsh`                  | interactive only | 4ms       |
| `fzf --zsh`                          | interactive only | 3ms       |
| `path_helper`                        | unconditional    | 3ms       |

Stale compdump incurred a one-time +46ms penalty when triggered.

## What was implemented

**`typeset -U fpath` before `compinit`** — Prevents duplicate fpath entries (added by `brew shellenv` and `devbox shellenv`) from
causing compinit to see a different hash each session and rebuild its dump file. This eliminated the +46ms stale-dump penalty
becoming a recurring cost.

**`compinit -C` always** — Skips the compaudit security scan (~9ms) on every startup. The `-C` flag is safe here because `typeset -U
fpath` already ensures the dump never goes stale due to duplicate entries. The dump file was also relocated from `~/.zcompdump` to
`~/.cache/zsh/.zcompdump` for organization. An earlier attempt at a timed expiry glob `(#qN.mh+24)` was tried and reverted — it
added measurable overhead (~10ms) that exceeded the gain.

**`ssh-alias` guarded by `ACTIVE_AGENT`** — The awk-based SSH host alias generator was called unconditionally at module source time.
Adding `[[ -z "${ACTIVE_AGENT}" ]] && ssh-alias` in `ssh.sh` saves ~15ms in agent shells without splitting SSH functionality across
files.

## What was passed on and why

**Cache `devbox global shellenv` output (would save ~132ms)** — The output includes session-specific variables (`TERM`, `TMPDIR`,
`USER`, `XPC_*`, `__CF_*`) that must be filtered before caching to avoid overriding correct terminal-set values in other sessions.
The filtering regex adds complexity that was judged not worth the return.

**Skip `devbox shellenv` in agent shells (would save ~132ms for agents)** — Agent shells set by VS Code are launched as login shells
with a clean environment, not as subprocesses of an existing devbox-initialized shell. Skipping the eval would leave VS Code agent
terminals without any devbox-managed tools on PATH.

**Cache `brew shellenv` output (would save ~17ms)** — Simpler than the devbox cache (no filtering needed), but 17ms was judged
insufficient return for the added logic.
