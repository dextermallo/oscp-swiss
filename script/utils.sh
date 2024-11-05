#!/bin/bash
# About utils.sh
# TODO: Doc


swiss_root="$HOME/oscp-swiss"
swiss_script="$swiss_root/script/oscp-swiss.sh"
swiss_alias="$swiss_root/script/alias.sh"
swiss_extension="$swiss_root/script/extension.sh"

swiss_utils="$swiss_root/utils"
swiss_private="$swiss_root/private"
swiss_wordlist="$swiss_root/wordlist"

swiss_settings="$swiss_root/settings.json"


_log() {
    local bold=""
    local fg_color=""
    local bg_color=""
    local no_color=0
    local text=""
    local underline=""
    local newline=1
    local ansi_bold="\033[1m"
    local ansi_underline="\033[4m"
    local ansi_reset="\033[0m"
    local fg_black="\033[30m"
    local fg_red="\033[31m"
    local fg_green="\033[32m"
    local fg_yellow="\033[33m"
    local fg_blue="\033[34m"
    local fg_magenta="\033[35m"
    local fg_cyan="\033[36m"
    local fg_white="\033[37m"
    local bg_black="\033[40m"
    local bg_red="\033[41m"
    local bg_green="\033[42m"
    local bg_yellow="\033[43m"
    local bg_blue="\033[44m"
    local bg_magenta="\033[45m"
    local bg_cyan="\033[46m"
    local bg_white="\033[47m"

    while [ "$1" ]; do
        case "$1" in
            --bold)
                bold=$ansi_bold
                shift
                ;;
            -u|--underline)
                underline=$ansi_underline
                shift
                ;;
            -f|--foreground)
                shift
                case "$1" in
                    black) fg_color=$fg_black ;;
                    red) fg_color=$fg_red ;;
                    green) fg_color=$fg_green ;;
                    yellow) fg_color=$fg_yellow ;;
                    blue) fg_color=$fg_blue ;;
                    magenta) fg_color=$fg_magenta ;;
                    cyan) fg_color=$fg_cyan ;;
                    white) fg_color=$fg_white ;;
                    *) fg_color="" ;;
                esac
                shift
                ;;
            -b|--background)
                shift
                case "$1" in
                    black) bg_color=$bg_black ;;
                    red) bg_color=$bg_red ;;
                    green) bg_color=$bg_green ;;
                    yellow) bg_color=$bg_yellow ;;
                    blue) bg_color=$bg_blue ;;
                    magenta) bg_color=$bg_magenta ;;
                    cyan) bg_color=$bg_cyan ;;
                    white) bg_color=$bg_white ;;
                    *) bg_color="" ;;
                esac
                shift
                ;;
            --no-color)
                no_color=1
                shift
                ;;
            -n|--no-newline)
                newline=0
                shift
                ;;
            *)
                text="$1"
                shift
                ;;
        esac
    done

    if [ "$_swiss_disable_color" = true ]; then

        if [ "$newline" -eq 1 ]; then
            echo -e "$text"
        else
            echo -e -n "$text"
        fi
        
    else

        if [ "$newline" -eq 1 ]; then
            echo -e "${bold}${underline}${fg_color}${bg_color}${text}${ansi_reset}"
        else
            echo -e -n "${bold}${underline}${fg_color}${bg_color}${text}${ansi_reset}"
        fi
    fi
}

check_logger_level() {
    case "$_swiss_logger_level" in
        debug) return 0 ;;
        info) [[ "$1" != "debug" ]] ;;
        warn) [[ "$1" == "warn" || "$1" == "error" ]] ;;
        error) [[ "$1" == "error" ]] ;;
        *) return 1 ;;
    esac
}

function swiss_logger() {
    case "$1" in
        debug)
            check_logger_level "debug" && _log -f white "$@"
            ;;
        info)
            check_logger_level "info" && _log -f green "$@"
            ;;
        warn)
            check_logger_level "warn" && _log -f yellow "$@"
            ;;
        error)
            check_logger_level "error" && _log --bold -f red "$@"
            ;;
        prompt)
            # prompt must be display in any given level
            check_logger_level "error" && _log -f green "$@"
            ;;
        hint)
            _log -f cyan "$@"
            ;;
        alternative)
            _log -f magenta "$@"
            ;;
        highlight)
            _log --bold -f white -b red "$@"
            ;;
        *)
            echo -n "$@"
            ;;
    esac
}

load_private_scripts() {
    if [ -d "$swiss_private" ]; then
        for script in "$swiss_private"/*.sh; do
            if [ -f "$script" ]; then
                source "$script"
            fi
        done
    else
        swiss_logger error "[e] Directory $swiss_private not found."
    fi
}

# Description: Simplified version of the `ip` command to show the IP address of the default network interface.
# TODO: move to oscp-swiss.sh
function i() {
    ip -o -f inet addr show | awk '{printf "%-6s: %s\n", $2, $4}'
}

# Description: Get the default network interface's IP address and copy it to the clipboard.
function gi() {
    swiss_logger info "[i] get default network interface's IP address"
    ip -o -f inet addr show | grep $_swiss_default_network_interface | awk '{split($4, a, "/"); printf "%s", a[1]}' | xclip -selection clipboard
}

# Description: Get the default network interface's IP address.
function get_default_network_interface_ip() {
    ip -o -f inet addr show | grep $_swiss_default_network_interface | awk '{split($4, a, "/"); printf "%s", a[1]}'
}

# Description:
#   Abbrivation for "set" to set a key-value item in the configuration file.
#   Uses with the function g (abbr for "get"). Works across different terminal sessions.
# Usage: s <key_name> <value>
# Example:
#   $> s next-attempt-url http://localhost
#   and you can use the command g to get it in another terminal session
#   $> g next-attempt-url
function s() {
    local arg_name="$1"
    local arg_value="$2"

    if [[ ! -f $swiss_settings ]]; then
        swiss_logger info "[i] Config file not found, creating one..."
        echo '{"swiss_variable": {}}' > "$swiss_settings"
    fi

    jq --arg name "$arg_name" --arg value "$arg_value" '.swiss_variable[$name] = $value' "$swiss_settings" > "${swiss_settings}.tmp" && mv "${swiss_settings}.tmp" "$swiss_settings"
    swiss_logger info "[i] $arg_name set to: $arg_value"
}

# Description:
#   Abbrivation for "get" to get a key-value item in the configuration file.
#   Uses with the function g (abbr for "set"). Works across different terminal sessions.
# 
# Usage: g <key_name>
# Example:
#   $> s next-attempt-url http://localhost
#   
#   and you can use the command g to get it in another terminal session
#   $> g next-attempt-url
function g() {
    local arg_name="$1"

    if [[ ! -f $swiss_settings ]]; then
        echo -n "-2"
        return
    fi

    local arg_value=$(jq -r --arg name "$arg_name" '.swiss_variable[$name] // empty' "$swiss_settings")

    if [[ -z $arg_value ]]; then
        echo -n "-1"
    else
        # Add underscore in front when outputting the variable
        echo -n "$arg_value"
    fi
}

# Description: Display a banner for commands, which are replaced by aliases.
# Usage: override_cmd_banner
override_cmd_banner() {
    if [ "$disable_sys_custom_command_banner" = false ]; then
        swiss_logger highlight "[ custom command, for default, add the sign _ in front of the command ]\n";
    fi
}

# Description: Display a banner for extension functions.
# Usage: extension_fn_banner
extension_fn_banner() {
    swiss_logger highlight "[ The function may relies on non-native command, binaries, and libraries. You may need to check extension.sh before the run ]\n";
}

# Description:
#   Load the settings from the settings.json file.
#   All the key-value pairs under `{ env }` are exported as environment variables.
#   The settings.json file should be located at $HOME/oscp-swiss/settings.json
# Usage: load_settings
function load_settings() {
    if [ ! -f "$swiss_settings" ]; then
        swiss_logger error "[e] $swiss_settings not found."
        return 1
    fi
    while IFS="=" read -r key value; do
        export "_swiss_$key"="$value"
    done < <(jq -r '.global_settings | to_entries | .[] | "\(.key)=\(.value)"' "$swiss_settings")
    while IFS="=" read -r key value; do
        export "_swiss_$key"="$value"
    done < <(jq -r '.functions | to_entries[] | .key as $k | .value | to_entries[] | "\($k)_\(.key)=\(.value)"' "$swiss_settings")
}

# TODO: doc
check_cmd_exist() {
    if command -v "$1" &> /dev/null
    then
        return 0
    else
        return 1
  fi
}