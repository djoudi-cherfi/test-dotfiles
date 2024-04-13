#!/usr/bin/env bash

declare -r GITHUB_REPOSITORY="djoudi-cherfi/test-dotfiles"

declare -r DOTFILES_ORIGIN="git@github.com:$GITHUB_REPOSITORY.git"
declare -r DOTFILES_TARBALL_URL="https://github.com/$GITHUB_REPOSITORY/tarball/main"
declare -r DOTFILES_UTILS_URL="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/src/os/utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

declare default_dotfiles_directory="$HOME/projects/dotfiles"
declare skipQuestions=false

# ----------------------------------------------------------------------
# | Helper Functions                                                   |
# ----------------------------------------------------------------------

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

download_dotfiles() {

    local tmpFile=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    print_in_purple "\n • Download and extract archive\n\n"

    tmpFile="$(mktemp /tmp/XXXXX)"

    download "$DOTFILES_TARBALL_URL" "$tmpFile"
    print_result $? "Download archive"
    printf "\n"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ! $skipQuestions; then

        ask_for_confirmation "Do you want to store the dotfiles in '$default_dotfiles_directory'?"

        if ! answer_is_yes; then
            default_dotfiles_directory=""
            while [ -z "$default_dotfiles_directory" ]; do
                ask "Please specify another location for the dotfiles (path): "
                default_dotfiles_directory="$(get_answer)"
            done
        fi

        # Ensure the `dotfiles` directory is available

        while [ -e "$default_dotfiles_directory" ]; do
            ask_for_confirmation "'$default_dotfiles_directory' already exists, do you want to overwrite it?"
            if answer_is_yes; then
                rm -rf "$default_dotfiles_directory"
                break
            else
                default_dotfiles_directory=""
                while [ -z "$default_dotfiles_directory" ]; do
                    ask "Please specify another location for the dotfiles (path): "
                    default_dotfiles_directory="$(get_answer)"
                done
            fi
        done

        printf "\n"

    else

        rm -rf "$default_dotfiles_directory" &> /dev/null

    fi

    mkdir -p "$default_dotfiles_directory"
    print_result $? "Create '$default_dotfiles_directory'" "true"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Extract archive in the `dotfiles` directory.

    extract "$tmpFile" "$default_dotfiles_directory"
    print_result $? "Extract archive" "true"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    rm -rf "$tmpFile"
    print_result $? "Remove archive"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    cd "$default_dotfiles_directory/src/os" \
        || return 1

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

extract() {

    local archive="$1"
    local outputDir="$2"

    if command -v "tar" &> /dev/null; then

        tar \
            --extract \
            --gzip \
            --file "$archive" \
            --strip-components 1 \
            --directory "$outputDir"

        return $?
    fi

    return 1

}

add_shebang_recursive() {
    local default_os_name="$1"
    local default_shebang_regex="^#\!.*"
    local default_usr_shebang_env="#!/usr/bin/env"
    local current_subfolder=""

    printf "\n"

    # Use find to get all non-hidden files, including those from subfolders
    find "$default_dotfiles_directory" -type f \
    \( -not -path "*/git/*" \
    -not -path "*/os/*" \
    -not -name ".*" \
    -not -name "hushlogin" \
    -not -name "README.md" \) \
    -print0 | while IFS= read -r -d '' file; do

        # Get the subfolder name
        subfolder_name=$(dirname "$file")

        # Display the subfolder name only if it has changed
        if [ "$subfolder_name" != "$current_subfolder" ]; then
            if [ -n "$current_subfolder" ]; then
                # Add a newline after processing the folder
                printf "\n"
            fi
            printf "   Processing files in subfolder: %s\n" "$subfolder_name"
            current_subfolder="$subfolder_name"
        fi

        if [ "$default_os_name" = "macos" ]; then
            # Remove existing shebang if present
            sed -i '' "1s;$default_shebang_regex;;" "$file"
            # Add the new shebang at the beginning of the file
            sed -i '' "1s;^;$default_usr_shebang_env zsh;" "$file"
        elif [ "$default_os_name" = "ubuntu" ]; then
            sed -i "1s;$default_shebang_regex;;" "$file"
            sed -i "1s;^;$default_usr_shebang_env bash;" "$file"
        else
            return 1
        fi

        print_result $? "Add shebang to $file"
    done
}

verify_os() {

    declare -r MINIMUM_MACOS_VERSION="10.10"
    declare -r MINIMUM_UBUNTU_VERSION="20.04"

    local os_name="$(get_os)"
    local os_version="$(get_os_version)"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Check if the OS is `macOS` and
    # it's above the required version.

    if [ "$os_name" == "macos" ]; then

        if is_supported_version "$os_version" "$MINIMUM_MACOS_VERSION"; then
            return 0
        else
            printf "Sorry, this script is intended only for macOS %s+" "$MINIMUM_MACOS_VERSION"
        fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Check if the OS is `Ubuntu` and
    # it's above the required version.

    elif [ "$os_name" == "ubuntu" ]; then

        if is_supported_version "$os_version" "$MINIMUM_UBUNTU_VERSION"; then
            return 0
        else
            printf "Sorry, this script is intended only for Ubuntu %s+" "$MINIMUM_UBUNTU_VERSION"
        fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    else
        printf "Sorry, this script is intended only for macOS and Ubuntu!"
    fi

    return 1

}

# ----------------------------------------------------------------------
# | Main                                                               |
# ----------------------------------------------------------------------

main() {

    # Ensure that the following actions
    # are made relative to this file's path.

    cd "$(dirname "${BASH_SOURCE[0]}")" \
        || exit 1

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Load utils

    if [ -x "utils.sh" ]; then
        . "utils.sh" || exit 1
    else
        download_utils || exit 1
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Ensure the OS is supported and
    # it's above the required version.

    verify_os \
        || exit 1

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    skip_questions "$@" \
        && skipQuestions=true

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    ask_for_sudo

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Check if this script was run directly (./<path>/setup.sh),
    # and if not, it most likely means that the dotfiles were not
    # yet set up, and they will need to be downloaded.

    printf "%s" "${BASH_SOURCE[0]}" | grep "setup.sh" &> /dev/null \
        || download_dotfiles

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    add_shebang_recursive "$(get_os)"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    ./create_symbolic_links.sh "$@"

    # # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # ./create_local_config_files.sh

    # # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # ./installs/main.sh

    # # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # ./preferences/main.sh

    # # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # if cmd_exists "git"; then

    #     if [ "$(git config --get remote.origin.url)" != "$DOTFILES_ORIGIN" ]; then
    #         ./initialize_git_repository.sh "$DOTFILES_ORIGIN"
    #     fi

    #     # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    #     if ! $skipQuestions; then
    #         ./update_content.sh
    #     fi

    # fi

    # # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # if ! $skipQuestions; then
    #     ./restart.sh
    # fi

}

main "$@"
