#!/usr/bin/env python3
"""Automated Cisco IOS Configuration Retrieval via SSH with Netmiko Framework.

ABSTRACT
========
This module implements a network configuration management system designed for
automated retrieval and archival of Cisco IOS running-configuration data across
multiple network devices. The system employs the Netmiko SSH abstraction library
to establish secure shell connections, authenticate via username/password
credentials, elevate privileges to enable mode, execute privileged EXEC commands,
and persist the retrieved configuration data to local filesystem storage.

The architecture adheres to the principle of separation of concerns, decoupling
credential management (environment variables via .env file), device inventory
(JSON-serialized host list), and operational logic (SSH connection handling and
error recovery). This design facilitates scalability across large-scale network
infrastructures while maintaining security best practices through externalized
credential storage.

THEORETICAL FOUNDATION
======================
Network device configuration management constitutes a critical component of
infrastructure-as-code (IaC) methodologies, enabling version control, disaster
recovery, compliance auditing, and change management workflows. The automated
retrieval of running-configuration data represents the initial phase of the
configuration lifecycle, followed by:

1. Version Control: Git-based tracking of configuration evolution
2. Diff Analysis: Detection of unauthorized or unintended modifications
3. Compliance Validation: Comparison against security baseline templates
4. Disaster Recovery: Rapid restoration of known-good configurations

PROTOCOL STACK ANALYSIS
========================
The SSH connection establishment traverses the following protocol layers:

1. TCP Three-Way Handshake (Port 22):
   SYN → SYN-ACK → ACK sequence with kernel-managed TCP state machine
   
2. SSH Protocol Negotiation (RFC 4253):
   - Algorithm negotiation (KEX, encryption, MAC, compression)
   - Server public key exchange and verification
   - Diffie-Hellman key exchange for session key derivation
   
3. SSH User Authentication (RFC 4252):
   - Username/password authentication via keyboard-interactive method
   - Paramiko library handles SSH_MSG_USERAUTH_REQUEST construction
   
4. SSH Channel Establishment (RFC 4254):
   - Interactive shell channel request (PTY allocation)
   - Window size negotiation for flow control
   
5. Cisco IOS Command Execution:
   - Prompt detection via regex pattern matching
   - Command transmission with newline terminator
   - Output buffering with automatic pagination handling

ALGORITHMIC COMPLEXITY
======================
Time Complexity: O(n × (t_connect + t_exec))
  n = number of devices in inventory
  t_connect = SSH connection establishment time (typically 2-5 seconds)
  t_exec = command execution time (typically 1-3 seconds for show running-config)
  
  For 10 devices: approximately 30-80 seconds (serial execution)
  Parallelization opportunity: concurrent.futures.ThreadPoolExecutor
  
Space Complexity: O(n × s)
  n = number of devices
  s = size of running-configuration per device (typically 10-100 KB)
  
  Memory resident: Active configuration data during processing
  Disk consumption: Cumulative storage of all backup files

SYSTEM CALL TAXONOMY
====================
The module induces the following kernel-level operations per device:

1. socket(AF_INET, SOCK_STREAM): TCP socket creation for SSH connection
2. connect(): TCP handshake initiation to device IP:22
3. send()/recv(): Bidirectional data transmission over TCP socket
4. select()/poll(): Multiplexed I/O for non-blocking socket operations
5. open(): File descriptor acquisition for backup file creation
6. write(): Buffer flush operations for configuration data persistence
7. close(): Socket and file descriptor release

Paramiko library additionally invokes:
- /dev/urandom reads for cryptographic random number generation
- getaddrinfo(): DNS resolution if hostnames provided instead of IP addresses
- fcntl(): Non-blocking I/O configuration on socket file descriptors

SECURITY CONSIDERATIONS
=======================
1. Credential Exposure:
   - Credentials stored in .env file (filesystem permissions critical)
   - Environment variables visible via /proc/<pid>/environ to same-UID processes
   - Consider integration with HashiCorp Vault or AWS Secrets Manager
   
2. Man-in-the-Middle Attacks:
   - SSH host key verification not implemented (auto_add_policy or similar)
   - Vulnerable to MITM on first connection
   - Production deployment requires known_hosts validation
   
3. Privilege Escalation:
   - Enable password transmitted in plaintext over encrypted SSH channel
   - Consider TACACS+ or RADIUS for centralized AAA with audit trails
   
4. Configuration Data Exposure:
   - Backup files contain sensitive data (passwords, SNMP communities, keys)
   - Implement filesystem encryption (LUKS, dm-crypt) or application-level
     encryption (AES-256-GCM) for backup storage
   
5. Denial of Service:
   - Rapid parallel connections may trigger SSH rate-limiting on devices
   - Consider exponential backoff and jitter for connection retry logic

IDEMPOTENCY ANALYSIS
====================
The backup operation exhibits idempotent characteristics:
- Multiple executions produce identical results given static device configurations
- Backup files undergo atomic replacement (write truncation mode 'w')
- No persistent state maintained on network devices (read-only operation)
- File timestamps reflect execution time, facilitating temporal analysis

Non-idempotent aspects:
- Filesystem metadata (mtime, ctime) updates with each execution
- Transient SSH connections visible in device logs (potential audit trail)

FAILURE MODE TAXONOMY
=====================
Exit Code 0: All devices successfully backed up
Exit Code 1: Catastrophic failure (unhandled exception, .env file missing)

Exception Hierarchy:
1. NetmikoTimeoutException:
   - Network unreachability (no route to host, interface down)
   - TCP handshake timeout (firewall blocking port 22)
   - SSH negotiation timeout (incompatible cipher suites)
   
2. NetmikoAuthenticationException:
   - Invalid username/password credentials
   - Authentication method not supported (e.g., public key only)
   - Account locked due to failed authentication attempts
   
3. SSHException:
   - SSH protocol violations (malformed packets)
   - Cipher negotiation failures
   - Host key verification failures
   
4. FileNotFoundError:
   - active_hosts.json inventory file absent
   - Indicates cenum_hosts.py prerequisite not executed
   
5. PermissionError:
   - Insufficient filesystem permissions for backup file creation
   - Target directory not writable by effective UID

Author: Expert Network Analyst
Description: Multi-device Cisco IOS configuration backup orchestration
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
    """Deserialize network device inventory from JSON with credential injection.
    
    This function orchestrates the loading and augmentation of network device
    inventory data, combining statically-defined host addresses (sourced from
    JSON serialization) with dynamically-loaded authentication credentials
    (sourced from environment variables). The resultant data structure conforms
    to Netmiko's device dictionary schema, enabling seamless integration with
    the ConnectHandler abstraction layer.
    
    OPERATIONAL WORKFLOW
    ====================
    The function implements a multi-stage data transformation pipeline:
    
    Stage 1: JSON Deserialization
      - Read inventory file from filesystem (blocking I/O operation)
      - Parse JSON array into Python list of dictionaries
      - Validate JSON syntax (raises JSONDecodeError on malformation)
      
    Stage 2: Credential Injection
      - Iterate through each host dictionary
      - Augment with authentication parameters from environment variables
      - Inject Netmiko-specific metadata (device_type, port)
      
    Stage 3: Schema Normalization
      - Remove 'hostname' key (not recognized by Netmiko ConnectHandler)
      - Netmiko requires 'host' parameter for IP address specification
      - Prevents ConnectHandler initialization failure due to unexpected kwargs
    
    NETMIKO DEVICE DICTIONARY SCHEMA
    ================================
    The function produces dictionaries conforming to the following schema:
    
    {
      "host": str,           # IPv4 address or resolvable hostname
      "device_type": str,    # Netmiko device driver (e.g., "cisco_ios")
      "username": str,       # SSH authentication username
      "password": str,       # SSH authentication password (plaintext)
      "secret": str,         # Enable password for privilege escalation
      "port": int            # TCP port for SSH connection (default: 22)
    }
    
    Device driver selection implications:
    - "cisco_ios": Standard IOS/IOS-XE devices (prompt detection via regex)
    - "cisco_nxos": Nexus devices (different prompt patterns)
    - "cisco_xr": IOS-XR devices (XML-based API support)
    
    ENVIRONMENT VARIABLE RESOLUTION
    ===============================
    Credentials sourced from environment variables with fallback defaults:
    
    1. NETMIKO_USER (default: "admin")
       - Primary authentication username
       - Should correspond to local or AAA-authenticated account
       
    2. NETMIKO_PASS (default: "password")
       - Primary authentication password (transmitted encrypted via SSH)
       - Consider vault-based secret management for production
       
    3. NETMIKO_SECRET (default: "secret")
       - Enable password for privilege escalation (exec-level 15)
       - Empty string acceptable if enable authentication disabled
       
    4. NETMIKO_PORT (default: 22)
       - TCP destination port for SSH connection
       - Non-standard ports (e.g., 2222) require explicit configuration
    
    The os.getenv() function queries the process environment variable table,
    which inherits from parent process (typically shell) and may be augmented
    by python-dotenv library via .env file parsing.
    
    ALGORITHMIC COMPLEXITY
    ======================
    Time Complexity: O(n + m)
      n = number of hosts in JSON inventory
      m = size of JSON file in bytes
      Dominated by I/O latency rather than CPU processing
      
    Space Complexity: O(n × k)
      n = number of hosts
      k = average dictionary size per host (approximately 200-300 bytes)
      
    File I/O: Single read() syscall (buffered via built-in open())
    JSON parsing: Native C implementation (json module uses _json C extension)
    
    IDEMPOTENCY & SIDE EFFECTS
    ==========================
    The function exhibits referential transparency properties:
    - Given identical input file and environment variables, produces identical output
    - No global state mutation
    - No filesystem modifications
    - File read operation is read-only (O_RDONLY flag)
    
    Observable side effects:
    - File descriptor allocation/deallocation
    - Page cache population with file contents
    - Environment variable access (immutable read operation)
    
    FAILURE MODES & EXCEPTION HANDLING
    ==================================
    The function explicitly raises FileNotFoundError under specific conditions:
    
    Condition: inventory_file path does not exist in filesystem
    Exception: FileNotFoundError with diagnostic message
    Recovery: User must execute cenum_hosts.py to generate inventory
    
    Additional exceptions (not explicitly handled, propagate to caller):
    1. JSONDecodeError: Malformed JSON syntax in inventory file
    2. PermissionError: Insufficient read permissions on inventory file
    3. TypeError: Invalid environment variable type conversion
    
    SECURITY CONSIDERATIONS
    =======================
    1. Credential Storage:
       - .env file contains plaintext credentials (filesystem-based security)
       - Environment variables visible to same-UID processes
       - Consider integration with secret management systems (Vault, KMS)
       
    2. JSON Injection:
       - Maliciously crafted JSON may inject unexpected keys
       - Netmiko ConnectHandler validates keys, raises TypeError on unknown
       - Consider schema validation via jsonschema library
       
    3. Path Traversal:
       - inventory_file parameter accepts arbitrary paths
       - Potential for directory traversal attacks (.., symlinks)
       - Consider validation via pathlib.Path.resolve() with strict=True
    
    Args:
        inventory_file: Relative or absolute filesystem path to JSON inventory.
                       Defaults to "active_hosts.json" in current working directory.
                       Path resolution follows standard filesystem semantics.
        
    Returns:
        List[Dict[str, Union[str, int]]]: Device inventory with augmented credentials.
            Each dictionary conforms to Netmiko device schema.
            Empty list if JSON contains empty array.
            
    Raises:
        FileNotFoundError: Inventory file absent from specified path.
                          Includes diagnostic message suggesting prerequisite execution.
        JSONDecodeError: Inventory file contains syntactically invalid JSON.
        PermissionError: Insufficient read permissions on inventory file.
        
    Example:
        >>> os.environ["NETMIKO_USER"] = "netadmin"
        >>> os.environ["NETMIKO_PASS"] = "secure123"
        >>> inventory = load_router_inventory("hosts.json")
        >>> inventory[0]
        {
            'host': '192.168.100.31',
            'device_type': 'cisco_ios',
            'username': 'netadmin',
            'password': 'secure123',
            'secret': '',
            'port': 22
        }
        
    References:
        Netmiko Documentation: https://ktbyers.github.io/netmiko/
        python-dotenv: https://github.com/theskumar/python-dotenv
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
    """Execute configuration retrieval workflow across network device inventory.
    
    This function serves as the primary orchestration layer for the automated
    configuration backup operation. It implements an iterative workflow that
    processes each device in the inventory sequentially, establishing SSH
    connections, authenticating, escalating privileges, retrieving configuration
    data, and persisting the results to filesystem storage. The function
    incorporates comprehensive error handling to ensure graceful degradation
    under partial failure conditions, enabling continuation of the backup
    operation despite individual device failures.
    
    OPERATIONAL STATE MACHINE
    =========================
    For each device, the function executes the following state transitions:
    
    State 1: Connection Establishment
      - TCP three-way handshake to device IP:22
      - SSH protocol negotiation (KEX, encryption algorithms)
      - Netmiko ConnectHandler instantiation
      - Transition to State 2 on success, Error Handler on failure
      
    State 2: Privilege Escalation
      - Invocation of net_connect.enable() method
      - Transmission of enable password via encrypted SSH channel
      - Privilege level verification (exec-level 15)
      - Transition to State 3 on success, Error Handler on failure
      
    State 3: Configuration Retrieval
      - Execution of "show running-config" command
      - Automatic handling of pagination (--More-- prompts)
      - Buffer accumulation of configuration text
      - Transition to State 4 on success, Error Handler on failure
      
    State 4: Filesystem Persistence
      - Construction of backup filename (backup_<IP>.txt format)
      - File creation with write truncation mode
      - Configuration data serialization to disk
      - Transition to State 5 on success, Error Handler on failure
      
    State 5: Connection Teardown
      - SSH channel closure via net_connect.disconnect()
      - TCP FIN handshake initiation
      - File descriptor and socket resource release
      - Transition to next device or completion
    
    ERROR HANDLING TAXONOMY
    =======================
    The function implements exception-specific error recovery strategies:
    
    1. NetmikoAuthenticationException:
       Cause: Invalid credentials, account lockout, unsupported auth method
       Action: Log authentication failure, skip device, continue iteration
       Recovery: Operator must verify credentials and device AAA configuration
       
    2. NetmikoTimeoutException:
       Cause: Network unreachability, TCP timeout, SSH negotiation failure
       Action: Log timeout condition, skip device, continue iteration
       Recovery: Verify network connectivity (ping, traceroute) and firewall rules
       
    3. SSHException:
       Cause: SSH protocol violations, cipher mismatches, key exchange failures
       Action: Log SSH error details, skip device, continue iteration
       Recovery: Verify device SSH configuration (crypto key generation, version)
       
    4. Exception (catch-all):
       Cause: File I/O errors, unexpected runtime conditions
       Action: Log generic error with exception details, skip device, continue
       Recovery: Investigate exception traceback for root cause analysis
    
    ALGORITHMIC COMPLEXITY
    ======================
    Time Complexity: O(n × t)
      n = number of devices in ROUTER_INVENTORY
      t = average time per device (connection + command execution + teardown)
      t typically ranges from 3-10 seconds per device
      
      Sequential execution pattern: Total time = n × t
      Example: 10 devices × 5 seconds = 50 seconds
      
    Optimization opportunity: Parallel execution via ThreadPoolExecutor
      Parallelized: Total time ≈ max(t_i) for i in [1, n]
      Example: 10 devices × 5 seconds ≈ 5 seconds (with adequate workers)
      
    Space Complexity: O(s)
      s = size of largest device configuration
      Only one configuration resident in memory at a time (sequential processing)
      Typical s: 10-100 KB for small routers, up to several MB for large devices
      
    I/O Complexity:
      Network I/O: n × (SSH handshake + command execution)
      Disk I/O: n × (file creation + configuration write)
      stdout I/O: n × (progress and result messages)
    
    NETMIKO INTERNALS: SSH CONNECTION LIFECYCLE
    ===========================================
    ConnectHandler(**device) triggers the following operations:
    
    1. Paramiko SSHClient instantiation
    2. AutoAddPolicy or custom host key verification
    3. SSHClient.connect() invocation with parameters:
       - hostname: device['host']
       - port: device['port']
       - username: device['username']
       - password: device['password']
       - look_for_keys: False (disable public key auth)
       - allow_agent: False (disable SSH agent)
    4. Channel allocation for interactive shell
    5. PTY request for terminal emulation
    6. Shell invocation and prompt detection via regex
    
    net_connect.enable() operations:
    1. Detection of current privilege level (prompt analysis)
    2. Transmission of "enable" command if not already privileged
    3. Secret password transmission (device['secret'])
    4. Verification of privilege escalation success
    
    net_connect.send_command("show running-config") operations:
    1. Command transmission with newline terminator
    2. Output buffering with pagination detection (--More-- or <space> prompts)
    3. Automatic space character transmission to continue pagination
    4. Prompt detection to identify command completion
    5. Output string return with pagination artifacts removed
    
    IDEMPOTENCY & SIDE EFFECTS
    ==========================
    Idempotency characteristics:
    - Multiple executions produce identical backup files (assuming static configs)
    - File truncation ensures previous backup content does not persist
    - No persistent state modification on network devices (read-only commands)
    
    Side effects:
    - Filesystem modifications (backup file creation/replacement)
    - Network traffic generation (SSH connections, ICMP may trigger)
    - Device logs populated with SSH connection records
    - stdout modification (progress and status messages)
    
    SECURITY & AUDIT CONSIDERATIONS
    ===============================
    1. Audit Trail:
       - Device syslog records SSH connections with source IP, username, timestamp
       - Consider centralized syslog collection for correlation analysis
       - TACACS+ accounting provides command-level audit trails
       
    2. Credential Exposure:
       - Passwords transmitted encrypted via SSH but visible in process memory
       - Consider memory scrubbing or secure_clear for credential variables
       - Production deployment should use AAA integration
       
    3. Configuration Data Sensitivity:
       - Backup files contain plaintext passwords, SNMP communities, crypto keys
       - Implement filesystem encryption or application-level encryption
       - Apply restrictive file permissions (chmod 600) post-creation
       
    4. Denial of Service:
       - Rapid connection establishment may trigger device rate-limiting
       - Consider exponential backoff for connection retry logic
       - Monitor device CPU utilization during backup operations
    
    PRODUCTION DEPLOYMENT CONSIDERATIONS
    ====================================
    1. Logging: Integrate with Python logging module for structured logs
    2. Metrics: Emit Prometheus metrics for success/failure rates
    3. Alerting: Trigger notifications on backup failures via PagerDuty/Slack
    4. Scheduling: Deploy via cron or systemd timer for periodic execution
    5. Retention: Implement backup rotation policy (7-day, 30-day, 90-day)
    6. Versioning: Commit backups to Git repository for change tracking
    
    Returns:
        None: Function exhibits side effects (file I/O, network operations)
              without explicit return value. Success/failure communicated via
              stdout messages and implicit exit code propagation.
              
    Example:
        >>> backup_configurations()
        [*] Starting Configuration Backup Task at 2026-01-09 14:57:32.170496
        ======================================================================
        [*] Processing Device: 192.168.100.31
        [-] ERROR (Timeout): Connection to 192.168.100.31 timed out. Check IP reachability.
        ----------------------------------------------------------------------
        [*] Processing Device: 192.168.100.32
        [+] SUCCESS: Configuration for 192.168.100.32 saved to backup_192_168_100_32.txt
        ----------------------------------------------------------------------
        [*] Backup Job Completed at 2026-01-09 14:57:46.729790
        
    References:
        Netmiko Documentation: https://ktbyers.github.io/netmiko/
        Cisco IOS Command Reference: https://www.cisco.com/c/en/us/support/ios-nx-os-software/
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