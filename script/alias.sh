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
alias xfreerdp="override_cmd_banner; mkdir -p xfreerdp-data; xfreerdp /drive:xfreerdp-data,$PWD/xfreerdp-data /cert-ignore /w:$_swiss_xfreerdp_default_width"

# Description:
#   Replace the default argument of the command wpscan
#   The default argument is to:
#       1. enumerate users, plugins, and themes
#       2. use aggressive plugin detection
#       3. use the WPSCAN_API_TOKEN environment variable (optional)
alias _wpscan="/usr/bin/wpscan"
alias wpscan="override_cmd_banner; wpscan --enumerate ap,at,u --plugins-detection aggressive --api-token $_swiss_wpscan_token"

# Description:
#   Replace the default argument of the command cat
#   The default argument is to:
#       1. display the content of the file with color under dark-mode Kali.
# Reference: https://stackoverflow.com/questions/62546404/how-to-use-dracula-theme-as-a-style-in-pygments

alias _cat="/usr/bin/cat"

if [ $_swiss_cat_use_pygmentize = true ]; then
    alias cat="override_cmd_banner; pygmentize -P style=dracula -g"
fi

alias _ls="ls"

if [ $_swiss_ls_use_nnn = true ]; then
    alias ls="n -dEH"
fi

############
# wordlist #
############
wordlist_path=$_swiss_wordlist_base
custom_wordlist_path=$HOME/oscp-swiss/wordlist

### directory & files
wordlist_dirsearch="$wordlist_path/seclists/Discovery/Web-Content/dirsearch.txt"
wordlist_dirb_commn="$wordlist_path/dirb/common.txt"
wordlist_raft_directory_big="$wordlist_path/seclists/Discovery/Web-Content/raft-large-directories.txt"
wordlist_raft_file_big="$wordlist_path/seclists/Discovery/Web-Content/raft-large-files.txt"

### subdomain
wordlist_subdomain_amass_small="$wordlist_path/amass/subdomains-top1mil-20000.txt"
wordlist_subdomain_amass_big="$wordlist_path/amass/subdomains-top1mil-110000.txt"
wordlist_subdomain_dirb="$wordlist_path/dirbuster/directory-list-2.3-medium.txt"
wordlist_subdomain_top="$wordlist_path/Discovery/DNS/subdomains-top1million-110000.txt"

### username & password
wordlist_username_big="$wordlist_path/seclists/Usernames/xato-net-10-million-usernames.txt"
wordlist_username_small="$wordlist_path/seclists/Usernames/top-usernames-shortlist.txt"
wordlist_rockyou="$wordlist_path/rockyou.txt"
wordlist_credential_small="$custom_wordlist_path/custom-default-credential-list.txt"

# api
wordlist_api_obj="$wordlist_path/seclists/Discovery/Web-Content/api/objects.txt"
wordlist_api_res="$wordlist_path/seclists/Discovery/Web-Content/api/api-endpoints-res.txt"

### specific
wordlist_snmp_community_string="$wordlist_path/seclists/Discovery/SNMP/common-snmp-community-strings-onesixtyone.txt"
wordlist_lfi="$wordlist_path/IntruderPayloads/FuzzLists/lfi.txt"

## hashcat
wordlist_hashcat_rules="/usr/share/hashcat/rules"
wordlist_hashcat_rule_best64="/usr/share/hashcat/rules/best64.rule"

# sqli
wordlist_sqli="$wordlist_path/custom-sqli.txt"

# traversal
wordlist_traversal="$wordlist_path/IntruderPayloads/FuzzLists/traversal.txt"

###########
# windows #
###########
windows_path="/usr/share/windows-resources"
windows_powercat='/usr/share/powershell-empire/empire/server/data/module_source/management/powercat.ps1'
windows_powerup='/usr/share/windows-resources/powersploit/Privesc/PowerUp.ps1'
windows_powerview='/usr/share/windows-resources/powersploit/Recon/PowerView.ps1'
windows_nc64="$HOME/oscp-swiss/utils/windows/nc64.exe"

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
windows_invoke_powershell_tcp='$HOME/oscp-swiss/utils/windows/nishang/Shells/Invoke-PowerShellTcp.ps1'
windows_GodPotato_NET2='$HOME/oscp-swiss/utils/windows/GodPotato/GodPotato-NET2.exe'
windows_GodPotato_NET35='$HOME/oscp-swiss/utils/windows/GodPotato/GodPotato-NET35.exe'
windows_GodPotato_NET4='$HOME/oscp-swiss/utils/windows/GodPotato/GodPotato-NET4.exe'
