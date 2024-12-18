#!/bin/bash


# TODO: rename to parse <parse-type>
function passwd_parser() {
    input_file="$1"
    [[ -z "$input_file" ]] && echo "Error: No input file provided!" && return 1
    [[ ! -f "$input_file" ]] && echo "Error: Input file '$input_file' not found!" && return 1

    # Use `sed` to replace spaces between entries with newlines
    sed -E 's/ ([^:]+:x:[0-9]+:[0-9]+:)/\n\1/g' "$input_file" > format.passwd

    # Extract usernames (first field before ":") from the formatted data
    cut -d: -f1 format.passwd > format.passwd.users

    _logger info "[i] $(realpath format.passwd) (multi-line formatted output)"
    _logger info "[i] $(realpath format.passwd.users) (list of usernames)"
}