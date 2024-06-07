#!/bin/bash

pgn_file="$1"

if [ ! -f "$pgn_file" ]; then
    echo "File does not exist: $pgn_file"
    exit 1
fi

metadata=$(grep -E "^\[.*\]" "$pgn_file")
echo "Metadata from PGN file:"
echo "$metadata"

move_start_line=$(grep -n -m 1 '^[0-9]\+' "$pgn_file" | cut -d: -f1)

#moves=$(tail -n +13 "$pgn_file")

# Extract the moves from the PGN file starting from the identified line
moves=$(tail -n +"$move_start_line" "$pgn_file")

uci_moves=$(python3 parse_moves.py "$moves")

IFS=' ' read -r -a uci_moves_array <<< "$uci_moves"

move_index=0


reset_board() {
    current_board=(
        "r n b q k b n r"
        "p p p p p p p p"
        ". . . . . . . ."
        ". . . . . . . ."
        ". . . . . . . ."
        ". . . . . . . ."
        "P P P P P P P P"
        "R N B Q K B N R"
    )
}

declare -A captured_pieces
declare -a promoted_pawns=()

display_board() {
    echo
    echo "Move $move_index/${#uci_moves_array[@]}"
    echo "  a b c d e f g h"
    for ((i=0; i<8; i++)); do
        row_num=$((8 - i))
        row="${current_board[i]}"
        # Split the row into individual squares
        squares=($row)
        printf "%d" "$row_num"
        for square in "${squares[@]}"; do
            printf " %s" "$square"
        done
        printf " %d\n" "$row_num"
    done
    echo "  a b c d e f g h"
}


# Function to convert board coordinates to array indices
board_index() {
    local file=$(echo "$1" | cut -c 1)
    local rank=$(echo "$1" | cut -c 2)
    local files="abcdefgh"
    local ranks="87654321"  
    local file_index=$(expr index "$files" "$file")
    local rank_index=$(expr index "$ranks" "$rank")
    echo "$((rank_index - 1)) $((file_index - 1))"

}


apply_move() {
    local move="$1"
    local from=${move:0:2}
    local to=${move:2:2}

     # Check for promotion
    if [[ "$move" =~ ^[a-h][27][a-h][18][qrbn]$ ]]; then
        promotion=${move:4:1}
        promoted_pawns+=("$move_index") 
        echo "move index:" $move_index
        echo "promoted_pawns_indexes:" $promoted_pawns
    fi

    # Capture the indices returned by board_inde
    local from_indices=($(board_index "$from"))
    local to_indices=($(board_index "$to"))

    # Extract the piece from the 'from' position , and remove it
    local piece=${current_board[from_indices[0]]:from_indices[1]*2:1}
    current_board[from_indices[0]]="${current_board[from_indices[0]]:0:from_indices[1]*2}. ${current_board[from_indices[0]]:from_indices[1]*2+2}"


    local captured_piece=${current_board[to_indices[0]]:to_indices[1]*2:1}
    if [ "$captured_piece" != "." ]; then
        captured_pieces["$move"]="$captured_piece"
    fi


    if [ -n "$promotion" ]; then
        piece="$promotion"

    fi
    current_board[to_indices[0]]="${current_board[to_indices[0]]:0:to_indices[1]*2}$piece ${current_board[to_indices[0]]:to_indices[1]*2+2}"

    moves_history+=("$move")

}


# Function to undo a move on the board
undo_move() {


    if (( ${#moves_history[@]} > 0 )); then
        # Get the last move and remove it from the history
        local move="${moves_history[-1]}"
        moves_history=("${moves_history[@]:0:${#moves_history[@]}-1}")

        local from=${move:0:2}
        local to=${move:2:2}

        local from_indices=($(board_index "$from"))
        local to_indices=($(board_index "$to"))

        # Move the piece back to its original position
        local piece=${current_board[to_indices[0]]:to_indices[1]*2:1}
        local captured_piece="${captured_pieces[$move]}"

        current_board[to_indices[0]]="${current_board[to_indices[0]]:0:to_indices[1]*2}. ${current_board[to_indices[0]]:to_indices[1]*2+2}"
        current_board[from_indices[0]]="${current_board[from_indices[0]]:0:from_indices[1]*2}$piece ${current_board[from_indices[0]]:from_indices[1]*2+2}"

         # Restore the captured piece, if any
        if [ -n "$captured_piece" ]; then
            current_board[to_indices[0]]="${current_board[to_indices[0]]:0:to_indices[1]*2}$captured_piece${current_board[to_indices[0]]:to_indices[1]*2+1}"
            unset captured_pieces["$move"]
        fi

        # Check if the move is in the list of promoted pawns
        for index in "${!promoted_pawns[@]}"; do
            if [ "${promoted_pawns[$index]}" == "$move_index" ]; then

                         if [[ "$piece" =~ [A-Z] ]]; then

                        piece="P"
                     else
                        piece="p"

                         echo
            fi
           
                current_board[from_indices[0]]="${current_board[from_indices[0]]:0:from_indices[1]*2}$piece ${current_board[from_indices[0]]:from_indices[1]*2+2}"
                unset "promoted_pawns[$index]"  
                break
            fi
        done


    else
        echo "No moves to undo."
    fi
}



# Function to move forward one step
move_forward() {
    local display_board="${1:-true}"  # Default value is true


    if (( move_index < ${#uci_moves_array[@]} )); then
        apply_move "${uci_moves_array[$move_index]}"
        (( move_index++ ))
    else
        echo
        echo "No more moves available."
        return  
    fi
    # Display the board if requested
    if $display_board; then
        display_board
    fi
}

# Function to move backward one step
move_backward() {
    if (( move_index > 0 )); then
        (( move_index-- ))
        undo_move "${uci_moves_array[$move_index]}"
        display_board
        
    else
        display_board
    fi
}

# Function to reset the board to the start
go_to_start() {
    reset_board
    move_index=0
    moves_history=()
    display_board
}

# Function to apply all moves to the end
go_to_end() {
    while (( move_index < ${#uci_moves_array[@]} )); do
         move_forward false  # Don't display the board
    done
    display_board
    
}


# Initialize the board
reset_board
display_board

# Simulate the game interactively
while true; do

  
   echo -n "Press 'd' to move forward, 'a' to move back, 'w' to go to the start, 's' to go to the end, 'q' to quit:"
   #read -n 1 key
   read key




    case "$key" in
        "d")
            move_forward
            ;;
        "a")
            move_backward
            ;;
        "w")
            go_to_start
            ;;
        "s")
            go_to_end
            ;;
        "q")
            echo
            echo "Exiting."
            echo "End of game."

            break
            ;;
        *)
            echo
            echo "Invalid key pressed: $key"
            ;;
    esac

done
