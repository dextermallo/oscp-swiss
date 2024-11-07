# File Search Cheatsheet

## Windows
```powershell
################################
# Interesting Files - Filename #
################################
# Basic
Get-ChildItem -Path C:\ -Include *.kdbx -File -Recurse -ErrorAction SilentlyContinue
dir /S /B *pass*.txt
where /R C:\ *.ini
where /R C:\ user.txt

# find flags
Get-ChildItem -Path "C:\" -Recurse -Include "local.txt", "proof.txt" -ErrorAction SilentlyContinue | Where-Object { $_.Name -in @("local.txt", "proof.txt") }

# Dump a tree of all the folders / files on the HDD
tree c:\\ > c:\\users\\public\\folders.txt
dir /s c:\\ > c:\\users\\public\\files.txt

# Common files
Get-ChildItem -Path C:\ -Include *.txt,*.sqlite,*conf*,*data*,*.pdf,*.apk,*.cfg,*.json,*.ini,*.log,*password*,*cred*,*.env,HEAD,*mbox,*.xls,*.xlsx,*.doc,*.docx,*.kdbx,*.ps1 -File -Recurse -ErrorAction SilentlyContinue

# find flags
Get-ChildItem -Path C:\ -Include flag.txt,local.txt,proof.txt,root.txt -File -Recurse -ErrorAction SilentlyContinue


###############################
# Interesting Files - Content #
###############################
# without file type constriction
dir -Recurse -ErrorAction SilentlyContinue | 
    Select-String -Pattern "user|username|login|pass|passwd|password|pw|credentials|flag|local|proof|db_username|db_passwd|db_password|db_user|db_host|database|api_key|api_token|access_token|private_key|jwt|auth_token|bearer|ssh_pass|ssh_key|identity_file|id_rsa|id_dsa|authorized_keys|env|environment|secret|admin|root" -ErrorAction SilentlyContinue

# with file constriction
dir -Recurse -Include *.txt,*.sqlite,*conf*,*data*,*.pdf,*.apk,*.cfg,*.json,*.ini,*.log,*password*,*cred*,*.env,HEAD,*mbox,*.xls,*.xlsx,*.doc,*.docx,*.kdbx,*.ps1 -ErrorAction SilentlyContinue | 
    Select-String -Pattern "user|username|login|pass|passwd|password|pw|credentials|flag|local|proof|db_username|db_passwd|db_password|db_user|db_host|database|api_key|api_token|access_token|private_key|jwt|auth_token|bearer|ssh_pass|ssh_key|identity_file|id_rsa|id_dsa|authorized_keys|env|environment|secret|admin|root" -ErrorAction SilentlyContinue
```

## Linux
```shell
ls -al

# automatically
ignore_list=("./usr/src/*" "./var/lib/*" "./etc/*" "./usr/share/*" "./snap/*" "./sys/*" "./usr/lib/*" "./usr/bin/*" "./run/*" "./boot/*" "./usr/sbin/*" "./proc/*" "./var/snap/*")
search_items=("*.txt" "*.sqlite" "*conf*" "*data*" "*.pdf" "*.apk" "*.cfg" "*.json" "*.ini" "*.log" "*.sh" "*password*" "*cred*" "*.env" "config" "HEAD" "*mbox" "*.sdf")

find_command="find . -type f"

for ignore in "${ignore_list[@]}"; do
find_command+=" \( -path \"$ignore\" -prune \) -o"
done

find_command+=" \("
for item in "${search_items[@]}"; do
find_command+=" -name \"$item\" -o"
done

find_command="${find_command% -o} \) -type f -print 2>/dev/null"

eval "$find_command"

grep -Erl "(user|username|login|pass|passwd|password|pw|credentials|flag|local|proof|db_username|db_passwd|db_password|db_user|db_host|database|api_key|api_token|access_token|private_key|jwt|auth_token|bearer|ssh_pass|ssh_key|identity_file|id_rsa|id_dsa|authorized_keys|env|environment|secret|admin|root)" . 2>/dev/null
```
