#!/bin/bash

command -v brew >/dev/null 2>&1 || return

# Optimize Homebrew behavior for faster, cleaner operation
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_EMOJI=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# Let bare `brew bundle` find the chezmoi-managed Brewfile
export HOMEBREW_BUNDLE_FILE="${XDG_CONFIG_HOME:-${HOME}/.config}/homebrew/Brewfile"

# Installs anything the Brewfile declares that is missing, then upgrades everything (casks
# included). A function, not an alias, so pkg-up can call it.
brew-up() {
    brew update && brew bundle install && brew upgrade && brew cleanup -s
}

# Bundle state — the Brewfile is the source of truth, `brew bundle` only ever
# adds. Drift accumulates because nothing prunes; brew-prune closes that gap.
alias brew-ls='brew bundle list --all'
alias brew-check='brew bundle check --verbose'

# Show (or with --force, remove) anything installed but not in the Brewfile
brew-prune() {
    if [[ "${1:-}" == "--force" ]]; then
        brew bundle cleanup --force
    else
        brew bundle cleanup
        echo "brew-prune: dry run — re-run 'brew-prune --force' to uninstall" >&2
    fi
}
