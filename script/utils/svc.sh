# Description: one-liner to start services.
# Usage: svc <service> [OPTIONS]
# Arguments:
#   - service: current support:
#     + docker          start docker service
#     + ftp             start a ftp server
#     + http            start a http server on port 80
#     + smb             start a smb server
#     + ssh             start sshd service
#     + bloodhound      start BloodHound (v4.3.1)
#     + bloodhound-ce   start BloodHound CE (v2.4.1)
#     + ligolo          start ligolo-ng_agent (v0.6.2)
#     + wsgi            start wsgid
#     + python-venv     create a python virtual environment
#   - Options
#     + -p, --port PORTS    Ports used (http)
# Configuration:
#   - function.svc_wsgi.default_port <integer>: default is 443.
# Example:
#   svc http # to spawn a http server in the current directory
#   svc ftp  # to spawn a ftp server in the current directory
function svc() {
    local service="$1"
    [[ -z "$service" ]] && _help && return 1

    case "$service" in
        docker)
            _banner extension docker
            _log info "[i] start docker"
            _log warn "[w] to stop, use the commands: sudo systemctl stop docker && sudo systemctl stop docker.socket"
            _wrap sudo service docker restart
            ;;
        ftp)
            _logger info "[i] start ftp server on host"
            _logger info "Usage:"
            _logger info "\t(1) run ftp"
            _logger info "\t(2) run open <ip> 21"
            _logger info "\t(2-2) Default Interface ($_swiss_default_network_interface) IP: $(_get_default_network_interface_ip)"
            _logger info "\t(3) use username anonymous"
            _logger info "\t(4) binary # use binary mode"
            _logger info "\t(5) put <file-you-want-to-download>"
            _wrap python3 -m pyftpdlib -w -p 21
            ;;
        http)
            local port="80"
            [[ $2 == "-p" || $2 == "--port" ]] && port=$3

            _logger info "[i] start http server"
            i
            _wrap python3 -m http.server $port
            ;;
        php)
            local port="80"
            [[ $2 == "-p" || $2 == "--port" ]] && port=$3
            _logger info "[i] start php server"
            i
            _wrap php -S 0.0.0.0:$port
            ;;
        smb)
            _logger info "[i] start smb server"
            _logger info "[i] using share name 'smb'"
            i
            _wrap impacket-smbserver smb . -smb2support
            ;;
        ssh)
            _logger info "[i] start ssh server"
            _logger warn "[w] sudo systemctl stop ssh; kill -9 $(pgrep ssh); sudo systemctl start ssh"
            i
            sudo systemctl stop ssh
            kill -9 $(pgrep ssh)
            _wrap sudo systemctl start ssh
            ;;
        bloodhound)
            _logger info "[i] start BloodHound (v2.4.3) ..."
            # TODO: add more instructions & reproduce from skretch
            _wrap sudo neo4j console
            ;;
        bloodhound-ce)
            _banner extension
            # ref: https://support.bloodhoundenterprise.io/hc/en-us/articles/17468450058267-Install-BloodHound-Community-Edition-with-Docker-Compose
            _logger info "[i] start BloodHound CE (v2.4.1) ..."
            _logger info "[i] start port check on 8080"

            # Check if port 8080 is open
            lsof -i :8080 > /dev/null && _logger error "[e] Port 8080 is open. Exited" && exit 1

            _logger info "[i] cloning docker-compose files from /opt/BloodHound/examples/docker-compose"
            cp /opt/BloodHound/examples/docker-compose/* $(pwd)

            _logger info "[i] BloodHound CE starts on port 8080 (default), username: admin, password check on the terminal logs"
            _logger info "[i] preferred password: @Bloodhound123"

            _wrap sudo docker-compose up
            ;;
        ligolo)
            _banner extension
            _logger warn "[w] one-time setup: sudo ip tuntap add user $(whoami) mode tun ligolo; sudo ip link set ligolo up"
            _logger info "[i] Example (On target): "
            _logger info "[i] Linux: ./ligolo-ng_agent_0.6.2_linux_amd64 -connect $(_get_default_network_interface_ip):443 -ignore-cert"
            _logger info "[i] Windows: .\ligolo-ng_agent_0.6.2_windows_amd64.exe -connect $(_get_default_network_interface_ip):443 -ignore-cert"
            _logger info "[i] after connection: "
            _logger info "[i] > session                                    # choose the session"
            _logger info "[i] > ifconfig                                   # check interface"
            _logger info "[i] sudo ip route add 192.168.0.0/24 dev ligolo  # add interface"
            _logger warn "[w] ip route del 122.252.228.38/32               # removal after use"
            _logger info "[i] start                                        # start the agent"
            _logger info "[i] Add listener (e.g., for svc http): listener_add --addr 0.0.0.0:80 --to 127.0.0.1:80 --tcp"
            _logger info "[i] Port Forwarding (access via 240.0.0.1): sudo ip route add 240.0.0.1/32 dev ligolo"
            # TODO: add to configuration
            local ligolo_agent_path="$swiss_utils/tunnel/ligolo-0.6.2/proxy"
            _wrap $ligolo_agent_path -selfcert -laddr 0.0.0.0:443
            ;;
        wsgi)
            _banner extension
            _logger info "[i] start wsgidav under the directory: $(pwd)"
            _logger info "[i] port used: 80"
            i
            _wrap $_swiss_svc_wsgi --host=0.0.0.0 --port=$_swiss_svc_wsgi_default_port --auth=anonymous --root .
            ;;
        python-venv)
            _banner extension
            _wrap python3 -m venv .venv
            _wrap source .venv/bin/activate
            ;;
        *) _help && return 1 ;;
    esac
}