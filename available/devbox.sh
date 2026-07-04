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
# These update the modify script source first, then apply + install atomically.
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

    # Insert before the first standalone -}} line (closes the $pkgs := list block)
    local tmp
    tmp=$(mktemp) || return 1
    awk -v pkg="    \"${pkg}\"" '
        !inserted && /^-\}\}/ { print pkg; inserted=1 }
        { print }
    ' "$tmpl" > "$tmp" && command mv "$tmp" "$tmpl" || { rm -f "$tmp"; return 1; }

    local _prev_nofile
    _prev_nofile=$(ulimit -n)
    ulimit -n 65536 2>/dev/null || true
    chezmoi apply \
        && devbox global add "${pkg}" \
        && eval "$(devbox global shellenv --preserve-path-stack -r)" \
        && hash -r
    ulimit -n "$_prev_nofile"
}

gbox-rm() {
    local pkgbase="${1:-}"
    pkgbase="${pkgbase%%@*}"  # strip @version — match on base name
    [[ -z "$pkgbase" ]] && { echo "Usage: gbox-rm <package>[@version]" >&2; return 1; }

    local tmpl
    tmpl="$(chezmoi source-path)/dot_local/share/devbox/global/default/modify_devbox.json.tmpl"
    [[ -f "$tmpl" ]] || { echo "gbox-rm: modify script not found: $tmpl" >&2; return 1; }

    if ! grep -qE "\"${pkgbase}(@[^\"]+)?\"" "$tmpl"; then
        echo "gbox-rm: ${pkgbase} not found in modify script" >&2
        return 1
    fi

    local tmp
    tmp=$(mktemp) || return 1
    grep -vE "\"${pkgbase}(@[^\"]+)?\"" "$tmpl" > "$tmp" \
        && command mv "$tmp" "$tmpl" || { rm -f "$tmp"; return 1; }

    local _prev_nofile
    _prev_nofile=$(ulimit -n)
    ulimit -n 65536 2>/dev/null || true
    devbox global rm "${pkgbase}" \
        && chezmoi apply \
        && eval "$(devbox global shellenv --preserve-path-stack -r)" \
        && hash -r
    ulimit -n "$_prev_nofile"
}

alias gbox-ls='devbox global list'
alias box-add='devbox add'
alias box-rm='devbox rm'
alias box-ls='devbox list'
alias box-search='devbox search'
