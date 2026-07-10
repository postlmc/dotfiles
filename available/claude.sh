#!/bin/bash
# Approach from https://erikzaadi.com/2026/02/15/auto-resume-claude-code-sessions/

command -v claude >/dev/null 2>&1 || return

ccr() {
    # Transcripts for a directory live under its sanitized path ("/" and "." become "-");
    # claude -c errors when the directory has no history, so probe before choosing
    if ls "${HOME}/.claude/projects/${PWD//[\/.]/-}/"*.jsonl >/dev/null 2>&1; then
        claude -c "$@"
    else
        claude "$@"
    fi
}

ccq() {
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

command -v copilot >/dev/null 2>&1 || return

cpr() {
    local id
    # Copilot records every session's cwd in its own store; resume the newest one for this
    # directory. A missed probe (schema change, no history) falls through to a fresh session.
    id=$(sqlite3 "${HOME}/.copilot/session-store.db" \
        "SELECT id FROM sessions WHERE cwd = '${PWD//\'/\'\'}' ORDER BY updated_at DESC LIMIT 1;" \
        2>/dev/null)
    if [[ "$id" =~ ^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$ ]]; then
        copilot --resume="$id" "$@"
    else
        copilot "$@"
    fi
}

cpq() {
    local model="" OPTIND opt
    while getopts "m:" opt; do
        case $opt in
            m) model=$OPTARG ;;
            *) return 1 ;;
        esac
    done
    shift $((OPTIND - 1))
    if [ -n "$model" ]; then
        copilot -p "$*" --allow-all-tools --silent --model "$model"
    else
        copilot -p "$*" --allow-all-tools --silent
    fi
}
