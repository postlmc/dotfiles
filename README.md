# Dotfiles Management with Chezmoi

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

So, what's `chezmoi` got that my [old pile of shell scripts][dotfiles] doesn't?

- **It Manages More Than Just Files**: It handles files, directories, symlinks, and still runs scripts for those extra setup tasks
  that I just can't escape.
- **Real Templating**: I love me some `awk` and a good shell script hack here and there, but it's time to move past all that.
  `chezmoi` uses Go's template syntax to manage variations between machines (e.g., home vs. work, macOS vs. Linux).
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

---

*Until something better comes along.*

[czm]: https://www.chezmoi.io/
[dotfiles]: https://github.com/PostlMC/dotfiles
[czm-install]: https://www.chezmoi.io/install/
