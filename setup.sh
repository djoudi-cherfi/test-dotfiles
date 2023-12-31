#!/usr/bin/env bash

declare -r GITHUB_REPOSITORY="djoudi-cherfi/test-dotfiles"
declare -r DOTFILES_UTILS_URL="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/src/os/utils.sh"

download() {

    local url="$1"
    local output="$2"

    if command -v "curl" &> /dev/null; then

        curl \
            --location \
            --silent \
            --show-error \
            --output "$output" \
            "$url" \
                &> /dev/null

        return $?

    elif command -v "wget" &> /dev/null; then

        wget \
            --quiet \
            --output-document="$output" \
            "$url" \
                &> /dev/null

        return $?
    fi

    return 1

}

download_utils() {
    local tmpFile=""

    tmpFile="$(mktemp /tmp/XXXXX)"

    download "$DOTFILES_UTILS_URL" "$tmpFile" \
        && . "$tmpFile" \
        && rm -rf "$tmpFile" \
        && return 0

   return 1

}

function_one() {
    execute "sleep $1" "$2"
}

function_two() {
    execute "ls -lah $1" "$2"
}

function_three() {
    myDirectory="00_Directory"
    mkdir -p "$myDirectory"
    print_result $? "Create $myDirectory"
}

main() {
    cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

    if [ -x "src/utils/utils.sh" ]; then
        . "src/utils/utils.sh" || exit 1
    else
        download_utils || exit 1
    fi

    function_one "3" "Hello world!"
    function_two "." "John Doe"
    # function_three
}

main