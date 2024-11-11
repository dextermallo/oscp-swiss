#!bin/bash
# About machine.sh
# The machine.sh is for the functions that are used on your machine. (not your VM)


source $HOME/oscp-swiss/script/utils.sh

# Description:
#   Run a docker container with a x86-based kali.
#   This is useful for Mac M-series users, which you can use the x86-based kali
#   to compile the exploit or tools that are not supported on the ARM-based kali.
function x64_kali() {
    _extension_fn_banner
    podman run -it --rm --privileged --userns=host --platform linux/amd64 -v $HOME:$HOME kalilinux/kali-rolling
}

# Description:
#   Upload a file to the ffsend.
#   In some cases, you may have issue regarding transferring files between your host and the VM.
#   You can use the ffsend to upload the file to the ffsend server and download it from the VM.
function upload() {
    _extension_fn_banner
    ffsend upload $1 --copy-cmd
}