#!/bin/bash


# TODO: Doc
function url_encode() {
    local string="${1}"
    printf '%s' "${string}" | jq -sRr @uri
}

# TODO: Doc
function url_decode() {
    local string="${1//+/ }"
    printf '%s' "$string" | perl -MURI::Escape -ne 'print uri_unescape($_)'
}

# TODO: Doc
function atob() {
    echo -n "$1" | base64 --decode
}

# TODO: Doc
function btoa() {
    echo -n "$1" | base64
}

function passwd_parser() {
    input_file="$1"

    [[ -z "$input_file" ]] && echo "Error: No input file provided!" && return 1fi
    [[ ! -f "$input_file" ]] && echo "Error: Input file '$input_file' not found!" && return 1

    # Use `sed` to replace spaces between entries with newlines
    sed -E 's/ ([^:]+:x:[0-9]+:[0-9]+:)/\n\1/g' "$input_file" > format.passwd

    # Extract usernames (first field before ":") from the formatted data
    cut -d: -f1 format.passwd > format.passwd.users

    swiss_logger info "[i] $(realpath format.passwd) (multi-line formatted output)"
    swiss_logger info "[i] $(realpath format.passwd.users) (list of usernames)"
}