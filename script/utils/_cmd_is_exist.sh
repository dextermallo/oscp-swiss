_cmd_is_exist() {
    command -v "$1" &> /dev/null && echo 1 || echo 0;
}