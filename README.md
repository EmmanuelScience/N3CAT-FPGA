# N3CAT-FPGA
Help Scripts for FPGA and SDR testing
# RISC-V FPGA Remote Processing System

This repository contains a complete implementation of a remote processing system using the Sargantana RISC-V core deployed on an Alveo U280 FPGA. 

## System Architecture

The system implements a multi-layered communication architecture that enables remote processing through the following data flow:

**Client Machine → SSH Relay Server → FPGA Host → Sargantana Core → Results Return Path**

The architecture addresses the challenge of accessing FPGA resources that reside behind multiple network boundaries while maintaining security through SSH authentication. The relay server acts as an intermediary, forwarding requests from the client to the FPGA host, which directly interfaces with the Sargantana core.

## Repository Structure

### Core Processing Files
- **`fpga_processor.S`** - RISC-V assembly program that runs on the Sargantana core, implementing a multiply-by-2 operation with continuous polling for new input data
- **`process_data.sh`** - Shell script that interfaces with QDMA hardware on the FPGA host, managing data conversion, DMA operations, and error handling
- **`linker.ld`** - Memory layout definition that maps code execution to the core's address space at 0x80000000
- **`Makefile`** - Build system that coordinates cross-compilation with the RISC-V toolchain

### Communication Scripts
- **`client.py`** - Client application that reads input data and communicates with the relay server through SSH tunneling
- **`relay_server.py`** - Server that runs on the intermediate SSH host, forwarding requests between clients and the FPGA host



## Prerequisites

### Hardware Requirements
- Alveo U280 FPGA with loaded Sargantana core bitstream
- Host machine with QDMA drivers installed and configured
- Network access to intermediate relay server

### Software Dependencies
- RISC-V cross-compilation toolchain (riscv64-unknown-elf-gcc)
- Python 3.6 or later
- SSH client with key forwarding capabilities
- QDMA utilities (dma-to-device, dma-from-device)

### Network Architecture
The system requires three connected machines: your local client machine connects to an intermediate SSH relay server (ssh.hca.bsc.es), which forwards requests to the FPGA host machine. This architecture accommodates typical research computing environments where FPGA resources are accessible only through gateway servers.

## Setup Instructions

### SSH Key Configuration

The system requires passwordless SSH authentication between all machines in the communication chain. Configure this by running the provided setup script or following these manual steps:

**On your local machine:**
```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Copy public key to relay server
ssh-copy-id user@ssh.hca.bsc.es

# Test passwordless connection
ssh user@ssh.hca.bsc.es
```

**On the relay server:**
```bash
# Generate key for FPGA host connection
ssh-keygen -t rsa -b 4096

# Copy key to FPGA host
ssh-copy-id user@raju

# Verify connection
ssh raju
```

### FPGA Programming

Before using the processing system, the FPGA must be programmed with the Sargantana core and the processing program must be loaded:

```bash
# On the FPGA host (raju)
cd ~/path/to/repository

# Compile the processing program
make clean && make

# Load the bitstream (if needed)
# ./load_binary.sh simple_test.bin

# Make processing script executable
chmod +x process_data.sh
```

### SSH Tunnel Setup

The communication system requires an SSH tunnel to forward network traffic from your local machine to the relay server. This tunnel must remain active during all processing operations:

```bash
# From your local machine, establish the tunnel
ssh -L 9999:hca-server:9999 user@ssh.hca.bsc.es

# Keep this terminal session open
```

This command creates a local port (9999) that forwards traffic through the SSH connection to the relay server's port 9999, enabling the client to connect to localhost while actually communicating with the remote relay.

## Usage Guide

### Basic Processing Workflow

The complete processing workflow involves several coordinated steps across multiple machines:

**Step 1: Start the Relay Server**
```bash
# On the relay server (user@ssh.hca.bsc.es)
cd /path/to/repository
python3 relay_server.py
```

The relay server will display a confirmation message and begin listening for client connections on port 9999.

**Step 2: Establish SSH Tunnel**
```bash
# From your local machine (keep this session open)
ssh -L 9999:hca-server:9999 user@ssh.hca.bsc.es
```

**Step 3: Prepare Input Data**
```bash
# On your local machine
echo "42" > test_input.txt
```

**Step 4: Execute Processing**
```bash
# On your local machine
python3 client.py test_input.txt
```

### Expected Output

A successful processing operation produces output similar to this:

```
Sending data to FPGA: 42
Processing value: 42
FPGA Result: 84
Expected (input * 2): 84
✓ Processing successful!
```

This output demonstrates the complete data flow: the client sends value 42 through the SSH tunnel to the relay server, which forwards it to the FPGA host where the Sargantana core processes it by multiplying by 2, returning the result 84 through the reverse path.



## File Descriptions and Implementation Details

### Core Processing Components

**fpga_processor.S** implements the computational logic that runs on the Sargantana RISC-V core. The assembly program establishes a continuous polling loop that monitors memory address 0x80001000 for input data, processes each value by shifting left one bit (equivalent to multiplication by 2), and writes results to address 0x80001010. The program uses the `li` pseudo-instruction rather than direct `lui` commands to avoid sign-extension issues that can cause memory access faults.

**process_data.sh** serves as the critical interface between the high-level communication system and the low-level QDMA hardware. This shell script handles input validation, converts decimal integers to little-endian binary format required by the DMA operations, manages file operations, and includes comprehensive error handling. The script creates temporary binary files for DMA transfers and ensures proper cleanup regardless of operation success or failure.

**linker.ld** defines the memory layout crucial for proper program execution on the Sargantana core. The linker script maps code execution to address 0x80000000, which corresponds to the core's expected execution region as defined by the bootrom. This addressing is essential because the core's memory management unit translates these addresses to physical HBM locations.

### Communication Infrastructure

**client.py** implements the user-facing interface that manages the complete request-response cycle. The client handles file input validation, establishes socket connections to the relay server through the SSH tunnel, manages network timeouts, and provides clear feedback about processing results. The script includes error handling for various failure modes including network connectivity issues and invalid server responses.

**relay_server.py** operates as the critical bridge between external clients and the FPGA infrastructure. This server manages concurrent client connections using threading, executes SSH commands to forward requests to the FPGA host, handles authentication and connection management, and provides logging for debugging and monitoring. The server design allows multiple clients to queue processing requests while maintaining session isolation.

## Troubleshooting Common Issues

### Connection Problems

**SSH Tunnel Not Working**: Verify that the SSH tunnel command uses the correct hostname and port numbers. The tunnel must remain active (keep the SSH session open) throughout processing operations. Test the tunnel by connecting to localhost:9999 from another terminal.

**Authentication Failures**: Ensure SSH keys are properly installed on both the relay server and FPGA host. Test passwordless authentication by manually connecting via SSH before running the automated scripts.

**Network Timeouts**: Processing operations include built-in timeouts to prevent hanging connections. If operations consistently timeout, check network connectivity and FPGA host responsiveness.

### FPGA Processing Issues

**DMA Device Access**: Verify that the QDMA devices (/dev/qdma08000-MM-1) are accessible and properly initialized. Check device permissions and ensure the QDMA drivers are loaded correctly.

**Memory Coherency**: The current system works around cache coherency limitations by implementing single-transaction processing. If results appear inconsistent, verify that the FPGA bitstream was recently reloaded to clear any cached state.

**Program Loading**: Ensure the RISC-V processing program is compiled and loaded correctly before attempting remote operations. The FPGA must be programmed with both the Sargantana core bitstream and the processing assembly code.

### Debugging Techniques

Enable verbose logging in both client and server scripts to trace the complete data flow. Check SSH connection logs to identify authentication or routing issues. Verify FPGA host accessibility by manually executing the processing script with test data.

