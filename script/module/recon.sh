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
            swiss_logger info "[i] Start tcp check. Saved to $saved_file_path/tcp/check"
            nmap -p0-65535 -v $ip -oN $saved_file_path/tcp/check

            local ports=$(grep -oP '^\d+\/\w+' $saved_file_path/tcp/check | awk -F/ '{print $1}' | tr '\n' ',' | sed 's/,$//')
            swiss_logger info "[i] Checking service on ports - $ports. Saved to $saved_file_path/tcp/svc"
            nmap -p$ports -sVC $ip -oN $saved_file_path/tcp/svc

            swiss_logger info "[i] Checking vuln script - $ports. Saved to $saved_file_path/tcp/vuln"
            nmap -p$ports --script vuln $ip -oN $saved_file_path/tcp/vuln
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