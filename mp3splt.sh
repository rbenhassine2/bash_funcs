mp3splt() {
    local input_file
    local dir_name
    local use_dir_name=false
    local segment_name_format

    # Check if ffmpeg is available
    if ! command -v ffmpeg &> /dev/null; then
        echo "Error: ffmpeg is not installed or not in PATH"
        return 1
    fi

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
    
    # Find the first M4B file in current directory
    input_file=$(find . -maxdepth 1 -name "*.mp3" -type f | head -n 1)
    
    if [[ -z "$input_file" ]]; then
        echo "Error: No MP3 file found in current directory"
        return 1
    fi

    echo "Found MP3 file: $input_file"

    # Get current directory name for output prefix
    dir_name=$(basename "$(pwd)")   
    if [[ "$use_dir_name" == true ]]; then
        segment_name_format="${dir_name}-%03d"
    else
        segment_name_format="%03d"
    fi

    # Convert M4B to MP3 with 5-minute segments, removing all tags
    ffmpeg -i "$input_file" -f segment -segment_time 300 -map_metadata -1 -map_chapters -1 -write_id3v2 0 -map 0:a -c copy "${segment_name_format}.mp3"


    if [[ $? -eq 0 ]]; then
        rm "$input_file"
        find . -maxdepth 1 -type f ! -name "*.mp3" -delete
        echo "Conversion completed successfully!"
    else
        echo "Error: Conversion failed"
        return 1
    fi
}