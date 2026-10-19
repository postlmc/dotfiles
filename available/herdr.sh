#!/bin/bash

command -v herdr >/dev/null 2>&1 || return

# A fresh herdr server opens its first workspace wherever it was started, so start the default
# session from herdr's own config directory instead of $HOME or whatever project you're in. Herdr
# ignores the start directory when it restores saved workspaces.
_herdr_home="${XDG_CONFIG_HOME:-$HOME/.config}/herdr"

# h: herdr. With no arguments, launch or attach to the default session from $_herdr_home.
h() {
    if [ $# -eq 0 ]; then
        (cd "$_herdr_home" && herdr)
    else
        herdr "$@"
    fi
}

# Namedrop activation is per workspace and keyed to herdr's workspace ID, so a new workspace starts
# inactive even when an earlier one with the same label was active. Activation leaves
# ~/.claude/settings.json alone when its permission entries are already there.
_herdr_namedrop_activate() {
    local ws="$1"
    local sock

    [ -x "$HOME/.local/bin/namedrop" ] || return 0
    sock=$(herdr status 2>/dev/null | awk '$1 == "socket:" { print $2 }')
    "$HOME/.local/bin/namedrop" activate --json --input-json '{"confirmed":true}' \
        --herdr-socket "$sock" --herdr-workspace "$ws" >/dev/null ||
        echo "hn: namedrop activation failed for workspace $ws; run namedrop doctor there" >&2
}

# hn [label]: a new workspace in the default session, rooted at $PWD and labeled with its name.
# Without --cwd, herdr would root it at the focused pane's directory, wherever that is. Starts the
# server first when none is running, activates namedrop in the workspace when it's installed, and
# attaches when run outside herdr.
hn() {
    local label="${1:-$(basename "$PWD")}"
    local i out

    if ! herdr workspace list >/dev/null 2>&1; then
        # HERDR_STARTUP_CWD is what herdr's own client passes a server it spawns; it roots the
        # server's first workspace when nothing is restored.
        (cd "$_herdr_home" && HERDR_STARTUP_CWD="$_herdr_home" nohup herdr server >/dev/null 2>&1 &)
        for i in 1 2 3 4 5 6 7 8 9 10; do
            herdr workspace list >/dev/null 2>&1 && break
            sleep 0.5
        done
    fi

    out=$(herdr workspace create --cwd "$PWD" --label "$label" --focus) || return
    _herdr_namedrop_activate "$(printf '%s\n' "$out" | sed -n 's/.*"workspace_id":"\([^"]*\)".*/\1/p')"
    [ -n "${HERDR_ENV:-}" ] || h
}
