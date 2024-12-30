# Description: wrap a function execution.
# Usage: _wrap <commands>
function _wrap() {
    local command="$*"
    _logger -l warn -i -n --no-mark  -b "[SWISS] Following command is executed: "
    _logger -l important -i --no-mark  -b "$command"
    eval "$command"
}