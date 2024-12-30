#!/bin/bash


# Description: Wrapped nmap command with default options
# Usage: recon [-s, --service SERVICE] [-m, --mode MODE] <-i, --ip IP>
# Arguements
# Modes: fast (default), tcp, udp, udp-all, stealth
# Example: recon 192.168.1.1
function recon() {
    _rustscan() {
        local output_path="$(pwd)/reports"
        local use_udp=""
        [[ "$mode" == "udp" ]] && use_udp="--udp"
        mkdir -p $output_path
        _wrap "rustscan -a $target $use_udp | tee $output_path/rustscan-$IP"
    }

    check_service_and_vuln() {
        local data_path=$1
        local ports=$(grep -oP '^\d+\/\w+' $data_path | awk -F/ '{print $1}' | tr '\n' ',' | sed 's/,$//')
        _logger warn "[w] Ports found: $ports."
        _logger info "[i] Checking service on ports. Saved to $data_path-svc"
        _wrap nmap -p$ports -sVC $IP -oN $data_path-svc
        _logger info "[i] Checking with nmap vuln script. Saved to $data_path-vuln"
        _wrap nmap -p$ports --script vuln $IP -oN $data_path-vuln
    }

    _nmap() {
        local saved_file_path="$(pwd)/reports/nmap/$IP"
        _logger info "[i] Creating directory $saved_file_path ..."
        mkdir -p $saved_file_path

        case "$mode" in
            fast)
                recon -s nmap -m tcp-5000 -i $IP && recon -s nmap -m udp-200 -i $IP
                _logger -l important -b "Remember to run tcp and udp mode for full enumeration"
            ;;
            tcp) _wrap nmap -p0-65535 -v $IP -oN $saved_file_path/tcp-full && check_service_and_vuln $saved_file_path/tcp-full ;;
            tcp-5000) _wrap nmap -v --top-ports 5000 $IP -oN $saved_file_path/tcp-top-5000 && check_service_and_vuln $saved_file_path/tcp-top-5000 ;;
            udp-200) _wrap sudo nmap --top-ports 200 -sU -F -v $IP -oN $saved_file_path/udp-top-200 ;;
            udp-all) _wrap sudo nmap -sU -F -v $IP -oN $saved_file_path/udp_all ;;
            stealth) _wrap sudo nmap -sS -p0-65535 $IP -Pn -oN $saved_file_path/stealth ;;
            *) _logger error "[e] Invalid mode '$mode'. Valid modes are: fast, tcp, udp-200, udp-all, stealth." && return 1 ;;
        esac
    }

    local IP=""
    local service="nmap"
    local mode="tcp"

    [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]] && _help && return 0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--ip) IP="$2" && shift 2 ;;
            -s|--service) service="$2" && shift 2 ;;
            -m|--mode) mode="$2" && shift 2 ;;
            *) _help && return 0 ;;
        esac
    done    

    if [[ ! $(_is_ip $IP) ]]; then
        _logger error "[e] invalid ip format" && return 1
    fi

    case "$service" in
        nmap) _nmap ;;
        rustscan) _rustscan ;;
    esac

}

# Description: directory fuzzing by default. compatible with original arguments
# Usage: recon_directory [-h, --help] [-m, --mode MODE] <URL> [OPTIONS]
# Arguments:
#   - MODE: dirsearch | ffuf.
#   - URL: URL endpoints. e.g., http://example.com/FUZZ
#   - OPTIONS: options from ffuf or dirsearch.
# Configuration:
#   - functions.recon_directory.recursive_depth: recursive depth
#   - functions.recon_directory.wordlist: default wordlist
# Example:
#   recon_directory http://example.com/FUZZ -fc 400
#   recon_directory -m dirsearch http://example.com
function recon_directory() {
    _logger debug "[d] Recursive depth: $_swiss_recon_directory_recursive_depth"
    _logger debug "[d] Wordlist: $_swiss_recon_directory_wordlist"

    [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]] && _help && return 0

    local mode="ffuf"
    [[ $1 == '-m' ]] && mode=$2 && shift 2
    
    local domain_dir=$(_create_web_fuzz_report_directory "$1")
    _display_wordlist_statistic $_swiss_recon_directory_wordlist

    case $mode in
        dirsearch)
            [[ ! $(_cmd_is_exist "dirsearch") ]] && _logger error "[e] dirsearch is not installed" && return 1
            _wrap dirsearch -r -R $((_swiss_recon_directory_recursive_depth+1)) -u ${@} -o "$domain_dir/dirsearch-recon"
        ;;
        ffuf)
            _logger hint "[h] You can use -fc 400,403 to make the output clean."
            _wrap ffuf -w $_swiss_recon_directory_wordlist -recursion \
                 -recursion-depth $_swiss_recon_directory_recursive_depth \
                 -c -t 200 \
                 -u ${@} | tee "$domain_dir/ffuf-recon"
        ;;
        *) _logger "[e] Unsupport mode. check -h or --help for instructions." && return 1 ;;
    esac
}

# Description: file traversal fuzzing using ffuf, compatible with original arguments
# Usage: recon_file_traversal [-h, --help] <URL> [options]
#   [!] You may need to try <URL>/FUZZ and <URL>FUZZ
# Arguments:
#   - URL: URL endpoints. e.g., http://example.com/FUZZ
#   - OPTIONS: options from ffuf.
# Configuration:
#   - functions.recon_file_traversal.wordlist: default wordlist
# Example: recon_file_traversal http://example.comFUZZ -fc 403
function recon_file_traversal() {
    [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]] && _help && return 0
    local domain_dir=$(_create_web_fuzz_report_directory "$1")
    _display_wordlist_statistic $_swiss_recon_file_traversal_wordlist
    _wrap ffuf -w $_swiss_recon_file_traversal_wordlist -c -t 200 -u ${@} | tee "$domain_dir/traversal-recon"
}

# Description: subdomain fuzzing using gobuster, compatible with original arguments
# Usage: recon_subdomain [-h, --help] <DOMAIN_NAME> [OPTIONS]
# Arguments:
#   - DOMAIN_NAME: Domain name. e.g., example.com
#   - OPTIONS: options from gobuster.
# Configuration:
#   - functions.recon_subdomain.wordlist: default wordlist
# Example: recon_subdomain example.com
function recon_subdomain() {
    [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]] && _help && return 0
    local domain_dir=$(_create_web_fuzz_report_directory "$1")
    _display_wordlist_statistic $_swiss_recon_subdomain_wordlist
    _wrap gobuster dns -w $_swiss_recon_subdomain_wordlist -t 50 -o $domain_dir/subdomain-recon -d ${@}
}

# Description: vhost fuzzing using gobuster, compatible with original arguments
# Usage: recon_vhost <IP> <DOMAIN_NAME> [OPTIONS]
# Arguments:
#   - IP: IP address
#   - DOMAIN_NAME: Domain name. e.g., example.com
#   - OPTIONS: options from gobuster.
# Configuration:
#   - functions.recon_vhost.wordlist: default wordlist
# Example: recon_vhost 192.168.1.1 example.com
function recon_vhost() {
    [ $# -eq 0 ] && _help && return 0
    local arg_ip="$1"
    local domain="$2"
    local domain_dir=$(_create_web_fuzz_report_directory "$domain")
    _display_wordlist_statistic $_swiss_recon_vhost_wordlist
    _wrap gobuster vhost -k -u $arg_ip --domain $domain --append-domain -r -w $_swiss_recon_vhost_wordlist -o $domain_dir/vhost-recon -t 100
}

# Description: get all urls from a web page
# Usage: get_web_pagelink <url>
function get_web_pagelink() {
    [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]] && _help && return 0
    _logger info "[i] Start extracting all urls from $1. original files will be stored at $PWD/links.txt"
    _logger info "[i] unique links (remove duplicated) will be stored at $PWD/links-uniq.txt"
    
    lynx -dump $1 | awk '/http/{print $2}' > links.txt
    sort -u links.txt > links-uniq.txt
    cat ./links-uniq.txt
}

# Description: get keywords from a web page
# Usage: get_web_keywords <url>
function get_web_keywords() {
    [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]] && _help && return 0
    _wrap cewl -d $_swiss_get_web_keywords_depth -m $_swiss_get_web_keywords_min_word_length --with-numbers -w cewl-wordlist.txt $1
    cat ./cewl-wordlist.txt
}

function _create_web_fuzz_report_directory() {
    local url="$1"
    if [[ "$url" =~ ^https?:// ]]; then
        local domain=$(echo "$url" | awk -F/ '{print $3}')
    else
        local domain=$(echo "$url" | awk -F/ '{print $1}')
    fi
    local domain_dir="$(pwd)/reports/ffuf/$domain"
    mkdir -p "$domain_dir"
    echo $domain_dir
}

function _display_wordlist_statistic() {
    if [[ -f "$1.statistic" ]]; then
        _logger -l warn --no-mark "====== Wordlist Statistic ======"
        \cat $1.statistic
        _logger -l warn  --no-mark "================================"
    fi
}