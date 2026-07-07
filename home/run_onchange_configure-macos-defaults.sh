#!/bin/bash
# macOS system preference defaults. Reruns automatically on chezmoi apply when this file changes.

[[ "$(uname)" == "Darwin" ]] || exit 0

# Keyboard: go below the UI minimums (UI floor is 15/2; these require defaults write)
defaults write -g InitialKeyRepeat -float 10
defaults write -g KeyRepeat -float 1

# Keyboard: disable autocorrect and auto-capitalization
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Finder: always show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: search within current folder instead of whole Mac
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Finder: show status bar (item count, disk space) and path bar
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true

# Spaces: don't reorder spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

killall Finder Dock 2>/dev/null || true
