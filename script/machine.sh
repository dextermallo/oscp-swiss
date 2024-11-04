#!bin/bash
# About machine.sh
# TODO: doc

function x64_kali() {
    podman run -it --rm --privileged --userns=host --platform linux/amd64 -v $HOME:$HOME kalilinux/kali-rolling
    # then update apt
}

function upload() {
    ffsend upload $1 --copy-cmd
}