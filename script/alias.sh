#!/bin/bash

source $HOME/oscp-swiss/script/utils.sh
load_settings

alias grep="grep --color=auto"
alias diff="diff --color=auto"

# Description:
#   Extended cd function with `-` and file support
#   If no argument is given, it will change to the home directory
#   If `-` is given, it will change to the previous directory
#   If a file is given, it will change to the directory of the file
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
        echo "cd: no such file or directory: $1"
        return 1
    fi
}

# Description:
#   Replace the default argument of the command xfreerdp
#   The default argument is to:
#       1. ignore the certificate
#       2. set the resolution to your preferred screen resolution
#       3. mount to the current directory
alias _xfrredp="/usr/bin/xfreerdp"
alias xfreerdp="override_cmd_banner; mkdir xfreerdp-data; xfreerdp /drive:$PWD,/xfreerdp-data /cert-ignore /w:$XFREERDP_WIDTH"

# Description:
#   Replace the default argument of the command wpscan
#   The default argument is to:
#       1. enumerate users, plugins, and themes
#       2. use aggressive plugin detection
#       3. use the WPSCAN_API_TOKEN environment variable (optional)
alias _wpscan="/usr/bin/wpscan"
alias wpscan="override_cmd_banner; wpscan --enumerate ap,at,u --plugins-detection aggressive --api-token $WP_TOKEN"

# Description:
#   Replace the default argument of the command cat
#   The default argument is to:
#       1. display the content of the file with color under dark-mode Kali.
# Reference: https://stackoverflow.com/questions/62546404/how-to-use-dracula-theme-as-a-style-in-pygments
alias _cat="/usr/bin/cat"
alias cat="override_cmd_banner; pygmentize -P style=dracula -g"

############
# wordlist #
############
wordlist_path=$WORDLIST_BASE
custom_wordlist_path=$HOME/oscp-swiss/wordlist

### directory & files
wordlist_dirsearch="$WORDLIST_BASE/seclists/Discovery/Web-Content/dirsearch.txt"
wordlist_dirb_commn="$WORDLIST_BASE/dirb/common.txt"
wordlist_raft_directory_big="$WORDLIST_BASE/seclists/Discovery/Web-Content/raft-large-directories.txt"
wordlist_raft_file_big="$WORDLIST_BASE/seclists/Discovery/Web-Content/raft-large-files.txt"

### subdomain
wordlist_subdomain_amass_small="$WORDLIST_BASE/amass/subdomains-top1mil-20000.txt"
wordlist_subdomain_amass_big="$WORDLIST_BASE/amass/subdomains-top1mil-110000.txt"
wordlist_subdomain_dirb="$WORDLIST_BASE/dirbuster/directory-list-2.3-medium.txt"
wordlist_subdomain_top="$WORDLIST_BASE/Discovery/DNS/subdomains-top1million-110000.txt"

### username & password
wordlist_username_big="$WORDLIST_BASE/seclists/Usernames/xato-net-10-million-usernames.txt"
wordlist_username_small="$WORDLIST_BASE/seclists/Usernames/top-usernames-shortlist.txt"
wordlist_rockyou="$WORDLIST_BASE/rockyou.txt"
wordlist_credential_small="$custom_wordlist_path/custom-default-credential-list.txt"

# api
wordlist_api_obj="$WORDLIST_BASE/seclists/Discovery/Web-Content/api/objects.txt"
wordlist_api_res="$WORDLIST_BASE/seclists/Discovery/Web-Content/api/api-endpoints-res.txt"

### specific
wordlist_snmp_community_string="$WORDLIST_BASE/seclists/Discovery/SNMP/common-snmp-community-strings-onesixtyone.txt"
wordlist_lfi="$WORDLIST_BASE/IntruderPayloads/FuzzLists/lfi.txt"

## hashcat
wordlist_hashcat_rules="/usr/share/hashcat/rules"
wordlist_hashcat_rule_best64="/usr/share/hashcat/rules/best64.rule"

# sqli
wordlist_sqli="$WORDLIST_BASE/custom-sqli.txt"

# traversal
wordlist_traversal="$WORDLIST_BASE/IntruderPayloads/FuzzLists/traversal.txt"

###########
# windows #
###########
windows_path="/usr/share/windows-resources"
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
hasncat_potfile_path="~/.local/share/hashcat/hashcat.potfile"
nmap_scripts_path="/usr/share/nmap/scripts"
swiss_utils="$HOME/oscp-swiss/utils"
swiss_script="$HOME/oscp-swiss/script/oscp-swiss.sh"
swiss_alias="$HOME/oscp-swiss/script/alias.sh"