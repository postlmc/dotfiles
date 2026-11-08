#!/bin/bash

command -v opencode >/dev/null 2>&1 || return

# OpenCode also loads skills from ~/.claude/skills/, including claude.ai-synced ones that depend on
# Claude-only tools. This repo's own skills reach OpenCode through rulesync instead; skills in
# ~/.agents/skills/ are unaffected.
export OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1

oc() {
    opencode "$@"
}

# oct [-m provider/model] [prompt...]: a throw-away session in a fresh directory. A prompt starts
# the session with it; opencode's own positional argument is a project path.
oct() {
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
    [ $# -gt 0 ] && args+=(--prompt "$*")
    dir=$(mktemp -d) || return
    (cd "$dir" && opencode "${args[@]}")
}
