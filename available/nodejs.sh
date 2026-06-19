#!/bin/sh

command -v npm >/dev/null 2>&1 || return

# Nix store is read-only; redirect global npm installs to a writable prefix
export NPM_CONFIG_PREFIX="${HOME}/.npm-global"
export PATH="${HOME}/.npm-global/bin:${PATH}"
