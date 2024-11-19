#!/bin/bash


source $HOME/oscp-swiss/script/utils.sh
source $HOME/oscp-swiss/script/alias.sh
source $HOME/oscp-swiss/script/extension.sh

# Description: Find the commands, aliases, or variable you need.
# Usage: swiss [-h|--help] <module>
# Arguments:
#   - module: see /script/module. Current support:
#       + bruteforce    functions relate to bruteforce
#       + crypto        functions relate to cryptography
#       + exploit       functions to support you search and craft payloads for exploitation.
#       + host          functions to use on your host (virtual machine).
#       + machine       functions to use on your real machine (e.g., MacOS).
#       + payload       functions relate to payload.
#       + prep          functions before you start the work.
#       + recon         functions relate to recon.
#       + target        functions relate to the target machine.
#       + workspace     functions to manage cross-terminal session, faster to nagivate.
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

    parse_function() {
        grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$1" | sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/';    
    }

    parse_alias() {
        grep -E '^\s*alias\s+' "$1" | sed -E 's/^\s*alias\s+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/';
    }

    parse_variable() {
        grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$1" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/';
    }
    

    swiss_logger info "[i] Functions:"
    {
        parse_function $swiss_script
        parse_function $swiss_extension
    } | sort | column

    swiss_logger info "[i] Aliases:"
    {
        parse_alias $swiss_extension
        parse_alias $swiss_alias
    } | sort | column
    
    swiss_logger info "[i] Variables:"
    {
        parse_variable $swiss_extension
        parse_variable $swiss_alias
        parse_variable $swiss_script
    } | sort | column

    # load /private scripts
    if [ -d "$swiss_private" ]; then
        for script in "$swiss_private"/*.sh; do
        if [ -f "$script" ]; then

            if grep -qE '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$script"; then
                swiss_logger info "[i] Function under $script:"
                parse_function $script | sort | column
            fi
            
            if grep -qE '^\s*alias\s+' "$script"; then
                swiss_logger info "[i] Aliases under $script:"
                parse_alias $script | sort | column
            fi
            
            if grep -qE '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$script"; then
                swiss_logger info "[i] Variables under $script:"
                parse_variable $script | sort | column
            fi
        fi
        done
    else
        swiss_logger error "[e] Directory $swiss_private not found."
    fi
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