#!/bin/bash

command -v ssh-agent >/dev/null 2>&1 || return

# Prefer 1Password's SSH agent when it's running — same key custody as macOS, no local
# passphrase to manage or forget. Takes priority over an inherited/systemd agent socket.
# The socket path is 1Password's own convention, not this repo's, and differs by OS. Only
# Linux hosts source this file at all (see enabled/mklinks.sh: macOS gets 1Password's agent
# via `IdentityAgent` in ~/.ssh/config instead) — both paths are checked anyway so this stays
# correct if that gating ever changes.
for OP_SSH_SOCK in \
    "${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" \
    "${HOME}/.1password/agent.sock"
do
    if [ -S "${OP_SSH_SOCK}" ]; then
        export SSH_AUTH_SOCK="${OP_SSH_SOCK}"
        return
    fi
done
unset OP_SSH_SOCK

# An agent is already available (e.g. forwarded) — don't spawn another or clobber its socket
[ -n "${SSH_AUTH_SOCK:-}" ] && [ -S "${SSH_AUTH_SOCK}" ] && return

# (Adapted from: http://mah.everybody.org/docs/ssh)
SSH_ENV="${HOME}/.ssh/environment"

start_agent() {
    #  echo "Starting SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' >"${SSH_ENV}"
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" >/dev/null
    /usr/bin/ssh-add
}

# The saved PID must exist and actually be ssh-agent — a bare pgrep/ps match on an empty or
# recycled PID could hit an unrelated (or another user's) process
agent_running() {
    [ -n "${SSH_AGENT_PID:-}" ] && \
        ps -p "${SSH_AGENT_PID}" -o comm= 2>/dev/null | grep -q 'ssh-agent$'
}

# Now run it if needed
if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" >/dev/null
    agent_running || start_agent
else
    start_agent
fi
