#!/usr/bin/env bash

# ----------------------------------------------------------------------
# | Colors                                                             |
# ----------------------------------------------------------------------

print_in_color() {
    echo -e "\e[$1$2\e[0m"
}

print_in_green() {
    print_in_color "92m" "$1"
}

print_in_purple() {
    print_in_color "95m" "$1"
}

print_in_red() {
    print_in_color "91m" "$1"
}

print_in_yellow() {
    print_in_color "93m" "$1"
}

# ----------------------------------------------------------------------
# | Question                                                           |
# ----------------------------------------------------------------------

print_question() {
    print_in_yellow "   [?] $1\n"
}

skip_questions() {

     while :; do
        case $1 in
            -y|--yes) return 0;;
                   *) break;;
        esac
        shift 1
    done

    return 1

}

ask() {
    print_question "$1"
    read -r
}

ask_for_confirmation() {
    print_question "$1 (y/n) "
    read -r -n 1
    echo ""
}

# ----------------------------------------------------------------------
# | Answer                                                             |
# ----------------------------------------------------------------------

get_answer() {
    echo "$REPLY"
}

answer_is_yes() {
    [[ "$REPLY" =~ ^[Yy]$ ]] && return 0 || return 1
}

# ----------------------------------------------------------------------
# | Success - Warning - Error                                          |
# ----------------------------------------------------------------------

print_success() {
    print_in_green "   [✔] $1\n"
}

print_result() {
    if [ "$1" -eq 0 ]; then
        print_success "$2"
    else
        print_error "$2"
    fi

    return "$1"
}

print_warning() {
    print_in_yellow "   [!] $1\n"
}

print_error() {
    print_in_red "   [✖] $1 $2\n"
}

print_error_stream() {
    while read -r line; do
        print_error "↳ ERROR: $line"
    done
}

# ----------------------------------------------------------------------
# | Process                                                            |
# ----------------------------------------------------------------------

kill_all_subprocesses() {

    local i=""

    for i in $(jobs -p); do
        kill "$i"
        wait "$i" &> /dev/null
    done

}

set_trap() {

    trap -p "$1" | grep "$2" &> /dev/null || trap '$2' "$1"

}

# ----------------------------------------------------------------------
# | Execute                                                            |
# ----------------------------------------------------------------------

execute() {
    
    local -r CMDS="$1"
    local -r MSG="${2:-$1}"
    local -r TMP_FILE="$(mktemp /tmp/execute.sh)"

    local exitCode=0
    local cmdsPID=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # If the current process is ended,
    # also end all its subprocesses.

    set_trap "EXIT" "kill_all_subprocesses"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Execute commands in background
    # shellcheck disable=SC2261

    eval "$CMDS" &> /dev/null 2> "$TMP_FILE" &

    cmdsPID=$!

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Show a spinner if the commands
    # require more time to complete.

    show_spinner "$cmdsPID" "$MSG"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Wait for the commands to no longer be executing
    # in the background, and then get their exit code.

    wait "$cmdsPID" &> /dev/null
    
    exitCode=$?

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Print output based on what happened.

    print_result $exitCode "$MSG"

    if [ $exitCode -ne 0 ]; then
        print_error_stream < "$TMP_FILE"
    fi

    rm -rf "$TMP_FILE"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    return "$exitCode"

}

# ----------------------------------------------------------------------
# | Spinner                                                            |
# ----------------------------------------------------------------------

spinner() {

    local -r SPIN='|/-\'
    local -r SPIN_LENGTH=${#SPIN}

    local -r PID="$1"
    local -r MSG="$2"

    local i=0
    local delay=0.2

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    while kill -0 "$PID" &>/dev/null; do

        spin_msg="   [${SPIN:i++%SPIN_LENGTH:1}] $MSG"

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        echo "$spin_msg"
        
        sleep "$delay"

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        # Clear frame text.
        echo -e "\r\033[K"

    done
    
}

# ----------------------------------------------------------------------
# | OS                                                                 |
# ----------------------------------------------------------------------

get_os() {

    local os=""
    local kernelName=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    kernelName="$(uname -s)"

    if [ "$kernelName" == "Darwin" ]; then
        os="macos"
    elif [ "$kernelName" == "Linux" ] && \
         [ -e "/etc/os-release" ]; then
        os="$(. /etc/os-release; echo "$ID")"

    else
        os="$kernelName"
    fi

    echo "$os"

}

get_os_version() {

    local os=""
    local version=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    os="$(get_os)"

    if [ "$os" == "macos" ]; then
        version="$(sw_vers -productVersion)"
    elif [ -e "/etc/os-release" ]; then
        version="$(. /etc/os-release; echo "$VERSION_ID")"
    fi

    echo "$version"

}

is_supported_version() {

    # shellcheck disable=SC2206
    declare -a v1=(${1//./ })
    # shellcheck disable=SC2206
    declare -a v2=(${2//./ })
    local i=""

    # Fill empty positions in v1 with zeros.
    for (( i=${#v1[@]}; i<${#v2[@]}; i++ )); do
        v1[i]=0
    done


    for (( i=0; i<${#v1[@]}; i++ )); do

        # Fill empty positions in v2 with zeros.
        if [[ -z ${v2[i]} ]]; then
            v2[i]=0
        fi

        if (( 10#${v1[i]} < 10#${v2[i]} )); then
            return 1
        elif (( 10#${v1[i]} > 10#${v2[i]} )); then
            return 0
        fi

    done

}

# ----------------------------------------------------------------------
# | CMD                                                                |
# ----------------------------------------------------------------------

cmd_exists() {
    command -v "$1" &> /dev/null
}

keep_alive_sudo() {

    # Ask for the administrator password upfront.

    sudo -v &> /dev/null

    # Keep-alive: update `sudo` time stamp
    # until this`setup.sh` has finished.
    #
    # https://gist.github.com/cowboy/3118588

    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done &> /dev/null &

}

is_git_repository() {
    git rev-parse &> /dev/null
}

mkd() {
    if [ -n "$1" ]; then
        if [ -e "$1" ]; then
            if [ ! -d "$1" ]; then
                print_error "$1 - a file with the same name already exists!"
            else
                print_success "$1"
            fi
        else
            execute "mkdir -p $1" "$1"
        fi
    fi
}
