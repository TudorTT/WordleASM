##  Wordle
A fully functional Wordle clone built in x86 assembly for the emu8086 emulator. The program gets the words from the file words.txt.

## Gameplay

6 attempts to guess a 5-letter secret word
Color-coded feedback system:

- Green : Correct letter, correct position
- Yellow : Correct letter, wrong position
- Gray : Letter not in word

## Features
- Dictionary-based word validation
- Random secret word selection using system timer

## Architecture:

- COM executable format (ORG 100h)
- Supports 128 word dictionary from words.txt
- File format: 7 bytes per word (5 letters + CR/LF)
- Automatic uppercase conversion for consistency

## Key Routines

- load_words : Reads and validates dictionary file
- select_secret : Uses timer (INT 1Ah) for pseudo-random selection
- get_input : Character-by-character input with backspace support
- validate_word : Linear search through word list
- check_guess : Letter-by-letter comparison with color output
- print_number : Decimal conversion for displaying tries

## Notes
- This is a universoty project
