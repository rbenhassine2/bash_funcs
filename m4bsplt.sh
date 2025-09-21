m4bsplt() {
    local input_file
    local dir_name
    local use_dir_name=false

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
    input_file=$(find . -maxdepth 1 -name "*.m4b" -type f | head -n 1)
    
    if [[ -z "$input_file" ]]; then
        echo "Error: No M4B file found in current directory"
        return 1
    fi

    echo "Found M4B file: $input_file"

    # Get current directory name for output prefix
    dir_name=$(basename "$(pwd)")
    if [[ "$use_dir_name" == true ]]; then
        output_prefix="${dir_name}-%03d"
    else
        output_prefix="%03d"
    fi

    
    # Check if ffmpeg is available
    if ! command -v ffmpeg &> /dev/null; then
        echo "Error: ffmpeg is not installed or not in PATH"
        return 1
    fi
    
    echo "Converting $input_file to MP3 segments..."
    
    # Convert M4B to MP3 with 5-minute segments, removing all tags
    ffmpeg -i "$input_file" \
        -f segment \
        -segment_time 300 \
        -c:a mp3 \
        -b:a 128k \
        -map_metadata -1 \
        -map_chapters -1 \
        -write_id3v2 0 \
        -map 0:a \
        "${output_prefix}.mp3"


    if [[ $? -eq 0 ]]; then
        find . -maxdepth 1 -type f ! -name "*.mp3" -delete
        echo "Conversion completed successfully!"
    else
        echo "Error: Conversion failed"
        return 1
    fi
}