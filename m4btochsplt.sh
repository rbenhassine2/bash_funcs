m4btochsplt() {
    local use_dir_name=false
    local m4b_file=$(find . -maxdepth 1 -name "*.m4b" -type f | head -1)

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dir-name)
                shift
                if [[ "$1" == "true" || "$1" == "false" ]]; then
                    use_dir_name="$1"
                    shift
                else
                    echo "Error: --dir-name requires a boolean value (true or false)"
                    echo "Usage: mp3splt [--dir-name true|false]"
                    return 1
                fi
                ;;
            *)
                echo "Unknown option: $1"
                echo "Usage: mp3splt [--dir-name true|false]"
                return 1
                ;;
        esac
    done
    
    if [[ -z "$m4b_file" ]]; then
        echo "No M4B file found in current directory"
        return 1
    fi
    
    echo "Found M4B file: $m4b_file"
    
    local chapter_count=$(ffprobe -v quiet -print_format csv -show_chapters "$m4b_file" | wc -l)
    
    if [[ $chapter_count -eq 0 ]]; then
        echo "No chapters found in $m4b_file. Splitting without chapters"
        m4bsplt --dir-name "$use_dir_name"
        return 0
    fi

    echo "Found $chapter_count chapters. Splitting..."
    
    local base_name="${m4b_file%.*}"
    local chapter_num=0

    declare -a commands
    
    while IFS=',' read -r start_time end_time; do
        if [[ -n "$start_time" && -n "$end_time" ]]; then
            printf -v chapter_file "chapter_%03d" $((++chapter_num))
            cmd="ffmpeg -v quiet -i \"$m4b_file\" -ss $start_time -to $end_time -c copy -map_metadata 0 \"$chapter_file.m4b\""
            commands+=("$cmd")
        fi
    done < <(ffprobe -v quiet -print_format json -show_chapters "$m4b_file" | jq -r '.chapters[] | "\(.start_time),\(.end_time)"')

    echo $commands

    for cmd in "${commands[@]}"; do
        echo "Running: $cmd"
        # Execute the command
        eval "$cmd"
        if [ $? -eq 0 ]; then
            echo "Command succeeded"
        else
            echo "Command failed"
        fi
    done

    if [[ $? -eq 0 ]]; then
        rm "$m4b_file"
        m4bchsplt --dir-name "$use_dir_name"
        return 0
    else
        echo "Error: Failed to split $m4b_file into its chapters."
        return 1
    fi
}