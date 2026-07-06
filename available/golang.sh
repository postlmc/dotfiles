#!/bin/bash

command -v go >/dev/null 2>&1 || return

# GOROOT is intentionally unset — modern go derives it from its own binary location
export GOPATH=${HOME}/Go

prepend_path PATH ${GOPATH}/bin
