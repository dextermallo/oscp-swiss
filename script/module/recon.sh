#!/bin/bash


# Description: Wrapped nmap command with default options
# Usage: nmap_default <IP> [mode]
# Modes: fast (default), tcp, udp, udp-all, stealth
# Example: nmap_default 192.168.1.1
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

    check_service_and_vuln() {
        local data_path=$1

        local ports=$(grep -oP '^\d+\/\w+' $data_path | awk -F/ '{print $1}' | tr '\n' ',' | sed 's/,$//')
        swiss_logger warn "[w] Ports found: $ports."
        swiss_logger info "[i] Checking service on ports. Saved to $data_path-svc"
        nmap -p$ports -sVC $ip -oN $data_path-svc

        swiss_logger info "[i] Checking with nmap vuln script. Saved to $data_path-vuln"
        nmap -p$ports --script vuln $ip -oN $data_path-vuln
    }

    case "$mode" in
        fast)
            # tcp-top-2000
            swiss_logger info "[i] Start quick check. Saved to $saved_file_path/tcp-top-2000"
            nmap -v --top-ports 2000 $ip -oN $saved_file_path/tcp-top-2000
            check_service_and_vuln $saved_file_path/tcp-top-2000

            swiss_logger info "[i] Check UDP top 200 ports. Saved to $saved_file_path/udp-top-200"
            sudo nmap --top-ports 200 -sU -F -v $ip -oN $saved_file_path/udp-top-200

            swiss_logger warn "[w] Remember to run tcp and udp mode for full enumeration"
            ;;
        tcp)
            swiss_logger info "[i] Start tcp check. Saved to $saved_file_path/tcp-full"
            nmap -p0-65535 $ip -oN $saved_file_path/tcp-full
            check_service_and_vuln $saved_file_path/tcp-full
            ;;
        udp)
            swiss_logger info "[i] Start udp check (top 200 ports). Saved to $saved_file_path/udp-top-200"
            sudo nmap --top-ports 200 -sU -F -v $ip -oN $saved_file_path/udp-top-200
            ;;
        udp-all)
            mkdir -p $saved_file_path/udp
            swiss_logger info "[i] Start udp check (all). Saved to $saved_file_path/udp/udp_all"
            sudo nmap -sU -F -v $ip -oN $saved_file_path/udp/udp_all
            ;;
        stealth)
            swiss_logger info "[i] Start stealth nmap. Saved to $saved_file_path/stealth"
            sudo nmap -sS -p0-65535 $ip -oN $saved_file_path/stealth/stealth
            ;;
        *)
            swiss_logger error "[e] Invalid mode '$mode'. Valid modes are: fast, tcp, udp, udp-all, stealth."
            return 1
            ;;
    esac
}

# Description: file traversal fuzzing using ffuf, compatible with original arguments
# Usage: ffuf_traversal [URL] (options)
# Example: ffuf_traversal http://example.com -fc 400
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

# Description: get all urls from a web page
# Usage: get_web_pagelink <url>
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
function get_web_keywords() {
    swiss_logger info "Usage: get_web_keywords <url>"
    cewl -d $_swiss_get_web_keywords_depth -m $_swiss_get_web_keywords_min_word_length -w cewl-wordlist.txt $1
}

# Description: directory fuzzing using fuff, compatible with original arguments
# Usage: ffuf_default [URL/FUZZ] (options)
# Example: ffuf_default http://example.com/FUZZ -fc 400
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
                dirsearch -u $stripped_url -r -R 2
            else
                swiss_logger error "[e] dirsearch is not installed"
            fi
        fi

        ffuf -w $_swiss_ffuf_default_wordlist -recursion -recursion-depth $_swiss_ffuf_default_recursive_depth -u ${@} | tee "$domain_dir/ffuf-default"
    fi
}

passwd_parser() {
    input_file="$1"

    # Validate input file
    if [[ -z "$input_file" ]]; then
        echo "Error: No input file provided!"
        return 1
    fi

    if [[ ! -f "$input_file" ]]; then
        echo "Error: Input file '$input_file' not found!"
        return 1
    fi

    # Use `sed` to replace spaces between entries with newlines
    sed -E 's/ ([^:]+:x:[0-9]+:[0-9]+:)/\n\1/g' "$input_file" > format.passwd

    # Extract usernames (first field before ":") from the formatted data
    cut -d: -f1 format.passwd > format.passwd.users

    echo "Files created:"
    echo "- $(realpath format.passwd) (multi-line formatted output)"
    echo "- $(realpath format.passwd.users) (list of usernames)"
}
