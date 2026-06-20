#!/bin/bash

# On macOS, the Tailscale CLI lives inside the app bundle and isn't in PATH unless installed separately.
if ! command -v tailscale >/dev/null 2>&1; then
    [[ -f "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]] && \
        alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
fi
