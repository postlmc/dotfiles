#!/bin/bash

command -v brew >/dev/null 2>&1 || return

# Optimize Homebrew behavior for faster, cleaner operation
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_EMOJI=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# Let bare `brew bundle` find the chezmoi-managed Brewfile
export HOMEBREW_BUNDLE_FILE="${XDG_CONFIG_HOME:-${HOME}/.config}/homebrew/Brewfile"

alias brew-up='brew update && \
        (brew upgrade; brew upgrade --cask) && \
        brew cleanup -s'

# Bundle state — the Brewfile is the source of truth, `brew bundle` only ever
# adds. Drift accumulates because nothing prunes; brew-prune closes that gap.
alias brew-ls='brew bundle list --all'
alias brew-check='brew bundle check --verbose'
alias brew-sync='brew bundle install'

# Show (or with --force, remove) anything installed but not in the Brewfile
brew-prune() {
    if [[ "${1:-}" == "--force" ]]; then
        brew bundle cleanup --force
    else
        brew bundle cleanup
        echo "brew-prune: dry run — re-run 'brew-prune --force' to uninstall" >&2
    fi
}

# Package management — wrappers keep the chezmoi Brewfile template in sync,
# mirroring gbox-add/gbox-rm for devbox global. Plain `brew install` bypasses
# the template entirely, so the next `brew bundle` never knows about it and the
# package lingers forever as untracked drift.
# Only handles the unconditional formula/cask sections (marked "appends here").
# Edit the template directly for conditional packages (azure, kubernetes, etc.).
_brewfile_tmpl() {
    local tmpl="$(chezmoi source-path)/dot_config/homebrew/Brewfile.tmpl"
    [[ -f "$tmpl" ]] || { echo "Brewfile template not found: $tmpl" >&2; return 1; }
    printf '%s\n' "$tmpl"
}

brew-add() {
    local kind="brew" marker="# Developer tools that must stay in Homebrew (brew-add appends here)"
    if [[ "${1:-}" == "--cask" ]]; then
        kind="cask"
        marker="# GUI applications (brew-add --cask appends here)"
        shift
    fi

    local pkg="${1:-}"
    [[ -z "$pkg" ]] && { echo "Usage: brew-add [--cask] <name>" >&2; return 1; }

    local tmpl
    tmpl=$(_brewfile_tmpl) || return 1

    if grep -qE "^${kind} \"([^\"]*/)?${pkg}(@[^\"]*)?\"" "$tmpl"; then
        echo "brew-add: ${pkg} already in Brewfile template" >&2
        return 1
    fi
    grep -qF "$marker" "$tmpl" || {
        echo "brew-add: anchor comment missing from template: ${marker}" >&2
        return 1
    }

    local backup
    backup=$(mktemp) || return 1
    command cp "$tmpl" "$backup" || { command rm -f "$backup"; return 1; }

    # Insert in sorted position within the block following the anchor comment
    local tmp
    tmp=$(mktemp) || { command rm -f "$backup"; return 1; }
    awk -v marker="$marker" -v kind="$kind" -v name="$pkg" '
        BEGIN { entry = kind " \"" name "\""; state = 0 }
        state == 0 && $0 == marker { print; state = 1; next }
        state == 1 && $0 ~ "^" kind " \"" {
            line = $0
            sub("^" kind " \"", "", line); sub("\".*$", "", line); sub(".*/", "", line)
            if (!done && name < line) { print entry; done = 1 }
            print; next
        }
        state == 1 { if (!done) { print entry; done = 1 } state = 2 }
        { print }
        END { if (!done) print entry }
    ' "$tmpl" > "$tmp" && command mv "$tmp" "$tmpl" || { command rm -f "$tmp" "$backup"; return 1; }

    local brewfile="${HOMEBREW_BUNDLE_FILE}"
    local _status
    if chezmoi apply "$brewfile" && grep -qE "^${kind} \"${pkg}\"" "$brewfile"; then
        if [[ "$kind" == "cask" ]]; then
            brew install --cask "$pkg"
        else
            brew install "$pkg"
        fi
        _status=$?
    else
        _status=1
    fi
    if (( _status != 0 )); then
        echo "brew-add: ${pkg} failed to install — rolling back template and Brewfile" >&2
        command mv "$backup" "$tmpl"
        chezmoi apply "$brewfile"
        return "$_status"
    fi
    command rm -f "$backup"
    hash -r
}

brew-rm() {
    local kind="brew" flag=""
    if [[ "${1:-}" == "--cask" ]]; then
        kind="cask"
        flag="--cask"
        shift
    fi

    local pkg="${1:-}"
    [[ -z "$pkg" ]] && { echo "Usage: brew-rm [--cask] <name>[@version]" >&2; return 1; }

    local tmpl
    tmpl=$(_brewfile_tmpl) || return 1

    # An explicit @version matches only that entry; a bare name matches any
    # version — but never several at once (postgresql@14 vs postgresql@15).
    local pattern
    if [[ "$pkg" == *"@"* ]]; then
        pattern="^${kind} \"([^\"]*/)?${pkg}\""
    else
        pattern="^${kind} \"([^\"]*/)?${pkg}(@[^\"]*)?\""
    fi
    if (( $(grep -cE "$pattern" "$tmpl") > 1 )); then
        echo "brew-rm: ${pkg} matches multiple entries — pass the versioned name:" >&2
        grep -E "$pattern" "$tmpl" >&2
        return 1
    fi
    if ! grep -qE "$pattern" "$tmpl"; then
        echo "brew-rm: ${pkg} not found as a ${kind} in Brewfile template" >&2
        return 1
    fi

    local backup
    backup=$(mktemp) || return 1
    command cp "$tmpl" "$backup" || { command rm -f "$backup"; return 1; }

    local tmp
    tmp=$(mktemp) || { command rm -f "$backup"; return 1; }
    grep -vE "$pattern" "$tmpl" > "$tmp" \
        && command mv "$tmp" "$tmpl" || { command rm -f "$tmp" "$backup"; return 1; }

    local _status
    # shellcheck disable=SC2086
    brew uninstall $flag "$pkg"
    _status=$?
    if (( _status != 0 )); then
        echo "brew-rm: ${pkg} failed to uninstall — rolling back template" >&2
        command mv "$backup" "$tmpl"
        return "$_status"
    fi
    command rm -f "$backup"

    chezmoi apply "${HOMEBREW_BUNDLE_FILE}"
    _status=$?
    if (( _status != 0 )); then
        echo "brew-rm: ${pkg} uninstalled but Brewfile apply failed — run 'chezmoi apply' manually" >&2
    fi
    hash -r
    return "$_status"
}
