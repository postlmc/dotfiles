#!/bin/bash

command -v claude >/dev/null 2>&1 || return

# Claude Code utilities

c() {
    if [[ -f .ccid ]]; then
        local cmd
        cmd=$(cat .ccid)
        rm -f .ccid
        eval "$cmd"
    else
        claude "$@"
    fi
}
