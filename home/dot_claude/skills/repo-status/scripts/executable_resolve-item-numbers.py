#!/usr/bin/env python3
"""Resolve stable, monotonically-increasing numbers for repo-status's work items.

Reads stable keys, one per line, from stdin (in the order they should be numbered --
that's the caller's job, this script never reorders anything). Assigns each a number
via a state file at .git/repo-status-state.json: a key seen before keeps its number, a
new key gets the next unused one. Numbers are never reused, so a retired item's number
stays retired rather than being handed to whatever shows up next.

Numbers are per-repo-checkout, not synced anywhere -- a second clone (another host, a
`git worktree`) gets its own independent counter, by design: nothing here writes
anywhere that would sync between them, and there was no requirement that it should.

A key not present in this run's input is dropped from state -- state reflects only
currently-existing items, which is what keeps it from going stale. This also means an
item's key needs to stay the same across runs for its number to stay stable; see
SKILL.md for the key convention (issue reference when there is one, a normalized
snippet of the item's own text otherwise).

Prints "<key>\t<number>" to stdout, one line per input key, in input order. A key
repeated in the same input reuses whatever number was assigned to its first
occurrence in this same run, rather than being treated as a second new item.
"""
import json
import os
import subprocess
import sys
from pathlib import Path


def git_dir() -> Path:
    out = subprocess.run(
        ["git", "rev-parse", "--git-dir"], capture_output=True, text=True, check=True
    )
    return Path(out.stdout.strip())


def load_state(path: Path) -> dict:
    if not path.exists():
        return {"next_number": 1, "items": {}}
    try:
        data = json.loads(path.read_text())
        if not isinstance(data, dict) or "next_number" not in data or "items" not in data:
            raise ValueError("unexpected state file shape")
        return data
    except (json.JSONDecodeError, ValueError):
        # A torn write or a hand-edit shouldn't wedge every future run on the same
        # corrupt file -- start fresh rather than crash forever.
        return {"next_number": 1, "items": {}}


def main() -> int:
    state_path = git_dir() / "repo-status-state.json"
    state = load_state(state_path)

    keys = [line.rstrip("\n") for line in sys.stdin if line.strip()]

    resolved: dict[str, int] = {}
    for key in keys:
        if key in resolved:
            continue
        if key in state["items"]:
            resolved[key] = state["items"][key]
        else:
            resolved[key] = state["next_number"]
            state["next_number"] += 1

    state["items"] = resolved

    tmp_path = state_path.with_suffix(".json.tmp")
    tmp_path.write_text(json.dumps(state, indent=2) + "\n")
    os.replace(tmp_path, state_path)  # atomic on POSIX -- no torn-write window

    for key in keys:
        print(f"{key}\t{resolved[key]}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
