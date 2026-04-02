#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 1 && -f "$1" ]] || { echo "usage: ${0##*/} <existing-cloud-init-file>" >&2; exit 1; }

CONFIG_FILE="$(realpath "$1")"
DOCKERFILE="${XDG_DATA_HOME:-$HOME/.local/share}/docker/cloud-init.Dockerfile"

[[ -f "$DOCKERFILE" ]] || { echo "error: missing $DOCKERFILE" >&2; exit 1; }

RUNTIME=$(command -v podman || command -v /opt/podman/bin/podman || command -v docker || true)
[[ -n "$RUNTIME" ]] || { echo "error: podman or docker required" >&2; exit 1; }

"$RUNTIME" build -q -t cloud-init-validator:local -f "$DOCKERFILE" "${DOCKERFILE%/*}" >/dev/null

exec "$RUNTIME" run --rm -v "${CONFIG_FILE}:/config.yaml:ro" cloud-init-validator:local /config.yaml
