#!/bin/bash
# Test script for 1_script.sh

SCRIPT_PATH="$HOME/fc64502/scripts/1_script.sh"


# Test 1: Clean slate

printf "Test 1: Clean environment\n"
rm -rf "$HOME/data_IBBCscripts"          # removes any structure that might exist
bash "$SCRIPT_PATH"                      # runs the script
find "$HOME/data_IBBCscripts"            # checks the director structure


# Test 2: Run again to check "already exists" behavior

printf "\nTest 2: Directory already exists\n"
bash "$SCRIPT_PATH"
