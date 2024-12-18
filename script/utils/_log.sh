# Description: low level function for logging which wrap the echo command with ANSI color codes.
# Usage: _log [options] <text>
function _log() {
    local bold=""
    local fg_color=""
    local bg_color=""
    local no_color=0
    local text=""
    local underline=""
    local newline=1
    local ansi_reset="\033[0m"

    while [ "$1" ]; do
        case "$1" in
            --bold) bold="\033[1m" && shift ;;
            -u|--underline) underline="\033[4m" && shift ;;
            -f|--foreground)
                shift
                case "$1" in
                    black) fg_color="\033[30m" ;;
                    red) fg_color="\033[31m" ;;
                    green) fg_color="\033[32m" ;;
                    yellow) fg_color="\033[33m" ;;
                    blue) fg_color="\033[34m" ;;
                    magenta) fg_color="\033[35m" ;;
                    cyan) fg_color="\033[36m" ;;
                    white) fg_color="\033[37m" ;;
                    gray) fg_color="\033[90m" ;;
                    *) fg_color="" ;;
                esac
                shift
                ;;
            -b|--background)
                shift
                case "$1" in
                    black) bg_color="\033[40m" ;;
                    red) bg_color="\033[41m" ;;
                    green) bg_color="\033[42m" ;;
                    yellow) bg_color="\033[43m" ;;
                    blue) bg_color="\033[44m" ;;
                    magenta) bg_color="\033[45m" ;;
                    cyan) bg_color="\033[46m" ;;
                    white) bg_color="\033[47m" ;;
                    gray) bg_color="\033[100m" ;;
                    *) bg_color="" ;;
                esac
                shift
                ;;
            --no-color) no_color=1 && shift ;;
            -n|--no-newline) newline=0 && shift ;;
            *) text="$1" && shift ;;
        esac
    done

    if [[ "$_swiss_disable_color" = true ]]; then
        [[ "$newline" -eq 1 ]] && echo -e "$text" || echo -e -n "$text"
    else
        [[ "$newline" -eq 1 ]] && newline_flag="" || newline_flag="-n"
        echo -e $newline_flag "${bold}${underline}${fg_color}${bg_color}${text}${ansi_reset}"
    fi
}

# Description:
#   _check_logger_level is a helper function to check the logger level,
#   the function will return 0 if the given level is equal or higher than the global logger level.
# Configuration:
#   - global_settings.logger_level <debug|info|warn|error>: default is info.
# Usage: _check_logger_level <level>
function _check_logger_level() {
    case "$_swiss_logger_level" in
        debug) return 0 ;;
        info) [[ "$1" != "debug" ]] ;;
        warn) [[ "$1" == "warn" || "$1" == "error" ]] ;;
        error) [[ "$1" == "error" ]] ;;
        *) return 1 ;;
    esac
}

# Description: wrap the _log function with the given level.
# Usage: _logger <level> <text>
function _logger() {
    case "$1" in
        debug) _check_logger_level "debug" && _log -f gray "$@" ;;
        info) _check_logger_level "info" && _log -f green "$@" ;;
        warn) _check_logger_level "warn" && _log -f yellow "$@" ;;
        error) _check_logger_level "error" && _log --bold -f red "$@" ;;
        # prompt must be display in any given level
        prompt) _check_logger_level "error" && _log -f green "$@" ;;
        hint) _log -f cyan "$@" ;;
        important-instruction) _log --bold -f red "$@" ;;
        warn-instruction) _log --bold -f yellow "$@" ;;
        info-instruction) _log --bold -f green "$@" ;;
        highlight) _log --bold -f white -b red "$@" ;;
        *) echo -n "$@" ;;
    esac
}