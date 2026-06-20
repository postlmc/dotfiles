#!/bin/bash

command -v uv >/dev/null 2>&1 || return

# Default fallback venv — active in every shell, so there's always a Python
# without touching the OS install. Project direnv configs (layout uv) override
# VIRTUAL_ENV when entering a project directory.
if [[ -d "${HOME}/.venv" ]]; then
    export VIRTUAL_ENV="${HOME}/.venv"
    export VIRTUAL_ENV_DISABLE_PROMPT=1
    prepend_path PATH "${HOME}/.venv/bin"
fi

# Safety net: prevent pip from installing into the OS Python
export PIP_REQUIRE_VIRTUALENV=true

# Escape hatch for installing into ~/.venv regardless of active project venv
gpip() { VIRTUAL_ENV="${HOME}/.venv" uv pip install "$@"; }
