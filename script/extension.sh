#!/bin/bash
# About extension.sh
# The extension.sh is for the non-native functions that are used in the script.
# You may need to download the tools and scripts or modify the path to use them.
# for extension function, you should use the `_extension_fn_banner` function to display the banner
# to inform the user that the function is an extension function.

CVE_sudo_PE="$HOME/oscp-swiss/utils/CVE/CVE-2021-3156"
CVE_DirtyPipe="$HOME/oscp-swiss/utils/CVE/CVE-2022-0847-DirtyPipe-Exploits"
CVE_polkit="$HOME/oscp-swiss/utils/CVE/CVE-polkit"
CVE_screen_4_5_0="$HOME/oscp-swiss/utils/CVE/screen-v4.5.0-priv-escalate"

ligolo_path="$swiss_utils/tunnel/ligolo-0.6.2"
ligolo_windows="$swiss_utils/tunnel/ligolo-0.6.2/ligolo-ng_agent_0.6.2_windows_amd64.exe"
ligolo_linux="$swiss_utils/tunnel/ligolo-0.6.2/ligolo-ng_agent_0.6.2_linux_amd64"

linux_lxd_group="$HOME/oscp-swiss/utils/linux/alpine-v3.13-x86_64-20210218_0139.tar.gz"
linux_linpeas="$swiss_utils/Peas/linpeas-v20240721.sh"
linux_pspy="$swiss_utils/linux/pspy"
linux_pspy64="$swiss_utils/linux/pspy/pspy64"

reverse_shell="$swiss_utils/reverse-shell"

service_crypto_firefox_decrypt="$HOME/oscp-swiss/utils/service/firefox_decrypt"
service_jdwp_shellifier="$HOME/oscp-swiss/utils/service/jdwp-shellifier"

recon_IOXIDResolver="$HOME/oscp-swiss/utils/recon/IOXIDResolver"

windows_GodPotato="$HOME/oscp-swiss/utils/windows/GodPotato"
windows_GodPotato_NET2="$swiss_utils/windows/GodPotato/GodPotato-NET2.exe"
windows_GodPotato_NET35="$swiss_utils/windows/GodPotato/GodPotato-NET35.exe"
windows_GodPotato_NET4="$swiss_utils/windows/GodPotato/GodPotato-NET4.exe"
windows_addUser="$HOME/oscp-swiss/utils/windows/windows-addUser"
windows_PrintSpoofer="$HOME/oscp-swiss/utils/windows/PrintSpoofer"
windows_PrintSpoofer32="$swiss_utils/windows/PrintSpoofer/PrintSpoofer32.exe"
windows_PrintSpoofer64="$swiss_utils/windows/PrintSpoofer/PrintSpoofer64.exe"
windows_Procmon="$HOME/oscp-swiss/utils/windows/Procmon"
windows_conpty="$swiss_utils/windows/Invoke-ConPtyShell.ps1"
windows_get_spn="$swiss_utils/windows/Get-SPN.ps1"
windows_invoke_kerberoast="$swiss_utils/windows/Invoke-Kerberoast.ps1"
windows_invoke_powershell_tcp="$swiss_utils/windows/nishang/Shells/Invoke-PowerShellTcp.ps1"
windows_nc64="$swiss_utils/windows/nc64.exe"
windows_runascs="$swiss_utils/windows/Invoke-RunasCs.ps1"
windows_winpeas_x86="$swiss_utils/Peas/winPEASx86-v20240721.exe"
windows_winpeas_x64="$swiss_utils/Peas/winPEASx64-v20240721.exe"
windows_dllAdduser="$swiss_utils/windows/dll-addUser.c"
windows_accesschk="$swiss_utils/windows/accesschk"
windows_sharphound_2_4_1="$swiss_utils/windows/SharpHound-v2.4.1"
windows_mimikatz="$swiss_utils/windows/windows-resources/mimikatz"
windows_mimikatz_x86="$swiss_utils/windows/windows-resources/mimikatz/Win32/mimikatz.exe"
windows_mimikatz_x64="$swiss_utils/windows/windows-resources/mimikatz/x64/mimikatz.exe"
windows_spary_password="$swiss_utils/windows/Spray-Passwords.ps1"
windows_rubeus="$swiss_utils/windows/Rubeus.exe"
windows_bloodhound_4_3_1="$swiss_utils/windows/BloodHoundCollector-4.3.1"
windows_bloodhound_4_3_1_exe="$windows_bloodhound_4_3_1/SharpHound.exe"

wordlist_credential_small="$swiss_wordlist/small-credential-custom.txt"
wordlist_ssti="$swiss_wordlist/ssti-custom.txt"

windows_family=( $windows_GodPotato_NET4 $windows_mimikatz_x64 $windows_PrintSpoofer64 $windows_winpeas_x64 $windows_nc64 $windows_powerview $windows_powerup $windows_bloodhound_4_3_1_exe )
linux_family=( $linux_pspy64 $linux_linpeas )
