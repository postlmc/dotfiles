#!/bin/bash
# Approach from https://erikzaadi.com/2026/02/15/auto-resume-claude-code-sessions/
data=$(cat)
session_id=$(printf '%s' "$data" | jq -r '.session_id // empty')
cwd=$(printf '%s' "$data" | jq -r '.cwd // empty')
[ -n "$session_id" ] && [ -n "$cwd" ] && \
    printf 'claude --resume %s\n' "$session_id" > "$cwd/.ccid"
