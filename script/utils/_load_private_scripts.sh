# Description:
#   Load all scripts under the $oscp-swiss/private directory.
#   If you have any private aliases, functions or variables, you can put them in the private directory.
#   Or if you already have a bunch of scripts, you can put them in the directory without any changes.
# Usage: _load_private_scripts
function _load_private_scripts() {
    if [ -d "$swiss_private" ]; then
        for script in "$swiss_private"/*.sh; do
            if [ -f "$script" ]; then
                source "$script"
            fi
        done
    else
        _logger -l error "Directory $swiss_private not found."
    fi
}