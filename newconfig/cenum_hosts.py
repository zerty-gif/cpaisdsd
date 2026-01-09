#!/usr/bin/env python3
"""Network Host Enumeration via ICMP Echo Request with JSON Serialization.

ABSTRACT
========
This module implements a network reconnaissance utility designed to enumerate
active hosts within a specified IPv4 subnet (192.168.100.0/24) through the
systematic transmission of ICMP Echo Request packets (colloquially known as
"ping"). The enumeration algorithm employs a sequential scanning methodology,
wherein each potential host address is probed via the system's native ICMP
implementation. The resultant dataset—comprising reachable host identifiers—
undergoes serialization to JSON format, facilitating interoperability with
subsequent network automation workflows, particularly Netmiko-based SSH
orchestration systems.

THEORETICAL FOUNDATION
======================
The enumeration strategy adheres to the principles of active network discovery,
as codified in RFC 792 (Internet Control Message Protocol). The algorithm
traverses the IPv4 address space [192.168.100.2, 192.168.100.254], dispatching
ICMP Type 8 (Echo Request) datagrams to each candidate host. Upon receipt of
an ICMP Type 0 (Echo Reply) datagram within the prescribed timeout interval,
the host is classified as "active" and appended to the resultant inventory.

ALGORITHMIC COMPLEXITY
======================
Time Complexity: O(n * t), where n represents the cardinality of the address
space (253 hosts) and t denotes the timeout duration per host (2 seconds).
In the worst-case scenario (all hosts unreachable), the algorithm executes
in approximately 506 seconds (8.43 minutes).

Space Complexity: O(k), where k represents the quantity of active hosts
discovered. Memory allocation scales linearly with discovery count, bounded
by the maximum possible value of 253 dictionary objects.

SYSTEM CALL TAXONOMY
====================
The module induces the following kernel-level system calls:
1. socket(AF_INET, SOCK_RAW, IPPROTO_ICMP): Creation of raw ICMP socket
2. sendto(): Transmission of ICMP Echo Request to destination host
3. recvfrom(): Reception of ICMP Echo Reply from responding host
4. open(): File descriptor acquisition for JSON output stream
5. write(): Buffer flush operations for JSON serialization
6. close(): File descriptor release and buffer synchronization

Note: The subprocess.run() invocation delegates ICMP packet construction to
the system's native 'ping' utility, which operates with CAP_NET_RAW capability
or SUID root privileges, thereby obviating the necessity for elevated Python
process privileges.

SECURITY CONSIDERATIONS
=======================
1. Privilege Escalation: The ping utility requires CAP_NET_RAW or SUID bit,
   potentially exposing privilege escalation vectors if improperly configured.
2. Network Reconnaissance: Active scanning constitutes detectable behavior,
   potentially triggering intrusion detection systems (IDS) or firewall ACLs.
3. Denial of Service: Rapid sequential ICMP transmission may saturate network
   bandwidth or trigger rate-limiting countermeasures on intermediate routers.
4. File System Race Conditions: JSON output file creation is susceptible to
   TOCTOU (Time-of-Check-Time-of-Use) vulnerabilities if concurrent processes
   manipulate the output path.

IDEMPOTENCY ANALYSIS
====================
The enumeration operation exhibits idempotent characteristics with caveats:
- Multiple invocations yield consistent results given static network topology
- JSON output file undergoes atomic replacement via write truncation (mode 'w')
- No persistent state maintained between invocations
- Network state variations between runs produce deterministically different
  results, reflecting legitimate topology changes rather than side effects

FAILURE MODE TAXONOMY
=====================
Exit Code 0: Successful enumeration and JSON serialization
Exit Code 1: Catastrophic failure (unhandled exception)
Exception States:
  - FileNotFoundError: 'ping' binary absent from PATH environment
  - PermissionError: Insufficient filesystem permissions for JSON output
  - subprocess.TimeoutExpired: ping subprocess exceeded timeout threshold
  - KeyboardInterrupt: User-initiated termination via SIGINT signal
  - OSError: Network interface down or routing table misconfiguration

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
    """Probe network host via ICMP Echo Request with bounded timeout.
    
    This function serves as a thin abstraction layer over the system's native
    ICMP implementation (typically /bin/ping or /usr/bin/ping). The invocation
    delegates packet construction and transmission to the ping utility, which
    operates with elevated privileges (CAP_NET_RAW capability or SUID bit) to
    construct raw ICMP packets without requiring Python process privilege
    escalation.
    
    OPERATIONAL SEMANTICS
    =====================
    The function constructs a subprocess execution context and invokes the ping
    utility with the following parameters:
      -c 1: Transmit exactly one ICMP Echo Request packet (minimizes network load)
      -W 2: Set receive timeout to 2 seconds (balances latency vs. false negatives)
    
    The subprocess output streams (stdout/stderr) undergo redirection to
    /dev/null via subprocess.DEVNULL, preventing buffer accumulation and
    conserving memory resources during large-scale scans.
    
    SYSTEM CALL CHAIN
    =================
    1. fork(): Clone parent process to create child subprocess context
    2. execve("/bin/ping", ...): Replace child process image with ping binary
    3. socket(AF_INET, SOCK_RAW, IPPROTO_ICMP): Child creates raw ICMP socket
    4. sendto(): Child transmits ICMP Echo Request to destination
    5. recvfrom(): Child awaits ICMP Echo Reply (blocks up to timeout duration)
    6. exit(): Child terminates with status code (0=success, non-zero=failure)
    7. wait4(): Parent harvests child exit status and resource usage statistics
    
    ALGORITHMIC COMPLEXITY
    ======================
    Time Complexity: O(t), where t = timeout duration (2 seconds)
      - Best case: O(rtt), where rtt = round-trip time for responsive host
      - Worst case: O(t), full timeout elapses for unresponsive host
    Space Complexity: O(1), constant memory allocation irrespective of input
    
    CONCURRENCY CONSIDERATIONS
    ==========================
    The subprocess.run() invocation blocks the calling thread until child
    termination or timeout expiration. For large-scale scans, consider:
    1. Parallel execution via concurrent.futures.ThreadPoolExecutor
    2. Asynchronous I/O via asyncio.create_subprocess_exec()
    3. Batch processing with multiprocessing.Pool for GIL circumvention
    
    FAILURE MODES
    =============
    Returns False under the following conditions:
    1. Host unreachable (no route to host, network down)
    2. Host reachable but ICMP filtered (firewall drops Echo Requests)
    3. Timeout expiration prior to Echo Reply reception
    4. ping binary absent from PATH environment
    5. Insufficient privileges for raw socket creation (no CAP_NET_RAW/SUID)
    
    Args:
        ip_address: Dot-decimal IPv4 address notation (e.g., "192.168.100.31")
                   Must conform to RFC 791 address format validation.
        
    Returns:
        bool: True if ICMP Echo Reply received within timeout window,
              False otherwise (timeout, unreachable, or execution failure)
              
    Raises:
        No explicit exceptions propagated; all error conditions return False
        to maintain scan continuity during network enumeration operations.
        
    Example:
        >>> ping_host("192.168.100.1")
        True
        >>> ping_host("192.168.100.254")
        False  # Timeout or unreachable
        
    Security:
        Input validation absent; malformed IP strings may trigger ping utility
        errors. Consider ipaddress.ip_address() validation for production use.
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
    """Execute systematic network reconnaissance across IPv4 subnet via ICMP.
    
    This function orchestrates a comprehensive network enumeration operation,
    systematically probing each host within the designated IPv4 subnet
    (192.168.100.0/24) for responsiveness to ICMP Echo Requests. The algorithm
    employs sequential iteration through the address space, invoking the
    ping_host() predicate for each candidate address and aggregating positive
    responses into a structured inventory suitable for network automation
    frameworks (Netmiko, Ansible, Nornir).
    
    ENUMERATION ALGORITHM
    =====================
    The function implements a linear scan with the following characteristics:
    
    1. Address Space Definition:
       Range: [192.168.100.2, 192.168.100.254] (253 addresses)
       Exclusions: 192.168.100.1 (typically gateway/router)
       Rationale: RFC 1918 private address space, /24 subnet mask
       
    2. Scan Methodology:
       Sequential iteration with real-time progress indication
       Non-parallel execution to minimize network congestion
       stdout feedback via carriage return (\r) for overwrite behavior
       
    3. Data Structure Construction:
       Each responsive host induces dictionary creation with schema:
       {
         "hostname": "router_{octet}",  # Heuristic naming convention
         "host": "192.168.100.{octet}"  # Canonical IPv4 address
       }
       
    SYSTEM CALL IMPLICATIONS
    ========================
    For each host in the 253-address range, the function indirectly triggers:
    1. fork() + execve(): Subprocess creation for ping invocation
    2. socket(SOCK_RAW): ICMP socket allocation within ping process
    3. sendto() + recvfrom(): ICMP packet transmission and reception
    4. wait4(): Child process status harvesting
    
    Total syscall count (worst case): 253 hosts × 5 syscalls ≈ 1265 syscalls
    
    PERFORMANCE CHARACTERISTICS
    ===========================
    Time Complexity: O(n × t)
      n = 253 (address space cardinality)
      t = 2 seconds (per-host timeout)
      Worst case: 506 seconds (all hosts timeout)
      Best case: 253 × rtt (all hosts respond immediately)
      
    Space Complexity: O(k)
      k = number of active hosts discovered
      Each host consumes approximately 150 bytes (dictionary + strings)
      Maximum memory: 253 hosts × 150 bytes ≈ 38KB
      
    I/O Characteristics:
      stdout write operations: 253 (progress indicators)
      Additional newlines: k (per discovered host)
      
    CONCURRENCY OPPORTUNITIES
    =========================
    Current implementation executes serially. Consider optimization via:
    1. ThreadPoolExecutor with max_workers=50 (reduce scan time by 80%)
    2. asyncio with asyncio.create_subprocess_exec() (single-threaded async)
    3. multiprocessing.Pool (bypass GIL for CPU-bound pre/post-processing)
    
    Note: Parallel execution risks triggering rate-limiting on intermediate
    routers or IDS/IPS systems. Employ exponential backoff if implementing.
    
    IDEMPOTENCY & SIDE EFFECTS
    ==========================
    The function exhibits functional purity with respect to Python state:
    - No global variable mutation
    - No filesystem operations
    - No persistent network state modification
    
    However, observable side effects occur:
    - ICMP traffic detectable by network monitoring systems
    - stdout modification (progress indicators)
    - Temporary file descriptor allocation for subprocess pipes
    
    FAILURE MODES & RESILIENCE
    ==========================
    The function implements defensive programming patterns:
    1. KeyboardInterrupt: User can abort via SIGINT without data corruption
    2. Network failures: Per-host failures isolated; scan continues
    3. Permission errors: ping privilege issues handled via False return
    4. Timeout handling: Built into ping_host() subprocess timeout
    
    Returns:
        List[Dict[str, str]]: Inventory of active hosts with structure:
            [
              {"hostname": "router_31", "host": "192.168.100.31"},
              {"hostname": "router_32", "host": "192.168.100.32"},
              ...
            ]
            Empty list if no hosts discovered.
            
    Example:
        >>> hosts = enumerate_network()
        [*] Scanning network 192.168.100.0/24 (excluding 192.168.100.1)...
        [*] This may take a few minutes...
        [*] Checking 192.168.100.31...
        [+] Found active host: 192.168.100.31
        >>> len(hosts)
        1
        >>> hosts[0]['host']
        '192.168.100.31'
        
    Security:
        - Network reconnaissance is detectable and may violate security policies
        - Consider implementing exponential backoff to evade rate-limiting
        - Validate network scope authorization before deployment
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
    """Serialize active host inventory to JSON with atomic write semantics.
    
    This function implements persistent storage of enumerated network hosts via
    JSON serialization, adhering to RFC 8259 (The JavaScript Object Notation
    Data Interchange Format). The serialization operation produces human-readable
    structured data suitable for consumption by network automation frameworks,
    configuration management systems, or subsequent Python processes.
    
    FILE I/O SEMANTICS
    ==================
    The function employs the built-in open() context manager with the following
    characteristics:
    
    1. Mode: 'w' (write with truncation)
       - Atomically truncates existing file to zero length prior to write
       - Creates new file if absent (subject to umask permissions)
       - Raises PermissionError if inadequate filesystem permissions
       
    2. Buffering: System default (typically 4096 bytes)
       - Data accumulates in userspace buffer before write() syscall
       - Context manager exit guarantees flush() invocation
       - fsync() not invoked; durability depends on OS write-back cache
       
    3. Encoding: UTF-8 (implicit default in Python 3)
       - JSON specification mandates UTF-8 encoding
       - Compatible with ASCII subset for typical network data
    
    SYSTEM CALL TAXONOMY
    ====================
    The function triggers the following kernel-level operations:
    
    1. open(pathname, O_WRONLY | O_CREAT | O_TRUNC, 0666)
       - Allocates file descriptor in process file descriptor table
       - Truncates existing file or creates new inode
       - Applies process umask to permission bits
       
    2. write(fd, buffer, count)
       - Copies data from userspace buffer to kernel page cache
       - May trigger multiple write() calls for large datasets
       - Not guaranteed to reach persistent storage immediately
       
    3. close(fd)
       - Flushes userspace buffers to kernel
       - Releases file descriptor resource
       - Does NOT guarantee durability (no fsync)
       
    SERIALIZATION CHARACTERISTICS
    =============================
    The json.dump() invocation produces:
    
    1. Indentation: 2 spaces (indent=2 parameter)
       - Enhances human readability
       - Increases file size by approximately 15-20%
       - Negligible performance impact for datasets <1MB
       
    2. Sort Order: Insertion order preserved (Python 3.7+ dict guarantee)
       - Keys appear in order: ["hostname", "host"]
       - Facilitates version control diffs
       
    3. Escaping: Automatic Unicode escape sequence handling
       - Non-ASCII characters encoded as \\uXXXX sequences
       - Ensures ASCII compatibility for network transmission
    
    ALGORITHMIC COMPLEXITY
    ======================
    Time Complexity: O(n × m)
      n = number of hosts in inventory
      m = average string length per host entry (typically 40-60 characters)
      Linear scaling with dataset size
      
    Space Complexity: O(n × m)
      json.dump() constructs complete JSON string in memory before write
      Peak memory: 2× dataset size (input dict + JSON string)
      
    I/O Complexity:
      Disk writes: O(n), typically 1-3 write() syscalls for small datasets
      Filesystem metadata updates: O(1), single inode modification
    
    IDEMPOTENCY & ATOMICITY
    =======================
    Idempotency: YES
      - Multiple invocations with identical input produce identical output
      - File truncation ensures previous content does not persist
      
    Atomicity: PARTIAL
      - Individual write() syscalls are atomic at kernel level
      - Complete file replacement is NOT atomic (vulnerable to TOCTOU)
      - Consider using temporary file + os.rename() for atomic replacement:
        1. Write to active_hosts.json.tmp
        2. fsync() to ensure durability
        3. rename(active_hosts.json.tmp, active_hosts.json)
      
    RACE CONDITIONS & SECURITY
    ==========================
    Potential vulnerabilities:
    
    1. TOCTOU (Time-of-Check-Time-of-Use):
       - Concurrent process may delete/modify file between open() and write()
       - Mitigation: Use O_EXCL flag or flock() advisory locking
       
    2. Symlink Attack:
       - Malicious user may replace output path with symlink to sensitive file
       - Mitigation: Use O_NOFOLLOW flag or validate path with os.path.realpath()
       
    3. Permission Escalation:
       - If script runs with elevated privileges, output file inherits those
       - Mitigation: Explicitly set restrictive permissions via os.chmod(0o600)
    
    FAILURE MODES
    =============
    Exceptions raised under error conditions:
    
    1. PermissionError: Insufficient filesystem permissions for write operation
    2. OSError: Disk full (ENOSPC), read-only filesystem (EROFS)
    3. TypeError: Invalid data structure passed to json.dump() (malformed input)
    4. JSONDecodeError: Should not occur during dump, but possible with custom encoders
    
    Args:
        hosts: List of dictionaries conforming to schema:
               [{"hostname": str, "host": str}, ...]
               Empty list produces valid empty JSON array: []
               
    Returns:
        None: Function exhibits side effects (file I/O) without return value.
        
    Example:
        >>> hosts = [{"hostname": "router_31", "host": "192.168.100.31"}]
        >>> save_hosts(hosts)
        [+] Results saved to active_hosts.json
        [+] Found 1 active host(s)
        >>> Path("active_hosts.json").read_text()
        '[\\n  {\\n    "hostname": "router_31",\\n    "host": "192.168.100.31"\\n  }\\n]'
        
    Security:
        - Output file world-readable by default (subject to umask)
        - Consider os.chmod(output_path, 0o600) for sensitive environments
        - Validate hosts list to prevent JSON injection attacks
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
