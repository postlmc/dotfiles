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

# hn [label]: a new workspace in the default session, rooted at $PWD and labeled with its name.
# Without --cwd, herdr would root it at the focused pane's directory, wherever that is. Starts the
# server first when none is running, and attaches when run outside herdr.
hn() {
    local label="${1:-$(basename "$PWD")}"
    local i

    if ! herdr workspace list >/dev/null 2>&1; then
        # HERDR_STARTUP_CWD is what herdr's own client passes a server it spawns; it roots the
        # server's first workspace when nothing is restored.
        (cd "$_herdr_home" && HERDR_STARTUP_CWD="$_herdr_home" nohup herdr server >/dev/null 2>&1 &)
        for i in 1 2 3 4 5 6 7 8 9 10; do
            herdr workspace list >/dev/null 2>&1 && break
            sleep 0.5
        done
    fi

    herdr workspace create --cwd "$PWD" --label "$label" --focus >/dev/null || return
    [ -n "${HERDR_ENV:-}" ] || h
}
