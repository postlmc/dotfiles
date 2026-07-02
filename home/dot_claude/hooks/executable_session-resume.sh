#!/bin/bash
data=$(cat)
session_id=$(printf '%s' "$data" | jq -r '.session_id // empty')
cwd=$(printf '%s' "$data" | jq -r '.cwd // empty')
[ -n "$session_id" ] && [ -n "$cwd" ] && \
    printf 'claude --resume %s\n' "$session_id" > "$cwd/.ccid"
