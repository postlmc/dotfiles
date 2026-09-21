#!/bin/bash

# Symlinks devbox-delivered fonts into the OS's actual font directory. Neither Linux's
# fontconfig nor macOS's font system scan a package manager's profile path on their own, so
# installing a font via devbox alone doesn't make it usable — this is the missing activation
# step. Points at devbox's stable "default" profile symlink, not the underlying nix store path,
# so it keeps working across font package updates without needing to change.
# Skipped entirely for agent shells — font activation is a GUI/interactive-terminal concern.

[ -z "${ACTIVE_AGENT}" ] || return

DEVBOX_FONTS_DIR="${HOME}/.local/share/devbox/global/default/.devbox/nix/profile/default/share/fonts"
[ -d "${DEVBOX_FONTS_DIR}" ] || return

if [[ "$OSTYPE" == darwin* ]]; then
    FONT_TARGET_DIR="${HOME}/Library/Fonts"
elif [[ "$OSTYPE" == linux* ]]; then
    FONT_TARGET_DIR="${HOME}/.local/share/fonts"
else
    return
fi

mkdir -p "${FONT_TARGET_DIR}"

_devbox_fonts_linked=0
while IFS= read -r -d '' font; do
    link="${FONT_TARGET_DIR}/$(basename "${font}")"
    # Never clobber a real (non-symlink) file already at this path — something else (a cask,
    # a manual install) owns it, and overwriting it has broken real font rendering before.
    [ -e "${link}" ] && [ ! -L "${link}" ] && continue
    [ -L "${link}" ] && [ "$(readlink "${link}")" = "${font}" ] && continue
    ln -sf "${font}" "${link}"
    _devbox_fonts_linked=1
done < <(find -L "${DEVBOX_FONTS_DIR}" -type f \( -name '*.ttf' -o -name '*.otf' \) -print0 2>/dev/null)

if [ "${_devbox_fonts_linked}" = "1" ] && [[ "$OSTYPE" == linux* ]] && command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "${FONT_TARGET_DIR}" >/dev/null 2>&1
fi
unset _devbox_fonts_linked DEVBOX_FONTS_DIR FONT_TARGET_DIR
true
