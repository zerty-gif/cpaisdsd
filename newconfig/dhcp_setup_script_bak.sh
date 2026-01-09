#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                    DHCP SERVER SETUP AND CONFIGURATION                    ║
# ║                         Academic Course Module                            ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 cpostinstallparrot Project
# Contact: andcs@mailbox.org
#
# Description:
#   Automated Kea DHCP4 server installation and configuration script.
#   Designed as an educational resource with comprehensive RFC-referenced
#   documentation explaining DHCP concepts and configuration decisions.
#
# Usage:
#   sudo ./dhcp_setup_script.sh
#
# Prerequisites:
#   - Debian-based Linux distribution (Debian 11+, Parrot OS, Ubuntu 22.04+)
#   - Root privileges (run with sudo)
#   - Network interface ens33 available
#
# References:
#   - RFC 2131: Dynamic Host Configuration Protocol
#   - RFC 2132: DHCP Options and BOOTP Vendor Extensions
#   - Kea Administrator Reference Manual: https://kea.isc.org/docs/kea-guide.html
#
#######################################

#######################################
# SHELL OPTIONS AND STRICT MODE
#######################################
#
# set -e: Exit immediately if a command exits with a non-zero status
#         This ensures we don't continue executing after a failure
#
# set -u: Treat unset variables as an error
#         Prevents silent bugs from typos in variable names
#
# set -o pipefail: Return value of a pipeline is the status of the last
#                  command to exit with a non-zero status
#         Ensures pipeline failures are caught (e.g., cmd1 | cmd2)
#
#######################################
set -euo pipefail

#######################################
# COLOR DEFINITIONS (Rich/Textual Style)
#######################################
#
# ANSI escape codes for terminal colors
# Format: \033[<attribute>;<foreground>;<background>m
#
# Attributes:
#   0 = Reset, 1 = Bold, 4 = Underline
#
# Foreground colors (30-37):
#   30=Black, 31=Red, 32=Green, 33=Yellow, 34=Blue, 35=Magenta, 36=Cyan, 37=White
#
# These readonly variables ensure consistent styling throughout the script
# and prevent accidental modification.
#
# shellcheck disable=SC2034  # These constants are used in functions below
#######################################
readonly C_RED='\033[0;31m'      # Error messages, failures
readonly C_GREEN='\033[0;32m'    # Success messages, confirmations
readonly C_YELLOW='\033[1;33m'   # Warnings, cautions
readonly C_BLUE='\033[0;34m'     # Informational messages
readonly C_MAGENTA='\033[0;35m'  # Highlights, special notes
readonly C_CYAN='\033[0;36m'     # Progress indicators, prompts
readonly C_BOLD='\033[1m'        # Emphasis, headers
readonly C_DIM='\033[2m'         # Subdued text, comments
readonly C_RESET='\033[0m'       # Reset to default terminal colors

#######################################
# CONFIGURATION CONSTANTS
#######################################
#
# These constants define the network configuration for the DHCP server.
# Modify these values to match your network environment.
#
# NETWORK DESIGN RATIONALE:
# ─────────────────────────
# The 192.168.10.0/24 subnet provides 254 usable host addresses.
# We allocate addresses as follows:
#
#   .1-.29    : Reserved for infrastructure (routers, switches, APs)
#   .30-.50   : Dynamic DHCP pool (21 addresses for transient clients)
#   .51-.99   : Reserved for future expansion
#   .100-.199 : Static reservations for servers and workstations
#   .200-.253 : Network services (DNS, DHCP, NTP, etc.)
#   .254      : Default gateway
#   .255      : Broadcast address (not usable)
#
# shellcheck disable=SC2034  # Configuration constants used in heredocs
#######################################

# Network interface for DHCP services
# This interface MUST have a static IP address
readonly C_DHCP_INTERFACE="ens32"

# Server's static IP address on the DHCP interface
# This IP must be outside the dynamic pool range
readonly C_SERVER_IP="192.168.100.1"

# Subnet configuration
readonly C_SUBNET="192.168.100.0/24"
readonly C_NETMASK="255.255.255.0"

# DHCP pool range for dynamic allocation
# RFC 2131 recommends keeping pool size manageable for lease tracking
readonly C_POOL_START="192.168.100.30"
readonly C_POOL_END="192.168.100.50"

# Default gateway (Option 3 in DHCP)
# RFC 2132 Section 3.5: "The routers option specifies a list of IP addresses
# for routers on the client's subnet."
readonly C_GATEWAY="192.168.100.1"

# DNS servers (Option 6 in DHCP)
# Primary: Local DNS server for internal resolution
# Secondary: Quad9 (9.9.9.9) - provides DNS-level malware blocking
# RFC 2132 Section 3.8: "The domain name server option specifies a list of
# Domain Name System name servers available to the client."
readonly C_DNS_PRIMARY="192.168.100.1"
readonly C_DNS_SECONDARY="9.9.9.9"

#######################################
# DHCP LEASE TIMERS CONFIGURATION
#######################################
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  DHCP Lease Lifecycle (RFC 2131 Section 4.4.5)                          │
# ├─────────────────────────────────────────────────────────────────────────┤
# │                                                                         │
# │  Lease         T1 (Renew)        T2 (Rebind)           Lease            │
# │  Obtained         50%               87.5%              Expires          │
# │     │              │                  │                   │             │
# │     ▼              ▼                  ▼                   ▼             │
# │  ───●──────────────●──────────────────●───────────────────●───►         │
# │     │              │                  │                   │   Time      │
# │     │              │                  │                   │             │
# │     │         RENEWING          REBINDING             INIT              │
# │     │         (unicast)         (broadcast)           (restart)         │
# │     │                                                                   │
# │   BOUND STATE                                                           │
# │   (Normal operation - client uses leased IP)                            │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘
#
# valid-lifetime (3200 seconds ≈ 53 minutes):
#   Total duration the client can use the IP address.
#   Shorter leases = faster IP reclamation but more DHCP traffic.
#   Longer leases = less overhead but slower pool turnover.
#
# renew-timer (T1 = 1800 seconds = 30 minutes):
#   Client attempts unicast renewal to the original DHCP server.
#   Default per RFC: 50% of lease time (0.5 × 3200 = 1600, we use 1800).
#   Unicast is efficient - no broadcast traffic.
#
# rebind-timer (T2 = 2700 seconds = 45 minutes):
#   Client broadcasts renewal request to ANY available DHCP server.
#   Default per RFC: 87.5% of lease time (0.875 × 3200 = 2800, we use 2700).
#   Provides failover if primary server is unavailable.
#
#######################################
readonly C_VALID_LIFETIME="3200"
readonly C_RENEW_TIMER="1800"
readonly C_REBIND_TIMER="2700"

#######################################
# HOST RESERVATIONS
#######################################
#
# DHCP reservations (also called "static mappings" or "fixed addresses")
# guarantee that specific hosts always receive the same IP address.
#
# How it works (RFC 2131):
# 1. Client sends DHCPDISCOVER with its MAC address (chaddr field)
# 2. Server checks reservation database for matching hw-address
# 3. If match found, server offers the reserved IP (not from pool)
# 4. Client proceeds with normal DORA process
#
# Benefits:
# - Consistent IP for servers, printers, IoT devices
# - Easier firewall rule management
# - DNS records remain stable
# - No need to configure static IP on client
#
# Format: "hostname:mac-address:ip-address"
#######################################
#readonly C_RESERVATION_1="ds1:00:0c:29:14:cd:90:192.168.10.100"
#readonly C_RESERVATION_2="ds3:00:0c:29:bd:6f:36:192.168.10.120"

#######################################
# RICH-STYLE OUTPUT FUNCTIONS
#######################################
#
# These functions provide consistent, visually appealing terminal output
# following the Textual/Rich design patterns.
#
# Each function:
# - Uses emoji prefixes for quick visual identification
# - Applies appropriate colors for message severity
# - Outputs to stderr for error/warning (allows stdout redirection)
#
#######################################

# Success message - operation completed successfully
# Usage: success "Configuration applied"
success() {
    echo -e "${C_GREEN}✅ [SUCCESS]${C_RESET} $*"
}

# Error message - operation failed, may need intervention
# Usage: error "Failed to start service"
error() {
    echo -e "${C_RED}❌ [ERROR]${C_RESET} $*" >&2
}

# Warning message - operation completed but with concerns
# Usage: warning "Configuration file already exists"
warning() {
    echo -e "${C_YELLOW}⚠️  [WARNING]${C_RESET} $*"
}

# Informational message - status updates and explanations
# Usage: info "Installing packages..."
info() {
    echo -e "${C_BLUE}📋 [INFO]${C_RESET} $*"
}

# Progress message - ongoing operation
# Usage: progress "Configuring network interface..."
progress() {
    echo -e "${C_CYAN}🔄 [PROGRESS]${C_RESET} $*"
}

# Debug message - detailed technical information
# Usage: debug "Variable value: $var"
debug() {
    echo -e "${C_DIM}🔍 [DEBUG]${C_RESET} $*"
}

# Academic note - educational explanation
# Usage: academic "This implements RFC 2131 Section 4.3.1"
academic() {
    echo -e "${C_MAGENTA}📚 [ACADEMIC]${C_RESET} $*"
}

#######################################
# PANEL AND TABLE FUNCTIONS
#######################################
#
# Rich-style panel drawing for organized output
# Uses Unicode box-drawing characters for visual appeal
#
#######################################

# Draw a panel header with title
# Usage: panel_header "Configuration Summary"
panel_header() {
    local title="$1"
    local width=70
    local padding=$(( (width - ${#title} - 2) / 2 ))
    local line
    line=$(printf '%*s' "$width" '' | tr ' ' '─')
    
    echo ""
    echo -e "${C_BOLD}╭${line}╮${C_RESET}"
    printf "${C_BOLD}│${C_RESET}%*s${C_CYAN}%s${C_RESET}%*s${C_BOLD}│${C_RESET}\n" \
        "$padding" "" "$title" "$((width - padding - ${#title}))" ""
    echo -e "${C_BOLD}├${line}┤${C_RESET}"
}

# Draw a panel footer
# Usage: panel_footer
panel_footer() {
    local width=70
    local line
    line=$(printf '%*s' "$width" '' | tr ' ' '─')
    echo -e "${C_BOLD}╰${line}╯${C_RESET}"
    echo ""
}

# Draw a table row
# Usage: table_row "Parameter" "Value"
table_row() {
    printf "${C_BOLD}│${C_RESET} %-25s ${C_DIM}:${C_RESET} %-42s${C_BOLD}│${C_RESET}\n" "$1" "$2"
}

# Print a separator line
# Usage: separator
separator() {
    local width=70
    local line
    line=$(printf '%*s' "$width" '' | tr ' ' '─')
    echo -e "${C_BOLD}├${line}┤${C_RESET}"
}

#######################################
# SPINNER ANIMATION
#######################################
#
# Provides visual feedback during long-running operations
# Uses Braille pattern characters for smooth animation
#
#######################################

# Global variable to track spinner process
SPINNER_PID=""

# Start spinner animation in background
# Usage: spinner_start "Installing packages"
spinner_start() {
    local message="$1"
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    
    (
        while true; do
            for (( i=0; i<${#chars}; i++ )); do
                echo -ne "\r${C_CYAN}${chars:$i:1}${C_RESET} ${message}..."
                sleep 0.1
            done
        done
    ) &
    SPINNER_PID=$!
    disown "$SPINNER_PID" 2>/dev/null || true
}

# Stop spinner animation
# Usage: spinner_stop
spinner_stop() {
    if [[ -n "${SPINNER_PID:-}" ]] && kill -0 "$SPINNER_PID" 2>/dev/null; then
        kill "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
        echo -ne "\r\033[K"  # Clear the line
    fi
    SPINNER_PID=""
}

# Cleanup function for signal handling
cleanup() {
    spinner_stop
    echo ""
    warning "Script interrupted. Partial configuration may have been applied."
    info "Check backup files (.bak) to restore previous configuration."
    exit 130
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

#######################################
# ROOT PRIVILEGE CHECK
#######################################
#
# DHCP server configuration requires root privileges because:
# 1. Installing packages (apt) requires root
# 2. Modifying /etc/kea/ requires root
# 3. Modifying /etc/network/interfaces requires root
# 4. Restarting system services requires root
#
# Security Note:
#   Always run system configuration scripts with sudo rather than
#   as the root user directly. This provides audit logging and
#   prevents accidental damage from root shell sessions.
#
#######################################
check_root() {
    academic "Checking for root privileges (required for system configuration)..."
    
    if [[ "$(id -u)" -ne 0 ]]; then
        error "This script must be run as root."
        info "Please run with: sudo $0"
        info ""
        info "Root privileges are required for:"
        info "  • Installing system packages (apt)"
        info "  • Modifying /etc/kea/kea-dhcp4.conf"
        info "  • Modifying /etc/network/interfaces"
        info "  • Managing systemd services"
        exit 1
    fi
    
    success "Running with root privileges (UID: $(id -u))"
}

#######################################
# SYSTEM INFORMATION DISPLAY
#######################################
#
# Display system information for troubleshooting and verification
#
#######################################
display_system_info() {
    panel_header "System Information"
    table_row "Hostname" "$(hostname)"
    table_row "Operating System" "$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    table_row "Kernel" "$(uname -r)"
    table_row "Date/Time" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    table_row "User" "$(whoami) (UID: $(id -u))"
    panel_footer
}

#######################################
# PACKAGE INSTALLATION
#######################################
#
# KEA DHCP SERVER OVERVIEW
# ════════════════════════
#
# Kea is the modern DHCP server from ISC (Internet Systems Consortium),
# designed as the successor to ISC DHCP (dhcpd).
#
# Architecture:
# ┌─────────────────────────────────────────────────────────────────────┐
# │                        Kea DHCP Suite                               │
# ├─────────────────┬─────────────────┬─────────────────────────────────┤
# │  kea-dhcp4      │   kea-dhcp6     │      kea-dhcp-ddns              │
# │  (DHCPv4)       │   (DHCPv6)      │   (Dynamic DNS Updates)         │
# ├─────────────────┴─────────────────┴─────────────────────────────────┤
# │                    kea-ctrl-agent (REST API)                        │
# ├─────────────────────────────────────────────────────────────────────┤
# │                    kea-common (Shared libraries)                    │
# └─────────────────────────────────────────────────────────────────────┘
#
# We install:
# - kea-dhcp4-server: Core DHCPv4 server daemon
# - kea-common: Shared libraries and utilities
#
#######################################
install_packages() {
    panel_header "Package Installation"
    
    academic "Installing Kea DHCP4 server (ISC's modern DHCP implementation)"
    academic "Kea uses JSON configuration format and supports database backends"
    
    info "Updating package repository index..."
    spinner_start "Updating apt cache"
    apt-get update -qq
    spinner_stop
    success "Package index updated"
    
    info "Installing kea-dhcp4-server and kea-common..."
    academic "kea-dhcp4-server: Core DHCPv4 daemon (listens on UDP port 67)"
    academic "kea-common: Shared libraries for all Kea components"
    
    spinner_start "Installing packages"
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq kea-dhcp4-server kea-common
    spinner_stop
    
    # Verify installation
    if command -v kea-dhcp4 &>/dev/null; then
        local kea_version
        kea_version=$(kea-dhcp4 -V 2>&1 | head -1 || echo "Unknown")
        success "Kea DHCP4 installed successfully"
        table_row "Kea Version" "$kea_version"
    else
        error "Kea DHCP4 installation failed"
        exit 1
    fi
    
    panel_footer
}

#######################################
# CONFIGURATION BACKUP
#######################################
#
# BACKUP STRATEGY
# ═══════════════
#
# Before modifying any configuration file, we create a timestamped backup.
# This allows recovery if the new configuration causes issues.
#
# Backup naming convention:
#   <original-file>.bak.<YYYYMMDD-HHMMSS>
#
# Example:
#   /etc/kea/kea-dhcp4.conf.bak.20260109-143022
#
#######################################
backup_configuration() {
    panel_header "Configuration Backup"
    
    local timestamp
    timestamp=$(date '+%Y%m%d-%H%M%S')
    
    academic "Creating timestamped backups before modification"
    academic "Allows rollback if new configuration causes issues"
    
    # Backup Kea configuration
    if [[ -f "/etc/kea/kea-dhcp4.conf" ]]; then
        local kea_backup="/etc/kea/kea-dhcp4.conf.bak.${timestamp}"
        cp "/etc/kea/kea-dhcp4.conf" "$kea_backup"
        success "Kea config backed up to: $kea_backup"
    else
        info "No existing Kea configuration to backup"
    fi
    
    # Backup network interfaces configuration
    if [[ -f "/etc/network/interfaces" ]]; then
        local net_backup="/etc/network/interfaces.bak.${timestamp}"
        cp "/etc/network/interfaces" "$net_backup"
        success "Network config backed up to: $net_backup"
    else
        info "No existing network configuration to backup"
    fi
    
    panel_footer
}

#######################################
# KEA DHCP4 CONFIGURATION
#######################################
#
# KEA CONFIGURATION FILE FORMAT
# ═════════════════════════════
#
# Kea uses JSON format for configuration (unlike ISC DHCP which used a
# custom format). This provides:
# - Machine-parseable configuration
# - Easy integration with automation tools
# - Runtime configuration via REST API
#
# CONFIGURATION STRUCTURE:
# ┌─────────────────────────────────────────────────────────────────────┐
# │ {                                                                   │
# │   "Dhcp4": {                    ◄── Root object for DHCPv4          │
# │     "interfaces-config": {},    ◄── Which interfaces to listen on   │
# │     "control-socket": {},       ◄── Unix socket for management      │
# │     "lease-database": {},       ◄── Where to store lease data       │
# │     "subnet4": [],              ◄── Subnet definitions              │
# │     "valid-lifetime": N,        ◄── Default lease duration          │
# │     "renew-timer": N,           ◄── T1 timer (RFC 2131)             │
# │     "rebind-timer": N           ◄── T2 timer (RFC 2131)             │
# │   }                                                                 │
# │ }                                                                   │
# └─────────────────────────────────────────────────────────────────────┘
#
#######################################
configure_dhcp_server() {
    panel_header "Kea DHCP4 Server Configuration"
    
    academic "Creating Kea configuration in JSON format"
    academic "Configuration path: /etc/kea/kea-dhcp4.conf"
    
    # Ensure the kea directory exists
    mkdir -p /etc/kea
    
    progress "Generating Kea DHCP4 configuration..."
    
    #######################################
    # Generate the Kea configuration file
    #######################################
    cat > /etc/kea/kea-dhcp4.conf <<EOF
{
    // ════════════════════════════════════════════════════════════════════════
    // KEA DHCP4 SERVER CONFIGURATION
    // ════════════════════════════════════════════════════════════════════════
    //
    // This configuration file implements a DHCP server for the 192.168.10.0/24
    // network with support for dynamic address allocation and static reservations.
    //
    // Generated by: dhcp_setup_script.sh
    // Generated on: $(date '+%Y-%m-%d %H:%M:%S %Z')
    //
    // References:
    //   - RFC 2131: DHCP Protocol
    //   - RFC 2132: DHCP Options
    //   - Kea Administrator Reference Manual
    //
    // ════════════════════════════════════════════════════════════════════════
    
    "Dhcp4": {
        
        // ────────────────────────────────────────────────────────────────────
        // INTERFACE CONFIGURATION
        // ────────────────────────────────────────────────────────────────────
        //
        // Specifies which network interfaces Kea should listen on for DHCP
        // requests. The server binds to UDP port 67 on these interfaces.
        //
        // IMPORTANT: The interface MUST have a static IP address assigned.
        // DHCP servers cannot operate on interfaces using DHCP themselves!
        //
        // "dhcp-socket-type": "raw" uses raw sockets instead of UDP
        //   - Required when server IP is not yet configured during boot
        //   - Allows responding before interface has an IP
        //   - More reliable for DHCP relay scenarios
        //
        // ────────────────────────────────────────────────────────────────────
        "interfaces-config": {
            "interfaces": [ "${C_DHCP_INTERFACE}" ],
            "dhcp-socket-type": "raw"
        },
        
        // ────────────────────────────────────────────────────────────────────
        // CONTROL SOCKET CONFIGURATION
        // ────────────────────────────────────────────────────────────────────
        //
        // The control socket enables runtime management without server restart:
        //   - Query lease database
        //   - Add/remove reservations dynamically
        //   - Retrieve statistics
        //   - Trigger configuration reload
        //
        // Socket location follows FHS (Filesystem Hierarchy Standard):
        //   /run/kea/ - Runtime variable data, cleared on reboot
        //
        // Usage example:
        //   echo '{"command": "config-get"}' | socat - UNIX:/run/kea/kea4-ctrl-socket
        //
        // ────────────────────────────────────────────────────────────────────
        "control-socket": {
            "socket-type": "unix",
            "socket-name": "/run/kea/kea4-ctrl-socket"
        },
        
        // ────────────────────────────────────────────────────────────────────
        // LEASE DATABASE CONFIGURATION
        // ────────────────────────────────────────────────────────────────────
        //
        // Kea supports multiple lease storage backends:
        //   - memfile: CSV file (simple, good for small networks)
        //   - mysql: MySQL/MariaDB database
        //   - postgresql: PostgreSQL database
        //   - cassandra: Apache Cassandra (for large scale)
        //
        // We use "memfile" which stores leases in a CSV file.
        // The file is human-readable and easy to backup.
        //
        // "lfc-interval": Lease File Cleanup interval in seconds
        //   - Removes expired leases from the file
        //   - Reduces file size and improves performance
        //   - 3600 = cleanup once per hour
        //
        // "persist": true ensures leases survive server restart
        //
        // ────────────────────────────────────────────────────────────────────
        "lease-database": {
            "type": "memfile",
            "persist": true,
            "name": "/var/lib/kea/dhcp4.leases",
            "lfc-interval": 3600
        },
        
        // ────────────────────────────────────────────────────────────────────
        // GLOBAL LEASE TIMERS (RFC 2131 Section 4.4.5)
        // ────────────────────────────────────────────────────────────────────
        //
        //        LEASE TIMELINE
        //        ══════════════
        //
        //    ┌────────────────────────────────────────────────────────┐
        //    │   0%          50%           84%          100%          │
        //    │   │            │             │             │           │
        //    │   ▼            ▼             ▼             ▼           │
        //    │   ●────────────●─────────────●─────────────●           │
        //    │   │            │             │             │           │
        //    │ Lease       T1 Timer      T2 Timer      Lease          │
        //    │ Start       (Renew)       (Rebind)      Expires        │
        //    │   │            │             │             │           │
        //    │ 0 sec      1800 sec      2700 sec      3200 sec        │
        //    └────────────────────────────────────────────────────────┘
        //
        // valid-lifetime: How long the client can use the IP address
        // renew-timer (T1): When client tries unicast renewal to server
        // rebind-timer (T2): When client broadcasts to any DHCP server
        //
        // ────────────────────────────────────────────────────────────────────
        "valid-lifetime": ${C_VALID_LIFETIME},
        "renew-timer": ${C_RENEW_TIMER},
        "rebind-timer": ${C_REBIND_TIMER},
        
        // ────────────────────────────────────────────────────────────────────
        // SUBNET CONFIGURATION
        // ────────────────────────────────────────────────────────────────────
        //
        // The subnet4 array defines network segments served by this DHCP server.
        // Each subnet has:
        //   - id: Unique identifier (required in Kea 2.6+)
        //   - subnet: Network address in CIDR notation
        //   - pools: IP ranges for dynamic allocation
        //   - option-data: DHCP options to send to clients
        //   - reservations: Static IP assignments by MAC address
        //
        // SUBNET DESIGN (192.168.10.0/24):
        // ┌──────────────────────────────────────────────────────────────────┐
        // │  Address Range              │  Purpose                          │
        // ├─────────────────────────────┼───────────────────────────────────┤
        // │  192.168.10.1 - .29         │  Infrastructure (reserved)        │
        // │  192.168.10.30 - .50        │  DHCP Dynamic Pool (21 IPs)       │
        // │  192.168.10.51 - .99        │  Future expansion                 │
        // │  192.168.10.100 - .199      │  Static reservations              │
        // │  192.168.10.200 - .253      │  Network services                 │
        // │  192.168.10.254             │  Default gateway                  │
        // └──────────────────────────────────────────────────────────────────┘
        //
        // ────────────────────────────────────────────────────────────────────
        "subnet4": [
            {
                // Unique subnet identifier (required for Kea 2.6+)
                // Used internally for logging and statistics
                "id": 1,
                
                // Network address in CIDR notation
                // /24 = 256 addresses (254 usable for hosts)
                "subnet": "${C_SUBNET}",
                
                // ────────────────────────────────────────────────────────────
                // ADDRESS POOLS
                // ────────────────────────────────────────────────────────────
                //
                // Pools define the range of IPs available for dynamic allocation.
                // Multiple pools can be defined for a single subnet.
                //
                // Pool size considerations:
                //   - Too small: Address exhaustion during peak usage
                //   - Too large: Wasted address space, harder tracking
                //   - Rule of thumb: 2× expected concurrent clients
                //
                // Our pool: 21 addresses (192.168.100.30 - 192.168.100.50)
                //
                // ────────────────────────────────────────────────────────────
                "pools": [
                    {
                        "pool": "${C_POOL_START} - ${C_POOL_END}"
                    }
                ],
                
                // ────────────────────────────────────────────────────────────
                // DHCP OPTIONS (RFC 2132)
                // ────────────────────────────────────────────────────────────
                //
                // DHCP options provide network configuration to clients.
                // Common options defined in RFC 2132:
                //
                //   Option 1:  Subnet Mask (auto-derived from subnet CIDR)
                //   Option 3:  Router (Default Gateway)
                //   Option 6:  Domain Name Server
                //   Option 15: Domain Name
                //   Option 51: IP Address Lease Time (set by valid-lifetime)
                //
                // ────────────────────────────────────────────────────────────
                "option-data": [
                    {
                        // ═══════════════════════════════════════════════════
                        // OPTION 6: DOMAIN NAME SERVERS (RFC 2132 Section 3.8)
                        // ═══════════════════════════════════════════════════
                        //
                        // Specifies DNS servers for name resolution.
                        // Clients query these servers to resolve hostnames to IPs.
                        //
                        // Primary: Local DNS for internal domain resolution
                        // Secondary: Quad9 (9.9.9.9) - Public DNS with:
                        //   - Malware domain blocking
                        //   - DNSSEC validation
                        //   - Privacy-focused (no logging)
                        //
                        "name": "domain-name-servers",
                        "data": "${C_DNS_PRIMARY}, ${C_DNS_SECONDARY}"
                    },
                    {
                        // ═══════════════════════════════════════════════════
                        // OPTION 3: ROUTERS (RFC 2132 Section 3.5)
                        // ═══════════════════════════════════════════════════
                        //
                        // Default gateway for traffic outside the local subnet.
                        // Clients add this as the default route in their
                        // routing table.
                        //
                        // Multiple routers can be specified for redundancy.
                        //
                        "name": "routers",
                        "data": "${C_GATEWAY}"
                    }
                ]
                
                // ────────────────────────────────────────────────────────────
                // HOST RESERVATIONS (DISABLED)
                // ────────────────────────────────────────────────────────────
                //
                // Reservations are disabled in this configuration.
                // All clients will receive dynamic addresses from the pool.
                //
                // To add reservations in the future, add a "reservations" array:
                // "reservations": [
                //     {
                //         "hw-address": "00:0c:29:xx:xx:xx",
                //         "ip-address": "192.168.100.100",
                //         "hostname": "hostname"
                //     }
                // ]
                //
                // ────────────────────────────────────────────────────────────
            }
        ],
        
        // ────────────────────────────────────────────────────────────────────
        // LOGGING CONFIGURATION
        // ────────────────────────────────────────────────────────────────────
        //
        // Kea supports flexible logging to multiple destinations:
        //   - syslog: System logging facility
        //   - stdout/stderr: Console output
        //   - file: Dedicated log file
        //
        // Log levels (from most to least verbose):
        //   DEBUG, INFO, WARN, ERROR, FATAL
        //
        // ────────────────────────────────────────────────────────────────────
        "loggers": [
            {
                "name": "kea-dhcp4",
                "output_options": [
                    {
                        "output": "syslog"
                    }
                ],
                "severity": "INFO",
                "debuglevel": 0
            }
        ]
    }
}
EOF

    success "Kea configuration file created: /etc/kea/kea-dhcp4.conf"
    
    # Validate JSON syntax
    progress "Validating configuration syntax..."
    if command -v kea-dhcp4 &>/dev/null; then
        if kea-dhcp4 -t /etc/kea/kea-dhcp4.conf 2>/dev/null; then
            success "Configuration syntax is valid"
        else
            warning "Configuration validation failed - check for syntax errors"
        fi
    else
        info "Skipping validation (kea-dhcp4 not found in PATH)"
    fi
    
    # Display configuration summary
    separator
    academic "Configuration Summary:"
    table_row "Subnet" "${C_SUBNET}"
    table_row "DHCP Pool" "${C_POOL_START} - ${C_POOL_END}"
    table_row "Gateway" "${C_GATEWAY}"
    table_row "DNS Servers" "${C_DNS_PRIMARY}, ${C_DNS_SECONDARY}"
    table_row "Lease Time" "${C_VALID_LIFETIME} seconds"
    table_row "Reservations" "None (dynamic only)"
    
    panel_footer
}

#######################################
# NETWORK INTERFACE CONFIGURATION
#######################################
#
# DHCP SERVER NETWORK REQUIREMENTS
# ════════════════════════════════
#
# The DHCP server interface MUST have a static IP address because:
#
# 1. Chicken-and-egg problem: A DHCP client cannot get an IP from itself!
#    If ens33 used DHCP, it would need to contact a DHCP server to get
#    an IP... but it IS the DHCP server.
#
# 2. Consistent server address: Clients need to know where to send
#    DHCPREQUEST (renewal) packets. A changing server IP would break this.
#
# 3. DNS and routing: Other services depend on the server having a
#    predictable IP address for configuration.
#
# INTERFACE FILE FORMAT (/etc/network/interfaces)
# ───────────────────────────────────────────────
#
# Debian-style network configuration using ifupdown:
#
#   auto <interface>     - Bring up interface at boot
#   allow-hotplug <if>   - Bring up when hardware detected
#   iface <if> inet      - IPv4 configuration
#     static             - Use static IP addressing
#     address <ip>       - The IP address to assign
#     netmask <mask>     - Subnet mask
#     gateway <ip>       - Default route (optional for internal-only interfaces)
#
#######################################
configure_network_interface() {
    panel_header "Network Interface Configuration"
    
    academic "Configuring ${C_DHCP_INTERFACE} with static IP for DHCP server operation"
    academic "DHCP servers must have static IPs - they cannot be DHCP clients!"
    
    # Ensure the network directory exists
    mkdir -p /etc/network
    
    progress "Writing network interface configuration..."
    
    cat > /etc/network/interfaces <<EOF
# ════════════════════════════════════════════════════════════════════════════
# NETWORK INTERFACE CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════
#
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).
#
# Generated by: dhcp_setup_script.sh
# Generated on: $(date '+%Y-%m-%d %H:%M:%S %Z')
#
# WARNING: Modifications to this file require restarting the networking
#          service: sudo systemctl restart networking
#
# ════════════════════════════════════════════════════════════════════════════

# Include interface-specific configuration fragments
# Files in /etc/network/interfaces.d/ are sourced alphabetically
source /etc/network/interfaces.d/*

# ────────────────────────────────────────────────────────────────────────────
# LOOPBACK INTERFACE
# ────────────────────────────────────────────────────────────────────────────
#
# The loopback interface (lo) is a virtual network interface that the
# computer uses to communicate with itself. It's used for:
#   - Local service communication (e.g., localhost:8080)
#   - Testing network applications
#   - System processes that use sockets
#
# IP address: 127.0.0.1/8 (all 127.x.x.x addresses route to loopback)
#
# ────────────────────────────────────────────────────────────────────────────
auto lo
iface lo inet loopback

# ────────────────────────────────────────────────────────────────────────────
# PRIMARY INTERFACE: ens32 (External/WAN)
# ────────────────────────────────────────────────────────────────────────────
#
# This interface connects to the external network (Internet/WAN).
# Using DHCP to obtain configuration from upstream router/ISP.
#
# "allow-hotplug": Brings up interface when hardware is detected
# "inet dhcp": Uses DHCP client to obtain IP configuration
#
# ────────────────────────────────────────────────────────────────────────────
allow-hotplug ens32
iface ens32 inet dhcp

# ────────────────────────────────────────────────────────────────────────────
# DHCP SERVER INTERFACE: ${C_DHCP_INTERFACE} (Internal/LAN)
# ────────────────────────────────────────────────────────────────────────────
#
# This interface serves the internal DHCP network.
# MUST use static IP - DHCP servers cannot be DHCP clients on the same network!
#
# Configuration breakdown:
#   address ${C_SERVER_IP}     - Server's IP on this interface
#   netmask ${C_NETMASK}       - /24 subnet (255.255.255.0)
#   gateway ${C_GATEWAY}       - Default route (if needed for routing)
#
# DNS servers specified here are used by THIS host for name resolution.
# Clients receive DNS servers from Kea DHCP options, not from here.
#
# ────────────────────────────────────────────────────────────────────────────
auto ${C_DHCP_INTERFACE}
allow-hotplug ${C_DHCP_INTERFACE}
iface ${C_DHCP_INTERFACE} inet static
    address ${C_SERVER_IP}
    netmask ${C_NETMASK}
    gateway ${C_GATEWAY}
    dns-nameservers ${C_DNS_PRIMARY} ${C_DNS_SECONDARY}
EOF

    success "Network configuration written to: /etc/network/interfaces"
    
    # Display interface configuration summary
    separator
    academic "Interface Configuration Summary:"
    table_row "DHCP Interface" "${C_DHCP_INTERFACE}"
    table_row "IP Address" "${C_SERVER_IP}"
    table_row "Netmask" "${C_NETMASK}"
    table_row "Gateway" "${C_GATEWAY}"
    table_row "DNS Servers" "${C_DNS_PRIMARY}, ${C_DNS_SECONDARY}"
    
    panel_footer
}

#######################################
# SERVICE MANAGEMENT
#######################################
#
# SYSTEMD SERVICE MANAGEMENT
# ══════════════════════════
#
# systemd is the init system and service manager for modern Linux.
# Key commands:
#   systemctl start <service>   - Start the service now
#   systemctl stop <service>    - Stop the service now
#   systemctl restart <service> - Stop then start the service
#   systemctl enable <service>  - Start at boot
#   systemctl status <service>  - Show service status
#   systemctl is-active <srv>   - Check if running (for scripts)
#
# SERVICE DEPENDENCIES
# ────────────────────
#
# The order of service restarts matters:
# 1. networking - Must come first (provides network interfaces)
# 2. kea-dhcp4-server - Depends on network being available
#
# If networking fails, kea-dhcp4-server will also fail because
# the interface it needs to bind to won't be available.
#
#######################################
restart_services() {
    panel_header "Service Management"
    
    academic "Restarting system services to apply new configuration"
    academic "Order matters: networking must be up before DHCP server can bind"
    
    # Ensure directories exist for Kea
    progress "Ensuring Kea directories exist..."
    mkdir -p /var/lib/kea
    mkdir -p /run/kea
    chown -R _kea:_kea /var/lib/kea 2>/dev/null || chown -R kea:kea /var/lib/kea 2>/dev/null || true
    chown -R _kea:_kea /run/kea 2>/dev/null || chown -R kea:kea /run/kea 2>/dev/null || true
    success "Kea directories configured"
    
    # Restart networking
    info "Restarting networking service..."
    academic "This applies the new /etc/network/interfaces configuration"
    spinner_start "Restarting networking"
    systemctl restart networking 2>/dev/null || true
    sleep 3
    spinner_stop
    
    if systemctl is-active --quiet networking 2>/dev/null; then
        success "Networking service is active"
    else
        warning "Networking service status unclear (may use NetworkManager instead)"
    fi
    
    # Restart Kea DHCP4 server
    info "Restarting kea-dhcp4-server..."
    academic "This loads the new /etc/kea/kea-dhcp4.conf configuration"
    spinner_start "Restarting kea-dhcp4-server"
    systemctl restart kea-dhcp4-server
    sleep 3
    spinner_stop
    
    if systemctl is-active --quiet kea-dhcp4-server; then
        success "kea-dhcp4-server is active"
    else
        error "kea-dhcp4-server failed to start"
        info "Checking service logs..."
        journalctl -u kea-dhcp4-server -n 20 --no-pager
        exit 1
    fi
    
    # Enable services for boot
    info "Enabling services to start at boot..."
    systemctl enable kea-dhcp4-server 2>/dev/null || true
    systemctl enable networking 2>/dev/null || true
    success "Services enabled for automatic start at boot"
    
    panel_footer
}

#######################################
# CONFIGURATION VERIFICATION
#######################################
#
# POST-CONFIGURATION VERIFICATION
# ═══════════════════════════════
#
# After applying configuration, we verify that:
# 1. Services are running
# 2. Network interface has correct IP
# 3. DHCP lease file exists (or can be created)
# 4. Control socket is accessible
#
# These checks help identify configuration errors early.
#
#######################################
verify_configuration() {
    panel_header "Configuration Verification"
    
    academic "Performing post-configuration verification checks"
    local all_passed=true
    
    # Check 1: kea-dhcp4-server status
    info "Check 1: kea-dhcp4-server service status"
    if systemctl is-active --quiet kea-dhcp4-server; then
        success "kea-dhcp4-server is running"
    else
        error "kea-dhcp4-server is NOT running"
        systemctl status kea-dhcp4-server --no-pager || true
        all_passed=false
    fi
    
    # Check 2: Network interface IP address
    info "Check 2: Network interface ${C_DHCP_INTERFACE} IP address"
    if ip addr show "${C_DHCP_INTERFACE}" 2>/dev/null | grep -q "inet ${C_SERVER_IP}"; then
        success "${C_DHCP_INTERFACE} has IP ${C_SERVER_IP}"
    else
        warning "${C_DHCP_INTERFACE} does not have expected IP ${C_SERVER_IP}"
        info "Current ${C_DHCP_INTERFACE} configuration:"
        ip addr show "${C_DHCP_INTERFACE}" 2>/dev/null || echo "Interface not found"
        all_passed=false
    fi
    
    # Check 3: DHCP lease database
    info "Check 3: DHCP lease database"
    if [[ -f "/var/lib/kea/dhcp4.leases" ]]; then
        local lease_count
        lease_count=$(wc -l < /var/lib/kea/dhcp4.leases 2>/dev/null || echo "0")
        success "Lease file exists (/var/lib/kea/dhcp4.leases)"
        table_row "Lease file entries" "${lease_count} lines"
    else
        warning "Lease file does not exist yet (will be created on first lease)"
        info "This is normal for a fresh installation"
    fi
    
    # Check 4: Control socket
    info "Check 4: Kea control socket"
    if [[ -S "/run/kea/kea4-ctrl-socket" ]]; then
        success "Control socket exists (/run/kea/kea4-ctrl-socket)"
    else
        warning "Control socket not found (may take a moment to create)"
    fi
    
    # Summary
    separator
    if [[ "$all_passed" == "true" ]]; then
        success "All verification checks passed!"
    else
        warning "Some verification checks failed - review output above"
    fi
    
    # Display listening ports
    academic "DHCP Server Network Status:"
    if command -v ss &>/dev/null; then
        info "Listening on UDP port 67 (DHCP server):"
        ss -ulnp | grep -E ":67\s" || echo "  (not yet listening - may need a moment)"
    fi
    
    panel_footer
}

#######################################
# USAGE INSTRUCTIONS
#######################################
display_next_steps() {
    panel_header "Setup Complete - Next Steps"
    
    success "DHCP server installation and configuration completed!"
    echo ""
    
    academic "═══════════════════════════════════════════════════════════════"
    academic "                    USEFUL COMMANDS                            "
    academic "═══════════════════════════════════════════════════════════════"
    echo ""
    
    info "View DHCP server status:"
    echo -e "    ${C_CYAN}sudo systemctl status kea-dhcp4-server${C_RESET}"
    echo ""
    
    info "View DHCP server logs:"
    echo -e "    ${C_CYAN}sudo journalctl -u kea-dhcp4-server -f${C_RESET}"
    echo ""
    
    info "View active leases:"
    echo -e "    ${C_CYAN}cat /var/lib/kea/dhcp4.leases${C_RESET}"
    echo ""
    
    info "Query server via control socket:"
    echo -e "    ${C_CYAN}echo '{\"command\": \"lease4-get-all\"}' | sudo socat - UNIX:/run/kea/kea4-ctrl-socket${C_RESET}"
    echo ""
    
    info "Test DHCP from a client:"
    echo -e "    ${C_CYAN}sudo dhclient -v eth0${C_RESET}"
    echo ""
    
    academic "═══════════════════════════════════════════════════════════════"
    academic "                    NETWORK DIAGRAM                            "
    academic "═══════════════════════════════════════════════════════════════"
    echo ""
    echo -e "${C_DIM}"
    echo "    ┌────────────────────────────────────────────────────────────┐"
    echo "    │                    192.168.100.0/24                        │"
    echo "    │                                                            │"
    echo "    │   DHCP Server (${C_SERVER_IP})                             │"
    echo "    │        │                                                   │"
    echo "    │        └── Pool: ${C_POOL_START} - ${C_POOL_END}           │"
    echo "    │                                                            │"
    echo "    │   Gateway: ${C_GATEWAY}                                    │"
    echo "    │   Mode: Dynamic allocation only (no reservations)         │"
    echo "    └────────────────────────────────────────────────────────────┘"
    echo -e "${C_RESET}"
    
    panel_footer
}

#######################################
# MAIN FUNCTION
#######################################
#
# SCRIPT EXECUTION FLOW
# ═════════════════════
#
# This script follows a structured execution order:
#
#   1. check_root         - Verify running as root
#   2. display_system_info - Show environment details
#   3. install_packages   - Install Kea DHCP4 server
#   4. backup_configuration - Backup existing configs
#   5. configure_dhcp_server - Write Kea configuration
#   6. configure_network_interface - Set static IP
#   7. restart_services   - Apply configuration
#   8. verify_configuration - Validate everything works
#   9. display_next_steps - Show usage instructions
#
# Each step builds on the previous, and failures cause
# immediate exit (due to set -e) to prevent partial configuration.
#
#######################################
main() {
    # Clear screen for clean output
    clear
    
    # Display banner
    echo -e "${C_BOLD}${C_CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                           ║"
    echo "║              🌐  DHCP SERVER SETUP AND CONFIGURATION  🌐                 ║"
    echo "║                       Academic Course Module                              ║"
    echo "║                                                                           ║"
    echo "║  This script will install and configure a Kea DHCP4 server with          ║"
    echo "║  comprehensive documentation explaining each configuration decision.      ║"
    echo "║                                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${C_RESET}"
    echo ""
    
    # Execute setup steps in order
    check_root
    display_system_info
    install_packages
    backup_configuration
    configure_dhcp_server
    configure_network_interface
    restart_services
    verify_configuration
    display_next_steps
    
    # Final message
    echo ""
    success "Script completed successfully at $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

#######################################
# SCRIPT ENTRY POINT
#######################################
#
# This idiom ensures the main function only runs when the script
# is executed directly, not when sourced by another script.
#
# When sourced:
#   $0 = path to the sourcing script (not this file)
#   ${BASH_SOURCE[0]} = path to this file
#
# When executed directly:
#   $0 = ${BASH_SOURCE[0]} = path to this file
#
#######################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
