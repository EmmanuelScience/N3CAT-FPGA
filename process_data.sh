#!/bin/bash
# process_data.sh - FPGA host script for processing data
# Runs on raju host machine

set -e

# Read input from stdin
read INPUT_VALUE

# Validate input
if ! [[ "$INPUT_VALUE" =~ ^-?[0-9]+$ ]]; then
    echo "Error: Invalid input - must be integer"
    exit 1
fi

# Convert to little-endian hex for DMA
create_binary() {
    local value=$1
    local filename=$2
    
    # Handle negative numbers (two's complement)
    if [ $value -lt 0 ]; then
        value=$((4294967296 + value))  # Convert to unsigned 32-bit
    fi
    
    local hex_val=$(printf "%08x" $value)
    local byte1=${hex_val:6:2}
    local byte2=${hex_val:4:2}
    local byte3=${hex_val:2:2}
    local byte4=${hex_val:0:2}
    
    printf "\\x$byte1\\x$byte2\\x$byte3\\x$byte4" > $filename
}

# Ensure we're in the correct directory
cd ~/core_tile/fpga/meep_shell

# Create input binary
create_binary $INPUT_VALUE input_data.bin

# Send data to FPGA
dma-to-device -d /dev/qdma08000-MM-1 -s 4 -a 0x1000 -f input_data.bin >/dev/null 2>&1

# Wait for processing
sleep 1

# Read result from FPGA
dma-from-device -d /dev/qdma08000-MM-1 -s 4 -a 0x1010 -f output_data.bin >/dev/null 2>&1

# Convert result back to integer
RESULT=$(od -An -td4 output_data.bin | tr -d ' ')

# Cleanup
rm -f input_data.bin output_data.bin

# Return result
echo $RESULT