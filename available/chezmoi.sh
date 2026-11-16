#!/bin/bash

command -v chezmoi >/dev/null 2>&1 || return

alias cm='chezmoi'
alias cmcd='cd $(chezmoi source-path)/..'  # Avoid the sub shell-ing of `chezmoi cd`

alias cm-sync='pushd $(chezmoi source-path) >/dev/null && \
    git pull --no-rebase --ff-only || true && \
    chezmoi apply && \
    popd >/dev/null'

alias cm-push='pushd $(chezmoi source-path) >/dev/null && \
    git add -A && \
    git diff --cached --quiet || git commit -m "Update managed dotfiles" && \
    git push || true && \
    popd >/dev/null'

alias cm-status='pushd $(chezmoi source-path) >/dev/null && \
    git status -sb && \
    popd >/dev/null'

# Updates everything: pulls the dotfiles, applies them, then updates Homebrew and devbox global
# where each exists.
pkg-up() {
    chezmoi git -- pull --ff-only \
        && chezmoi apply \
        && { ! command -v brew-up >/dev/null 2>&1 || brew-up; } \
        && { ! command -v gbox-up >/dev/null 2>&1 || gbox-up; }
}
