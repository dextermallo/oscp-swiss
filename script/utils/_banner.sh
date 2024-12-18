_banner() {
    _cmd_is_exist() { command -v "$1" &> /dev/null && echo 1 || echo 0; }
    type=$1
    arg_cmd=$2
    case $type in
        swiss)
            gum style \
                --foreground 212 --border-foreground 212 --border double \
                --align center --width 50 --margin "1 2" --padding "2 4" \
                "__________       _______________________" \
                "__  ___/_ |     / /___  _/_  ___/_  ___/" \
                "_____ \\__ | /| / / __  / _____ \\_____ \\" \
                "____/ /__ |/ |/ / __/ /  ____/ /____/ /" \
                "/____/ ____/|__/  /___/  /____/ /____/" \
                "" \
                "by @dextermallo v$SWISS_VERSION"
            ;;
        extension)
            _logger warn "[ The function relies on non-native commands, binaries, or libraries ($arg_cmd). Check the function before the run ]"
            [[ $(_cmd_is_exist "$arg_cmd") -eq 0 ]] && _logger error "Command $arg_cmd not found" && return 1
        ;;
        override-cmd)
            _logger warn "[ custom command, for default, add the sign _ in front of the command ]\n"
        ;;
    esac
}