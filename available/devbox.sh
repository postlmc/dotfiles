#!/bin/sh

command -v devbox >/dev/null 2>&1 || return

# Suppress devbox's "(devbox)" prompt prefix — starship handles prompt decoration
export DEVBOX_NO_PROMPT=1

# Update and refresh: global
gbox-up() {
    local _prev_nofile
    _prev_nofile=$(ulimit -n)
    ulimit -n 65536
    devbox global update \
        && chezmoi apply "${HOME}/.local/share/devbox/global/default/devbox.json" \
        && eval "$(devbox global shellenv --preserve-path-stack -r)" \
        && hash -r \
        && nix-collect-garbage
    ulimit -n "$_prev_nofile"
}

# Update: local project (no shell refresh needed — local devbox doesn't inject into interactive shell)
box-up() {
    local _prev_nofile
    _prev_nofile=$(ulimit -n)
    ulimit -n 65536
    devbox update && nix-collect-garbage
    ulimit -n "$_prev_nofile"
}

# Nix store GC without a package update
alias nix-gc='nix-collect-garbage'
alias nix-gc-all='nix-collect-garbage -d'

alias gbox-ls='devbox global list'
alias box-add='devbox add'
alias box-rm='devbox rm'
alias box-ls='devbox list'
alias box-search='devbox search'
