#!/bin/bash

source $HOME/oscp-swiss/script/utils.sh
base=$HOME/oscp-swiss/utils

mkdir -p $base

# pspy
# REF: https://github.com/DominicBreuker/pspy/releases/tag/v1.2.1
mkdir $base/pspy
wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy32 -P $base/pspy
wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy32s -P $base/pspy
wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64 -P $base/pspy
wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64s -P $base/pspy


# Linpeas/Winpeas
# REF: https://github.com/peass-ng/PEASS-ng/releases/tag/20240721-1e44f951
mkdir $base/Peas
wget https://github.com/peass-ng/PEASS-ng/releases/download/20240721-1e44f951/linpeas.sh -P $base/Peas
wget https://github.com/peass-ng/PEASS-ng/releases/download/20240721-1e44f951/winPEASx64.exe -P $base/Peas
wget https://github.com/peass-ng/PEASS-ng/releases/download/20240721-1e44f951/winPEASx86.exe -P $base/Peas

cd $HOME/oscp-swiss/wordlist

# directory traversal
merge   /usr/share/wordlists/IntruderPayloads/FuzzLists/traversal-short.txt \
        /usr/share/wordlists/IntruderPayloads/FuzzLists/traversal.txt \
        '/usr/share/wordlists/PayloadsAllTheThings/Directory Traversal/Intruder/deep_traversal.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/Directory Traversal/Intruder/traversals-8-deep-exotic-encoding.txt' \
        -o file-traversal-default.txt

# web fuzzing
merge   /usr/share/wordlists/seclists/Discovery/Web-Content/raft-large-files.txt \
        /usr/share/wordlists/seclists/Discovery/Web-Content/raft-large-directories.txt \
        /usr/share/wordlists/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt \
        /usr/share/wordlists/seclists/Discovery/Web-Content/common.txt \
        /usr/share/wordlists/dirb/common.txt \
        /usr/share/wordlists/dirb/big.txt \
        /usr/share/wordlists/seclists/Discovery/Web-Content/dirsearch.txt \
        -o ffuf-default.txt

# subdomain & vhost fuzzing
merge   /usr/share/wordlists/amass/subdomains-top1mil-110000.txt \
        /usr/share/wordlists/seclists/Discovery/DNS/fierce-hostlist.txt \
        /usr/share/wordlists/seclists/Discovery/DNS/bitquark-subdomains-top100000.txt \
        -o subdomain+vhost-default.txt

# sqli
merge   /usr/share/wordlists/IntruderPayloads/FuzzLists/sqli-error-based.txt \
        /usr/share/wordlists/IntruderPayloads/FuzzLists/sqli-time-based.txt \
        /usr/share/wordlists/IntruderPayloads/FuzzLists/sqli-union-select.txt \
        /usr/share/wordlists/IntruderPayloads/FuzzLists/sqli_escape_chars.txt \
        /usr/share/wordlists/seclists/Fuzzing/Databases/MSSQL-Enumeration.fuzzdb.txt \
        /usr/share/wordlists/seclists/Fuzzing/Databases/MSSQL.fuzzdb.txt \
        /usr/share/wordlists/seclists/Fuzzing/Databases/MySQL-Read-Local-Files.fuzzdb.txt \
        /usr/share/wordlists/seclists/Fuzzing/Databases/MySQL-SQLi-Login-Bypass.fuzzdb.txt \
        /usr/share/wordlists/seclists/Fuzzing/Databases/MySQL.fuzzdb.txt \
        /usr/share/wordlists/seclists/Fuzzing/Databases/NoSQL.txt \
        /usr/share/wordlists/seclists/Fuzzing/Databases/sqli.auth.bypass.txt \
        /usr/share/wordlists/seclists/Fuzzing/Polyglots/SQLi-Polyglots.txt \
        /usr/share/wordlists/seclists/Fuzzing/SQLi/Generic-BlindSQLi.fuzzdb.txt \
        /usr/share/wordlists/seclists/Fuzzing/SQLi/Generic-SQLi.txt \
        /usr/share/wordlists/seclists/Fuzzing/SQLi/quick-SQLi.txt \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/Auth_Bypass.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/Auth_Bypass2.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/FUZZDB_MSSQL-WHERE_Time.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/FUZZDB_MSSQL.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/FUZZDB_MSSQL_Enumeration.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/FUZZDB_MYSQL.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/FUZZDB_MySQL-WHERE_Time.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/FUZZDB_MySQL_ReadLocalFiles.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/FUZZDB_Oracle.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/FUZZDB_Postgres_Enumeration.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/Generic_ErrorBased.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/Generic_Fuzz.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/Generic_TimeBased.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/Generic_UnionSelect.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/SQL-Injection' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/SQLi_Polyglots.txt' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/payloads-sql-blind-MSSQL-INSERT' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/payloads-sql-blind-MSSQL-WHERE' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/payloads-sql-blind-MySQL-INSERT' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/payloads-sql-blind-MySQL-ORDER_BY' \
        '/usr/share/wordlists/PayloadsAllTheThings/SQL Injection/Intruder/payloads-sql-blind-MySQL-WHERE' \
        -o sqli-custom.txt