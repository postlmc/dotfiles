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

# Package management — wrappers keep the chezmoi modify script in sync.
# Plain add/rm would mutate the live file but get normalized on next chezmoi apply.
# These update the modify script source first, then apply + install. If the
# install/uninstall step fails (e.g. a package name that doesn't resolve in
# nixpkgs), the template edit is rolled back so the template and live
# devbox.json never end up out of sync with what devbox actually has installed.
# Only handles unconditional packages (main $pkgs list). Edit the modify script
# directly for conditional packages (kubernetes, python, etc.).
gbox-add() {
    local pkg="${1:-}"
    [[ -z "$pkg" ]] && { echo "Usage: gbox-add <package>[@version]" >&2; return 1; }
    [[ "$pkg" != *"@"* ]] && pkg="${pkg}@latest"

    local tmpl
    tmpl="$(chezmoi source-path)/dot_local/share/devbox/global/default/modify_devbox.json.tmpl"
    [[ -f "$tmpl" ]] || { echo "gbox-add: modify script not found: $tmpl" >&2; return 1; }

    if grep -qF "\"${pkg}\"" "$tmpl"; then
        echo "gbox-add: ${pkg} already in modify script" >&2
        return 1
    fi

    local backup
    backup=$(mktemp) || return 1
    command cp "$tmpl" "$backup" || { command rm -f "$backup"; return 1; }

    # Insert before the first standalone -}} line (closes the $pkgs := list block)
    local tmp
    tmp=$(mktemp) || { command rm -f "$backup"; return 1; }
    awk -v pkg="    \"${pkg}\"" '
        !inserted && /^-\}\}/ { print pkg; inserted=1 }
        { print }
    ' "$tmpl" > "$tmp" && command mv "$tmp" "$tmpl" || { command rm -f "$tmp" "$backup"; return 1; }

    local devbox_json="${HOME}/.local/share/devbox/global/default/devbox.json"
    local _prev_nofile _status
    _prev_nofile=$(ulimit -n)
    ulimit -n 65536 2>/dev/null || true
    chezmoi apply "$devbox_json" \
        && grep -qF "\"${pkg}\"" "$devbox_json" \
        && devbox global add "${pkg}"
    _status=$?
    if (( _status != 0 )); then
        echo "gbox-add: ${pkg} failed to install — rolling back template and devbox.json" >&2
        command mv "$backup" "$tmpl"
        chezmoi apply "$devbox_json"
        ulimit -n "$_prev_nofile"
        return "$_status"
    fi
    command rm -f "$backup"

    eval "$(devbox global shellenv --preserve-path-stack -r)" && hash -r
    _status=$?
    ulimit -n "$_prev_nofile"
    if (( _status != 0 )); then
        echo "gbox-add: ${pkg} installed but shell refresh failed — run 'hash -r' or restart your shell" >&2
    fi
    return "$_status"
}

gbox-rm() {
    local pkg="${1:-}"
    [[ -z "$pkg" ]] && { echo "Usage: gbox-rm <package>[@version]" >&2; return 1; }
    local pkgbase="${pkg%%@*}"

    local tmpl
    tmpl="$(chezmoi source-path)/dot_local/share/devbox/global/default/modify_devbox.json.tmpl"
    [[ -f "$tmpl" ]] || { echo "gbox-rm: modify script not found: $tmpl" >&2; return 1; }

    # An explicit @version matches only that entry; a bare name matches any
    # version — but never several at once (kubectl@1.30 vs kubectl@1.31), since
    # the removal below is a grep -v that would delete every match at once.
    local pattern matches
    if [[ "$pkg" == *"@"* ]]; then
        pattern="\"${pkg}\""
    else
        pattern="\"${pkgbase}(@[^\"]+)?\""
    fi
    matches=$(grep -cE "$pattern" "$tmpl")
    if (( matches == 0 )); then
        echo "gbox-rm: ${pkg} not found in modify script" >&2
        return 1
    fi
    if (( matches > 1 )); then
        echo "gbox-rm: ${pkg} matches multiple entries — pass the versioned name:" >&2
        grep -E "$pattern" "$tmpl" | sed 's/^[[:space:]]*/  /' >&2
        return 1
    fi

    local backup
    backup=$(mktemp) || return 1
    command cp "$tmpl" "$backup" || { command rm -f "$backup"; return 1; }

    local tmp
    tmp=$(mktemp) || { command rm -f "$backup"; return 1; }
    grep -vE "$pattern" "$tmpl" > "$tmp" \
        && command mv "$tmp" "$tmpl" || { command rm -f "$tmp" "$backup"; return 1; }

    local devbox_json="${HOME}/.local/share/devbox/global/default/devbox.json"
    local _prev_nofile _status
    _prev_nofile=$(ulimit -n)
    ulimit -n 65536 2>/dev/null || true
    devbox global rm "${pkgbase}"
    _status=$?
    if (( _status != 0 )); then
        echo "gbox-rm: ${pkgbase} failed to uninstall — rolling back template" >&2
        command mv "$backup" "$tmpl"
        ulimit -n "$_prev_nofile"
        return "$_status"
    fi
    command rm -f "$backup"

    chezmoi apply "$devbox_json" \
        && eval "$(devbox global shellenv --preserve-path-stack -r)" \
        && hash -r
    _status=$?
    ulimit -n "$_prev_nofile"
    if (( _status != 0 )); then
        echo "gbox-rm: ${pkgbase} uninstalled but devbox.json apply/shell refresh failed — run 'chezmoi apply' manually" >&2
    fi
    return "$_status"
}

alias gbox-ls='devbox global list'
alias box-add='devbox add'
alias box-rm='devbox rm'
alias box-ls='devbox list'
alias box-search='devbox search'
