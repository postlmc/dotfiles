#!/bin/bash

command -v chezmoi >/dev/null 2>&1 || return

alias cm='chezmoi'
alias cmcd='cd $(chezmoi source-path)/..'  # Avoid the sub shell-ing of `chezmoi cd`

alias cm-sync='pushd $(chezmoi source-path) >/dev/null && \
    git pull --no-rebase --ff-only || true && \
    chezmoi apply && \
    popd >/dev/null'

alias cm-status='pushd $(chezmoi source-path) >/dev/null && \
    git status -sb && \
    popd >/dev/null'

# Updates everything: pulls the dotfiles, applies them, then updates Homebrew and devbox global
# where each exists. Refuses to run off main: apply would push a feature branch's unlanded files
# onto the whole host, and the pull would fast-forward the wrong branch or fail without upstream.
pkg-up() {
    local branch
    branch=$(chezmoi git -- branch --show-current) || return
    if [ "$branch" != "main" ]; then
        echo "pkg-up: dotfiles repo is on '${branch:-detached HEAD}', not main; land or switch first" >&2
        return 1
    fi
    chezmoi git -- pull --ff-only \
        && chezmoi apply \
        && { ! command -v brew-up >/dev/null 2>&1 || brew-up; } \
        && { ! command -v gbox-up >/dev/null 2>&1 || gbox-up; }
}
