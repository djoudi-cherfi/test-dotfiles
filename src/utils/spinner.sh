#!/usr/bin/env bash

spinner() {
    local -r SPIN='|/-\'
    local -r SPIN_LENGTH=${#SPIN}

    local -r PID="$1"
    local -r MSG="$2"

    i=0
    delay=0.2

    while kill -0 "$PID" &>/dev/null; do        
        spin_msg="   [${SPIN:i++%SPIN_LENGTH:1}] $MSG"
        printf "%s" "$spin_msg"
        
        sleep "$delay"

        # Clear frame text.
        printf "\r\033[K"
    done
}
echo "Test spinner !"