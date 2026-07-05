#!/bin/sh

command -v eza >/dev/null 2>&1 || return

export EZA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/eza"

# eza needs a TTY: Claude Code `!` commands and pipes run without one and bare eza prints
# nothing. Agent shells get no benefit from eza either, so keep both on the plain-ls baseline.
if [ -t 1 ] && [ -z "${ACTIVE_AGENT}" ]; then
    alias ls='eza'
    alias l='eza --classify'
    alias ll='eza -l --time-style=long-iso'
    alias la='eza -la --time-style=long-iso'
    alias ls-l='eza -l --time-style=long-iso'
    alias ls-la='eza -la --time-style=long-iso'
    alias lso='eza -la --octal-permissions'
fi
