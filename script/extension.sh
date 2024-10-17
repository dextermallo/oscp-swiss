#!/bin/bash

source $HOME/oscp-swiss/script/utils.sh
source $HOME/oscp-swiss/script/alias.sh
load_settings

# About extension.sh
# The extension.sh is for the non-native functions that are used in the script.
# You may need to download the tools and scripts or modify the path to use them.
# for extension function, you should use the `extension_fn_banner` function to display the banner
# to inform the user that the function is an extension function.

windows_winpeas_x86="$swiss_utils/Peas/winPEASx86-v20240721.exe"
windows_winpeas_x64="$swiss_utils/Peas/winPEASx64-v20240721.exe"
linux_linpeas="$swiss_utils/Peas/linpeas-v20240721.sh"
windows_get_spn="$HOME/oscp-swiss/utils/windows/Get-SPN.ps1"
windows_invoke_kerberoast="$swiss_utils/windows/Invoke-Kerberoast.ps1"
windows_runascs="$swiss_utils/windows/RunasCs.ps1"
linux_pspy="$swiss_utils/linux/pspy"
rev_shell="$swiss_utils/rev"
windows_sharphound='/usr/share/windows-resources/SharpHoundv2.4.1'

# ref: https://github.com/antonioCoco/ConPtyShell
windows_conpty="$swiss_utils/Invoke-ConPtyShell.ps1"
ligolo_path="$swiss_utils/tunnel/ligolo-0.6.2"