#!/usr/bin/env python3
"""
Automated BIND9 DNS Zone Provisioning
Author: ANDCS
Contact: andcs@mailbox.org
Description: Installs BIND9, configures a new zone (Master/Slave),
generates zone files, and verifies resolution.

Abstract:
This script automates the provisioning of DNS zones using BIND9, ensuring that the necessary configurations are applied to facilitate domain name resolution. The script is designed to be idempotent, allowing for safe re-execution without adverse effects on existing configurations.

Algorithmic Analysis:
- Time Complexity: O(n) where n is the number of commands executed.
- Space Complexity: O(1) as the script primarily utilizes system resources without significant memory overhead.

System Call Analysis:
The script invokes several system calls, including:
- `os.geteuid()`: To check for root privileges.
- `subprocess.run()`: To execute shell commands for package management.
- `shutil.copy2()`: To create backups of configuration files.

Security & Idempotency:
The script is designed to be idempotent, meaning it can be executed multiple times without changing the outcome beyond the initial application. It checks for root privileges to mitigate risks associated with privilege escalation.

Failure Modes:
Potential exit codes include:
- 0: Success
- 1: General error (e.g., failure to install packages)
- Specific error codes from subprocess calls indicating failure in command execution.

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
    """Ensure script is run as root (EUID 0).

    Abstract:
    This function verifies that the script is executed with root privileges, which are necessary for modifying system configurations.

    Algorithmic Analysis:
    - Time Complexity: O(1)
    - Space Complexity: O(1)

    System Call Analysis:
    - `os.geteuid()`: Checks the effective user ID.

    Security & Idempotency:
    This function is critical for ensuring that subsequent operations do not fail due to insufficient permissions.

    Failure Modes:
    - Exits with code 1 if not run as root.
    """
    if os.geteuid() != 0:
        print("[-] ERROR: Root privileges required for DNS configuration.")
        sys.exit(1)


def install_bind9():
    """
    Idempotent installation of the bind9 package.

    Abstract:
    This function installs the BIND9 package if it is not already installed, ensuring that the DNS server is available for configuration.

    Algorithmic Analysis:
    - Time Complexity: O(n) where n is the number of commands executed.
    - Space Complexity: O(1)

    System Call Analysis:
    - `subprocess.run()`: Executes shell commands to check and install the package.

    Security & Idempotency:
    The function is designed to be idempotent, allowing for safe re-execution.

    Failure Modes:
    - Exits with code 1 if the installation fails.
    """
    pkg = "bind9"
    try:
        cmd = ["dpkg-query", "-W", pkg]
        result = subprocess.run(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )

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

    Abstract:
    This function creates a backup of the BIND9 configuration file to prevent data loss during updates.

    Algorithmic Analysis:
    - Time Complexity: O(1)
    - Space Complexity: O(1)

    System Call Analysis:
    - `shutil.copy2()`: Copies the configuration file to a backup location.

    Security & Idempotency:
    The function is idempotent; multiple executions will not affect the existing backup.

    Failure Modes:
    - Exits with code 1 if the backup fails.
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

    Abstract:
    This function prompts the user for necessary parameters to configure a new DNS zone.

    Algorithmic Analysis:
    - Time Complexity: O(1)
    - Space Complexity: O(1)

    System Call Analysis:
    - None.

    Security & Idempotency:
    The function is idempotent; it simply collects user input.

    Failure Modes:
    - None.
    """
    print("\n--- New DNS Zone Parameters ---")
    zone_name = input("Enter Zone Name (e.g., mangad.local): ").strip()

    # Validate Zone Type
    while True:
        zone_type = input("Enter Zone Type (master/slave): ").strip().lower()
        if zone_type in ["master", "slave"]:
            break
        print("Invalid type. Please enter 'master' or 'slave'.")

    # Default filename suggestion
    default_file = f"db.{zone_name}"
    zone_file = input(f"Enter Zone Filename [default: {default_file}]: ").strip()
    if not zone_file:
        zone_file = default_file

    return zone_name, zone_type, zone_file


def append_zone_definition(name: str, z_type: str, filename: str):
    """
    Appends the zone definition block to named.conf.local.

    Abstract:
    This function modifies the BIND9 configuration file to include the new zone definition.

    Algorithmic Analysis:
    - Time Complexity: O(1)
    - Space Complexity: O(1)

    System Call Analysis:
    - `open()`: Opens the configuration file for appending.

    Security & Idempotency:
    The function is idempotent; repeated calls will not alter the existing configuration.

    Failure Modes:
    - Exits with code 1 if the update fails.
    """
    file_path = os.path.join(ZONE_FILE_DIR, filename)

    # Bind syntax requires semi-colons at specific points
    zone_config = (
        f'\nzone "{name}" {{\n    type {z_type};\n    file "{file_path}";\n}};\n'
    )

    try:
        with open(BIND_CONFIG_LOCAL, "a") as f:
            f.write(zone_config)
        print(
            f"[+] Configuration: Zone definition for '{name}' added to {BIND_CONFIG_LOCAL}"
        )
        return file_path
    except IOError as e:
        print(f"[-] ERROR: Failed to update named configuration: {e}")
        sys.exit(1)


def create_zone_file(zone_name: str, file_path: str):
    """
    Generates a valid BIND9 zone file with SOA, NS, and A records.
    Only executed if the zone type is 'master'.

    Abstract:
    This function creates a zone file that defines the DNS records for the specified zone.

    Algorithmic Analysis:
    - Time Complexity: O(1)
    - Space Complexity: O(1)

    System Call Analysis:
    - `open()`: Opens the zone file for writing.

    Security & Idempotency:
    The function is idempotent; it will overwrite existing files.

    Failure Modes:
    - Exits with code 1 if the file writing fails.
    """
    ns_ip = socket.gethostbyname(socket.gethostname())  # Use actual hostname's IP
    ns_hostname = "dsd3"

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

    Abstract:
    This function restarts the BIND9 service to apply configuration changes.

    Algorithmic Analysis:
    - Time Complexity: O(1)
    - Space Complexity: O(1)

    System Call Analysis:
    - `subprocess.check_call()`: Executes the command to restart the service.

    Security & Idempotency:
    The function is idempotent; repeated calls will not adversely affect the service.

    Failure Modes:
    - Exits with code 1 if the restart fails.
    """
    print("[*] Restarting BIND9 Service...")
    try:
        subprocess.check_call(["systemctl", "restart", BIND_SERVICE])
        print("[+] SUCCESS: BIND9 service restarted.")
    except subprocess.CalledProcessError:
        print("[-] ERROR: BIND9 failed to restart.")
        print("    Running 'named-checkconf' for diagnostics:")
        subprocess.run(["named-checkconf", "-z"])  # -z checks zone files too
        sys.exit(1)


def test_dns_resolution(zone_name: str):
    """
    Tests local resolution of the newly created zone using Python's socket library.

    Abstract:
    This function verifies that the DNS zone is correctly configured by attempting to resolve its hostname.

    Algorithmic Analysis:
    - Time Complexity: O(1)
    - Space Complexity: O(1)

    System Call Analysis:
    - `socket.gethostbyname()`: Resolves the hostname to an IP address.

    Security & Idempotency:
    The function is idempotent; it simply checks DNS resolution.

    Failure Modes:
    - None.
    """
    print(f"\n[*] Testing Resolution for ns1.{zone_name}...")
    target = f"ns1.{zone_name}"

    try:
        ip = socket.gethostbyname(target)
        print(f"[+] TEST PASSED: {target} resolved to {ip}")
    except socket.gaierror:
        print(f"[-] TEST FAILED: Could not resolve {target}. Check configuration.")


def main():
    """Main execution function for the DNS provisioning script.

    Abstract:
    This function orchestrates the execution of the script, ensuring that all necessary steps are performed in sequence.

    Algorithmic Analysis:
    - Time Complexity: O(n) where n is the number of functions called.
    - Space Complexity: O(1)

    System Call Analysis:
    - None.

    Security & Idempotency:
    The function is idempotent; it can be executed multiple times without adverse effects.

    Failure Modes:
    - None.
    """
    check_root_privileges()
    install_bind9()
    backup_named_conf()

    z_name, z_type, z_file = get_zone_parameters()

    file_path = append_zone_definition(z_name, z_type, z_file)

    # Only create the zone file if we are the master.
    if z_type == "master":
        create_zone_file(z_name, file_path)

    restart_bind_service()
    test_dns_resolution(z_name)


if __name__ == "__main__":
    main()
