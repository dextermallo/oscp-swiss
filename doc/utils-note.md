# Utils: GodPotato
## Description: SEImpersonate to PE as NT AUTHORITY\SYSTEM
## Path: /utils/windows/GodPotato
## Shortcut: windows_GodPotato
## Usage:
> Ref: https://github.com/BeichenDream/GodPotato
> Ref: https://stackoverflow.com/questions/1565434/how-do-i-find-the-installed-net-versions

```powershell
# check NET version
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP"
```

# Utils: PrintSpoofer
## Description: SeImpersonatePrivilege PE as NT AUTHORITY\SYSTEM (Win 10, 2016, 2019)
## Path: /utils/windows/PrintSpoofer
## Shortcut: windows_PrintSpoofer
## Usage:
```powershell
PrintSpoofer64.exe -i -c cmd
```
# Utils: Procmon
## Description: 
## Path: /utils/windows/Procmon
## Shortcut: windows_Procmon
## Usage:
<-- Declare the usage here -->

# Utils: CVE-2021-3156
## Description: Sudo RCE (version 1.8.9-1.8.23)
## Path: /utils/CVE/CVE-2021-3156
## Shortcut: CVE_sudo_PE
## Usage:
<-- Declare the usage here -->

# Utils: alpine-v3.13-x86_64-20210218_0139.tar.gz
## Description: lxd Group Privilege Escalation
## Path: /utils/linux/alpine-v3.13-x86_64-20210218_0139.tar.gz
## Shortcut: linux_PE_lxd_group
## Usage:
<-- Declare the usage here -->

# Utils: windows-addUser
## Description: .exe to add user to PE as administrator (binary hijacking etc)
## Path: /utils/windows/windows-addUser
## Shortcut: windows_PE_addUser
## Usage:
<-- Declare the usage here -->

# Utils: firefox_decrypt
## Description: Decrypt filefox credentials 
## Path: /utils/service/firefox_decrypt
## Shortcut: service_crypto_firefox_decrypt
## Usage:
<-- Declare the usage here -->

# Utils: pspy
## Description: Check all hidden process 
## Path: /utils/linux/pspy
## Shortcut: linux_recon_pspy
## Usage:
```sh
./pspy
```

# Utils: dll-addUser.c
## Description: Payload for DLL to add user as administrator
## Path: windows/dll-addUser.c
## Shortcut: windows_PE_dllAdduser
## Usage:
```sh
x86_64-w64-mingw32-gcc TextShaping.cpp --shared -o TextShaping.dll
```

# Utils: accesschk
## Description: permission check 
## Path: /utils/windows/accesschk
## Shortcut: windows_PE_accesschk
## Usage:
```powershell
.\accesschk64.exe -accepteula -wv (whoami) C:\Users\steve\Pictures\BackendCacheCleanup.exe
```

# Utils: SharpHound-v2.4.1
## Description: BloodHound (bloodhound-ce)
## Path: /utils/windows/SharpHound-v2.4.1
## Shortcut: windows_RECON_SharpHound2_4_1
## Usage:
```sh
svc bloodhound-ce
```

# Utils: mimikatz
## Description: 
## Path: windows/windows-resources/mimikatz
## Shortcut: windows_PE_mimikatz
## Usage:

# Utils: Spray-Passwords.ps1
## Description: Windows Spary Password (OSCP 22.2.1.) 
## Path: /utils/windows/Spray-Passwords.ps1
## Shortcut: windows_spary_password
## Usage: 
```powershell
# identify admin users and spray
.\Spary-Passwords.ps1 -Pass Password123 -Admin
```

# Utils: Rubeus.exe
## Description: Kerberoasting, AS-REP Roasting, and others
## Path: /utils/windows/Rubeus.exe
## Shortcut: windows_PE_rubeus
## Usage:
```powershell
# AS-Rep Roasting
.\Rubeus.exe asreproast /nowrap

# Keroasting
.\Rubeus.exe kerberoast /outfile:hashes.kerberoast
```
# Utils: BloodHoundCollector-4.3.1
## Description: BloodHound 4.3.1 collector
## Path: windows/BloodHoundCollector-4.3.1
## Shortcut: windows_bloodhound_4_3_1
## Usage:
```powershell
.\SharpHound.exe -c All
```

