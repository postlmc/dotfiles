# Zsh Startup Performance

I want to measure and reduce zsh startup time in my chezmoi-managed dotfiles at
`~/.local/share/chezmoi`. The shell config is in `home/dot_zshrc`.

## Current structure (relevant to startup cost)

`.zshrc` runs these in order, unconditionally for every shell:

1. `path_helper` (macOS, subprocess: `eval $(/usr/libexec/path_helper -s)`)
2. `devbox global shellenv --init-hook` (subprocess: `eval "$(/usr/local/bin/devbox global shellenv --init-hook)"`)
3. `brew shellenv` (subprocess: `eval "$(/opt/homebrew/bin/brew shellenv)"`)
4. `direnv hook zsh` (subprocess: `eval "$(direnv hook zsh)"`)
5. Source all shell modules from `available/??-*` (file sourcing loop, ~20 files)
6. PATH additions (`prepend_path` calls)

Then, for interactive shells only (`ACTIVE_AGENT` is unset):

7. `compinit` (scans fpath)
8. Tool completions (kubectl, kubelogin, op — each cached to `~/.cache/zsh/`)
9. Plugins: zsh-autosuggestions, zsh-syntax-highlighting, zsh-hist
10. `fzf --zsh` (subprocess: `eval "$(fzf --zsh)"`)
11. `starship init zsh` (subprocess: `eval "$(starship init zsh)"`)

Agent shells (when `ACTIVE_AGENT` is set) skip steps 7-11 entirely.

## What I want to understand

1. How to measure: `zsh --startuptime /tmp/zsh-startup.log -i -c exit` and `time zsh -i -c exit`
2. Which of the subprocess `eval $(...)` calls are actually slow on this machine
3. Whether any can be cached, deferred, or eliminated
4. Whether `compinit` can be sped up (dump file, skip security check, etc.)
5. Whether the agent-shell fast path is actually fast, and if not, what's still loading

## Constraints

- devbox, brew, direnv, and starship are all required and in active use
- The shell modules loop (step 5) is a recent architectural change — it replaced a symlink-based
  enabled/available pattern. Performance impact there should be negligible but worth confirming.
- macOS (Darwin), zsh is the primary shell

## Starting point

Run the startup timer and share the output so we can triage from data, not guesses.
