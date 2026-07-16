#!/bin/bash
# Second chezmoi instance for host-local files that need tracking but cannot live in the
# public dotfiles repo. The config is deployed by that repo; cml-init bootstraps the rest.

command -v chezmoi >/dev/null 2>&1 || return

CML_CONFIG="${HOME}/.config/chezmoi.local/chezmoi.toml"

cml() {
    chezmoi --config "${CML_CONFIG}" "$@"
}

cml-init() {
    local src="${HOME}/.local/share/chezmoi.local"
    if [ ! -f "${CML_CONFIG}" ]; then
        echo "cml-init: ${CML_CONFIG} missing — run chezmoi apply first" >&2
        return 1
    fi
    mkdir -p "${src}"
    [ -d "${src}/.git" ] || git -C "${src}" init
    # Guard against the two instances fighting over a path: last apply would silently win
    if [ ! -f "${src}/run_after_check-overlap.sh" ]; then
        cat > "${src}/run_after_check-overlap.sh" <<'EOF'
#!/bin/bash
overlap=$(comm -12 \
    <(chezmoi managed --path-style=absolute | sort) \
    <(chezmoi --config "${HOME}/.config/chezmoi.local/chezmoi.toml" managed --path-style=absolute | sort))
if [ -n "${overlap}" ]; then
    printf 'Managed by BOTH chezmoi instances (remove from one):\n%s\n' "${overlap}" >&2
    exit 1
fi
EOF
        git -C "${src}" add run_after_check-overlap.sh
    fi
    echo "cml-init: ${src} ready — set a private remote, then track files with 'cml add <path>'"
}
