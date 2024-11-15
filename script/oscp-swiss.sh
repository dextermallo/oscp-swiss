#!/bin/bash


source $HOME/oscp-swiss/script/utils.sh
source $HOME/oscp-swiss/script/alias.sh
source $HOME/oscp-swiss/script/extension.sh

# Description: List all functions, aliases, and variables
# Usage: swiss
# swiss -f <function name>
# swiss -c "category"
# swiss -h
# Category: [ ]
function swiss() {
    _banner() {
        swiss_logger info ".--------------------------------------------."
        swiss_logger info "|                                            |"
        swiss_logger info "|                                            |"
        swiss_logger info "|  __________       _______________________  |"
        swiss_logger info "|  __  ___/_ |     / /___  _/_  ___/_  ___/  |"
        swiss_logger info "|  _____ \\__ | /| / / __  / _____ \\_____ \\   |"
        swiss_logger info "|  ____/ /__ |/ |/ / __/ /  ____/ /____/ /   |"
        swiss_logger info "|  /____/ ____/|__/  /___/  /____/ /____/    |"
        swiss_logger info "|                                            |"
        swiss_logger info "|  by @dextermallo v1.4.2                    |"
        swiss_logger info "'--------------------------------------------'"
    }

    if [ $_swiss_app_banner = true ]; then
        _banner
    fi

    swiss_logger info "[i] Functions:"
    {
        grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$swiss_script" | sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/';
        grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$swiss_extension" | sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/';
    } | sort | column

    swiss_logger info "[i] Aliases:"
    {
        grep -E '^\s*alias\s+' "$swiss_extension" | sed -E 's/^\s*alias\s+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/';
        grep -E '^\s*alias\s+' "$swiss_alias" | sed -E 's/^\s*alias\s+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/';
    } | sort | column
    
    swiss_logger info "[i] Variables:"
    {
        grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$swiss_extension" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/';
        grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$swiss_alias" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/';
        grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$swiss_script" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/';
    } | sort | column

    # load /private scripts
    if [ -d "$swiss_private" ]; then
        for script in "$swiss_private"/*.sh; do
        if [ -f "$script" ]; then

            if grep -qE '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$script"; then
                swiss_logger info "[i] Function under $script:"
                grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$script"| sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/' | sort | column
            fi
            
            if grep -qE '^\s*alias\s+' "$script"; then
                swiss_logger info "[i] Aliases under $script:"
                grep -E '^\s*alias\s+' "$script" | sed -E 's/^\s*alias\s+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column
            fi
            
            if grep -qE '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$script"; then
                swiss_logger info "[i] Variables under $script:"
                grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$script" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column
            fi
        fi
        done
    else
        swiss_logger error "[e] Directory $swiss_private not found."
    fi
}

# TODO: deprecate
function find_category() {
    if [[ "$1" == "-h" ]]; then

        local categories_list=()
        
        local category_exists() {
            local category="$1"
            for existing_category in "${categories_list[@]}"; do
                if [[ "$existing_category" == "$category" ]]; then
                    return 0
                fi
            done
            # category does not exist
            return 1  
        }        

        for script in "$swiss_root/script/"*.sh; do
            while IFS= read -r line; do
        
                if [[ $line == *"Category:"* ]]; then
                    # extract the categories between [ ] and split by comma
                    script_categories=$(echo "$line" | sed -n 's/.*Category: \[\(.*\)\].*/\1/p' | tr ',' '\n')

                    if [[ -n "$script_categories" ]]; then
                        while read -r category; do
                            # trim any leading/trailing whitespace
                            category=$(echo "$category" | xargs)
                            if [[ -n "$category" ]]; then
                                if ! category_exists "$category"; then
                                    categories_list+=("$category")
                                fi
                            fi
                        done <<< "$script_categories"
                    fi
                fi
            done < "$script"
        done

        swiss_logger info "[i] Supported Categories:"
        for category in $(printf "%s\n" "${categories_list[@]}" | sort); do
            swiss_logger "\t- $category\n"
        done
        return 0
    fi

    local evaluate_condition() {
        local condition="$1"
        local match=true

        # Nested parentheses
        while echo "$condition" | grep -q "("; do
            local inner_expr=$(echo "$condition" | sed -E 's/.*\(([^()]*)\).*/\1/')
            local inner_result=""

            if [[ "$inner_expr" == *"&"* ]]; then
                $inner_result=$(evaluate_condition "$inner_expr")
            elif [[ "$inner_expr" == *"|"* ]]; then
                $inner_result=$(evaluate_condition "$inner_expr")
            fi

            $condition="${condition//"(${inner_expr})"/"$inner_result"}"
        done

        # Handle and/or
        if [[ "$condition" == *"&"* ]]; then
            IFS='&' read -r term1 term2 <<< "$condition"
            for term in $term1 $term2; do
                if [[ "$term" == *"|"* ]]; then
                    if ! evaluate_condition "$term"; then
                        match=false
                        break
                    fi
                else
                    if [[ ! " $script_categories " =~ " $term " ]]; then
                        match=false
                        break
                    fi
                fi
            done
        elif [[ "$condition" == *"|"* ]]; then
            IFS='|' read -r term1 term2 <<< "$condition"
            match=false
            for term in $term1 $term2; do
                if [[ "$term" == *"&"* ]]; then
                    if evaluate_condition "$term"; then
                        match=true
                        break
                    fi
                else
                    if [[ " $script_categories " =~ " $term " ]]; then
                        match=true
                        break
                    fi
                fi
            done
        else
            match=false
            if [[ " $script_categories " =~ " $condition " ]]; then
                match=true
            fi
        fi
        $match && return 0 || return 1
    }

    for condition in "$@"; do
        for script in "$swiss_root/script/"*.sh; do
        while IFS= read -r line; do
            if [[ $line == *"Category:"* ]]; then
                script_categories=$(echo $line | sed -n 's/.*Category: \[\(.*\)\].*/\1/p' | tr ',' ' ')
                if evaluate_condition "$condition"; then
                    while IFS= read -r func_line; do
                        if [[ $func_line == "function "* ]]; then
                            func_name=$(echo $func_line | awk '{print $2}' | tr -d '(){')
                            swiss_logger info "[i] Function found: $func_name"
                            break
                        fi
                    done
                fi
            fi
        done < "$script"
        done
    done
}

source $swiss_module/bruteforce.sh
source $swiss_module/crypto.sh
source $swiss_module/exploit.sh
source $swiss_module/host.sh
source $swiss_module/payload.sh
source $swiss_module/prep.sh
source $swiss_module/recon.sh
source $swiss_module/target.sh
source $swiss_module/workspace.sh

spawn_session_in_workspace