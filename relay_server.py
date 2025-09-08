#!/usr/bin/env python3
"""
Relay server running on eirabor@ssh.hca.bsc.es
Forwards data between client and FPGA host
"""
import socket
import subprocess
import threading
import time

def handle_client(conn, addr):
    """Handle individual client connection"""
    print(f"Connection from {addr}")
    
    try:
        # Receive data from client
        data = conn.recv(1024).decode().strip()
        if not data:
            return
            
        print(f"Received from client: {data}")
        
        # Forward to FPGA host via SSH
        ssh_command = [
            "ssh", "raju", 
            f"cd ~/core_tile/fpga/meep_shell && echo '{data}' | ./process_data.sh"
        ]
        
        try:
            result = subprocess.run(
                ssh_command, 
                capture_output=True, 
                text=True, 
                timeout=30
            )
            
            if result.returncode == 0:
                response = result.stdout.strip()
                print(f"FPGA returned: {response}")
            else:
                response = f"Error: {result.stderr.strip()}"
                print(f"SSH Error: {response}")
                
        except subprocess.TimeoutExpired:
            response = "Timeout: FPGA processing took too long"
            print(response)
        except Exception as e:
            response = f"SSH Error: {str(e)}"
            print(response)
        
        # Send response back to client
        conn.sendall(response.encode())
        
    except Exception as e:
        print(f"Error handling client {addr}: {e}")
        conn.sendall(f"Server Error: {str(e)}".encode())
    finally:
        conn.close()

def main():
    HOST = '0.0.0.0'
    PORT = 9999
    
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((HOST, PORT))
        s.listen(5)
        
        print(f"Relay server listening on {HOST}:{PORT}")
        
        while True:
            try:
                conn, addr = s.accept()
                # Handle each client in a separate thread
                client_thread = threading.Thread(
                    target=handle_client, 
                    args=(conn, addr)
                )
                client_thread.daemon = True
                client_thread.start()
                
            except KeyboardInterrupt:
                print("\nShutting down relay server...")
                break
            except Exception as e:
                print(f"Server error: {e}")

if __name__ == "__main__":
    main()