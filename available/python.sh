#!/bin/bash

command -v uv >/dev/null 2>&1 || return

# Default fallback venv, shared with VS Code and Cursor, active in every shell so there's always a
# Python without touching the OS install. Project direnv configs (layout uv) override VIRTUAL_ENV
# when entering a project directory.
_default_venv="${XDG_DATA_HOME:-${HOME}/.local/share}/venv"
if [[ -d "${_default_venv}" ]]; then
    export VIRTUAL_ENV="${_default_venv}"
    export VIRTUAL_ENV_DISABLE_PROMPT=1
    prepend_path PATH "${_default_venv}/bin"
fi
unset _default_venv

# Safety net: prevent pip from installing into the OS Python
export PIP_REQUIRE_VIRTUALENV=true

# Escape hatch for installing into the default venv regardless of active project venv
gpip() { uv pip install --python "${XDG_DATA_HOME:-${HOME}/.local/share}/venv/bin/python" "$@"; }
