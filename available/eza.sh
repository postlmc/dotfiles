#!/bin/sh

command -v eza >/dev/null 2>&1 || return

export EZA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/eza"

alias ll='eza -l --time-style=long-iso'
alias la='eza -la --time-style=long-iso'
