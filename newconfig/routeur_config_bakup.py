#!/usr/bin/env python3
"""
Exercise 1: Automated Cisco Router Configuration Backup
Author: Expert Network Analyst
Description: Connects to R1, R2, R3, retrieves running-config, 
saves to file, and handles errors.
"""

import datetime
import json
import os
from pathlib import Path
from typing import List
from dotenv import load_dotenv
from netmiko import ConnectHandler
from netmiko.exceptions import NetmikoTimeoutException, NetmikoAuthenticationException
from paramiko.ssh_exception import SSHException

# Load environment variables from .env file
load_dotenv()

# Get credentials from environment variables
C_NETMIKO_USER = os.getenv("NETMIKO_USER", "admin")
C_NETMIKO_PASS = os.getenv("NETMIKO_PASS", "password")
C_NETMIKO_SECRET = os.getenv("NETMIKO_SECRET", "secret")
C_NETMIKO_PORT = int(os.getenv("NETMIKO_PORT", "22"))


def load_router_inventory(inventory_file: str = "active_hosts.json") -> List:
    """
    Load router inventory from a JSON file and merge with credentials from .env.
    
    Args:
        inventory_file: Path to the inventory JSON file
        
    Returns:
        List of router configuration dictionaries
        
    Raises:
        FileNotFoundError: If inventory file does not exist
    """
    inventory_path = Path(inventory_file)
    
    if not inventory_path.exists():
        raise FileNotFoundError(
            f"Inventory file '{inventory_file}' not found. "
            "Run cenum_hosts.py to generate it."
        )
    
    with open(inventory_path, 'r') as f:
        hosts = json.load(f)
    
    # Add credentials and device type to each host
    for host in hosts:
        host["device_type"] = "cisco_ios"
        host["username"] = C_NETMIKO_USER
        host["password"] = C_NETMIKO_PASS
        host["secret"] = C_NETMIKO_SECRET
        host["port"] = C_NETMIKO_PORT
        # Remove 'hostname' if present, as netmiko uses 'host' for IP/hostname
        if "hostname" in host:
            del host["hostname"]
    
    return hosts


# Load router inventory from file
try:
    ROUTER_INVENTORY = load_router_inventory()
except FileNotFoundError as e:
    print(f"[!] ERROR: {e}")
    ROUTER_INVENTORY = []

def backup_configurations():
    """
    Iterates through the router inventory and backs up the running configuration.
    """
    print(f"[*] Starting Configuration Backup Task at {datetime.datetime.now()}")
    print("=" * 70)

    for device in ROUTER_INVENTORY:
        current_host = device['host']
        print(f"[*] Processing Device: {current_host}")

        try:
            # Establish the SSH connection
            # Netmiko handles the SSH handshake and prompt detection
            net_connect = ConnectHandler(**device)
            
            # Enter Enable Mode (Privileged EXEC)
            # Required because 'show running-config' is a privileged command
            net_connect.enable()
            
            # Retrieve the configuration
            # send_command handles the paging (--More--) automatically
            config_data = net_connect.send_command("show running-config")
            
            # Construct the filename using string concatenation as requested
            # Format: backup_HOSTNAME.txt
            filename = "backup_" + current_host.replace(".", "_") + ".txt"
            
            # Write the configuration to disk
            with open(filename, 'w') as f:
                f.write(config_data)
            
            # Success notification
            print(f"[+] SUCCESS: Configuration for {current_host} saved to {filename}")
            
            # Gracefully disconnect
            net_connect.disconnect()

        except NetmikoAuthenticationException:
            # Specific handling for authentication failures
            print(f"[-] ERROR (Auth): Failed to authenticate to {current_host}. Check username/password.")
            
        except NetmikoTimeoutException:
            # Specific handling for timeouts (network or device unresponsive)
            print(f"[-] ERROR (Timeout): Connection to {current_host} timed out. Check IP reachability.")
            
        except SSHException as e:
            # Specific handling for underlying SSH protocol errors
            print(f"[-] ERROR (SSH): Protocol error with {current_host}: {str(e)}")
            
        except Exception as e:
            # Catch-all for other unforeseen errors (e.g., file permission issues)
            print(f"[-] ERROR (General): An unexpected error occurred: {str(e)}")
            
        print("-" * 70)

    print(f"[*] Backup Job Completed at {datetime.datetime.now()}")

if __name__ == "__main__":
    backup_configurations()