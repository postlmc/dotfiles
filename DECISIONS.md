# Decisions

Append-only log of cross-instance negotiated decisions — the kind of thing that spans multiple commits and a Remote Control
exchange neither `git log` nor a single commit message reconstructs on its own. One or two lines per entry, plus the commit
hash(es) to read the real story. Not for routine single-commit work; that's what commit messages already cover, and duplicating
their rationale here would just drift from the commits it describes.

- 2026-09-20: 1Password SSH agent preferred in ssh-agent.sh; macOS doesn't source the file at all (mklinks.sh gate) but the check
  covers both OS paths defensively anyway. 7a02166, b332c5d.
- 2026-09-20: nushell/opencode/ruff/scrub/stress-ng moved from ad-hoc Homebrew to devbox global (pkg-audit). 9be7506.
- 2026-09-20: Fira Code Nerd Font delivery scoped to Linux-only after a live test broke macOS rendering. Devbox delivers it
  cleanly and fontconfig picks it up fine on Linux, but on macOS the devbox-built font didn't register even as a plain
  non-symlinked file with completely independent bytes (a fresh Homebrew cask reinstall worked immediately, confirmed by
  sha256 mismatch against the devbox build) — root cause undetermined. macOS keeps the Brewfile.tmpl cask. 9306e0f, 30246b2.
