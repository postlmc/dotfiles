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

cq() {
    local model="" OPTIND opt
    while getopts "m:" opt; do
        case $opt in
            m) model=$OPTARG ;;
            *) return 1 ;;
        esac
    done
    shift $((OPTIND - 1))
    if [ -n "$model" ]; then
        claude -p --no-session-persistence --model "$model" "$@"
    else
        claude -p --no-session-persistence "$@"
    fi
}
