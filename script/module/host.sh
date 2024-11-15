# Description: lookup the public IP address of the host
# Usage: host_public_ip
# Category: [ network ]
function host_public_ip() {
    curl ipinfo.io/ip
}