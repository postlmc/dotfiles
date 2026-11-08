#!/bin/bash

command -v claude >/dev/null 2>&1 || return

# cc shadows the C compiler only at an interactive prompt; builds run /usr/bin/cc directly, and
# `command cc` still reaches it.
cc() {
    claude "$@"
}

# cct [-m model] [args...]: a throw-away session in a fresh directory.
# Remaining arguments go to claude as-is, so a quoted prompt starts the session with it.
cct() {
    local model="" OPTIND opt dir
    local -a args=()
    while getopts "m:" opt; do
        case $opt in
            m) model=$OPTARG ;;
            *) return 1 ;;
        esac
    done
    shift $((OPTIND - 1))
    [ -n "$model" ] && args+=(--model "$model")
    dir=$(mktemp -d) || return
    (cd "$dir" && claude "${args[@]}" "$@")
}
