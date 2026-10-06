#!/bin/bash

# Google Cloud SDK
command -v gcloud >/dev/null 2>&1 || return

alias gcloud-up='gcloud components update --quiet'

# The include files live in the SDK root. Resolving it through the gcloud symlink finds any install
# location (Homebrew on Apple Silicon or Intel, a user install); Debian/Ubuntu packages keep the
# include files under /usr/share instead.
_gcloud_sh=bash
[[ -n "${ZSH_VERSION}" ]] && _gcloud_sh=zsh
_gcloud_root="$(dirname "$(dirname "$(readlink -f "$(command -v gcloud)")")")"
[[ -f "${_gcloud_root}/path.${_gcloud_sh}.inc" ]] || _gcloud_root=/usr/share/google-cloud-sdk

[[ -f "${_gcloud_root}/path.${_gcloud_sh}.inc" ]] && . "${_gcloud_root}/path.${_gcloud_sh}.inc"
# Completions need compinit/bashcompinit, which agent shells skip
[[ -z "${ACTIVE_AGENT}" && -f "${_gcloud_root}/completion.${_gcloud_sh}.inc" ]] &&
    . "${_gcloud_root}/completion.${_gcloud_sh}.inc"

unset _gcloud_sh _gcloud_root
