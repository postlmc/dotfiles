#!/usr/bin/env bash

# Wrapper script for Copilot terminal with Podman container and workspace mounting
exec /opt/podman/bin/podman run \
    --rm \
    -ti \
    -v "$(pwd):$(pwd)" \
    -w "$(pwd)" \
    debian:trixie-slim \
    /bin/bash
