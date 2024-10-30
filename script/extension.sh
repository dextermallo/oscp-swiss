#!/bin/bash
# About extension.sh
# The extension.sh is for the non-native functions that are used in the script.
# You may need to download the tools and scripts or modify the path to use them.
# for extension function, you should use the `extension_fn_banner` function to display the banner
# to inform the user that the function is an extension function.


source $HOME/oscp-swiss/script/utils.sh
source $HOME/oscp-swiss/script/alias.sh
load_settings

CVE_sudo_PE="$HOME/oscp-swiss/utils/CVE/CVE-2021-3156"

ligolo_path="$swiss_utils/tunnel/ligolo-0.6.2"

linux_PE_lxd_group="$HOME/oscp-swiss/utils/linux/alpine-v3.13-x86_64-20210218_0139.tar.gz"
linux_linpeas="$swiss_utils/Peas/linpeas-v20240721.sh"
linux_pspy="$swiss_utils/linux/pspy"
linux_recon_pspy="$HOME/oscp-swiss/utils/linux/pspy"

rev_shell="$swiss_utils/rev"

service_crypto_firefox_decrypt="$HOME/oscp-swiss/utils/service/firefox_decrypt"

windows_GodPotato="$HOME/oscp-swiss/utils/windows/GodPotato"
windows_GodPotato_NET2="$swiss_utils/windows/GodPotato/GodPotato-NET2.exe"
windows_GodPotato_NET35="$swiss_utils/windows/GodPotato/GodPotato-NET35.exe"
windows_GodPotato_NET4="$swiss_utils/windows/GodPotato/GodPotato-NET4.exe"
windows_PE_addUser="$HOME/oscp-swiss/utils/windows/windows-addUser"
windows_PrintSpoofer="$HOME/oscp-swiss/utils/windows/PrintSpoofer"
windows_PrintSpoofer32="$swiss_utils/windows/PrintSpoofer32.exe"
windows_PrintSpoofer64="$swiss_utils/windows/PrintSpoofer64.exe"
windows_Procmon="$HOME/oscp-swiss/utils/windows/Procmon"
windows_conpty="$swiss_utils/Invoke-ConPtyShell.ps1"
windows_get_spn="$swiss_utils/windows/Get-SPN.ps1"
windows_invoke_kerberoast="$swiss_utils/windows/Invoke-Kerberoast.ps1"
windows_invoke_powershell_tcp="swiss_utils/windows/nishang/Shells/Invoke-PowerShellTcp.ps1"
windows_nc64="$swiss_utils/windows/nc64.exe"
windows_runascs="$swiss_utils/windows/RunasCs.ps1"
windows_sharphound="/usr/share/windows-resources/SharpHoundv2.4.1"
windows_winpeas_x64="$swiss_utils/Peas/winPEASx64-v20240721.exe"
windows_winpeas_x86="$swiss_utils/Peas/winPEASx86-v20240721.exe"

wordlist_credential_small="$swiss_wordlist/custom-default-credential-list.txt"
wordlist_sqli="$wordlist_path/custom-sqli.txt"

windows_PE_dllAdduser="$HOME/oscp-swiss/utils/windows/dll-addUser.c"
windows_PE_accesschk="$HOME/oscp-swiss/utils/windows/accesschk"
windows_RECON_SharpHound2_4_1="$HOME/oscp-swiss/utils/windows/SharpHound-v2.4.1"
windows_PE_mimikatz="$HOME/oscp-swiss/utils/windows/windows-resources/mimikatz"