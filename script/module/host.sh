#!/bin/bash


# Description:
#   Lookup the public IP address of the host.
#   This does not be used in the OSCP exam but IRL.
# Usage: host_public_ip
function host_public_ip() {
    curl ipinfo.io/ip
}