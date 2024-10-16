#!/bin/bash

source $HOME/oscp-swiss/.env

DISABLE_COLOR=0

log() {
    local bold=""
    local fg_color=""
    local bg_color=""
    local no_color=0
    local text=""
    local underline=""

    # Define ANSI color codes using basic variables
    local ansi_bold="\033[1m"
    local ansi_underline="\033[4m"
    local ansi_reset="\033[0m"

    # Define color codes for foreground
    local fg_black="\033[30m"
    local fg_red="\033[31m"
    local fg_green="\033[32m"
    local fg_yellow="\033[33m"
    local fg_blue="\033[34m"
    local fg_magenta="\033[35m"
    local fg_cyan="\033[36m"
    local fg_white="\033[37m"

    # Define color codes for background
    local bg_black="\033[40m"
    local bg_red="\033[41m"
    local bg_green="\033[42m"
    local bg_yellow="\033[43m"
    local bg_blue="\033[44m"
    local bg_magenta="\033[45m"
    local bg_cyan="\033[46m"
    local bg_white="\033[47m"

    # Parse arguments
    while [ "$1" ]; do
        case "$1" in
            -bold)
                bold=$ansi_bold
                shift
                ;;
            --underline)
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
                    *) fg_color="" ;;  # Default: no color
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
                    *) bg_color="" ;;  # Default: no color
                esac
                shift
                ;;
            --no-color)
                no_color=1
                shift
                ;;
            *)
                text="$1"
                shift
                ;;
        esac
    done

    # Print the text with or without colors based on --no-color flag
    if [ "$DISABLE_COLOR" -eq 1 ]; then
        echo -e "$text"
    else
        echo -e "${bold}${underline}${fg_color}${bg_color}${text}${ansi_reset}"
    fi
}

logger() {
    case "$1" in
        info)
            log -f green "$@"
            ;;
        warn)
            log --bold --underline -f yellow "$@"
            ;;
        error)
            log --bold -f red "$@"
            ;;
        green-banner)
            log --bold -f black -b green "$@"
            ;;
        yellow-banner)
            log --bold -f black -b yellow "$@"
            ;;
        red-banner)
            log --bold -f white -b red "$@"
            ;;
        *)
            echo -n "$@"
            ;;
    esac
}

load_private_scripts() {
  local script_dir="$HOME/oscp-swiss/private"
  if [ -d "$script_dir" ]; then
    for script in "$script_dir"/*.sh; do
      if [ -f "$script" ]; then
        source "$script"
      fi
    done
  else
    echo "Directory $script_dir not found."
  fi
}

generate_random_filename() {
    # Generate a random 6-character alphanumeric string
    echo "$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)"
}

# list ip address
function i() {
    ip -o -f inet addr show | awk '{printf "%-6s: %s\n", $2, $4}'
}

# get default interface IPv4
function gi() {
    logger info "[i] get default network interface's IP address"
    ip -o -f inet addr show | grep $DEFAULT_NETWORK_INTERFACE | awk '{split($4, a, "/"); printf "%s", a[1]}' | xclip -selection clipboard
}

function get_default_network_interface_ip() {
    ip -o -f inet addr show | grep $DEFAULT_NETWORK_INTERFACE | awk '{split($4, a, "/"); printf "%s", a[1]}'
}

# Description:
#   Abbrivation for "set" to set a key-value item in the configuration file.
#   Uses with the function g (abbr for "get"). Works across different terminal sessions.
# 
# Usage: s <key_name> <value>
# Example:
#   s next-attempt-url http://localhost
#   
#   and you can use the command g to get it in another terminal session
#   g next-attempt-url
function s() {
    local config_file="$HOME/oscp-swiss/settings.json"
    local arg_name="$1"
    local arg_value="$2"

    if [[ ! -f $config_file ]]; then
        logger info "[i] Config file not found, creating one..."
        echo "{}" > "$config_file"
    fi

    jq --arg name "$arg_name" --arg value "$arg_value" '.[$name] = $value' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
    logger info "[i] $arg_name set to: $arg_value"
}

# Description:
#   Abbrivation for "get" to get a key-value item in the configuration file.
#   Uses with the function g (abbr for "set"). Works across different terminal sessions.
# 
# Usage: g <key_name>
# Example:
#   s next-attempt-url http://localhost
#   
#   and you can use the command g to get it in another terminal session
#   g next-attempt-url
function g() {
    local config_file="$HOME/oscp-swiss/settings.json"
    local arg_name="$1"

    if [[ ! -f $config_file ]]; then
        echo -n "-2"
        return
    fi

    local arg_value=$(jq -r --arg name "$arg_name" '.[$name] // empty' "$config_file")

    if [[ -z $arg_value ]]; then
        echo -n "-1"
    else
        echo -n $arg_value
    fi
}

# internal func
custom_cmd_banner() {
    logger warn "[ custom command, for default, add the sign _ in front of the command ]\n";
}

load_credential() {
    local settings_file="$HOME/oscp-swiss/settings.json"

    if [ ! -f "$settings_file" ]; then
        logger error "$settings_file not found."
        return 1
    fi

    while IFS="=" read -r key value; do
        export "$key"="$value"
    done < <(jq -r '.env | to_entries | .[] | "\(.key)=\(.value)"' "$settings_file")

    echo "Environment variables loaded successfully."
}