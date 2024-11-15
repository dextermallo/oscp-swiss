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