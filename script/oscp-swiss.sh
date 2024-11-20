#!/bin/bash
# About oscp-swiss.sh
# The oscp-swiss.sh is the main script that contains the main functions to support the OSCP exam.
# It loads all the modues under the script/module directory and other ncessary scripts.


source $HOME/oscp-swiss/script/utils.sh
source $HOME/oscp-swiss/script/alias.sh
source $HOME/oscp-swiss/script/extension.sh

# Description: Find the commands, aliases, or variable you need.
# Usage: swiss [-h|--help] <module>
# Arguments:
#   - module: see /script/module. Current support:
#     + bruteforce    functions relate to bruteforce
#     + crypto        functions relate to cryptography
#     + exploit       functions to support you search and craft payloads for exploitation.
#     + host          functions to use on your host (virtual machine).
#     + machine       functions to use on your real machine (e.g., MacOS).
#     + payload       functions relate to payload.
#     + prep          functions before you start the work.
#     + recon         functions relate to recon.
#     + target        functions relate to the target machine.
#     + workspace     functions to manage cross-terminal session, faster to nagivate.
#     + private       all scripts (.sh) under the directory /private
# Configuration:
#   - global_settings.app_banner: true/false. Show the banner of the app.
# Example:
#   swiss bruteforce
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

    parse() {
        if grep -qE '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$1"; then
            swiss_logger info "[i] Function under $1:"
            swiss_logger hint "[i] Check function instructions with <command> -h or which <command>"
            grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$1" | sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/' | sort | column
        fi
        if grep -qE '^\s*alias\s+' "$1"; then
            swiss_logger info "[i] Alias under $1:"
            grep -E '^\s*alias\s+' "$1" | sed -E 's/^\s*alias\s+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column
        fi
        if grep -qE '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$1"; then
            swiss_logger info "[i] Variable under $1:"
            grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$1" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column
        fi
    }

    [ $_swiss_app_banner = true ] && _banner

    local module

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                _help
                return 0
                ;;
            *)
                module=$1
                shift
                ;;
        esac
    done

    case $module in
        private)
        if [ -d "$swiss_private" ]; then
            for script in "$swiss_private"/*.sh; do
                [ -f "$script" ] && parse $script
            done
        else
            swiss_logger error "[e] Directory $swiss_private not found."
        fi
        ;;
        utils|alias|extension)
            parse "$swiss_script/$module.sh"
        ;;
        bruteforce|crypto|exploit|host|machine|payload|prep|recon|target|workspace)
            parse "$swiss_script/module/$module.sh"
        ;;
        *)
            swiss_logger error "[e] invalid modules. see -h, --help."
        ;;
    esac
}

source $swiss_module/bruteforce.sh
source $swiss_module/crypto.sh
source $swiss_module/help-exploit.sh
source $swiss_module/host.sh
source $swiss_module/payload.sh
source $swiss_module/prep.sh
source $swiss_module/recon.sh
source $swiss_module/target.sh
source $swiss_module/workspace.sh

spawn_session_in_workspace