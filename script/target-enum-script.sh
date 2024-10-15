DISABLE_COLOR=0

function log() {
    local bold=""
    local fg_color=""
    local bg_color=""
    local no_color=0
    local text=""
    local ansi_bold="\033[1m"
    local ansi_reset="\033[0m"
    local fg_black="\033[30m"
    local fg_red="\033[31m"
    local fg_green="\033[32m"
    local fg_yellow="\033[33m"
    local fg_blue="\033[34m"
    local fg_magenta="\033[35m"
    local fg_cyan="\033[36m"
    local fg_white="\033[37m"
    local bg_black="\033[40m"
    local bg_red="\033[41m"
    local bg_green="\033[42m"
    local bg_yellow="\033[43m"
    local bg_blue="\033[44m"
    local bg_magenta="\033[45m"
    local bg_cyan="\033[46m"
    local bg_white="\033[47m"
    while [ "$1" ]; do
        case "$1" in
            -bold)
                bold=$ansi_bold
                shift
                ;;
            -f|--foreground)
                shift
                case "$1" in
                    black) fg_color=$fg_black ;;
                    red) fg_color=$fg_red ;;
                    green) fg_color=$fg_green ;;
                    yellow) fg_color=$fg_yellow ;;
                    blue) fg_color=$fg_blue ;;
                    magenta) fg_color=$fg_magenta ;;
                    cyan) fg_color=$fg_cyan ;;
                    white) fg_color=$fg_white ;;
                    *) fg_color="" ;;  # Default: no color
                esac
                shift
                ;;
            -b|--background)
                shift
                case "$1" in
                    black) bg_color=$bg_black ;;
                    red) bg_color=$bg_red ;;
                    green) bg_color=$bg_green ;;
                    yellow) bg_color=$bg_yellow ;;
                    blue) bg_color=$bg_blue ;;
                    magenta) bg_color=$bg_magenta ;;
                    cyan) bg_color=$bg_cyan ;;
                    white) bg_color=$bg_white ;;
                    *) bg_color="" ;;  # Default: no color
                esac
                shift
                ;;
            --no-color)
                no_color=1
                shift
                ;;
            *)
                text="$1"
                shift
                ;;
        esac
    done
    if [ "$DISABLE_COLOR" -eq 1 ]; then
        echo -e "$text"
    else
        echo -e "${bold}${fg_color}${bg_color}${text}${ansi_reset}"
    fi
}

function check() {
    if [ "$2" = "--no-color" ]; then
        DISABLE_COLOR=1
    else
        DISABLE_COLOR=0
    fi
    case "$1" in
        1|user|u)
            clear 2>/dev/null
            log --bold -f red "=== User Info ===\n"
            log --bold -f yellow "[i] id:"
            id
            log --bold -f yellow "\n[i] hostname:"
            hostname
            log --bold -f yellow "\n[i] All users (from /etc/passwd):"
            cut -d: -f1 /etc/passwd | sort -r | column
            log --bold -f yellow "\n[i] Super users (from /etc/passwd):"
            grep -v -E "^#" /etc/passwd | awk -F: '$3 == 0 { print $1 }' | column
            ;;
        2|su)
            clear 2>/dev/null
            log --bold -f red "=== Easy Su===\n"
            log --bold -f yellow "[i] manual test for 'sudo -l' and 'su - root'"

            # Disabled
            # printf "\n[i] check if brute-focrable\n"
            # EXISTS_SU="$(command -v su 2>/dev/null)"; error=$(echo "" | timeout 1 su $(whoami) -c whoami 2>&1); [ "$EXISTS_SU" ] && ! echo "$error" | grep -q "must be run from a terminal" && echo "non-brute-forcable" || echo "brute-forcable"
            ;;
        3|suid)
            clear 2>/dev/null;
            log --bold -f red "=== SUID/SGID ==="
            log --bold -f yellow "[i] SUID:\n"
            
            local suid_keywords=("aa-exec" "ab" "agetty" "alpine" "ar" "arj" "arp" "as" "ascii-xfr" "ash" "aspell" "atobm" "awk" "base32" "base64" "basenc" "basez" "bash" "bc" "bridge" "busctl" "busybox" "bzip2" "cabal" "capsh" "cat" "chmod" "choom" "chown" "chroot" "clamscan" "cmp" "column" "comm" "cp" "cpio" "cpulimit" "csh" "csplit" "csvtool" "cupsfilter" "curl" "cut" "dash" "date" "dd" "debugfs" "dialog" "diff" "dig" "distcc" "dmsetup" "docker" "dosbox" "ed" "efax" "elvish" "emacs" "env" "eqn" "espeak" "expand" "expect" "file" "find" "fish" "flock" "fmt" "fold" "gawk" "gcore" "gdb" "genie" "genisoimage" "gimp" "grep" "gtester" "gzip" "hd" "head" "hexdump" "highlight" "hping3" "iconv" "install" "ionice" "ip" "ispell" "jjs" "join" "jq" "jrunscript" "julia" "ksh" "ksshell" "kubectl" "ld.so" "less" "links" "logsave" "look" "lua" "make" "mawk" "minicom" "more" "mosquitto" "msgattrib" "msgcat" "msgconv" "msgfilter" "msgmerge" "msguniq" "multitime" "mv" "nasm" "nawk" "ncftp" "nft" "nice" "nl" "nm" "nmap" "node" "nohup" "ntpdate" "od" "openssl" "openvpn" "pandoc" "paste" "perf" "perl" "pexec" "pg" "php" "pidstat" "Command " "pr" "ptx" "python" "rc" "readelf" "restic" "rev" "rlwrap" "rsync" "rtorrent" "run-parts" "rview" "rvim" "sash" "scanmem" "sed" "setarch" "setfacl" "setlock" "shuf" "soelim" "softlimit" "sort" "sqlite3" "ss" "ssh-agent" "ssh-keygen" "Library load " "ssh-keyscan" "sshpass" "start-stop-daemon" "stdbuf" "strace" "strings" "sysctl" "systemctl" "tac" "tail" "taskset" "tbl" "tclsh" "tee" "terraform" "tftp" "tic" "time" "timeout" "troff" "ul" "unexpand" "uniq" "unshare" "unsquashfs" "unzip" "update-alternatives" "uudecode" "uuencode" "vagrant" "varnishncsa" "view" "vigr" "vim" "vimdiff" "vipw" "w3m" "watch" "wc" "wget" "whiptail" "xargs" "xdotool" "xmodmap" "xmore" "xxd" "xz" "yash" "zsh" "zsoelim")

            is_keyword_present() {
                local file="$1"
                local filename=$(basename "$file")
                for keyword in "${suid_keywords[@]}"; do
                    if [[ "$filename" == "$keyword" ]]; then
                        return 0
                    fi
                done
                return 1
            }

            find / -perm -u=s -type f 2>/dev/null | while read -r file; do
                if is_keyword_present "$file"; then
                    log --bold -f red "$file"
                else
                    log "$file"
                fi
            done

            log --bold -f yellow "\n[i] SGID:\n"

            find / -perm -g=s -type f 2>/dev/null
            ;;
        4|cerd-file)
            clear 2>/dev/null
            log --bold -f red "=== Credential Files ===\n"
            log --bold -f yellow "[i] permission:\n"
            ls -ln /etc/passwd /etc/shadow /etc/sudoers /etc/group
            log --bold -f yellow "\n[i] /etc/passwd:\n"
            cat /etc/passwd
            log --bold -f yellow "\n[i] /etc/shadow:\n"
            cat /etc/shadow
            log --bold -f yellow "\n[i] /etc/sudoers:\n"
            cat /etc/sudoers
            log --bold -f yellow "\n[i] /etc/group:\n"
            cat /etc/group | column
            log --bold -f yellow "\n[i] ssh file:\n"
            for user_dir in /home/*; do [ -d "$user_dir/.ssh" ] && echo "found: $user_dir/.ssh"; done
            ;;
        5|exec|executable)
            clear 2>/dev/null
            log --bold -f red "=== Executables ===\n"
            log --bold -f yellow "\n[i] *.sh files (executables for the current user will be marked in red)"
            for file in $(find / -type f -name "*.sh" 2>/dev/null); do
                file_details=$(ls -l "$file")
                if [[ -x "$file" ]]; then
                    log --bold -f red "$file_details"
                else
                    log "$file_details"
                fi
            done
            ;;
        6|directory|dir)
            clear 2>/dev/null
            log --bold -f red "=== Interessting Directories ===\n"
            log --bold -f yellow "[i] / \n"
            ls -al / 2>/dev/null
            
            log --bold -f yellow "[i] /mnt \n"
            ls -al /mnt 2>/dev/null

            log --bold -f yellow "\n[i] /tmp \n"
            ls -al /tmp 2>/dev/null

            log --bold -f yellow "\n [i] /opt \n"
            ls -al /opt 2>/dev/null
            
            log --bold -f yellow "\n[i] /home \n"
            ls -laR /home 2>/dev/null

            log --bold -f yellow "\n[i] /var/spool/mail \n"
            ls -laR /var/spool/mail 2>/dev/null            
            ;;
        7|os)
            clear 2>/dev/null
            log --bold -f red "=== OS ===\n"
            log --bold -f yellow "[i] /etc/*-release:\n"
            cat /etc/*-release
            log --bold -f yellow "\n[i] uname:\n"
            uname -ar
            log --bold -f yellow "\n[i] lsb_release:\n"
            lsb_release -a
            ;;
        8|ps|proc|process)
            clear 2>/dev/null
            log --bold -f red "=== Process ===\n"
            log --bold -f red "[i] some processes may not be visible, should try pspy as well\n"
            ps auxfww
            ;;
        9|cron|crontab)
            clear 2>/dev/null
            log --bold -f red "=== CRON JOB ===\n"
            log --bold -f red "[i] Root CRON JOB may not be visible, should try pspy as well\n"
            cat /etc/crontab
            crontab -l
            ;;
        10|net|network)
            clear 2>/dev/null
            log --bold -f red "=== Network ===\n"
            log --bold -f yellow "[i] ip addr\n"
            ip addr
            log --bold -f yellow "[i] ss -tulpn\n"
            ss -tulpn
            ;;
        11|dir-filename)
            clear 2>/dev/null
            log --bold -f red "=== Interesting filename under the current directory ===\n"
            ignore_list=("./usr/src/*" "./var/lib/*" "./etc/*" "./usr/share/*" "./snap/*" "./sys/*" "./usr/lib/*" "./usr/bin/*" "./run/*" "./boot/*" "./usr/sbin/*" "./proc/*" "./var/snap/*")
            search_items=("*.txt" "*.sqlite" "*conf*" "*data*" "*.pdf" "*.apk" "*.cfg" "*.json" "*.ini" "*.log" "*.sh" "*password*" "*cred*" "*.env" "config" "HEAD")

            find_command="find . -type f"

            for ignore in "${ignore_list[@]}"; do
            find_command+=" \( -path \"$ignore\" -prune \) -o"
            done

            find_command+=" \("
            for item in "${search_items[@]}"; do
            find_command+=" -name \"$item\" -o"
            done

            find_command="${find_command% -o} \) -type f -print 2>/dev/null"

            eval "$find_command"
            ;;
        12|dir-file)
            clear 2>/dev/null
            log --bold -f red "=== Interesting file content under the current directory ===\n"
            
            log --bold -f yellow "\n[i] files contains keywords\n"
            grep -Erl "(user|username|login|pass|passwd|password|pw|credentials|flag|local|proof|db_username|db_passwd|db_password|db_user|db_host|database|api_key|api_token|access_token|private_key|jwt|auth_token|bearer|ssh_pass|ssh_key|identity_file|id_rsa|id_dsa|authorized_keys|env|environment|secret|admin|root)" . 2>/dev/null

            log --bold -f yellow "\n[i] .* files\n"
            find . -type f -name ".*" 2>/dev/null
            ;;
        13|search-filename)
            if [ -z "$1" ]; then
                echo "Usage: search-filename <keyword>"
            return 1
            fi

            echo "Searching for filenames containing '$1':"
            find . -type f -name "*$1*" 2>/dev/null
            ;;
        14|search-file)
            if [ -z "$1" ]; then
                echo "Usage: search-file <keyword>"
                return 1
            fi

            # Search for file contents containing the keyword
            echo "Searching for file contents containing '$1':"
            grep -r --include="*" "$1" . 2>/dev/null
            ;;
        15|env)
            clear
            log --bold -f red "=== Env ===\n"
            log --bold -f yellow "env"
            env
        *)
            log --bold -f green "Usage: check <option>\n"
            log --bold -f green "Options: [user|su|suid|cred-file|directory|os|ps|cron|net|dir-filename|dir-file]\n"
            ;;
    esac
}

clear