# New and Improved Dotfiles

## The Problem: Config Files Have Sprawled Out

Remember simpler times when we just used `~/.bashrc`? Tools can't seem to consistently get onboard with `$XDG_whatever`, so now in
addition to `~/.whatever`, everything needs its own directory tree:

- `~/.config/<app>/`: Because why have one config file when you can have 20+?
- `~/.local/share/<app>/`: For "data" that's definitely not "config."
- `~/.cache/<app>/`: A graveyard for files that will be deleted... eventually.
- `~/.local/state/<app>/`: For state that's somehow different from data *and* config.

Simply symlinking a few files from a `~/.dotfiles` directory won't cut it anymore. If I'm going to embrace the chaos, I might as
well do it with style, which means adding things like templates, logic, and proper secrets management.

This is where [Chezmoi][czm] enters the chat. It's not the first dotfile manager I've tried, and it probably won't be the last.
*Cloners beware*.

So, what's Chezmoi got that my [old pile of shell scripts][dotfiles-OLD] doesn't?

- **It Manages More Than Just Files**: It handles files, directories, symlinks, and still runs scripts for those extra setup tasks
  that I just can't escape.
- **Real Templating**: I love me some `awk` and a good shell script hack here and there, but it's time to move past all that.
  Chezmoi uses Go's template syntax to manage variations between machines (e.g., home vs. work, macOS vs. Linux).
- **Secrets Management**: Integrates with actual password managers (1Password, Bitwarden, etc.) and encryption tools.
- **Declarative & Idempotent**: Define the target state, and let the tool `chezmoi` make it happen **once**.
- **No Dependencies**: Single, statically-linked binaries are the best. A true lifesaver on a new machine.
- **Transparent**: Most operations just wrap `git`, so it behaves just as I expect it to (so far).

## Quick Start

1. **Install it**: See [the official docs][czm-install]. The simplest way is usually with a package manager.

```bash
# On macOS or Linux
brew install chezmoi
```

1. **Initialize this repo**:

```bash
# Replace <your-github-username> with your actual username
chezmoi init --apply https://github.com/<your-github-username>/dotfiles.git
```

1. **Use it**:

```bash
chezmoi apply    # Apply changes to bring your dotfiles to the target state
chezmoi diff     # See what would change
chezmoi edit     # Edit a file in your source directory
```

## Machine-Specific Config

`chezmoi init` generates `~/.config/chezmoi/chezmoi.toml` from `.chezmoi.toml.tmpl`, prompting for the flags that genuinely vary
by machine (AWS tooling, personal vs. work, SDR hardware) and filling in the static data groups (`development`, `cloud`,
`machine`, `tools`) that templates read via `dig`. To change a machine's profile, edit that file and run `chezmoi apply`.

Identity does not live there: git user/email comes from the per-host include at `~/.config/local/git/<short-hostname>`, and
host-specific shell config is sourced from `~/.config/local/shell/<short-hostname>`. Files under `~/.config/local/` are
host-local; the per-host variants checked into the source tree are age-encrypted and only deploy when the machine has the key.

Host-local files that need version control but cannot live in this public repo (work configs, host-specific agent files in
`~/.claude` and friends) belong to a second, private chezmoi instance. This repo delivers its config
(`~/.config/chezmoi.local/chezmoi.toml`, reusing the same age key when present) and the `cml` wrapper in
`available/chezmoi-local.sh`. On a new host, enable the module and run `cml-init`: it creates `~/.local/share/chezmoi.local` as
the source repo and seeds a `run_after_` guard that fails any `cml apply` where both instances claim the same path. Point that
repo at whatever private remote suits the host and track files with `cml add <path>`.

## Repository Layout

This repository uses `.chezmoiroot` to relocate the source directory structure. The actual dotfiles are stored in `home/`, while
repository-level files (like this README) live at the root. This keeps the source tree clean and organized and allows for...

### Modular Shell Configuration

The `available` and `enabled` directories provide a modular approach to shell configuration, similar to how Apache and Nginx manage
their config:

- **`available`**: Contains all available shell configuration modules (aliases, functions, environment variables, completions)
- **`enabled`**: Symlinks to configs from `available` that should be sourced, prefixed with numbers (e.g., `10-git.sh`,
  `20-docker.sh`) to control load order

To enable a config module:

```bash
cd ~/.local/share/chezmoi/enabled  # Or $XDG_DATA_HOME/chezmoi/enabled
ln -s ../available/git.sh 10-git.sh
```

The shell configuration (`dot_zshrc`) automatically sources all files matching `enabled/??-*` during shell initialization. This
pattern allows you to:

- Enable only the tools you use on each machine
- Control load order through number prefixes
- Share a common set of configs across machines without duplication
- Keep your main shell config clean and focused

### Bash vs Zsh: Agent-Aware Configuration

Both bash and zsh now share a similar structure optimized for both interactive use and LLM agent contexts:

- **Shared features**: Both shells source all `enabled/??-*` modules, set up PATH (including GNU utilities on macOS), and handle
  Homebrew integration consistently
- **Agent detection**: When `ACTIVE_AGENT` is set (by GitHub Copilot, Cursor, or similar tools), both shells skip expensive
  interactive features:
    - No completions (bash-completion, kubectl, kubelogin, etc.)
    - No plugins (zsh-autosuggestions, zsh-syntax-highlighting, fzf)
    - No history (`HISTFILE=/dev/null`, `HISTSIZE=0`)
    - No prompts (Starship)
    - No vi mode
- **Interactive features**: When `ACTIVE_AGENT` is not set, both shells load their full configurations with completions, plugins,
  history (1.2M entries), and Starship prompt

This approach gives you fast, minimal shells for LLM agents (50-100ms startup) while maintaining full-featured interactive shells
with all the conveniences you expect. The agent optimization is automatic—no manual switching required.

## Operational Notes

### PATH in Agent Tool Shells

The shell that runs an agent's tool calls (Claude Code's Bash tool spawns `zsh -c`) is a **non-interactive login** zsh. It reads
`~/.zshenv` (and `/etc/zprofile`, which runs `path_helper`), but **not `~/.zshrc`**. So the devbox and Homebrew `shellenv` evals
near the top of `dot_zshrc` never run for a tool shell. What a tool shell actually gets is the PATH it **inherited** from the CC
process (captured from whatever interactive shell launched `claude`, which did run `.zshrc`) plus the user-bin prepend in
`dot_zshenv`.

That inheritance is why `dot_zshenv` prepends `~/.local/bin` and `~/bin`: a devbox project entered via direnv recomputes PATH and
silently drops earlier prepends, so tool shells there lost `~/.local/bin` until `.zshenv` started restoring it unconditionally.
`dot_zshrc` still re-prepends the same dirs so they stay ahead of `path_helper`/devbox/brew reshuffles in interactive shells;
`prepend_path` dedupes, so the two placements never double up.

devbox global and Homebrew are deliberately **not** ported into `dot_zshenv`. They reach agents by inheritance in every launch
context that matters, and the alternatives are worse: running `devbox global shellenv` costs ~120ms on *every* tool call, and its
PATH contribution is a moving set of virtenv dirs that changes with the global package set, so a hand-copied static path would rot
silently. Coverage by launch context:

| Tool           | Clean launch (from a terminal) | Project launch (direnv/devbox) | Context-less launch (Spotlight, LaunchAgent) |
|----------------|--------------------------------|--------------------------------|----------------------------------------------|
| `~/.local/bin` | inherited                      | restored by `dot_zshenv`       | provided by `dot_zshenv`                     |
| devbox global  | inherited                      | present via project activation | absent                                       |
| Homebrew       | inherited                      | inherited                      | absent                                       |

Only the context-less column misses devbox and brew, and launching agents that way is rare here. If that changes, revisit — but
adding brittle static devbox paths to guard a case you do not hit is speculative complexity worth skipping.

### Managing Devbox Global Packages

`~/.local/share/devbox/global/default/devbox.json` is managed via a chezmoi modify script rather than a regular template. Devbox
reformats this file in its own style whenever it runs, which would cause format drift on every `chezmoi apply`. The modify script
outputs via `jq`, which matches devbox's formatting, so the two stay in sync.

Use the `gbox-*` wrappers in `available/devbox.sh` for all package changes. They update the modify script source first, then
reconcile the live environment (the devbox operation plus `chezmoi apply`) so the source and the live file stay in sync:

```bash
gbox-add ripgrep          # adds ripgrep@latest — @latest is appended automatically
gbox-add kubectl@1.30     # adds a pinned version
gbox-rm ripgrep           # removes, stripping @version automatically
gbox-up                   # updates all packages and re-normalizes devbox.json format
gbox-ls                   # lists currently installed global packages
```

**Conditional packages** (kubernetes tooling, terraform, rust/rustup) are controlled by `~/.config/chezmoi/chezmoi.toml`
data flags and must be added or removed by editing the modify script directly:
`home/dot_local/share/devbox/global/default/modify_devbox.json.tmpl`

**Host-specific packages** that shouldn't appear on every machine belong in the local devbox plugin at
`~/.config/local/devbox`, which is outside chezmoi's management and included via the `include` directive in `devbox.json`.

### Session Resume

`ccr` and `cpr` reconnect to the most recent Claude Code or Copilot CLI conversation for the current directory, starting fresh
when there is none. Neither needs hooks or marker files: each tool already records where its sessions ran. `ccr` probes Claude
Code's per-directory transcript store (`~/.claude/projects/<sanitized-path>/`) and invokes `claude -c` only when history exists,
since `-c` errors in a directory without any. `cpr` asks Copilot's session database (`~/.copilot/session-store.db`) for the
newest session recorded against the directory and hands it to `--resume`. Both degrade gracefully — if either internal storage
layout changes, the probe misses and you get a fresh session instead of an error.

An earlier hook-based approach wrote a `.ccid` marker file at session end; it was retired in favor of the probes once
`claude -c` covered the resume-by-directory case natively. The git history keeps the details.

### Refreshing zsh Completions

The zsh completion system caches its state in `~/.cache/zsh/.zcompdump` and loads that file on every shell start rather than
re-scanning `fpath`. This keeps startup fast but means completions for newly installed tools won't appear until the cache is
cleared.

After installing a new tool, delete the dump file and it will be rebuilt on the next shell start:

```bash
rm ~/.cache/zsh/.zcompdump
```

---

*Until something better comes along...* <span title="@worthyl expects this to happen sooner rather than later">☠️</span>

[czm]: https://www.chezmoi.io/
[dotfiles-OLD]: https://github.com/PostlMC/dotfiles.OLD
[czm-install]: https://www.chezmoi.io/install/
