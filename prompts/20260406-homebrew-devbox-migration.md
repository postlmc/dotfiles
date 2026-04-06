# Devbox-Primary Migration

Move CLI tools from Homebrew to devbox global, eliminating the GNU utils PATH war and the defensive prepend logic that has to be
kept in sync across multiple files.

**Homebrew stays for:** casks, podman, qemu/vde, postgresql/mysql (brew services), dotnet, powershell, google-cloud-sdk,
iproute2mac, and any hardware-driver stacks (SDR, etc.).

**Aurora caveat:** devbox global changes won't help there until Nix/devbox is re-integrated. The Homebrew shellenv blocks and their
fallbacks can stay in place — they no-op when brew isn't present — so Aurora is unaffected by this migration.

---

## Phase 1 — Add GNU tools to devbox global

This is the root cause of all the PATH complexity. Moving these to devbox makes them first-class in every devbox shell without any
init_hook hacks.

Edit `home/dot_local/share/devbox/global/default/devbox.json`. Add to `packages`:

```json
"coreutils", "findutils", "gnutar", "gnused", "gnugrep", "gnumake", "curl", "openssl"
```

Verify after `devbox global shellenv` that `which sed` resolves to the nix store, not
`/opt/homebrew/opt/gnu-sed/libexec/gnubin/sed`.

---

## Phase 2 — Add CLI tools to devbox global

Add the remaining Brewfile tools to `devbox.json`. The current file is not a chezmoi template — to preserve conditional installation
per machine, rename it to `devbox.json.tmpl` and use the same `{{ if dig ... }}` pattern already used in `Brewfile.tmpl`.

Packages to add (nixpkgs names):

| Brewfile name | nixpkgs/devbox name |
|---------------|---------------------|
| git           | git                 |
| tmux          | tmux                |
| vim           | vim                 |
| fzf           | fzf                 |
| jq            | jq                  |
| yq            | yq-go               |
| age           | age                 |
| starship      | starship            |
| direnv        | direnv              |
| zellij        | zellij              |
| go            | go                  |
| uv            | uv                  |
| rustup        | rustup              |
| kubectl       | kubectl             |
| kubectx       | kubectx             |
| helm          | kubernetes-helm     |
| k9s           | k9s                 |
| terraform     | terraform           |
| azure-cli     | azure-cli           |
| gum           | gum                 |

Skip `python` — uv manages Python versions. Skip `rust` (standalone) — rustup covers it.

Wrap the conditional packages in the template the same way Brewfile.tmpl does:

```gotmpl
{{- if dig "development" "golang" false . }}
"go",
{{- end }}
```

---

## Phase 3 — Gut the Brewfile

Remove from `home/dot_config/homebrew/Brewfile.tmpl` everything moved to devbox:

- The entire `{{- if eq .chezmoi.os "darwin" }}` block (lines 1–11) — GNU utils + curl + openssl
- `git`, `tmux`, `vim`, `fzf`, `jq`, `yq`, `age`, `starship`, `direnv`, `zellij`
- Conditional blocks for: `python`/`uv`, `go`, `rustup`, `kubectl`/`kubectx`/`helm`/`k9s`, `azure-cli`, `terraform`, `gum`

Leave in place: `podman`, `google-cloud-sdk` cask, and anything in the "stays in Homebrew" list above.

---

## Phase 4 — Simplify devbox init_hook

Once Phase 1 is done, the init_hook in `devbox.json` no longer needs to prepend Homebrew paths. Replace the entire `init_hook` array
with a no-op or remove the entries:

```json
"init_hook": []
```

---

## Phase 5 — Remove GNU utils PATH blocks from shell configs

Both files have an identical block. Remove it from both:

**`home/dot_zshrc` lines 36–47:**

```zsh
# GNU utilities PATH setup (darwin only)
if [[ -n "${HOMEBREW_PREFIX}" ]] && [[ "$OSTYPE" == darwin* ]]; then
    for gnu_tool in coreutils findutils gnu-tar gnu-sed grep make; do
        ...
    done
    ...
fi
```

**`home/dot_bashrc` lines 37–48:** same block, remove entirely.

---

## Phase 6 — Fix remaining HOMEBREW_PREFIX references in shell configs

After the tools move to devbox, several hooks that look up tools via `$HOMEBREW_PREFIX` need to become plain `command -v` checks.

### direnv hook

Both `dot_zshrc:23–24` and `dot_bashrc:23–25` use `${HOMEBREW_PREFIX}/bin/direnv`. Change to:

```zsh
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"
```

```bash
command -v direnv &>/dev/null && eval "$(direnv hook bash)"
```

### starship init

Both `dot_zshrc:135–138` and `dot_bashrc:129–132` gate on `${HOMEBREW_PREFIX}/bin/starship`. Change to:

```zsh
command -v starship &>/dev/null && {
    export STARSHIP_CONFIG=${HOME}/.config/starship/starship.toml
    eval "$(starship init zsh)"
}
```

### zsh completions fpath (`dot_zshrc:75`)

```zsh
[[ -n "${HOMEBREW_PREFIX}" ]] && fpath=(${HOMEBREW_PREFIX}/share/zsh/site-functions $fpath)
```

Devbox puts completions in the nix store and wires them through `$FPATH` automatically. Remove this line and verify completions
still work after the migration.

### azure-cli completion (`dot_zshrc:90–94`, `dot_bashrc:87–91`)

The Homebrew path `${HOMEBREW_PREFIX}/etc/bash_completion.d/az` won't exist once azure-cli is in devbox. The devbox/nix azure-cli
package ships its own completion. Check where it lands after install (`find $(devbox global path) -name 'az' -path '*/completion*'`)
and update the source path, or switch to `az --completion` if that's supported.

### bash completion (`dot_bashrc:76–82`)

The `${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh` path won't apply for devbox tools. Devbox injects completion paths
automatically. Test and trim this block after migration.

---

## Phase 7 — Fix EDITOR in available/core.sh

`available/core.sh:122–123` checks `${HOMEBREW_PREFIX}/bin/vim` first. Once vim is in devbox, that path won't exist. The existing
fallback chain (`command -v vim`, `command -v vi`) already handles this correctly — just remove the Homebrew-specific first branch:

```sh
# Before
if [ -n "$HOMEBREW_PREFIX" ] && [ -x "${HOMEBREW_PREFIX}/bin/vim" ]; then
    export EDITOR="${HOMEBREW_PREFIX}/bin/vim"
elif command -v vim &>/dev/null; then

# After
if command -v vim &>/dev/null; then
```

---

## Verification

After each phase, open a new shell and check:

- `which sed`, `which grep`, `which tar` — should resolve to nix store paths, not Homebrew
- `devbox global shellenv` — no errors
- `direnv` and `starship` load correctly in a new interactive shell
- `kubectl`, `helm`, `k9s` available globally
- Open a project devbox shell — no PATH fights, GNU tools still win
- `brew list` shrinks appropriately after Brewfile edits + `brew bundle --cleanup`
