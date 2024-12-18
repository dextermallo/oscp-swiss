# Description: Get the default network interface's IP address.
# Configuration:
#   - global_settings.default_network_interface: default is eth0.
# Usage: _get_default_network_interface_ip
function _get_default_network_interface_ip() {
    if [[ -z $_swiss_default_network_interface ]]; then
        _logger error "No default network interface was set." && return 1
    fi
    ip -o -f inet addr show | grep $_swiss_default_network_interface | awk '{split($4, a, "/"); printf "%s", a[1]}'
}