# Description: bruteforce services
# Usage: bruteforce <-i, --ip IP> <-s, --service ftp|ssh> [-u, --username string|file] [-p, --password string|file] [-P, --port port]
# Example: 
#   ```sh
#   bruteforce -i 192.168.1.1 ssh    
#   ```
# Category: [ recon, brute-force, ftp, ssh, auto-exploit ]
function bruteforce() {
    _disable_auto_exploit_function

    if [ $? -eq 1 ]; then
        return 1
    fi

    local IP
    local service
    local port
    local used_username="$PWD/username.txt"
    local used_password="$PWD/password.txt"

    _helper() {
        swiss_logger info "[i] Usage: hydra_default <-i, --ip IP> <-s, --service ftp|ssh> [-u, --username string|file] [-p, --password string|file] [-P, --port port]"
    }

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--ip)
                IP="$2"
                shift 2
                ;;
            -s|--service)
                service="$2"
                shift 2
                ;;
            -P|--port)
                port="$2"
                shift 2
                ;;
            -u|--username)
                used_username="$2"
                shift 2
                ;;
            -p|--password)
                used_password="$2"
                shift 2
                ;;
            *)
                _helper
                return 0
                ;;
        esac
    done

    swiss_logger debug "[d] service: $service"

    if [[ ! -f "$used_username" && ! -n "$used_username" ]]; then
        swiss_logger error "[e] type of username incorrect. Required: string, files"
    fi

    if [[ ! -f "$used_password" && ! -n "$used_password" ]]; then
        swiss_logger error "[e] type of password incorrect. Required: string, files"
    fi

    case $service in
        ftp)
            local used_port="${port:-21}"

            swiss_logger info "[i] Running hydra_default for FTP"
            swiss_logger info "[i] Run -e nsr with $used_username"

            if [ -f "$used_username" ]; then
                hydra -L $used_username -e nsr -s $used_port ftp://$IP
            elif [ -n "$used_username" ]; then
                hydra -l $used_username -e nsr -s $used_port ftp://$IP
            fi

            swiss_logger info "[i] Run $used_username with $used_password"
            if [ -f "$used_username" ]; then   
                if [ -f "$used_password" ]; then
                    hydra -L $used_username -P $used_password -s $used_port ftp://$IP
                else
                    hydra -L $used_username -p $used_password -s $used_port ftp://$IP
                fi
            elif [ -n "$used_username" ]; then
                if [ -f "$used_password" ]; then
                    hydra -l $used_username -P $used_password -s $used_port ftp://$IP
                else
                    hydra -l $used_username -p $used_password -s $used_port ftp://$IP
                fi
            fi
            ;;
        ssh)
            local used_port="${port:-22}"

            swiss_logger info "[i] Running hydra_default for SSH"
            swiss_logger info "[i] Run -e nsr with $used_username"

            if [ -f "$used_username" ]; then
                hydra -L $used_username -e nsr -s $used_port ssh://$IP
            elif [ -n "$used_username" ]; then
                hydra -l $used_username -e nsr -s $used_port ssh://$IP
            fi

            swiss_logger info "[i] Run $used_username with $used_password"
            if [ -f "$used_username" ]; then
                if [ -f "$used_password" ]; then
                    hydra -L $used_username -P $used_password -s $used_port ssh://$IP
                else
                    hydra -L $used_username -p $used_password -s $used_port ssh://$IP
                fi
            elif [ -n "$used_username" ]; then
                if [ -f "$used_password" ]; then
                    hydra -l $used_username -P $used_password -s $used_port ssh://$IP
                else
                    hydra -l $used_username -p $used_password -s $used_port ssh://$IP
                fi
            fi
            ;;
        smb)
            _wrap "crackmapexec smb $IP -u $used_username -p $used_password"
            ;;
        *)
            swiss_logger error "[e] Port $PORT not recognized or not supported for brute-forcing by this script."
            ;;
    esac
}

# Description: dump files from FTP or SMB service
# Usage: dump <service name> <ip> [service options]
# Arguments:
#   - service name: ftp, smb
#   - ip: IP address of the target machine
# Example:
#   dump ftp $target_ip -u username -p password
#   dump smb $target_ip -s share
# Category: [ ftp, smb, file-transfer ]
# TODO: optimize the logic using flags
function dump() { 
    _help() {
        swiss_logger info "Usage: dump <service name> <ip> [service options]"
        swiss_logger info "* ftp"
        swiss_logger info "\t[optional] -u, --username (default: anonymous)"
        swiss_logger info "\t[optional] -p, --password (default: anonymous)"
        swiss_logger info "* smb"
        swiss_logger info "\t[required] -s, --share"
    }

    local service="$1"
    local ip="$2"
    shift 2;
    if [[ -z "$service" ]] || [[ -z "$ip" ]]; then
        _help
        return 1
    fi

    case "$service" in
        ftp)
            swiss_logger info "[i] dump from FTP"
            local username="anonymous"
            local password="anonymous"
            while [[ $# -gt 0 ]]; do
                case $1 in
                    -u|--username)
                        username="$2"
                        shift 2
                        ;;
                    -p|--password)
                        password="$2"
                        shift 2
                        ;;
                    *)
                        shift 1
                        ;;
                esac
            done
            wget -r --no-passive --no-parent ftp://$username:$password@$ip
            ;;
        smb)
            swiss_logger info "[i] dump from SMB"
            local username=""
            local password=""
            local share=""
            while [[ $# -gt 0 ]]; do
                case $1 in
                    -s|--share)
                        share="$2"
                        shift 2
                        ;;
                    *)
                        shift 1
                        ;;
                esac
            done

            if [[ -z "$share" ]]; then
                _help
                return 1
            fi

            smbclient //$ip/$share -N -c 'prompt OFF;recurse ON;cd; lcd '$PWD';mget *'
            ;;
        *)
            swiss_logger error "[e] Invalid service '$service'. Valid service: ftp, smb"
            return 1
            ;;
    esac
}