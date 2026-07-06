#!/bin/bash

command -v op >/dev/null 2>&1 || return

# 1Password CLI completion (cached — delete cache file to regenerate); ZSH_VERSION guard
# keeps the zsh completion script away from bash
if [[ -n "$ZSH_VERSION" && -n "$ZSH_CACHE_DIR" ]]; then
    _opc="${ZSH_CACHE_DIR}/op.zsh"
    [[ ! -f "$_opc" ]] && op completion zsh 2>/dev/null > "$_opc"
    [[ -f "$_opc" ]] && source "$_opc"
    unset _opc
fi
