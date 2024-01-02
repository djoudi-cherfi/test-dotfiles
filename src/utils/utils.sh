#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "./print.sh" \
    && . "./execute.sh" \
    && . "./process.sh" \
    && . "./spinner.sh"

echo "Test utils !"