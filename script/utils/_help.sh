# Description: 
#   _help generates a shell-script Docstring.
#   By default, it uses in a function, and prints all information from the line
#   "# Description" to the end of function $function-name()
# Usage: _help
_help() {
    local script_file
    local function_name
    local annotations=""
    local start_reading=false

    if [ -n "$ZSH_VERSION" ]; then
        function_name="${funcstack[-1]}"
        script_file="${functions_source[$function_name]}"
    elif [ -n "$BASH_VERSION" ]; then
        function_name="${FUNCNAME[1]}"
        script_file="${BASH_SOURCE[1]}"
    else
        swiss_logger error "[e] Only Zsh and Bash shells are supported."
        return 1
    fi

    while IFS= read -r line; do
        if [[ $line =~ ^#\ Description ]]; then
            start_reading=true && annotations="${line/#\# /}"$'\n' && continue
        fi

        if $start_reading && [[ $line =~ ^# ]]; then
            annotations+="${line/#\# /}"$'\n' && continue
        fi

        if [[ $line =~ ^function\  ]]; then
            if [[ $line =~ ^function\ $function_name\(\) ]]; then
                echo -e "$annotations" && return 0
            fi
            start_reading=false
            annotations=""
        fi
    done < "$script_file"

    # If no annotations were found for the function
    _logger warn "No annotations found for function: $function_name"
}