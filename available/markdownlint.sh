#!/bin/bash

command -v markdownlint-cli2 &>/dev/null || return

markdownlint-cli2() {
    command markdownlint-cli2 --config "${HOME}/.markdownlint-cli2.jsonc" "$@"
}

alias mdl='markdownlint-cli2'
alias mdlf='markdownlint-cli2 --fix'
