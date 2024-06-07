#!/bin/bash

# Function to display usage message
usage() {
    echo "Usage: $0 <source_pgn_file> <destination_directory>"
    exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    usage
fi

# Assign command-line arguments to variables
input_file="$1"
dest_dir="$2"

# Check if the source PGN file exists
if [ ! -e "$input_file" ]; then
    echo "Error: File '$input_file' does not exist."
    exit 1
fi

# Check if the destination directory exists, create it if it does not
if [ ! -d "$dest_dir" ]; then
    mkdir -p "$dest_dir"
    echo "Created directory '$dest_dir'."
fi


# Function to split PGN file into individual games
split_pgn_file() {
    local file="$1"
    local output_dir="$2"
    local base_name=$(basename "$file" .pgn)
    local game_num=0
    local game_content=""
    local empty_line_count=0
    local trimmed_content=""

    # Read the file line by line
    while IFS= read -r line || [ -n "$line" ]; do

        # If the line is empty or only whitespace, increment the empty line count
        if [[ "$line" =~ ^[[:space:]]*$ ]]; then
            empty_line_count=$((empty_line_count + 1))

            # If two empty lines are detected, it indicates the end of one game
            if [ "$empty_line_count" -eq 2 ]; then
                    # Save the previous game if it exists
                    if [ -n "$game_content" ]; then
                        game_num=$((game_num + 1))
                        output_file="$output_dir/${base_name}_$game_num.pgn"

                         # Append an additional empty line before saving
                         game_content+="\n"

                         # Remove trailing newline from game_content
                         echo -e "${game_content%$'\n'}" > "$output_file"

                        # Delete the last row
                         #sed -i '$d' "$output_file"


                        echo "Saved game to $output_file"
                        game_content=""
                    fi
                    # Reset the empty line count for the next game
                    empty_line_count=0
            elif [ "$empty_line_count" -eq 1 ]; then
                # Append theg the first empty line
                game_content+="$line\n"
            fi
        else
            # Append the line to game content,
            game_content+="$line\n"
        fi

      
    done < "$file"

    # Save the last game if it exists
    if [ -n "$game_content" ]; then
        game_num=$((game_num + 1))
        output_file="$output_dir/${base_name}_$game_num.pgn"
        echo -e "$game_content" > "$output_file"
        echo "Saved game to $output_file"
    fi

    echo "All games have been split and saved to '$output_dir'."
}



# Split the PGN file into individual game files
split_pgn_file "$input_file" "$dest_dir"


