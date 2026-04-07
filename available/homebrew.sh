#!/bin/bash

command -v brew >/dev/null 2>&1 || return

# Optimize Homebrew behavior for faster, cleaner operation
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_EMOJI=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

alias brew-up='brew update && \
        (brew upgrade; brew upgrade --cask) && \
        brew cleanup -s'
alias brew86-up='brew86 update && \
        (brew86 upgrade; brew86 upgrade --cask) && \
        brew86 cleanup -s'
