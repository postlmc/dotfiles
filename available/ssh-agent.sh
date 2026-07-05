#!/bin/bash

command -v ssh-agent >/dev/null 2>&1 || return

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
