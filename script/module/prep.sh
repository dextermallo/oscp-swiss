#!/bin/bash


# Description: 
#   Command `memory` is a cheatsheet function for your binaries, scripts, and all files you keep.
#   You can take notes and read it effortlessly to find what you need rapidly.
#   All the notes are stored under `/doc/utils-note.md`.
#   For example, you can add a note by running the command: `memory /home/kali/oscp-swiss/utils/windows/GodPotato`
#   If it is not a valid file/directory, it will print out the error
#   If it is a valid file/directory:
#       - If there's no note under `/doc/utils-note.md`, it will ask whether you want to create a note
#       - If there's note, the note will be printed by cat
#   Note formats (.md):
#   ```md
#   # $filename
#   ## Description: $description
#   ## Path: $path
#   ## Usage:
#   <-- Declare the usage here -->
#   ````
# Usage: memory <$path>
# Variable:
#   - path: path is a filepath or a path to a directory. If it is a file path, it will shows the file's note (if exist). If it is a directory, it will list all files under the directory (with the description).
# Example: memory utils/windows
function memory() {
    _helper() {
        swiss_logger info "memorize [mode] [options] <$PATH>"
        swiss_logger info "[Mode]"
        swiss_logger info "-m, --mode: <add, view, default>"
        swiss_logger info "  in add mode, you can add notes"
        swiss_logger info "  in view mode, path (for both file and directory) will display their notes"
        swiss_logger info "  in default mode, path will have different display:"
        swiss_logger info "      - file: display the notes"
        swiss_logger info "      - directory: display a tree structure showing with the description"
        swiss_logger info "[Options]"
        swiss_logger info "  -s, --shortcut <shortcut_name>: can add a shortcut for files"
        swiss_logger info "  -st, --shortcut-type <shortcut_type>: type of shortcuts. Current support: alias, extension (default: extension)"
        swiss_logger highlight "[H] Filename MUST BE IDENTICAL. The function uses filename to search."
        swiss_logger highlight "[H] For adding notes, the description should be short. Otherwise it will impact the diplay when you view in tree mode."
    }
    local notes_path="$HOME/oscp-swiss/doc/utils-note.md"
    local utils_base_path=$swiss_utils
    local mode="default"
    local shortcut_name=""
    local shortcut_type="extension"
    local input_path

    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mode)
                mode="$2"
                if [[ ! "$mode" =~ ^(default|view|add)$ ]]; then
                    swiss_logger error "[e] mode support: default, view, add"
                    return 1
                fi
                shift 2
                ;;
            -s|--shortcut)
                shortcut_name="$2"
                shift 2
                ;;
            -st|--shortcut-type)
                shortcut_type="$2"
                if [[ ! "$shortcut_type" =~ ^(extension|alias)$ ]]; then
                    swiss_logger error "[e] shortcut_type support: extension, alias"
                    return 1
                fi
                shift 2
                ;;
            -h|--help)
                _helper
                return 0
                ;;
            *)
                input_path="$1"
                shift 1
                ;;
        esac
    done

    swiss_logger debug "[d] Mode: $mode"

    local absolute_path=""
    local relative_path=""

    if [[ "$input_path" == "$utils_base_path"* ]]; then
        relative_path="${input_path/#$utils_base_path//utils}"
        absolute_path=$input_path
    else
        relative_path=$input_path
        absolute_path="$utils_base_path/$relative_path"
    fi

    local filename=$(basename "$absolute_path")

    if [[ ! -e "$absolute_path" ]]; then
        swiss_logger error "[e] Path '$absolute_path' does not exist."
        return 1
    fi

    if [[ "$absolute_path" != "$utils_base_path"* ]]; then
        swiss_logger "[e] Only files under $utils_base_path are allowed."
    fi

    _add_note() {
        if grep -q "^# $filename$" "$notes_path"; then
            swiss_logger warn "[w] Notes exists already."
            return 0
        fi

        if [[ ! -z "$shortcut_name" ]]; then
            shortcut -f $absolute_path -n $shortcut_name -t $shortcut_type
        fi

        local temp_note="$mktemp.md"
        {
            echo "# Utils: $filename"
            echo "## Description: "
            echo "## Path: $relative_path"
            echo "## Shortcut: $shortcut_name"
            echo "## Usage:"
            echo "<-- Declare the usage here -->"
            echo ""
        } > "$temp_note"

        vim "$temp_note"
        \cat "$temp_note" >> "$notes_path"
        rm "$temp_note"
        swiss_logger info "[u] Note saved to $notes_path."
    }

    _view_note() {
        if grep -q "^# Utils: $filename$" "$notes_path"; then
            swiss_logger debug "[d] Note found for $filename:"
            output=$(sed -n "/^# Utils: $filename$/,/^# Utils: /{ /^# Utils: $filename$/b; /^# Utils: /q; p }" "$notes_path")
            if [ $_swiss_cat_use_pygmentize = true ]; then
                swiss_logger debug "[d] Use pygementize"
                local temp_md="$mktemp.md"
                echo $output >> $temp_md
                cat $temp_md
                rm $temp_md
            else
                echo $output
            fi
        else
            swiss_logger warn "[w] No notes found."
        fi
    }

    _view_tree() {
        swiss_logger debug "[d] Directory detected. Listing files with descriptions:"
        tree -C "$absolute_path" -L 1 | while read -r line; do
            filename=$(echo "$line" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' | awk '{print $NF}')
            if grep -q "^# Utils: $filename$" "$notes_path"; then
                local description=$(grep -A 1 "^# Utils: $filename$" "$notes_path" | grep '^## Description' | cut -d':' -f2-)
                echo -e "$line \033[33m$description\033[0m"
            else
                echo "$line"
            fi
        done
    }

    if [[ -d "$absolute_path" ]]; then
        case $mode in
            add)
                _add_note
                ;;
            view)
                _view_tree
                ;;
            default)
                _view_note
                ;;
            *)
                swiss_logger error "[e] Mode type incorrect."
                return 1
                ;;
        esac
    elif [[ -f "$absolute_path" ]]; then
        case $mode in
            add)
                _add_note
                ;;
            view)
                _view_note
                ;;
            default)
                _view_note
                ;;
            *)
                swiss_logger error "[e] Mode type incorrect."
                return 1
                ;;
        esac
    else
        swiss_logger error "[e] '$absolute_path' is neither a valid file nor a directory."
    fi
}

# TODO: Doc
function shortcut() {
    local file_path
    local name
    local type="extension"

    _helper() {
        swiss_logger info "Usage: shortcut <-f, --file FILE> <-n, --name VARIABLE_NAME> [-t, --type VARIABLE_TYPE]"
        swiss_logger info "Type supported: extension, alias (Default: extension)"
    }

    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                file_path="$2"
                shift 2
                ;;
            -n|--name)
                name="$2"
                shift 2
                ;;
            -t|--type)
                type="$2"
                if [[ ! "$type" =~ ^(extension|alias)$ ]]; then
                    swiss_logger error "[e] type support: alias, extension"
                    return
                fi
                shift 2
                ;;
            *)
                shift 1
                ;;
        esac
    done

    if [[ "$file_path" != /* ]]; then
        file_path="$(realpath "$file_path")"
    fi

    if [ ! -f "$file_path" ] && [ ! -d "$file_path" ]; then
        swiss_logger error "[e] The file path $file_path does not exist."
        return 1
    fi

    file_path="${file_path/#$HOME/\$HOME}"

    if [ -z "$name" ]; then
        swiss_logger error "[e] Required a name for the shortcut"
    fi

    local dest
    [[ "$type" == "extension" ]] && dest=$swiss_extension || dest=$swiss_alias

    if [ -n "$(tail -c 1 "$dest")" ]; then
        echo >> "$dest"
    fi

    echo "$name=\"$file_path\"" >> "$dest"
    swiss_logger info "[i] Variable $name for $file_path has been added to $type."
}

# Description:
#   function `cheatsheet` display a list of your cheatsheet files 
#   and allow you to select one to view its contents.
#   This can be useful for quick reference to common commands or syntax.
#   Path of your cheatsheet files is defined in the `cheatsheet_dir` variable.
#   Only support for .md files.
# Usage: cheatsheet
# TODO: configurable cheatsheet directory
function cheatsheet() {
    local cheatsheet_dir="$HOME/oscp-swiss/doc/cheatsheet"
    local files=()
    local original_files=()

    for file in "$cheatsheet_dir"/*.md; do    
        if [[ -f "$file" ]]; then
            original_files+=("$file")
            # Format filename for display: remove leading number, replace dashes with spaces, capitalize
            formatted_name=$(basename "$file" .md | sed 's/^[0-9]*-//' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
            files+=("$formatted_name")
        fi
    done

    # Check if there are any files to display
    if [[ ${#files[@]} -eq 0 ]]; then
        swiss_logger warn "[w] No cheatsheet files found in $cheatsheet_dir."
        return 1
    fi

    swiss_logger warn info "[i] Available Cheatsheets:"
    for ((i=1; i<=${#files[@]}; i++)); do
        swiss_logger info "$((i)). ${files[$i]}"
    done

    swiss_logger prompt "[i] Select a cheatsheet by number: \c"
    read choice

    if [[ $choice -gt 0 && $choice -le ${#files[@]} ]]; then
        local index=$((choice))
        swiss_logger info "[i] Displaying contents: ${original_files[$index]}:"
        cat "${original_files[$index]}"
    else
        swiss_logger warn "[w] Invalid selection."
    fi
}

# Description: function to check all predefined shortcuts under the extension.sh
# Usage: check_extension
function check_extension() {
    local alias_file="$swiss_extension"
    while IFS= read -r line; do
        [[ -z "$line" || ! "$line" =~ "=" || "$line" =~ ^# ]] && continue
        local var_name="${line%%=*}"
        local file_path="${line#*=}"
        [[ ! "$var_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && continue
        file_path="${file_path%\"}"
        file_path="${file_path#\"}"

        eval expanded_file_path="$file_path"

        if [[ ! -e "$expanded_file_path" ]]; then
            swiss_logger warn "[w] $var_name is invalid or does not exist: $expanded_file_path"
        fi
    done < "$alias_file"
}

function cb() {
    \cat $1 | xclip -selection clickboard
}

function merge_to_md() {
    output_file="report.md"
    echo "" > "$output_file"

    for file in *; do
        if [[ ! -f "$file" || "$file" == "$output_file" ]]; then
            continue
        fi

        if [[ "$file" == *.* ]]; then
            filetype="${file##*.}"
        else
            filetype=""
        fi

        echo "- \`$file\`"  >> "$output_file"
        echo -e "\t\`\`\`$filetype"  >> "$output_file"
        sed 's/^/\t/' "$file" >> "$output_file"
        echo -e "\t\`\`\`"  >> "$output_file"
    done

    swiss_logger info "[i] Contents in the current path are merged into $output_file."
}
