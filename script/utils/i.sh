# Description:
#   Simplified version of the `ip a` command to show the IP address of the default network interface.
#   The default network interface's IP address is copied to the clipboard.
# Usage: i [-c, --copy] [-h, --help]
# Arguments:
#   -c, --copy: copy the default interface IP.
function i() {
    local auto_copy=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--copy)
                auto_copy=true
                shift
            ;;
            -h|--help)
                _help
                return 0
            ;;
            *)
                _logger error "[e] invalid options. see -h, --help."
                return 1
            ;;
        esac
    done
    local default_ip="$(_get_default_network_interface_ip)"
    _logger info "[i] $_swiss_default_network_interface: $default_ip"

    if [[ "$auto_copy" = true ]]; then
        echo -n $default_ip | xclip -selection clipboard
    fi
}