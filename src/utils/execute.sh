#!/usr/bin/env bash

execute() {
    local -r CMDS="$1"
    local -r MSG="${2:-$1}"

    exitCode=0
    cmdsPID=""

    set_trap "EXIT" "kill_all_subprocesses"

    eval "$CMDS" \
        &> /dev/null &

    cmdsPID=$!

    show_spinner "$cmdsPID" "$MSG"

    wait "$cmdsPID" &> /dev/null
    exitCode=$?

    print_result $exitCode "$MSG"

    return "$exitCode"
}
echo "Test execute !"