# Chess Simulator Bash

This repository contains a set of Bash scripts designed to help you manage and analyze chess games stored in PGN (Portable Game Notation) files. Whether you have a large collection of chess games that need to be split into manageable pieces or you want to simulate and visualize individual games, these scripts provide a straightforward and efficient solution.

## Installation

1. Clone this repository to your local machine:

    ```bash
    git clone https://github.com/edenbdv/Chess_Simulator_Bash.git
    cd Chess_Simulator_Bash
    ```

2. Make the script executable:

    ```bash
    chmod +x ./pgn_split.sh
    chmod +x ./chess_sim.sh

    ```


## Usage

### Part 1: Split PGN Files


1. Prepare your PGN file and place it in the project directory. For example, `capmemel24.pgn`.

2. Run the `pgn_split.sh` script to split the PGN file:

    ```bash
    ./pgn_split.sh ./capmemel24.pgn ./splited_pgn
    ```

     - The first argument is the path to the input PGN file.
    - The second argument is the directory where the split PGN files will be saved.

3. The split PGN files will be saved in the specified directory.


### Part 2: Simulate Chess Games

1. Run the `chess_sim.sh` script to simulate a chess game from a split PGN file:

    ```bash
    ./chess_sim.sh splited_pgn/capmemel24_1.pgn
    ```

    - The argument is the path to the specific split PGN file you want to simulate.
