
function _test.logger() {
    _swiss_logger_level="warn"
    echo "=== current level: $_swiss_logger_level ==="
    _logger -l error -n "new line test: " && _logger -l warn --no-mark "merging color"
    _logger -l debug -i "this should bypass logger_level restriction"
    
    _swiss_logger_level="debug"
    echo "=== current level: $_swiss_logger_level ==="

    _logger -l debug "test debug"
    _logger -l info "test info"
    _logger -l hint "test hint"
    _logger -l warn "test warn"
    _logger -l error "test error"
    _logger -l important "test important"

    _swiss_logger_level="error"
    echo "=== current level: $_swiss_logger_level ==="
    _logger -l debug "test debug"
    _logger -l info "test info"
    _logger -l hint "test hint"
    _logger -l warn "test warn"
    _logger -l error "test error"
    _logger -l important "test important"

    _swiss_logger_level="warn"
    echo "=== current level: $_swiss_logger_level ==="
    _logger -l debug "test debug"
    _logger -l info "test info"
    _logger -l hint "test hint"
    _logger -l warn "test warn"
    _logger -l error "test error"
    _logger -l important "test important"
}