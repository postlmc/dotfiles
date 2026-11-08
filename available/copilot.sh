#!/bin/bash

command -v copilot >/dev/null 2>&1 || return

co() {
    copilot "$@"
}

# cot [-m model] [prompt...]: a throw-away session in a fresh directory. A prompt starts the
# session with it.
cot() {
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
    [ $# -gt 0 ] && args+=(-i "$*")
    dir=$(mktemp -d) || return
    (cd "$dir" && copilot "${args[@]}")
}
