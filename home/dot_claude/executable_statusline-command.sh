#!/usr/bin/env bash
# Claude Code status line: repo/branch | model | 5h usage % | context % | reset timer
# Dracula color scheme (24-bit truecolor)

input=$(cat)
cwd=$(echo "$input"    | jq -r '.workspace.current_dir // .cwd // empty')
repo=$(echo "$input"   | jq -r '.workspace.repo.name // empty')
model=$(echo "$input"  | jq -r '.model.display_name // empty')
ctx_pct=$(echo "$input"  | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
lines_add=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
lines_del=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')

# Skip optional locks so we never block an active git operation
branch=""
if [ -n "$cwd" ]; then
    branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# Dracula palette
C_CYAN=$'\033[38;2;139;233;253m'
C_GREEN=$'\033[38;2;80;250;123m'
C_PURPLE=$'\033[38;2;189;147;249m'
C_YELLOW=$'\033[38;2;241;250;140m'
C_ORANGE=$'\033[38;2;255;184;108m'
C_PINK=$'\033[38;2;255;121;198m'
C_RED=$'\033[38;2;255;85;85m'
C_FG=$'\033[38;2;248;248;242m'
C_RESET=$'\033[0m'
SEP="${C_FG} | "

out=""

add_part() {
    if [ -n "$out" ]; then
        out="${out}${SEP}$1"
    else
        out="$1"
    fi
}

# repo/branch
if [ -n "$repo" ] && [ -n "$branch" ]; then
    add_part "${C_CYAN}${repo}${C_FG}/${C_GREEN}${branch}${C_RESET}"
elif [ -n "$branch" ]; then
    add_part "${C_GREEN}${branch}${C_RESET}"
elif [ -n "$repo" ]; then
    add_part "${C_CYAN}${repo}${C_RESET}"
fi

# model display name
[ -n "$model" ] && add_part "${C_PURPLE}${model}${C_RESET}"

# 5-hour rate limit usage % (only present after first API response for subscribers)
if [ -n "$five_pct" ]; then
    pct=$(printf '%.0f' "$five_pct")
    add_part "${C_FG}5h:${C_ORANGE}${pct}%${C_RESET}"
fi

# context window used %
if [ -n "$ctx_pct" ]; then
    ctx=$(printf '%.0f' "$ctx_pct")
    add_part "${C_FG}ctx:${C_YELLOW}${ctx}%${C_RESET}"
fi

# countdown to 5-hour window reset
if [ -n "$resets_at" ]; then
    now=$(date +%s)
    remaining=$(( resets_at - now ))
    if [ "$remaining" -gt 0 ]; then
        mins=$(( remaining / 60 ))
        hrs=$(( mins / 60 ))
        mins=$(( mins % 60 ))
        [ "$hrs" -gt 0 ] && timer="${hrs}h${mins}m" || timer="${mins}m"
        add_part "${C_FG}rst:${C_PINK}${timer}${C_RESET}"
    fi
fi

# code velocity: lines added/removed this session
if [ -n "$lines_add" ] || [ -n "$lines_del" ]; then
    add="${lines_add:-0}"
    del="${lines_del:-0}"
    add_part "${C_GREEN}+${add}${C_RESET} ${C_RED}-${del}${C_RESET}"
fi

printf '%s\n' "$out"
