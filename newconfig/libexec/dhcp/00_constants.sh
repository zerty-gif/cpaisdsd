#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                         GLOBAL CONSTANTS MODULE                           ║
# ║                    DHCP Server Configuration Script                       ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 cpostinstallparrot Project
# Contact: andcs@mailbox.org
#
# ═══════════════════════════════════════════════════════════════════════════════
# MODULE DESCRIPTION
# ═══════════════════════════════════════════════════════════════════════════════
#
#   This module defines all global constants used throughout the DHCP server
#   configuration script. Constants are organized into logical groups:
#
#     1. ANSI Color Codes      - Terminal styling for Rich/Textual output
#     2. Script Configuration  - Paths and script-level settings
#     3. Lease Timer Defaults  - RFC 2131 compliant DHCP timers
#     4. Global Data Structures - Arrays for multi-scope support
#
#   NAMING CONVENTION (C-Prefix):
#   ─────────────────────────────
#   All constants follow the project's C-prefix naming convention:
#     - C_UPPER_SNAKE_CASE for readonly constants
#     - This prevents naming collisions with system/environment variables
#     - Makes it immediately clear these are project-specific values
#
# ═══════════════════════════════════════════════════════════════════════════════
# USAGE
# ═══════════════════════════════════════════════════════════════════════════════
#
#   This file is sourced by the main script:
#     source "${C_LIB_DIR}/00_constants.sh"
#
#   Constants become available globally after sourcing.
#
#######################################

#######################################
# ANSI COLOR DEFINITIONS
#######################################
#
# TERMINAL COLOR ESCAPE SEQUENCES
# ════════════════════════════════
#
# ANSI escape codes enable colored terminal output. The format is:
#
#   \033[<attribute>;<foreground>;<background>m
#
# Where:
#   \033[     : Escape sequence introducer (ESC + '[')
#   attribute : Text style (0=reset, 1=bold, 2=dim, 4=underline)
#   foreground: Text color (30-37 for standard colors)
#   background: Background color (40-47 for standard colors)
#   m         : Terminates the sequence
#
# STANDARD FOREGROUND COLORS (30-37):
# ┌──────────┬──────────┬──────────┬──────────┐
# │ 30=Black │ 31=Red   │ 32=Green │ 33=Yellow│
# ├──────────┼──────────┼──────────┼──────────┤
# │ 34=Blue  │ 35=Magenta│36=Cyan  │ 37=White │
# └──────────┴──────────┴──────────┴──────────┘
#
# Rich/Textual Style Philosophy:
# ──────────────────────────────
# We follow the Rich library's approach to terminal output:
#   - Consistent color usage for message types
#   - Emoji prefixes for quick visual scanning
#   - Box-drawing characters for structured layouts
#
# shellcheck disable=SC2034  # Constants are used in other modules
#######################################

# ─────────────────────────────────────────────────────────────────────────────
# ERROR AND WARNING COLORS
# ─────────────────────────────────────────────────────────────────────────────
#
# C_RED: Used for error messages indicating failures that require attention.
#        Example: "❌ [ERROR] Failed to start DHCP service"
#
readonly C_RED='\033[0;31m'

# ─────────────────────────────────────────────────────────────────────────────
# SUCCESS COLORS
# ─────────────────────────────────────────────────────────────────────────────
#
# C_GREEN: Used for success messages confirming operations completed.
#          Example: "✅ [SUCCESS] Configuration file created"
#
readonly C_GREEN='\033[0;32m'

# ─────────────────────────────────────────────────────────────────────────────
# WARNING COLORS
# ─────────────────────────────────────────────────────────────────────────────
#
# C_YELLOW: Used for warnings - operation completed but with concerns.
#           Example: "⚠️ [WARNING] Using default DNS servers"
#
readonly C_YELLOW='\033[1;33m'

# ─────────────────────────────────────────────────────────────────────────────
# INFORMATIONAL COLORS
# ─────────────────────────────────────────────────────────────────────────────
#
# C_BLUE: Used for informational messages and status updates.
#         Example: "📋 [INFO] Installing packages..."
#
readonly C_BLUE='\033[0;34m'

# ─────────────────────────────────────────────────────────────────────────────
# ACADEMIC/EDUCATIONAL COLORS
# ─────────────────────────────────────────────────────────────────────────────
#
# C_MAGENTA: Used for academic notes and RFC references.
#            These provide educational context explaining WHY something is done.
#            Example: "📚 [ACADEMIC] RFC 2131 Section 4.3.1 specifies..."
#
readonly C_MAGENTA='\033[0;35m'

# ─────────────────────────────────────────────────────────────────────────────
# PROGRESS AND PROMPT COLORS
# ─────────────────────────────────────────────────────────────────────────────
#
# C_CYAN: Used for progress indicators and user prompts.
#         Example: "🔄 [PROGRESS] Configuring network interface..."
#
readonly C_CYAN='\033[0;36m'

# ─────────────────────────────────────────────────────────────────────────────
# TEXT STYLE MODIFIERS
# ─────────────────────────────────────────────────────────────────────────────
#
# C_BOLD: Makes text bold/bright. Used for emphasis and headers.
#         Combines with colors: echo -e "${C_BOLD}${C_CYAN}Header${C_RESET}"
#
readonly C_BOLD='\033[1m'

# C_DIM: Makes text dimmed/subdued. Used for secondary information.
#        Example: Debug output, comments, less important details
#
readonly C_DIM='\033[2m'

# ─────────────────────────────────────────────────────────────────────────────
# RESET SEQUENCE
# ─────────────────────────────────────────────────────────────────────────────
#
# C_RESET: Resets all text attributes to terminal defaults.
#          ALWAYS use this after colored output to prevent color bleeding.
#          Example: echo -e "${C_RED}Error${C_RESET} Normal text"
#
readonly C_RESET='\033[0m'


#######################################
# SCRIPT DIRECTORY CONFIGURATION
#######################################
#
# DETERMINING SCRIPT LOCATION
# ═══════════════════════════
#
# ${BASH_SOURCE[0]} contains the path to the current script file.
# This is more reliable than $0 which can change based on how
# the script is invoked (directly, via symlink, or sourced).
#
# The pattern: $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
#
# Breakdown:
#   1. dirname "${BASH_SOURCE[0]}"  → Extract directory part of path
#   2. cd "..."                      → Change to that directory
#   3. pwd                           → Print absolute path
#   4. $(...)                        → Capture output in variable
#
# This handles symlinks and relative paths correctly.
#
# DIRECTORY STRUCTURE:
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  newconfig/                     ← C_SCRIPT_DIR (main script location)   │
# │  ├── dhcp_setup_script.sh       ← Main entry point                      │
# │  ├── *.scope                    ← Scope configuration files             │
# │  └── libexec/                                                           │
# │      └── dhcp/                  ← C_LIB_DIR (module location)           │
# │          ├── 00_constants.sh    ← This file                             │
# │          ├── 01_output.sh       ← Output functions                      │
# │          ├── 02_validation.sh   ← IP validation                         │
# │          └── ...                ← Other modules                         │
# └─────────────────────────────────────────────────────────────────────────┘
#
#######################################

# C_SCRIPT_DIR: Absolute path to the main script directory.
#               Used as base path for finding scope files.
#               Set by main script before sourcing modules.
#
# Note: This will be set by the main script; we provide a fallback here
if [[ -z "${C_SCRIPT_DIR:-}" ]]; then
    # Fallback: Calculate from this file's location (go up two directories)
    readonly C_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

# C_LIB_DIR: Absolute path to the library modules directory.
#            All subscript modules are located here.
#
readonly C_LIB_DIR="${C_SCRIPT_DIR}/libexec/dhcp"


#######################################
# DHCP LEASE TIMER CONFIGURATION
#######################################
#
# RFC 2131 LEASE TIMERS EXPLAINED
# ═══════════════════════════════
#
# DHCP uses three timers to manage IP address leases:
#
#   1. VALID-LIFETIME (Lease Duration)
#      The total time a client can use the assigned IP address.
#
#   2. T1 (RENEW TIMER)
#      When the client should attempt to renew its lease.
#      Default: 50% of lease time (T1 = 0.5 × valid-lifetime)
#
#   3. T2 (REBIND TIMER)
#      When the client should broadcast for ANY DHCP server.
#      Default: 87.5% of lease time (T2 = 0.875 × valid-lifetime)
#
# LEASE TIMELINE VISUALIZATION:
# ┌─────────────────────────────────────────────────────────────────────────┐
# │                                                                         │
# │  Lease         T1 (Renew)        T2 (Rebind)           Lease            │
# │  Obtained         50%               87.5%              Expires          │
# │     │              │                  │                   │             │
# │     ▼              ▼                  ▼                   ▼             │
# │  ───●──────────────●──────────────────●───────────────────●───►         │
# │     │              │                  │                   │   Time      │
# │     │              │                  │                   │             │
# │   BOUND         RENEWING          REBINDING            INIT             │
# │   STATE         (unicast)         (broadcast)         (restart)         │
# │                                                                         │
# │  0 sec        1800 sec           2700 sec            3200 sec           │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘
#
# CLIENT STATE MACHINE:
# ─────────────────────
#   BOUND     → Client uses IP normally
#   RENEWING  → Client unicasts DHCPREQUEST to original server
#   REBINDING → Client broadcasts DHCPREQUEST to any server
#   INIT      → Lease expired, client must start over
#
# WHY THESE VALUES?
# ─────────────────
#   valid-lifetime (3200 seconds ≈ 53 minutes):
#     - Short enough for reasonable IP reclamation
#     - Long enough to avoid excessive DHCP traffic
#     - Good balance for typical office/lab environments
#
#   renew-timer (1800 seconds = 30 minutes):
#     - Gives client time to renew before rebind
#     - Slightly longer than strict 50% for cushion
#
#   rebind-timer (2700 seconds = 45 minutes):
#     - Provides failover window if primary server is down
#     - Close to 87.5% as per RFC recommendation
#
#######################################

# C_VALID_LIFETIME: Total lease duration in seconds.
#                   Client must renew or lose the IP after this time.
#
readonly C_VALID_LIFETIME="3200"

# C_RENEW_TIMER: T1 timer - when client attempts unicast renewal.
#                Client sends DHCPREQUEST directly to the server.
#
readonly C_RENEW_TIMER="1800"

# C_REBIND_TIMER: T2 timer - when client broadcasts for any server.
#                 Used if unicast renewal fails (server unreachable).
#
readonly C_REBIND_TIMER="2700"


#######################################
# GLOBAL DATA STRUCTURES
#######################################
#
# MULTI-SCOPE ARCHITECTURE
# ════════════════════════
#
# This script supports multiple DHCP scopes (subnets) served by
# a single Kea DHCP server. Each scope is defined in a separate
# .scope configuration file.
#
# DATA STRUCTURE: C_SCOPES Array
# ──────────────────────────────
#
# C_SCOPES is a Bash indexed array where each element represents
# one complete scope configuration as a colon-separated string:
#
#   C_SCOPES[0]="interface:network:netmask:pool_start:pool_end:host_addr:gateway:dns1:dns2"
#   C_SCOPES[1]="interface:network:netmask:pool_start:pool_end:host_addr:gateway:dns1:dns2"
#   ...
#
# FIELD POSITIONS (0-indexed):
# ┌───────┬─────────────┬────────────────────────────────────────────────────┐
# │ Index │ Field       │ Description                                        │
# ├───────┼─────────────┼────────────────────────────────────────────────────┤
# │   0   │ INTERFACE   │ Network interface name (e.g., "ens32")             │
# │   1   │ NETWORK     │ Network ID (e.g., "192.168.100.0")                 │
# │   2   │ NETMASK     │ Subnet mask (e.g., "255.255.255.0")                │
# │   3   │ POOL_START  │ First IP in DHCP pool (e.g., "192.168.100.30")     │
# │   4   │ POOL_END    │ Last IP in DHCP pool (e.g., "192.168.100.50")      │
# │   5   │ HOST_ADDRESS│ Server's IP on this interface                      │
# │   6   │ GATEWAY     │ Default gateway for clients                        │
# │   7   │ DNS_PRIMARY │ Primary DNS server                                 │
# │   8   │ DNS_SECONDARY│ Secondary DNS server                              │
# └───────┴─────────────┴────────────────────────────────────────────────────┘
#
# EXAMPLE:
#   C_SCOPES[0]="ens32:192.168.100.0:255.255.255.0:192.168.100.30:192.168.100.50:192.168.100.1:192.168.100.254:192.168.100.1:9.9.9.9"
#
# PARSING A SCOPE:
#   IFS=':' read -r interface network netmask pool_start pool_end host_addr gateway dns1 dns2 <<< "${C_SCOPES[0]}"
#
# WHY COLON-SEPARATED?
# ────────────────────
#   - Colons are not valid in IP addresses (unlike periods)
#   - Simple to parse with IFS and read
#   - Compact single-string representation
#   - Easy to store and retrieve
#
#######################################

# C_SCOPES: Array to store parsed scope configurations.
#           Populated by parse_scope_files() function.
#           Used by configure_dhcp_server() and configure_network_interface().
#
# Note: Using declare -a (not readonly) because this is populated at runtime
#
declare -a C_SCOPES=()


#######################################
# MODULE LOAD CONFIRMATION
#######################################
#
# Provides verbose feedback during script initialization.
# Helps with debugging module loading issues.
#
#######################################

# Only output if we're in verbose mode (check if info function exists)
if declare -f info &>/dev/null; then
    info "Module loaded: 00_constants.sh (Global Constants)"
fi
