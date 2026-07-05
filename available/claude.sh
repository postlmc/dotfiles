#!/bin/bash
# Approach from https://erikzaadi.com/2026/02/15/auto-resume-claude-code-sessions/

command -v claude >/dev/null 2>&1 || return

c() {
    if [[ -f .ccid ]]; then
        local id
        id=$(<.ccid)
        rm -f .ccid
        # .ccid may come from an untrusted repo — resume only if it looks like a session UUID
        if [[ "$id" =~ ^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$ ]]; then
            claude --resume "$id" "$@"
        else
            echo "c: ignoring .ccid with unexpected content" >&2
            claude "$@"
        fi
    else
        claude "$@"
    fi
}
