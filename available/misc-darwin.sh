#!/bin/bash

# macOS-specific configurations and utilities

# Prevent resource fork and extended attribute issues when copying files
export COPY_EXTENDED_ATTRIBUTES_DISABLE=true
export COPYFILE_DISABLE=true

alias show-files='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hide-files='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'
alias fix-openwith='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
        -kill -r -domain local -domain system -domain user'
alias cpu-model='sysctl -n machdep.cpu.brand_string'
alias reset-launchpad='defaults -currentHost write com.apple.dock ResetLaunchPad -bool true; killall Dock'
alias flush-dns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias tm-wtf='sudo log stream --style syslog --predicate '\''processImagePath contains "backupd"'\'' --info'
alias tm-logs='log stream --style syslog  --predicate '"'"'senderImagePath contains[cd] "TimeMachine"'"'"' --info'
alias stopspotlight='sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist'
alias startspotlight='sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist'

# Old now, but keeping handy:
# http://www.reecefowell.com/2012/11/16/ksfetch-annoyance-on-mac-os-x-10-8-ml-with-hands-off-or-little-snitch-firewall/)
# defaults write com.google.Keystone.Agent checkInterval 4233600

# fdsnap: save a snapshot of file descriptor and pty usage to ~/fdsnap-<timestamp>.txt: limits,
# the top fd holders, /dev/ptmx holders, and a per-process breakdown for each claude process.
fdsnap() {
    local out=~/fdsnap-$(date +%Y%m%d-%H%M%S).txt
    {
        echo "== cwd: $PWD"
        ls -al . 2>&1 | head -3
        echo "== ulimit: $(ulimit -Sn)"
        sysctl kern.num_files kern.maxfiles kern.tty.ptmx_max
        echo "== top holders"
        lsof -n 2>/dev/null | awk 'NR>1{print $1,$2}' | sort | uniq -c | sort -rn | head
        echo "== ptmx"
        lsof /dev/ptmx 2>/dev/null | awk 'NR>1{print $1,$2}' | sort | uniq -c | sort -rn
        for p in $(pgrep -f claude); do
            echo "== claude pid $p: $(lsof -p $p 2>/dev/null | wc -l) fds"
            lsof -p $p 2>/dev/null | awk '{print $5}' | sort | uniq -c | sort -rn | head -5
        done
    } > "$out"
    echo "saved $out"
}
