mp3chsplt() {
    local use_dir_name=false
    local dir_name
    local mp3_files
    local file_num=1
    
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

    # Find all MP3 files in current directory, sorted by name
    mapfile -t mp3_files < <(find . -maxdepth 1 -name "*.mp3" -type f | sort -V)
    
    if [[ ${#mp3_files[@]} -eq 0 ]]; then
        echo "Error: No MP3 files found in current directory"
        return 1
    fi

    echo "Found ${#mp3_files[@]} MP3 file(s)"

    # Get current directory name for output prefix
    dir_name=$(basename "$(pwd)")
    
    # Determine zero-padding for file numbers
    local file_num_format
    if [[ ${#mp3_files[@]} -lt 100 ]]; then
        file_num_format="%02d"
    else
        file_num_format="%03d"
    fi
    
    # Check if ffmpeg is available
    if ! command -v ffmpeg &> /dev/null; then
        echo "Error: ffmpeg is not installed or not in PATH"
        return 1
    fi
    
    # Process each MP3 file
    for input_file in "${mp3_files[@]}"; do
        echo "Converting $input_file to MP3 segments (file $file_num)..."
        
        # Format file number with appropriate zero-padding
        local formatted_file_num
        printf -v formatted_file_num "$file_num_format" "$file_num"
        
        # Build output filename based on flag
        local output_prefix
        if [[ "$use_dir_name" == true ]]; then
            output_prefix="${dir_name}-${formatted_file_num}"
        else
            output_prefix="${formatted_file_num}"
        fi
        
        # Get duration of the file in seconds
        local duration
        duration=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$input_file" 2>/dev/null)
        
        # Check if duration is valid and convert to integer
        if [[ -n "$duration" ]] && [[ "$duration" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            local duration_int=${duration%.*}  # Remove decimal part
            
            if [[ $duration_int -le 300 ]]; then
                # File is 5 minutes or less, just rename it
                echo "File is ${duration_int}s (≤5min), renaming instead of splitting..."
                ffmpeg -i "$input_file" -map_metadata -1 -map_chapters -1 -write_id3v2 0 -map 0:a -c copy "${output_prefix}.mp3"
                if [[ $? -eq 0 ]]; then
                    rm "$input_file"
                else
                    echo "Error: Failed to process $input_file"
                    return 1
                fi
            else
                # File is longer than 5 minutes, split it
                echo "File is ${duration_int}s (>5min), splitting into segments..."
                ffmpeg -i "$input_file" -f segment -segment_time 300 -map_metadata -1 -map_chapters -1 -write_id3v2 0 -map 0:a -c copy "${output_prefix}-%03d.mp3"
                
                if [[ $? -eq 0 ]]; then
                    rm "$input_file"
                else
                    echo "Error: Failed to process $input_file"
                    return 1
                fi
            fi
        else
            echo "Warning: Could not determine duration for $input_file, skipping..."
            continue
        fi

        echo "Successfully processed $input_file"
        
        ((file_num++))
    done
    
    # Clean up any non-MP3 files
    find . -maxdepth 1 -type f ! -name "*.mp3" -delete
    echo "All conversions completed successfully!"
}