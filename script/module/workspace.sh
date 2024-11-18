#!/bin/bash


# Description: go to the path defined as workspace (cross-session)
# Usage: go_workspace
# Category: [ func: shortcut ]
function go_workspace() {
    if [ "$_swiss_workspace_auto_cleanup" = true ]; then     
        check_workspace
    fi

    local cur_workspace_path
    cur_workspace_path=$(jq -r '.swiss_variable.workspace.cur.path // empty' "$swiss_settings")

    if [[ -n "$cur_workspace_path" && -d "$cur_workspace_path" ]]; then
        cd "$cur_workspace_path" || { echo "[e] Failed to navigate to directory '$cur_workspace_path'"; return 1; }
    # TODO: in spawn_session_in_workspace, the else condition should not print the error if the variable is empty
    # else
        # echo "[e] Workspace path is empty or does not exist"
    fi
}

# Description: set the workspace path and target
# Usage: set_workspace <workspace_path> <workspace_target>
# Category: [ ]
function set_workspace() {
    local workspace_path="$1"
    local workspace_target="$2"

    local tmp_conf="$(mktemp).json"

    if [[ -d "$workspace_path" ]]; then
        jq --arg path "$workspace_path" '.swiss_variable.workspace.cur.path = $path' "$swiss_settings" > $tmp_conf && mv $tmp_conf "$swiss_settings"
        swiss_logger debug "[d] Current workspace path set to $workspace_path"
    else
        swiss_logger error "[e] Directory '$workspace_path' does not exist"
        return 1
    fi

    jq --arg target "$workspace_target" '.swiss_variable.workspace.cur.target = $target' "$swiss_settings" > $tmp_conf && mv $tmp_conf "$swiss_settings"
    swiss_logger debug "[d] Target set to $workspace_target"

    local exists_in_list
    exists_in_list=$(jq --arg path "$workspace_path" --arg target "$workspace_target" \
        '.swiss_variable.workspace.list[] | select(.path == $path and .target == $target)' "$swiss_settings")

    if [[ -z "$exists_in_list" ]]; then
        jq --arg path "$workspace_path" --arg target "$workspace_target" \
            '.swiss_variable.workspace.list += [{"path": $path, "target": $target}]' "$swiss_settings" > $tmp_conf && mv $tmp_conf "$swiss_settings"
        swiss_logger debug "[d] Workspace added to list: $workspace_path with target $workspace_target"
    else
        swiss_logger debug "[d] Workspace already exists in the list"
    fi

    # set variable
    target="$workspace_target"
}

# Description: select a workspace from the list
# Usage: select_workspace
# Category: [ ]
function select_workspace() {
    if [ "$_swiss_workspace_auto_cleanup" = true ]; then     
        check_workspace
    fi

    local paths
    paths=($(jq -r '.swiss_variable.workspace.list[].path' "$swiss_settings"))
    
    if [ ${#paths[@]} -lt 1 ]; then
        swiss_logger info "[i] No workspace found."
        return 0
    fi

    swiss_logger prompt "Please choose a workspace:"
    for ((i=1; i<=${#paths[@]}; i++)); do
        swiss_logger prompt "$((i)). ${paths[i]}"
    done

    swiss_logger prompt "Enter your choice: \c"
    read choice

    if [[ "$choice" -gt 0 && "$choice" -le "${#paths[@]}" && -d "${paths[choice]}" ]]; then

        local selected_path="${paths[choice]}"
        local selected_target=$(jq -r ".swiss_variable.workspace.list[$choice - 1].target" "$swiss_settings")

        swiss_logger debug "[d] change to path: $selected_path, target: $selected_target"

        jq --arg path "$selected_path" --arg target "$selected_target" \
           '.swiss_variable.workspace.cur = { "path": $path, "target": $target }' "$swiss_settings" > /tmp/tmp.$$.json && mv /tmp/tmp.$$.json "$swiss_settings"

        # reset variable target
        target=$selected_target

        cd $selected_path || { swiss_logger error "[e] Failed to enter directory '${paths[choice]}'"; return 1; }
    else
        swiss_logger error "[e] Invalid choice or directory does not exist"
    fi
}

# Description: check all workspaces' paths are exist. If a workspace does not exist, it will be removed automatically
# Usage: check_workspace
# Category: [ ]
function check_workspace() {
    local updated_list=()

    jq -c '.swiss_variable.workspace.list[]' "$swiss_settings" | while read -r item; do
        local cur_path=$(echo "$item" | jq -r '.path')
        if [[ -d "$cur_path" ]]; then
            updated_list+=("$item")
        else
            swiss_logger info "[i] Removing non-existent workspace path: $cur_path"
        fi
    done

    jq --argjson list "$(printf '%s\n' "${updated_list[@]}" | jq -s '.')" '.swiss_variable.workspace.list = $list' "$swiss_settings" > /tmp/tmp.$$.json && mv /tmp/tmp.$$.json "$swiss_settings"
    
    local cur_workspace_path
    cur_workspace_path=$(jq -r '.swiss_variable.workspace.cur.path // empty' "$swiss_settings")

    if [[ -n "$cur_workspace_path" && ! -d "$cur_workspace_path" ]]; then
        swiss_logger info "[i] Current workspace path does not exist: $cur_workspace_path"
        jq '.swiss_variable.workspace.cur = {}' "$swiss_settings" > /tmp/tmp.$$.json && mv /tmp/tmp.$$.json "$swiss_settings"
    fi
}

# # Description:
# #   Generate workspace for pen test. Including:
# #       - Create a directory with the format <name>-<ip>
# #       - Create username.txt and password.txt
# #       - Set the current path as workspace, you can use go_workspace to jump to the workspace across sessions
# #       - Set the target IP address, you can use get_target to copy the target IP address to the clipboard
# #       - Copy the ip to the clipboard
# # Usage: init_workspace
# # Category: [ prep ]
function init_workspace() {
    local name=""
    local ip=""

    _helper() {
        swiss_logger info "[i] Usage: init_workspace <-n, --name workspace_name> <-i, --ip IP>"
    }

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -i|--ip)
                ip="$2"
                shift 2
                ;;
            -n|--name)
                name="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ -z "$name" || -z "$ip" ]]; then
        _helper
        return 1
    fi
    local dir_name="${name}-${ip}"
    echo $dir_name
    mkdir -p "$dir_name"
    cd "$dir_name" || { swiss_logger error "[e] Failed to enter directory '$dir_name'"; return 1; }

    if [ -f "$_swiss_init_workspace_default_username_wordlist" ]; then
        cp $_swiss_init_workspace_default_username_wordlist username.txt
    else
        touch username.txt
    fi

    if [ -f "$_swiss_init_workspace_default_password_wordlist" ]; then
        cp $_swiss_init_workspace_default_password_wordlist password.txt
    else
        touch password.txt
    fi

    set_workspace $PWD $ip
}

# Description:
#   - get the target IP address and copy it to the clipboard.
#   - set the variable `target` to the target IP address
# Usage: get_target
# Category: [ ]
function get_target() {
    cur_target=$(jq -r '.swiss_variable.workspace.cur.target // ""' "$swiss_settings")
    if [[ -n $cur_target ]]; then
        target=$cur_target
        echo $cur_target | xclip -selection clipboard
    fi
}

# Description:
#   Spawn the new session in the workspace, and set target into the variables.
#   The  function is configured by the environment variable _swiss_spawn_session_in_workspace_start_at_new_session
#   See settings.json for more details.
# Usage: spawn_session_in_workspace
# Category: [ ]
function spawn_session_in_workspace() {
    if [ "$_swiss_spawn_session_in_workspace_start_at_new_session" = true ]; then
        go_workspace
        get_target
    fi
}


clean_workspace() {
  if [[ ! -f "$swiss_settings" ]]; then
    swiss_logger error "[e] File not found: $swiss_settings"
    return 1
  fi

  local tmp_file="$mktemp.json"

  jq '.swiss_variable.workspace.list = [] | .swiss_variable.workspace.cur = {}' "$swiss_settings" > $tmp_file

  if [[ $? -eq 0 ]]; then
    mv "$tmp_file" "$swiss_settings"
    swiss_logger info "[i] Workspaces have been cleaned up."
  else
    swiss_logger error "[e] Failed to clean workspace."
    rm -f "$tmp_file"
    return 1
  fi
}