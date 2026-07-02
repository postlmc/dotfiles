#!/bin/bash

HOST=$(hostname -s | tr "[:upper:]" "[:lower:]")
OS=$(uname | awk -F "(_|/|-)" '{print tolower($1)}')

# Core shell configuration (loaded early as other files may depend on it)
ln -sf ../available/core.sh 02-core
command -v chezmoi >/dev/null 2>&1 && ln -sf ../available/chezmoi.sh 03-chezmoi

# Tools we should have everywhere
command -v eza >/dev/null 2>&1 && ln -sf ../available/eza.sh 09-eza
command -v openssl >/dev/null 2>&1 && ln -sf ../available/openssl.sh 10-openssl
command -v ssh >/dev/null 2>&1 && ln -sf ../available/ssh.sh 11-ssh

# Load Homebrew on both macOS and Linux (for Aurora)
command -v brew >/dev/null 2>&1 && ln -sf ../available/homebrew.sh 20-homebrew
command -v devbox >/dev/null 2>&1 && ln -sf ../available/devbox.sh 21-devbox

# Network tools
{ command -v tailscale >/dev/null 2>&1 || [[ -f "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]]; } && \
    ln -sf ../available/tailscale.sh 28-tailscale

# OS-specific configurations (load after core, network, and tools)
case "$OS" in
darwin)
    ln -sf ../available/misc-darwin.sh 29-misc-darwin
    ;;
linux)
    # Check for package managers and create appropriate links
    if command -v apt-get >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
        ln -sf ../available/misc-linux.sh 22-misc-linux
    fi

    # Raspberry Pi detection using device tree model
    if [ -f /proc/device-tree/model ] && grep -q "Raspberry Pi" /proc/device-tree/model; then
        ln -sf ../available/misc-rpi.sh 23-misc-rpi
    fi

    # SSH agent management (macOS hosts use 1Password SSH agent instead)
    command -v ssh-agent >/dev/null 2>&1 && ln -sf ../available/ssh-agent.sh 12-ssh-agent
    ;;
esac

# Markdown linting
command -v markdownlint-cli2 >/dev/null 2>&1 && ln -sf ../available/markdownlint.sh 49-markdownlint

# Now we can load general development tools
command -v git >/dev/null 2>&1 && ln -sf ../available/git.sh 30-git
{ command -v docker >/dev/null 2>&1 || command -v podman >/dev/null 2>&1; } && ln -sf ../available/docker.sh 31-docker

# Language-specific tools (load after general development tools)
command -v python >/dev/null 2>&1 && ln -sf ../available/python.sh 40-python
command -v go >/dev/null 2>&1 && ln -sf ../available/golang.sh 41-golang
command -v rustc >/dev/null 2>&1 && ln -sf ../available/rust.sh 42-rust
command -v npm >/dev/null 2>&1 && ln -sf ../available/nodejs.sh 43-nodejs

# Cloud and platform tools (load after all the other stuff)
command -v op >/dev/null 2>&1 && ln -sf ../available/op.sh 50-op
command -v az >/dev/null 2>&1 && ln -sf ../available/azure.sh 60-azure
command -v gcloud >/dev/null 2>&1 && ln -sf ../available/gcloud.sh 61-gcloud
command -v kubectl >/dev/null 2>&1 && ln -sf ../available/kubernetes.sh 70-kubernetes
command -v terraform >/dev/null 2>&1 && ln -sf ../available/terraform.sh 71-terraform

# AI tools
command -v claude >/dev/null 2>&1 && ln -sf ../available/claude.sh 80-claude
