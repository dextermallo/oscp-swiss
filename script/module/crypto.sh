#!/bin/bash


# TODO: Doc
# Category: [ http ]
function url_encode() {
    local string="${1}"
    printf '%s' "${string}" | jq -sRr @uri
}

# TODO: Doc
# Category: [ target:http ]
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