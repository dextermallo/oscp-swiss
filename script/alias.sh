#!/bin/bash
# About alias.sh
# alias.sh is a collection of alias commands that are used across the oscp-swiss scripts.
# The functions under alias.sh are the default commands that are replaced with the custom commands.


alias grep="grep --color=auto"
alias diff="diff --color=auto"

# Description:
#   Extended cd function with `-` and file support
#   - If no argument is given, it will change to the home directory
#   - If `-` is given, it will change to the previous directory
#   - If a file is given, it will change to the directory of the file
function cd() {
    if [ $# -eq 0 ]; then
        builtin cd
    elif [ "$1" == "-" ]; then
        builtin cd "$OLDPWD" && pwd
    elif [ -d "$1" ]; then
        builtin cd "$1"
    elif [ -e "$1" ]; then
        builtin cd "$(dirname "$1")"
    else
        swiss_logger error "[e] cd: no such file or directory: $1"
        return 1
    fi
}

# Description:
#   Replace the default argument of the command xfreerdp. The default argument is to:
#   1. ignore the certificate
#   2. set the resolution to your preferred screen resolution
#   3. mount to the current directory (optional)
#   4. set a preferred screen resolution (dynamic/full/half)
# Usage: xfreerdp [-h, --help] [-m, --mode mode]
# Arguments:
#   [-m, --mode mode]: dynamic, full, half
# Configuration:
#   - function.xfreerdp.use_custom_xfreerdp <boolean>: Use the custom xfreerdp function
#   - function.xfreerdp.prompt_create_mount <boolean>: Prompt to create a mount
#   - function.xfreerdp.create_mount_by_default <boolean>: Create a mount by default
#   - function.xfreerdp.default_mode <string>: Default mode (dynamic/full/half)
#   - function.xfreerdp.full_width <integer>: Full width resolution
#   - function.xfreerdp.half_width <integer>: Half width resolution
#   - function.xfreerdp.full_height <integer>: Full height resolution
#   Example:
#       xfreerdp -m dynamic /u:username /p:password /v:$target
#       xfreerdp -m full /u:username /p:password /v:$target
function _xfreerdp_default() {
    _override_cmd_banner
    local create_mount=$_swiss_xfreerdp_create_mount_by_default
    local mode=$_swiss_xfreerdp_default_mode
    local new_args=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mode) mode="$2" && shift 2 ;;
            -h|--help) swiss_logger warn "[w] For built-in xfreerdp, check \\\xfreerdp" && _help && return 0 ;;
            *) new_args+=("$1") && shift ;;
        esac
    done
    if [ "$_swiss_xfreerdp_prompt_create_mount" = true ]; then
        swiss_logger prompt "[i] Mount? (y/n) \c"
        read -r user_input

        if [ "$user_input" = "y" ]; then
            create_mount=true
        elif [ "$user_input" = "n" ]; then
            create_mount=false
        else
            swiss_logger error "[e] Invalid input. Please enter 'y' or 'n'." && return 1
        fi
    fi
    swiss_logger debug "[d] create_mount: $create_mount"
    swiss_logger debug "[d] mode: $mode"
    if [ $create_mount = true ]; then
        mkdir -p xfreerdp-data
        case "$mode" in
            dynamic)
                \xfreerdp /drive:xfreerdp-data,$PWD/xfreerdp-data /cert-ignore /dynamic-resolution ${new_args[@]}
            ;;
            full)
                \xfreerdp /drive:xfreerdp-data,$PWD/xfreerdp-data /cert-ignore /w:$_swiss_xfreerdp_full_width /h:$_swiss_xfreerdp_full_height ${new_args[@]}
            ;;
            half)
                \xfreerdp /drive:xfreerdp-data,$PWD/xfreerdp-data /cert-ignore /w:$_swiss_xfreerdp_half_width /h:$_swiss_xfreerdp_full_height ${new_args[@]}
            ;;
            *)
                swiss_logger error "[e] Unsupported mode (dynamic/full/half)."
            ;;
        esac
    else
        case "$mode" in
            dynamic)
                \xfreerdp /cert-ignore /dynamic-resolution ${new_args[@]}
            ;;
            full)
                \xfreerdp /cert-ignore /w:$_swiss_xfreerdp_full_width /h:$_swiss_xfreerdp_full_height ${new_args[@]}
            ;;
            half)
                \xfreerdp /cert-ignore /w:$_swiss_xfreerdp_half_width /h:$_swiss_xfreerdp_full_height ${new_args[@]}
            ;;
            *)
                swiss_logger error "[e] Unsupported mode (dynamic/full/half)."
            ;;
        esac
    fi
}

if [[ $_swiss_xfreerdp_use_custom_xfreerdp = true ]]; then
    alias xfreerdp=_xfreerdp_default
fi

# Description:
#   Replace the default argument of the command wpscan. The default argument is to:
#   1. enumerate users, plugins, and themes
#   2. use aggressive plugin detection
#   3. use the WPSCAN_API_TOKEN environment variable (optional)
#   You can request a free API token from https://wpscan.com/api
# Configuration:
#   - function.wpscan.wpscan_token <string>: WPScan API token
alias wpscan="_override_cmd_banner; \wpscan --enumerate ap,at,u --plugins-detection aggressive --api-token $_swiss_wpscan_token"

# Description: Use pygmentize to display the content of the file with color under dark-mode Kali.
# Configuration:
#   - function.cat.use_pygmentize <boolean>: feature flag to use pygmentize
# Reference: https://stackoverflow.com/questions/62546404/how-to-use-dracula-theme-as-a-style-in-pygments
if [[ $_swiss_cat_use_pygmentize = true ]]; then
    alias cat="_override_cmd_banner; pygmentize -P style=dracula -g"
fi

# Description: Use the nnn file manager as the default file manager
# Configuration:
#   - function.ls.use_nnn <boolean>: feature flag to use nnn
# References:
#   - https://github.com/jarun/
#   - https://software.opensuse.org//download.html?project=home%3Astig124%3Annn&package=nnn
if [[ $_swiss_ls_use_nnn = true ]]; then
    alias l="\ls"
    alias ls="n -dEH"
fi

############
# wordlist #
############
### directory & files
wordlist_dirsearch="$_swiss_wordlist_base/seclists/Discovery/Web-Content/dirsearch.txt"
wordlist_dirb_commn="$_swiss_wordlist_base/dirb/common.txt"
wordlist_raft_directory_big="$_swiss_wordlist_base/seclists/Discovery/Web-Content/raft-large-directories.txt"
wordlist_raft_file_big="$_swiss_wordlist_base/seclists/Discovery/Web-Content/raft-large-files.txt"

### subdomain
wordlist_subdomain_amass_small="$_swiss_wordlist_base/amass/subdomains-top1mil-20000.txt"
wordlist_subdomain_amass_big="$_swiss_wordlist_base/amass/subdomains-top1mil-110000.txt"
wordlist_subdomain_dirb="$_swiss_wordlist_base/dirbuster/directory-list-2.3-medium.txt"
wordlist_subdomain_top="$_swiss_wordlist_base/Discovery/DNS/subdomains-top1million-110000.txt"

### username & password
wordlist_username_big="$_swiss_wordlist_base/seclists/Usernames/xato-net-10-million-usernames.txt"
wordlist_username_medium="$_swiss_wordlist_base/dirb/others/names.txt"
wordlist_username_small="$_swiss_wordlist_base/seclists/Usernames/top-usernames-shortlist.txt"
wordlist_rockyou="$_swiss_wordlist_base/rockyou.txt"

# api
wordlist_api_obj="$_swiss_wordlist_base/seclists/Discovery/Web-Content/api/objects.txt"
wordlist_api_res="$_swiss_wordlist_base/seclists/Discovery/Web-Content/api/api-endpoints-res.txt"

### specific
wordlist_snmp_community_string="$_swiss_wordlist_base/seclists/Discovery/SNMP/common-snmp-community-strings-onesixtyone.txt"
wordlist_lfi="$_swiss_wordlist_base/IntruderPayloads/FuzzLists/lfi.txt"

## hashcat
wordlist_hashcat_rules="/usr/share/hashcat/rules"
wordlist_hashcat_rule_best64="/usr/share/hashcat/rules/best64.rule"

# traversal
wordlist_traversal="$_swiss_wordlist_base/IntruderPayloads/FuzzLists/traversal.txt"

###########
# windows #
###########
windows_resource="/usr/share/windows-resources"
windows_powercat='/usr/share/powershell-empire/empire/server/data/module_source/management/powercat.ps1'
windows_powerup='/usr/share/windows-resources/powersploit/Privesc/PowerUp.ps1'
windows_powerview='/usr/share/windows-resources/powersploit/Recon/PowerView.ps1'

#########
# linux #
#########
linux_privesc="/usr/bin/unix-privesc-check"

########
# disc #
########
hasncat_potfile_path="$HOME/.local/share/hashcat/hashcat.potfile"
nmap_scripts_path="/usr/share/nmap/scripts"
payload_backdoor="/usr/share/davtest/backdoors"
