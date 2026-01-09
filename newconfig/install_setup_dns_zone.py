#!/usr/bin/env python3
"""
Exercise 3: Automated BIND9 DNS Zone Provisioning
Author: Expert Network Reliability Engineer
Description: Installs BIND9, configures a new zone (Master/Slave), 
generates zone files, and verifies resolution.
"""

import os
import sys
import subprocess
import shutil
import datetime
import socket

# BIND9 Constants
BIND_CONFIG_LOCAL = "/etc/bind/named.conf.local"
ZONE_FILE_DIR = "/etc/bind"
BIND_SERVICE = "bind9"

def check_root_privileges():
    """Ensure script is run as root (EUID 0)."""
    if os.geteuid()!= 0:
        print("[-] ERROR: Root privileges required for DNS configuration.")
        sys.exit(1)

def install_bind9():
    """
    Idempotent installation of the bind9 package.
    """
    pkg = "bind9"
    try:
        # dpkg-query to check status
        cmd =
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        if "install ok installed" in result.stdout:
            print(f"[+] Package: '{pkg}' is already installed.")
        else:
            print(f"[*] Package '{pkg}' missing. Installing...")
            subprocess.check_call(["apt-get", "update"], stdout=subprocess.DEVNULL)
            subprocess.check_call(["apt-get", "install", "-y", pkg])
            print(f"[+] Installation: '{pkg}' installed successfully.")
            
    except subprocess.CalledProcessError as e:
        print(f"[-] ERROR: Failed to manage package '{pkg}'. {e}")
        sys.exit(1)

def backup_named_conf():
    """
    Backs up the named.conf.local file before modification.
    """
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{BIND_CONFIG_LOCAL}.bak_{timestamp}"
    
    if os.path.exists(BIND_CONFIG_LOCAL):
        try:
            shutil.copy2(BIND_CONFIG_LOCAL, backup_path)
            print(f"[+] Backup: Configuration saved to {backup_path}")
        except IOError as e:
            print(f"[-] ERROR: Configuration backup failed: {e}")
            sys.exit(1)

def get_zone_parameters():
    """
    Interactively gathers zone configuration data from the user.
    """
    print("\n--- New DNS Zone Parameters ---")
    zone_name = input("Enter Zone Name (e.g., mangad.local): ").strip()
    
    # Validate Zone Type
    while True:
        zone_type = input("Enter Zone Type (master/slave): ").strip().lower()
        if zone_type in ['master', 'slave']:
            break
        print("Invalid type. Please enter 'master' or 'slave'.")
    
    # Default filename suggestion
    default_file = f"db.{zone_name}"
    zone_file = input(f"Enter Zone Filename [default: {default_file}]: ").strip()
    if not zone_file:
        zone_file = default_file
        
    return zone_name, zone_type, zone_file

def append_zone_definition(name, z_type, filename):
    """
    Appends the zone definition block to named.conf.local.
    """
    # Construct the full path for the zone file
    file_path = os.path.join(ZONE_FILE_DIR, filename)
    
    # Bind syntax requires semi-colons at specific points
    zone_config = f'\nzone "{name}" {{\n    type {z_type};\n    file "{file_path}";\n}};\n'
    
    try:
        with open(BIND_CONFIG_LOCAL, "a") as f:
            f.write(zone_config)
        print(f"[+] Configuration: Zone definition for '{name}' added to {BIND_CONFIG_LOCAL}")
        return file_path
    except IOError as e:
        print(f"[-] ERROR: Failed to update named configuration: {e}")
        sys.exit(1)

def create_zone_file(zone_name, file_path):
    """
    Generates a valid BIND9 zone file with SOA, NS, and A records.
    Only executed if the zone type is 'master'.
    """
    # Assuming the server's own IP is the nameserver IP.
    # In a complex setup, we might ask for this.
    # We use a dummy IP or try to detect it. For GNS3 topology, we use the Debian IP.
    ns_ip = "192.168.100.1" 
    ns_hostname = "ns1"
    
    # Dynamic SOA record generation
    # Serial is hardcoded to 1 for initial creation.
    # Root email format: root.zone_name. (replacing @ with.)
    
    zone_content = f"""$TTL    604800
@       IN      SOA     {ns_hostname}.{zone_name}. root.{zone_name}. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      {ns_hostname}.{zone_name}.
@       IN      A       {ns_ip}
{ns_hostname}     IN      A       {ns_ip}
"""
    try:
        with open(file_path, "w") as f:
            f.write(zone_content)
        print(f"[+] Zone Data: File created at {file_path}")
    except IOError as e:
        print(f"[-] ERROR: Failed to write zone data file: {e}")
        sys.exit(1)

def restart_bind_service():
    """
    Restarts bind9 and provides detailed error feedback if it fails.
    """
    print("[*] Restarting BIND9 Service...")
    try:
        subprocess.check_call()
        print("[+] SUCCESS: BIND9 service restarted.")
    except subprocess.CalledProcessError:
        print("[-] ERROR: BIND9 failed to restart.")
        print("    Running 'named-checkconf' for diagnostics:")
        subprocess.run(["named-checkconf", "-z"]) # -z checks zone files too
        sys.exit(1)

def test_dns_resolution(zone_name):
    """
    Tests local resolution of the newly created zone using Python's socket library.
    """
    print(f"\n[*] Testing Resolution for ns1.{zone_name}...")
    target = f"ns1.{zone_name}"
    
    # We need to make sure the system is using the local DNS.
    # This might require pointing /etc/resolv.conf to 127.0.0.1 temporarily
    # or utilizing a resolver object if using dnspython. 
    # For this exercise, we use the system resolver.
    
    try:
        ip = socket.gethostbyname(target)
        print(f"[+] TEST PASSED: {target} resolved to {ip}")
    except socket.gaierror:
        print(f"[-] TEST FAILED: Could not resolve {target}. Check configuration.")

def main():
    check_root_privileges()
    install_bind9()
    backup_named_conf()
    
    z_name, z_type, z_file = get_zone_parameters()
    
    file_path = append_zone_definition(z_name, z_type, z_file)
    
    # Only create the zone file if we are the master. 
    # If slave, the server will fetch it from the master.
    if z_type == 'master':
        create_zone_file(z_name, file_path)
    
    restart_bind_service()
    test_dns_resolution(z_name)

if __name__ == "__main__":
    main()

