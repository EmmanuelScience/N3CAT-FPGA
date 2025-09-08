#!/usr/bin/env python3
"""
Client script for remote FPGA processing
Reads data from file and sends to relay server
"""
import socket
import time
import sys

def send_to_relay(data, host="127.0.0.1", port=9999):
    """Send data to relay server and wait for response"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((host, port))
            s.sendall(f"{data}\n".encode())
            
            # Wait for response
            response = s.recv(1024).decode().strip()
            return response
    except Exception as e:
        print(f"Error communicating with relay: {e}")
        return None

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 client.py <input_file.txt>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    try:
        with open(input_file, 'r') as f:
            data = f.read().strip()
    except FileNotFoundError:
        print(f"Error: File {input_file} not found")
        sys.exit(1)
    
    print(f"Sending data to FPGA: {data}")
    
    # Convert to integer for validation
    try:
        value = int(data)
        print(f"Processing value: {value}")
    except ValueError:
        print("Error: Input must be a valid integer")
        sys.exit(1)
    
    # Send to relay server
    result = send_to_relay(data)
    
    if result:
        try:
            result_value = int(result)
            print(f"FPGA Result: {result_value}")
            print(f"Expected (input * 2): {value * 2}")
            
            if result_value == value * 2:
                print("✓ Processing successful!")
            else:
                print("⚠ Unexpected result")
        except ValueError:
            print(f"Received: {result}")
    else:
        print("Failed to get response from FPGA")

if __name__ == "__main__":
    main()