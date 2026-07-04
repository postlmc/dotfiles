#!/bin/bash
# Approach from https://erikzaadi.com/2026/02/15/auto-resume-claude-code-sessions/

command -v claude >/dev/null 2>&1 || return

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
