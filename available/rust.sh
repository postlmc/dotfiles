#!/bin/bash

command -v rustup >/dev/null 2>&1 || return

prepend_path PATH "${HOME}/.cargo/bin"

# . "${HOME}/.cargo/env"
