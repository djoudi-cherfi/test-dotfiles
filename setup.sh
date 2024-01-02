#!/usr/bin/env bash

declare -r GITHUB_REPOSITORY="djoudi-cherfi/test-dotfiles"

declare -r DOTFILES_PRINT_URL="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/src/utils/print.sh"
declare -r DOTFILES_EXECUTE_URL="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/src/utils/execute.sh"
declare -r DOTFILES_PROCESS_URL="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/src/utils/process.sh"
declare -r DOTFILES_SPINNER_URL="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/src/utils/spinner.sh"
declare -r DOTFILES_UTILS_URL="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/src/utils/utils.sh"

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
    local tmpFilePrint=""
    local tmpFileExecute=""
    local tmpFileProcess=""
    local tmpFileSpinner=""
    local tmpFileUtils=""

    tmpFilePrint="$(mktemp /tmp/print.sh)"
    tmpFileExecute="$(mktemp /tmp/execute.sh)"
    tmpFileProcess="$(mktemp /tmp/process.sh)"
    tmpFileSpinner="$(mktemp /tmp/spinner.sh)"
    tmpFileUtils="$(mktemp /tmp/utils.sh)"

    download "$DOTFILES_PRINT_URL" "$tmpFilePrint" \
    && download "$DOTFILES_EXECUTE_URL" "$tmpFileExecute" \
    && download "$DOTFILES_PROCESS_URL" "$tmpFileProcess" \
    && download "$DOTFILES_SPINNER_URL" "$tmpFileSpinner" \
    && download "$DOTFILES_UTILS_URL" "$tmpFileUtils" \
        && . "$tmpFileUtils" \
        && return 0
        # && rm -rf "$tmpFileUtils" \
        # && rm -rf "$tmpFileSpinner" \
        # && rm -rf "$tmpFileProcess" \
        # && rm -rf "$tmpFileExecute" \
        # && rm -rf "$tmpFilePrint" \

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
    download_utils || exit 1
    # if [ -x "src/utils/utils.sh" ]; then
    #     . "src/utils/utils.sh" || exit 1
    # else
    #     download_utils || exit 1
    # fi

    # function_one "3" "Hello world!"
    # function_two "." "John Doe"
    # function_three
}

main