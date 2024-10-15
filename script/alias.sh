#!/bin/bash

source ~/oscp-swiss/.env
source ~/oscp-swiss/script/utils.sh

# extend existing func
alias grep="grep --color=auto"
alias diff="diff --color=auto"

function cd() {
    if [ $# -eq 0 ]; then
        # No arguments
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

# for customized size
alias _xfrredp="/usr/bin/xfreerdp"
alias xfreerdp="custom_cmd_banner; mkdir xfreerdp-data; xfreerdp /drive:$PWD,/xfreerdp-data /cert-ignore /w:932"

# use with WP token for detailed recon
alias _wpscan="/usr/bin/wpscan"
alias wpscan="custom_cmd_banner; wpscan --api-token $WP_TOKEN"

# colorized cat command
alias _cat="/usr/bin/cat"

# ref: https://stackoverflow.com/questions/62546404/how-to-use-dracula-theme-as-a-style-in-pygments
alias cat="custom_cmd_banner; pygmentize -P style=dracula -g"

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
wordlist_ffuf_default="$WORDLIST_BASE/custom-ffuf-default.txt"

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

########
# nmap #
########
nmap_scripts_path="/usr/share/nmap/scripts"

###########
# windows #
###########
windows_path="/usr/share/windows-resources"
windows_get_spn="$HOME/oscp-swiss/utils/windows/Get-SPN.ps1"
windows_invoke_kerberoast="$HOME/oscp-swiss/utils/windows/Invoke-Kerberoast.ps1"
windows_runascs="$HOME/oscp-swiss/utils/windows/RunasCs.ps1"
windows_powercat='/usr/share/powershell-empire/empire/server/data/module_source/management/powercat.ps1'
windows_powerup='/usr/share/windows-resources/powersploit/Privesc/PowerUp.ps1'
windows_powerview='/usr/share/windows-resources/powersploit/Recon/PowerView.ps1'
windows_winpeas_x86="$HOME/oscp-swiss/utils/Peas/winPEASx86.exe"
windows_winpeas_x64="$HOME/oscp-swiss/utils/Peas/winPEASx64.exe"

#########
# linux #
#########
linux_privesc="/usr/bin/unix-privesc-check"
linux_linpeas="$HOME/oscp-swiss/utils/Peas/linpeas.sh"
linux_pspy="$HOME/oscp-swiss/utils/pspy"

########
# disc #
########
hasncat_potfile_path="~/.local/share/hashcat/hashcat.potfile"
swiss_utils="$HOME/oscp-swiss/utils"
swiss_script="$HOME/oscp-swiss/script/oscp-swiss.sh"
swiss_alias="$HOME/oscp-swiss/script/alias.sh"