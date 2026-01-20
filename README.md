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

For variables that change from one machine to another (like your name, email, or a machine-specific identifier), create a
`~/.config/chezmoi/chezmoi.toml` file:

```toml
[data]
name = "Your Name"
email = "your.email@example.com"
machine = "work-laptop"
```

## Repository Layout

This repository uses `.chezmoiroot` to relocate the source directory structure. The actual dotfiles are stored in `home/`, while
repository-level files (like this README) live at the root. This keeps the source tree clean and organized and allows for...

### Modular Shell Configuration

The `available` and `enabled` directories provide a modular approach to shell configuration, similar to how Apache and Nginx
manage their config:

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

---

*Until something better comes along...* <span title="@worthyl expects this to happen sooner rather than later">☠️</span>

[czm]: https://www.chezmoi.io/
[dotfiles-OLD]: https://github.com/PostlMC/dotfiles.OLD
[czm-install]: https://www.chezmoi.io/install/
