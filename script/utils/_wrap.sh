# Description: wrap a function execution.
# Usage: _wrap <commands>
function _wrap() {
    local command="$*"
    _logger warn-instruction "[SWISS] Following command is executed:"
    _logger important-instruction "$command"
    eval "$command"
}