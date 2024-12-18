# Description: One-liner to start a interactive reverse shell listener.
# Usage: listen <port>
function listen() {
    i
    _wrap rlwrap nc -lvnp $1
}