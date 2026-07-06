# Repository Review Findings

Full review of the chezmoi source repository at commit `c94e9dd` (2026-07-05), covering every shell module, template, script,
hook, and document. Scope: bugs, security issues, documentation mismatches (including comments), and inconsistencies. Rule parity
across Claude Code, Cursor, and Copilot was verified by checksum after stripping frontmatter and is perfect. Findings are ordered
by severity within each section. This review doubled as my first test of Anthropic's Fable 5 model.

## Bugs

1. **`home/dot_zshrc:94` sets `export GIT_PAGER=ca`.** Typo for `cat`. In agent shells, git tries to pipe output through a
   nonexistent `ca` command. The bashrc equivalent (line 115) is correct.  
   **Resolved** in commit `fe317d6`.

2. **`available/docker.sh`: `docker-clean` is a single broken command.** The three `docker rm` / `docker rmi` /
   `docker volume rm` invocations are joined only by line continuations, with no `;` or `&&`. It expands to one `docker rm` call
   with `docker`, `rmi`, and the rest passed as container names. The alias has never worked as written, and its comment warns
   that it "deletes volumes," which it cannot.  
   **Resolved** in commit `7ee92e3`: rewritten as a function running `container`/`image`/`volume prune -f` against whichever of
   docker or podman resolves to an executable, since `command -v docker` returns alias text under the module's `docker=podman`
   alias.

3. **`home/dot_gitconfig.tmpl`: `[diffs]` section should be `[diff]`.** The `renames = true` setting is silently ignored.  
   **Resolved** in commit `a023bef`.

4. **`home/run_onchange_configure-vscode-copilot-terminal.sh.tmpl`: sed-based JSON editing corrupts `settings.json`.** Two
   problems: the insert branch replaces the final `}` without adding a comma after the previous property, producing invalid JSON
   for any non-empty settings file; and the replace branch's range `/"$PROFILE_KEY":/,/\}/` ends at the first line containing
   `}`, which is the nested `env` closing brace, so it cuts the block mid-structure and leaves a stray `},`. The file
   `home/dot_claude/modify_settings.json` already shows the right pattern (a jq merge); this script should do the same.  
   **Resolved** in commit `2a00ac6`: rewritten as a jq merge that bails cleanly on JSONC rather than corrupting the file.
   Follow-up in `f835e02`: the live settings.json is JSONC, so the script exits quietly when the key is already present.

5. **`available/kubernetes.sh`: zsh-only syntax reachable from bash.** The completion block is guarded by
   `[[ -n "$ZSH_CACHE_DIR" ]]`, but `dot_zshrc:30` exports `ZSH_CACHE_DIR`. A bash shell started from an interactive zsh inherits
   it, so bash reaches `(( $+commands[kubectl] ))` (an arithmetic error in bash) and sources `kubectl.zsh` completions into bash.
   The same latent issue exists in `op.sh`, which would source zsh completions into bash. Guard on `$ZSH_VERSION` instead, or
   stop exporting `ZSH_CACHE_DIR`.  
   **Resolved** in commits `0b63bc1` and `507caa6`: both — `ZSH_CACHE_DIR` is no longer exported, and both modules guard their
   completion blocks on `$ZSH_VERSION`.

6. **`available/eza.sh` undoes the TTY gating from commit `7adf3fd`.** `core.sh` (loaded as `02-core`) aliases `ll` and `la` to
   eza only when `[ -t 1 ]`; `eza.sh` (loaded later as `09-eza`) re-aliases them to eza unconditionally. Non-TTY shells get eza
   for `ll` and `la` after all.  
   **Resolved** in commit `ab69e5c`: `eza.sh` owns all eza aliases, gated on a TTY and an unset `ACTIVE_AGENT`; `core.sh` keeps
   only the plain-ls baseline.

7. **`available/misc-darwin.sh` clobbers `tailscale.sh`.** The `28-tailscale` module only aliases the app-bundle binary when
   `tailscale` is not already in PATH; `29-misc-darwin` then sets `alias tailscale=/Applications/...` unconditionally, overriding
   a PATH-installed CLI and breaking entirely if the app bundle is absent. Delete the misc-darwin line.  
   **Resolved** in commit `c77e6fa`.

8. **`home/dot_bash_logout` wipes history that bashrc works hard to keep.** `> ~/.bash_history; history -c` truncates on every
   login-shell exit, while bashrc configures 1.2M-entry appending history. One of these is wrong; they cannot both be intended.  
   **Resolved** in commit `530e2a5`: the wipe is removed; the deliberate 1.2M-entry history configuration wins. The
   `clear_console` privacy bit stays.

9. **`available/git.sh`: `getgit()` never reads its argument.** The body uses `${D}`, not `$1`. Recursion only works because `D`
   leaks into the subshell from the caller's loop; a top-level `getgit` call runs `cd` with `D` unset, silently landing in
   `$HOME` and scanning the wrong tree. The `find` fallback also uses GNU-only `-printf`, which fails on stock macOS find.  
   **Resolved** in commit `f34283b`: `getgit` takes `"${1:-.}"` and recurses on relative paths; the `find` fallback uses
   portable `! -name` exclusions instead of `-regex`/`-printf`.

10. **`available/homebrew.sh`: `brew86-up` references `brew86`, which is defined nowhere in the repo.** If it lives in a
    host-local file, fine; otherwise it is a dead alias from the Intel/Rosetta era.  
    **Resolved** in commit `19e9503`: removed. A host that still needs a Rosetta brew wrapper can define both in its
    `~/.config/local/shell/<host>` file.

## Security

1. **`available/claude.sh`: `c()` evals arbitrary file content, and the README's mitigation does not exist.** The function runs
   `eval` on the contents of `.ccid`. The README (line 152) claims ".ccid is gitignored globally so it never ends up committed,"
   but `home/dot_gitignore` has no `.ccid` entry (verified in both the source and the live `~/.gitignore`; only this repo's own
   `.gitignore` has one). Worse, a global gitignore would not protect you anyway: any repo you clone can ship a committed
   `.ccid`, and running `c` inside it executes whatever the file contains. Fix: have the SessionEnd hook write only the session
   ID, then have `c()` validate that it looks like a UUID and exec `claude --resume "$id"` with no eval. Add `.ccid` to the
   global gitignore regardless.  
   **Resolved** in commit `469b98c`: `.ccid` stores only the session ID, `c()` validates it as a UUID before resuming, and the
   global gitignore entry exists.

2. **`available/openssl.sh`: `aesenc` uses OpenSSL's legacy key derivation.** Without `-pbkdf2 -iter`, it uses the deprecated
   EVP_BytesToKey with one MD5 round. Add `-pbkdf2 -iter 600000`.  
   **Resolved** in commit `1526914`: `aesenc` uses `-pbkdf2 -iter 600000`, with a comment giving the matching decrypt invocation.

3. **`available/ssh.sh`: `ssh-alias` shadows commands.** Every `Host` shortname in `~/.ssh/config` becomes an alias; a host named
   `test`, `time`, or `stat` silently shadows the real command. Low risk since you control the config, but worth knowing.
   Related: the liveness check in `ssh-agent.sh` (`ps -ef | grep ${SSH_AGENT_PID}`) breaks if `SSH_AGENT_PID` is empty and can
   match other users' processes; a `kill -0`-style check is more robust.  
   **Resolved** in commits `97ad1a2` and `bdb0ed4`: `ssh-alias` skips names that already resolve to a command, alias, or
   function; `ssh-agent.sh` checks the exact PID's command name via `ps -p ... -o comm=` and treats an empty `SSH_AGENT_PID` as
   not running. `22d5fee` additionally returns before spawning when a live agent socket is already present.

## Documentation Mismatches

1. **README "Machine-Specific Config" section is stale.** It tells the reader to hand-create `~/.config/chezmoi/chezmoi.toml`
   with `name`, `email`, and `machine` keys. Nothing in the repo consumes those keys (gitconfig identity comes from the
   `~/.config/local/git/<host>` include), and `.chezmoi.toml.tmpl` generates that exact file with completely different data
   (`development`, `cloud`, `machine.personal`, `tools`). Running `chezmoi init` would clobber the hand-written version.  
   **Resolved** in commit `db6ac98`: the section is rewritten to describe the generated file, the prompt flags, and where
   identity actually lives (the per-host `~/.config/local/` includes).

2. **README says python/uv is a conditional devbox package.** The Operational Notes list "kubernetes tooling, terraform,
   python/uv, rust/rustup" as flag-controlled, but since commit `80e1472` `uv` is baseline and the modify script has no python
   conditional at all. Relatedly, the `development.python` and `development.golang` flags in `.chezmoi.toml.tmpl` are consumed by
   nothing; both are dead config.  
   **Resolved** in commit `db6ac98`: the README no longer lists python/uv as conditional. The two flags stay by choice, now
   commented as reserved toggles for future conditionals.

3. **AGENTS.md load-order table stops at 60-79, but `mklinks.sh` assigns `80-claude`.** The 80+ range is undocumented.  
   **Resolved** in commit `e173653`: `80-89: AI tools` added to the load-order list.

4. **README describes the gbox wrappers as "update the modify script source first, then apply chezmoi and install."** `gbox-rm`
   runs `devbox global rm` before `chezmoi apply`, the opposite order from `gbox-add` and from the doc. Harmless in practice, but
   one of them does not match the description.  
   **Resolved** in commit `db6ac98`: the README wording now says the wrappers reconcile the live environment after updating the
   source, which covers both orders.

5. **AGENTS.md names only `run_once_before_` as the script naming convention.** The repo actually uses `run_once_` and
   `run_onchange_after_`. Trivial, but this is the file agents read to learn the conventions.  
   **Resolved** in commit `e173653`: the naming bullet now covers `run_once_`, `run_onchange_`, and the optional
   `before_`/`after_` ordering.

## Inconsistencies and Cruft

1. **The repo-root `.envrc` does nothing.** It contains only two comment lines, the same two lines that appear verbatim at the
   bottom of `.gitignore`. It looks like a paste went to the wrong file; either it needs a real directive (for example,
   `PATH_add .bin`) or it should go.  
   **Resolved** in commit `77546a7`: it now does `PATH_add .bin` (run `direnv allow` once to activate).

2. **Duplicate curl-format files.** `home/dot_curl-format` and `home/dot_config/curl/curl-format` are byte-identical, and
   `core.sh`'s `curl-trace` reads only the XDG one. `~/.curl-format` is a drift-prone leftover.  
   **Resolved** in commit `19e9503`: `chezmoi destroy` removed `home/dot_curl-format` and the deployed `~/.curl-format`; the
   XDG copy is the single source.

3. **`home/dot_gitignore` lists `*.gz`, `*.tar`, and `*.zip` twice** in the Archives section. `dot_gitconfig.tmpl` also still
   carries `git-media` and `hawser` filter sections, the pre-LFS ancestors of the LFS block right below them, dead for about a
   decade.  
   **Resolved** in commit `19e9503`: duplicates deduped and both legacy filter sections removed; only the LFS filter remains.

4. **`available/golang.sh` hardcodes `GOROOT=$HOME/opt/go`.** With go from devbox or Homebrew this points at the wrong (likely
   nonexistent) tree and breaks the toolchain; modern Go wants GOROOT unset. Also, `mklinks.sh:3` sets `HOST` and never uses it,
   and the `gitb` alias filters out `master` but not `main`.  
   **Resolved** in commits `a93ac05` (GOROOT), `19e9503` (HOST), and `f34283b` (`gitb` excludes `main` as well).

5. **`available/kubernetes.sh`: `export KUBECONFIG=$(kcfg)` leaves a trailing `:`** (from `tr '\n' ':'`), which kubectl treats as
   an extra empty entry meaning the default location. It also runs `kcfg`, a directory scan, in every shell startup, including
   agent shells.  
   **Resolved** in commit `507caa6`: the trailing colon is stripped and `KUBECONFIG` is only exported when `kcfg` produces
   output, so an empty value can no longer mask `~/.kube/config`. The startup scan stays — agent shells legitimately need
   `KUBECONFIG` and the cost is one directory listing.

6. **`core.sh` assumes a GNU userland for its fallbacks.** The non-eza branch uses `ls --color=auto`, and the
   `rm`/`chown`/`chmod` `--preserve-root` flags are GNU-only. That is fine while devbox coreutils lead PATH, but the same file's
   `lso` fallback uses BSD `ls -alG`. If devbox is ever absent on macOS, the "fallback" aliases are the ones that break.  
   **Accepted**: devbox global coreutils leading PATH is the deliberate baseline on every machine, so the GNU assumption is by
   design. Not worth per-flag feature detection for a bootstrap-window edge case.

7. **`[core] filemode = false` is set globally in gitconfig.** That disables exec-bit tracking in every repo on every machine.
   It is sensible for WSL or NTFS mounts, surprising everywhere else. Worth confirming it is still intentional.  
   **Resolved** in commit `a2bcbc4`: removed from the global config so exec-bit tracking follows git's default. A host that
   needs it (WSL/NTFS) can set it in its `~/.config/local/git/<host>` include.

8. **Cross-tool parity gap.** Claude Code and Copilot both have a `git-commit` command/prompt; Cursor has no equivalent skill.
   The AGENTS.md three-tool rule covers rules and instructions, so this may be deliberate, but it is the one asymmetry in an
   otherwise perfectly synced setup. The check-mark character echoed by the VS Code terminal script also violates the repo's own
   no-emoji rule.  
   **Resolved** in commit `ff154dc` — the gap was deliberate after all: Cursor reads `~/.claude/commands/` natively (a trial
   Cursor skill showed up as a duplicate in the command picker and was removed). `docs/AI-Tools.md` now documents the native
   command pickup. The check-mark character was already dropped in the `2a00ac6` rewrite.

## Highest-Value Fixes

The fixes with the best effort-to-payoff ratio: the `.ccid` eval hardening plus the missing global gitignore entry (Security 1),
the `GIT_PAGER` typo (Bugs 1), the `[diffs]` to `[diff]` rename (Bugs 3), the VS Code sed script rewrite in jq (Bugs 4), and the
eza and tailscale alias clobbering (Bugs 6 and 7).

Every finding above is now marked **Resolved** or **Accepted** in place; the per-item notes record what changed and why.
