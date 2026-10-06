---
name: pkg-audit
description: Audit installed packages across devbox global and Homebrew against the chezmoi source of truth. Identifies untracked installs, misplaced packages, and suggests corrections.
---

# /pkg-audit — Package Bucket Audit

Review what is installed via devbox global and Homebrew against the chezmoi source files. Identify
untracked ad-hoc installs and packages in the wrong bucket, then suggest corrections.

## Bucketing Rules

**devbox global** — default for CLI tools:

- Any CLI tool available in nixpkgs belongs here
- Language runtimes are project-specific, with two deliberate baseline exceptions that this repo's
  own tooling needs on every host:
    - `nodejs` — provides `npx`, which runs rulesync and `npx skills add`
    - `uv` — runs `uv run` shebang scripts such as `align-tables`
- `rustup` is global only behind the `development.rust` conditional

**Homebrew formula** — stays here when any of these apply (the full list is in `AGENTS.md`):

- Needs `brew services` to run as a daemon (postgresql, mysql, clamav, etc.)
- System or hardware-level integration (qemu, vde, iproute2mac)
- No cached binary on `cache.nixos.org`, forcing an expensive from-source build
  (azure-functions-core-tools)
- Vendor ships it as supporting tooling for another Homebrew package (kubelogin with the Azure CLI),
  or explicitly recommends Homebrew (Azure CLI, dotnet)
- Bootstrap tool that manages other tools (chezmoi itself)
- Not available in nixpkgs — verify with `devbox search <name>` before concluding this

**Homebrew cask** — GUI applications:

- Anything that installs a `.app` bundle, never in devbox

**Not globally tracked** — project-specific only:

- go, python interpreters, ruby, java, and version managers (nvm, fnm, pyenv, rbenv)

## Workflow

### Step 1: Gather current state

Run in parallel:

- `devbox global list`
- `brew list --formula`
- `brew list --cask`
- `chezmoi data` — to know which template conditionals are active on this machine

### Step 2: Read chezmoi source of truth

Read both source files:

- `home/dot_local/share/devbox/global/default/modify_devbox.json.tmpl`
- `home/dot_config/homebrew/Brewfile.tmpl`

Parse which packages are declared. In both files, note which are inside conditional blocks and
cross-reference with `chezmoi data` to determine if those conditionals are active.

### Step 3: Find untracked installs

- devbox packages in `devbox global list` but absent from `modify_devbox.json.tmpl` → untracked
  devbox install
- Homebrew formulae in `brew list --formula` but absent from `Brewfile.tmpl` → untracked Homebrew
  install
- Homebrew casks in `brew list --cask` but absent from `Brewfile.tmpl` → untracked cask install

An untracked install is not automatically a mistake. The source files are the shared baseline every
host gets; a package meant for one host only is installed directly (`devbox global add`,
`brew install`) and stays out of them on purpose. The devbox modify script merges, so host-local
devbox installs survive `chezmoi apply`. Ask the user which untracked installs are intentionally
host-local before recommending they be added or removed.

Also check that no package is declared in both source files. `chezmoi apply` installs both copies
and Homebrew's `bin` shadows devbox's. `bin/brew-devbox-overlap` lists Homebrew formulae whose
binaries devbox global already provides.

### Step 4: Check for misplaced packages

**Homebrew formulae that might belong in devbox:** For each Homebrew formula not in a "stays in
Homebrew" category, check `devbox search <name>`. If found in nixpkgs, flag as a devbox candidate.

**devbox packages that might belong in Homebrew:** Check for language runtimes other than the
`nodejs` and `uv` baseline exceptions — flag as should-be-project-specific. Check for anything with
a vendor Homebrew recommendation.

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

- Shared baseline, unconditional: use the wrappers, which edit the template, apply, install, and
  roll the template back if the install fails — `gbox-add`/`gbox-rm` for devbox,
  `brew-add`/`brew-rm` (`--cask` for casks) for Homebrew
- Shared baseline, behind a conditional: edit
  `home/dot_local/share/devbox/global/default/modify_devbox.json.tmpl` (add
  `{{- $pkgs = append $pkgs "name@latest" -}}` inside the conditional) or
  `home/dot_config/homebrew/Brewfile.tmpl` directly
- Removing an undeclared Homebrew install: `brew-prune` lists them, `brew-prune --force` removes
  them all — confirm first that none are intentionally host-local

After direct template edits, remind the user to run `chezmoi apply`; `brew-check` confirms the
Brewfile is satisfied.

Never edit live files. All edits go to the chezmoi source in this repo.

## Notes

- `modify_devbox.json.tmpl`: `append` takes exactly two args — `append $list "single-item"`. Use
  `@latest` for all packages unless pinned.
- `Brewfile.tmpl`: the `azure/functions` tap must be declared before
  `azure/functions/azure-functions-core-tools@4`.
- A package missing from `devbox global list` may just be behind a false conditional — check
  `chezmoi data` before flagging it as missing.
