#!/bin/bash

command -v git >/dev/null 2>&1 || return

# Git aliases
alias gitv='GIT_SSH_COMMAND="ssh -v" GIT_CURL_VERBOSE=1 GIT_TRACE=1 git'
alias gitb='for B in $(git branch -a | awk '\''/remotes/ && !/HEAD|master/'\''); do git branch --track ${B#remotes/origin/} $B ; done'

# Git functions
git-remotes() {
    for DIR in $(command -v fd &>/dev/null && fd --type d . || find . -type d); do
        [ -d "$DIR"/.git ] &&
            (cd "$DIR" && printf "${DIR}: [%s] %s\n" $(git remote -v | awk '{print $1" "$2}' | uniq))
    done
}

getgit() {
    (
        cd ${D}
        if [[ -d .git ]]; then
            printf "${PWD}, %s\n" $(git config --get remote.origin.url)
        else
            for D in $(command -v fd &>/dev/null && \
                fd --max-depth 1 --min-depth 1 --type d . || \
                find . -maxdepth 1 -mindepth 1 -type d -regex '.*/[^.-].*' -printf '%f\n'); do
                getgit ${D}
            done
        fi
    )
}

ghostars() {
    local fetcher
    if command -v xh &>/dev/null; then
        fetcher='xh'
    elif command -v curl &>/dev/null; then
        fetcher='curl -s'
    else
        echo "Error: xh or curl is required for ghostars function"
        return 1
    fi
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is required for ghostars function"
        return 1
    fi
    for ORG in $@; do
        printf "$ORG: %s\n" $($fetcher https://api.github.com/orgs/$ORG/repos |
            jq '[ .[] | .stargazers_count ] | add')
    done
}

gitlarge() {
    # List objects in the repository sorted by size
    # (not necessarily the largest files, but the largest objects)
    # Note: this will not work on a bare repository
    git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
        grep -v tag | sort -k3nr
}
