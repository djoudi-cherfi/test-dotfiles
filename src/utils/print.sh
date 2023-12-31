#!/usr/bin/env bash

print_in_color() {
    printf "\e[$1%b\e[0m" "$2";
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

print_question() {
    print_in_yellow "   [?] $1\n"
}

print_success() {
    print_in_green "   [✔] $1\n"
}

print_warning() {
    print_in_yellow "   [!] $1\n"
}

print_error() {
    print_in_red "   [✖] $1\n"
}

print_result() {
    if [ "$1" -eq 0 ]; then
        print_success "$2"
    else
        print_error "$2"
    fi

    return "$1"
}
echo "Test print !"