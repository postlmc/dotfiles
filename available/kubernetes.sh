#!/bin/bash

command -v kubectl >/dev/null 2>&1 || return

alias k='kubectl'
alias kv='kubectl -v=6'
alias kvv='kubectl -v=9'

alias ktaints='kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints'

if command -v gum &>/dev/null; then
    kctx() {
        if [ -n "$1" ]; then
            kubectl config use-context "$1"
            return $?
        fi
        
        local current=$(kubectl config current-context 2>/dev/null)
        local contexts=($(kubectl config get-contexts -o name))
        
        if [ ${#contexts[@]} -eq 0 ]; then
            gum style --foreground 196 "No contexts available"
            return 1
        fi
        
        gum style --bold --foreground 212 "Select Kubernetes Context"
        echo
        
        local context=$(printf '%s\n' "${contexts[@]}" | \
            gum filter --placeholder="Type to filter..." \
                       --prompt="❯ " \
                       --indicator="*" \
                       --height=15)
        
        if [ -n "$context" ]; then
            gum spin --spinner dot --title "Switching context..." -- \
                kubectl config use-context "$context"
            
            if [ $? -eq 0 ]; then
                gum style --foreground 76 "Switched to context: $context"
            else
                gum style --foreground 196 "Failed to switch context"
                return 1
            fi
        else
            gum style --foreground 214 "No context selected"
            return 1
        fi
    }
elif command -v fzf &>/dev/null; then
    kctx() {
        if [ -n "$1" ]; then
            kubectl config use-context "$1"
            return $?
        fi
        
        local current=$(kubectl config current-context 2>/dev/null)
        local context=$(kubectl config get-contexts -o name | \
            fzf --height=40% --reverse --prompt="Select context: " \
                --preview="kubectl config get-contexts {}" \
                --preview-window=down:3:wrap \
                --query="$current")
        [ -n "$context" ] && kubectl config use-context "$context"
    }
else
    kctx() {
        if [ -n "$1" ]; then
            kubectl config use-context "$1"
            return $?
        fi
        
        local contexts=($(kubectl config get-contexts -o name))
        if [ ${#contexts[@]} -eq 0 ]; then
            echo "No contexts available"
            return 1
        fi
        
        echo "Available contexts:"
        PS3="Select context (number): "
        select context in "${contexts[@]}"; do
            if [ -n "$context" ]; then
                kubectl config use-context "$context"
                break
            fi
        done
    }
fi

if command -v jq &>/dev/null; then
    alias kimg="kubectl get pods --all-namespaces -o json | jq -r '.items[].spec.containers[].image' | sort | uniq -c"
else
    alias kimg="echo 'Error: jq is required for kimg alias'"
fi

alias kans='kubectl get --all-namespaces $(kubectl api-resources | awk '\''$4~/true/{printf "%s ", $1}'\'')'

ka() { kubectl "$@" --all-namespaces; }
kdr() { kubectl "$@" --dry-run=client -o yaml; }
if command -v bat &>/dev/null; then
    ke() { kubectl explain "${1}" --recursive | bat --paging=always --language=yaml; }
else
    ke() { kubectl explain "${1}" --recursive | less; }
fi
kf() { kubectl "$@" --grace-period=0 --force; }
knh() { kubectl "$@" --no-headers; }
kns() { kubectl config set-context --current --namespace="${1}"; }

kcfg() {
    if [ -d ~/.kube ] && [ -s ~/.kube/current-context ]; then
        if command -v fd &>/dev/null; then
            echo ~/.kube/current-context:$(fd --max-depth 1 --type f -e yml -e yaml --exclude '_*' . ~/.kube | tr '\n' ':')
        else
            echo ~/.kube/current-context:$(find ~/.kube -maxdepth 1 -type f \
                \( -name '*.yml' -o -name '*.yaml' \) ! -name '.*' ! -name '_*' | tr '\n' ':')
        fi
    fi
}
export KUBECONFIG=$(kcfg)

# Completions (cached — delete cache file to regenerate)
if [[ -n "$ZSH_CACHE_DIR" ]]; then
    if (( $+commands[kubectl] )); then
        _kc="${ZSH_CACHE_DIR}/kubectl.zsh"
        [[ ! -f "$_kc" ]] && kubectl completion zsh 2>/dev/null > "$_kc"
        [[ -f "$_kc" ]] && source "$_kc"
        unset _kc
    fi
    if (( $+commands[kubelogin] )); then
        _kc="${ZSH_CACHE_DIR}/kubelogin.zsh"
        [[ ! -f "$_kc" ]] && kubelogin completion zsh 2>/dev/null > "$_kc"
        [[ -f "$_kc" ]] && source "$_kc"
        unset _kc
    fi
fi
