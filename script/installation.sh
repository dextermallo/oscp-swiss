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