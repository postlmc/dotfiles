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

# Package management — template-aware wrappers keep devbox.json.tmpl in sync
# Plain add/rm would mutate the live file but get clobbered on next chezmoi apply.
# These update the chezmoi template first, then apply + install atomically.
# Only handles unconditional packages (main $pkgs list). Edit the template
# directly for conditional packages (kubernetes, python, etc.).
gbox-add() {
    local pkg="${1}"
    [[ -z "$pkg" ]] && { echo "Usage: gbox-add <package>[@version]" >&2; return 1; }
    [[ "$pkg" != *"@"* ]] && pkg="${pkg}@latest"

    local tmpl
    tmpl="$(chezmoi source-path)/dot_local/share/devbox/global/default/devbox.json.tmpl"

    if grep -qF "\"${pkg}\"" "$tmpl"; then
        echo "gbox-add: ${pkg} already in template" >&2
        return 1
    fi

    # Insert before the first standalone -}} line (closes the $pkgs := list block)
    local tmp
    tmp=$(mktemp) || return 1
    awk -v pkg="    \"${pkg}\"" '
        !inserted && /^-\}\}/ { print pkg; inserted=1 }
        { print }
    ' "$tmpl" > "$tmp" && mv "$tmp" "$tmpl" || { rm -f "$tmp"; return 1; }

    chezmoi apply \
        && devbox global add "${pkg}" \
        && eval "$(devbox global shellenv --preserve-path-stack -r)" \
        && hash -r
}

gbox-rm() {
    local pkgbase="${1%%@*}"  # strip @version — match on base name
    [[ -z "$pkgbase" ]] && { echo "Usage: gbox-rm <package>[@version]" >&2; return 1; }

    local tmpl
    tmpl="$(chezmoi source-path)/dot_local/share/devbox/global/default/devbox.json.tmpl"

    if ! grep -qE "\"${pkgbase}(@[^\"]+)?\"" "$tmpl"; then
        echo "gbox-rm: ${pkgbase} not found in template" >&2
        return 1
    fi

    local tmp
    tmp=$(mktemp) || return 1
    grep -vE "\"${pkgbase}(@[^\"]+)?\"" "$tmpl" > "$tmp" \
        && mv "$tmp" "$tmpl" || { rm -f "$tmp"; return 1; }

    chezmoi apply \
        && devbox global rm "${pkgbase}" \
        && eval "$(devbox global shellenv --preserve-path-stack -r)" \
        && hash -r
}

alias gbox-ls='devbox global list'
alias box-add='devbox add'
alias box-rm='devbox rm'
alias box-ls='devbox list'
alias box-search='devbox search'
