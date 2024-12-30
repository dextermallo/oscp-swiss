function _banner() {
    type=$1
    arg_cmd=$2
    case $type in
        swiss)
            random_int=$(shuf -i 1-255 -n 1)
            gum style \
                --foreground $random_int --border-foreground $random_int --border double \
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
            _logger -l warn --no-mark -b "[ The function relies on non-native commands, binaries, or libraries ($arg_cmd). Check the function before the run ]"
            [[ $(_cmd_is_exist "$arg_cmd") -eq 0 ]] && _logger -l error -b "Command ($arg_cmd) not found" && return 1
        ;;
    esac
}