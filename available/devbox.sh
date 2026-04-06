#!/bin/sh

command -v devbox >/dev/null 2>&1 || return

# Suppress devbox's "(devbox)" prompt prefix — starship handles prompt decoration
export DEVBOX_NO_PROMPT=1

# Update and refresh: global
alias gbox-up='devbox global update && \
        eval "$(devbox global shellenv --preserve-path-stack -r)" && \
        hash -r && \
        nix-collect-garbage'

# Update: local project (no shell refresh needed — local devbox doesn't inject into interactive shell)
alias box-up='devbox update && nix-collect-garbage'

# Nix store GC without a package update
alias nix-gc='nix-collect-garbage'
alias nix-gc-all='nix-collect-garbage -d'

# Package management shorthands
alias gbox-add='devbox global add'
alias gbox-rm='devbox global rm'
alias gbox-ls='devbox global list'
alias box-add='devbox add'
alias box-rm='devbox rm'
alias box-ls='devbox list'
alias box-search='devbox search'
