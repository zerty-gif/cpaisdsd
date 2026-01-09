#!/usr/bin/env python3
"""
Network Host Enumeration Script

Scans the network 192.168.100.0/24 for active hosts (excluding 192.168.100.1)
and saves the results to a JSON file.

Author: ANDCS
License: See LICENSE.md
"""

import subprocess
import json
import sys
from pathlib import Path
from typing import List

C_NETWORK = "192.168.100"
C_START_IP = 2
C_END_IP = 254
C_EXCLUDE_IPS = [1]
C_OUTPUT_FILE = "active_hosts.json"
C_PING_TIMEOUT = 2
C_PING_COUNT = 1


def ping_host(ip_address: str) -> bool:
    """
    Ping a single host to check if it's active.
    
    Args:
        ip_address: IP address to ping
        
    Returns:
        True if host is reachable, False otherwise
    """
    try:
        result = subprocess.run(
            ["ping", "-c", str(C_PING_COUNT), "-W", str(C_PING_TIMEOUT), ip_address],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=C_PING_TIMEOUT + 1
        )
        return result.returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False


def enumerate_network() -> List:
    """
    Enumerate all active hosts on the network.
    
    Returns:
        List of dictionaries containing active host information
    """
    active_hosts = []
    
    print(f"[*] Scanning network {C_NETWORK}.0/24 (excluding {C_NETWORK}.1)...")
    print(f"[*] This may take a few minutes...")
    
    for octet in range(C_START_IP, C_END_IP + 1):
        if octet in C_EXCLUDE_IPS:
            continue
            
        ip_address = f"{C_NETWORK}.{octet}"
        sys.stdout.write(f"\r[*] Checking {ip_address}...")
        sys.stdout.flush()
        
        if ping_host(ip_address):
            active_hosts.append({
                "hostname": f"router_{octet}",
                "host": ip_address
            })
            print(f"\n[+] Found active host: {ip_address}")
    
    print(f"\n[*] Scan complete!")
    return active_hosts


def save_hosts(hosts: List) -> None:
    """
    Save enumerated hosts to a JSON file.
    
    Args:
        hosts: List of active host dictionaries
    """
    output_path = Path(C_OUTPUT_FILE)
    
    with open(output_path, 'w') as f:
        json.dump(hosts, f, indent=2)
    
    print(f"[+] Results saved to {C_OUTPUT_FILE}")
    print(f"[+] Found {len(hosts)} active host(s)")


def main() -> None:
    """Main entry point."""
    active_hosts = enumerate_network()
    
    if active_hosts:
        save_hosts(active_hosts)
    else:
        print("[!] No active hosts found on the network")


if __name__ == "__main__":
    main()
