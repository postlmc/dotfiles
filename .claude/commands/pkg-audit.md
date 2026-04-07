---
name: pkg-audit
description: Audit installed packages across devbox global and Homebrew against the chezmoi source of truth. Identifies untracked installs, misplaced packages, and suggests corrections.
---

# /pkg-audit — Package Bucket Audit

Review what is installed via devbox global and Homebrew against the chezmoi source files. Identify untracked ad-hoc installs and
packages in the wrong bucket, then suggest corrections.

## Bucketing Rules

**devbox global** — default for CLI tools:

- Any CLI tool available in nixpkgs belongs here
- Language runtimes (go, rust/rustup, python/uv, node, ruby, java) are project-specific — never install globally

**Homebrew formula** — stays here when any of these apply:

- Needs `brew services` to run as a daemon (postgresql, mysql, clamav, etc.)
- System or hardware-level integration (qemu, vde, iproute2mac)
- Vendor explicitly recommends Homebrew (Azure CLI, azure-functions-core-tools, dotnet)
- Bootstrap tool that manages other tools (chezmoi itself)
- Not available in nixpkgs — verify with `devbox search <name>` before concluding this

**Homebrew cask** — GUI applications:

- Anything that installs a `.app` bundle, never in devbox

**Not globally tracked** — project-specific only:

- go, rustup/rust, python, node, nvm, fnm, ruby, java and their version managers

## Workflow

### Step 1: Gather current state

Run in parallel:

- `devbox global list`
- `brew list --formula`
- `brew list --cask`
- `chezmoi data` — to know which template conditionals are active on this machine

### Step 2: Read chezmoi source of truth

Read both source files:

- `home/dot_local/share/devbox/global/default/devbox.json.tmpl`
- `home/dot_config/homebrew/Brewfile.tmpl`

Parse which packages are declared. For Brewfile, note which are inside conditional blocks and cross-reference with `chezmoi data` to
determine if those conditionals are active.

### Step 3: Find untracked installs

- devbox packages in `devbox global list` but absent from `devbox.json.tmpl` → untracked devbox install
- Homebrew formulae in `brew list --formula` but absent from `Brewfile.tmpl` → untracked Homebrew install
- Homebrew casks in `brew list --cask` but absent from `Brewfile.tmpl` → untracked cask install

These were installed ad-hoc and need to be either added to the appropriate source file or removed.

### Step 4: Check for misplaced packages

**Homebrew formulae that might belong in devbox:** For each Homebrew formula not in a "stays in Homebrew" category, check `devbox
search <name>`. If found in nixpkgs, flag as a devbox candidate.

**devbox packages that might belong in Homebrew:** Check for language runtimes — flag as should-be-project-specific. Check for
anything with a vendor Homebrew recommendation.

**Stays-in-Homebrew categories** (do not flag as misplaced):

- `brew services` daemons: postgresql, postgresql@*, mysql, clamav, redis, nginx
- System-level: qemu, vde, iproute2mac
- Vendor-mandated: azure-cli, azcopy, aztfexport, azure-functions-core-tools@*, dotnet
- Fonts: font-* casks
- Bootstrap: chezmoi

### Step 5: Report findings

Three sections:

**Untracked installs** — table: Package | Current bucket | Recommended action

**Misplaced packages** — table: Package | Current bucket | Should be in | Notes

**Clean** — confirm if a category has no issues

### Step 6: Offer to apply fixes

For each confirmed fix:

- Adding to devbox: edit `home/dot_local/share/devbox/global/default/devbox.json.tmpl` — append to the `$pkgs := list` block, or add
  `{{- $pkgs = append $pkgs "name@latest" -}}` inside the appropriate conditional
- Adding to Brewfile: edit `home/dot_config/homebrew/Brewfile.tmpl` — add `brew "name"` or `cask "name"` in the appropriate section
- Removing from a source file: delete the relevant line

After edits, remind the user to run `chezmoi apply` followed by `gbox-up` or `brew bundle --file=~/.config/homebrew/Brewfile` as
needed.

Never edit live files. All edits go to the chezmoi source in this repo.

## Notes

- `devbox.json.tmpl`: `append` takes exactly two args — `append $list "single-item"`. Use `@latest` for all packages unless pinned.
- `Brewfile.tmpl`: the `azure/functions` tap must be declared before `azure/functions/azure-functions-core-tools@4`.
- A package missing from `devbox global list` may just be behind a false conditional — check `chezmoi data` before flagging it as
  missing.
