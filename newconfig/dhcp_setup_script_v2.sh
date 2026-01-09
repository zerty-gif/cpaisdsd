#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║          ██████╗██████╗  ██████╗ ███████╗████████╗██╗███╗   ██╗          ║
# ║         ██╔════╝██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝██║████╗  ██║          ║
# ║         ██║     ██████╔╝██║   ██║███████╗   ██║   ██║██╔██╗ ██║          ║
# ║         ██║     ██╔═══╝ ██║   ██║╚════██║   ██║   ██║██║╚██╗██║          ║
# ║         ╚██████╗██║     ╚██████╔╝███████║   ██║   ██║██║ ╚████║          ║
# ║          ╚═════╝╚═╝      ╚═════╝ ╚══════╝   ╚═╝   ╚═╝╚═╝  ╚═══╝          ║
# ║                                                                           ║
# ║          KEA DHCP4 SERVER AUTOMATED CONFIGURATION SCRIPT                  ║
# ║                     Multi-Scope External Configuration                    ║
# ║                                                                           ║
# ╠═══════════════════════════════════════════════════════════════════════════╣
# ║                                                                           ║
# ║  This script automates the configuration of a Kea DHCP4 server with      ║
# ║  support for multiple network scopes defined in external .scope files.   ║
# ║                                                                           ║
# ║  Features:                                                                ║
# ║    • Multi-scope support via external configuration files                ║
# ║    • Interactive fallback when no scope files exist                      ║
# ║    • Comprehensive IP validation (RFC-compliant)                         ║
# ║    • Detailed academic-style documentation                               ║
# ║    • Rich terminal output with colors and formatting                     ║
# ║    • Full verification of configuration                                  ║
# ║                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 cpostinstallparrot Project
# Contact: andcs@mailbox.org
#
# ═══════════════════════════════════════════════════════════════════════════════
# SCRIPT OVERVIEW
# ═══════════════════════════════════════════════════════════════════════════════
#
#   This is the main entry point for the DHCP server configuration automation.
#   It sources modular subscripts that provide specific functionality:
#
#   ┌─────────────────────────────────────────────────────────────────────────┐
#   │                        MODULE ARCHITECTURE                              │
#   ├─────────────────────────────────────────────────────────────────────────┤
#   │                                                                         │
#   │   dhcp_setup_script_v2.sh (This file)                                   │
#   │           │                                                             │
#   │           ├── 00_constants.sh     : Global constants and paths          │
#   │           ├── 01_output.sh        : Terminal output functions           │
#   │           ├── 02_validation.sh    : IP and netmask validation           │
#   │           ├── 03_interactive.sh   : Interactive user input              │
#   │           ├── 04_parser.sh        : Scope file parser                   │
#   │           ├── 05_configure_dhcp.sh: Kea configuration generator         │
#   │           ├── 06_configure_interface.sh: Network interface config       │
#   │           ├── 07_verify.sh        : Configuration verification          │
#   │           └── 08_next_steps.sh    : Post-install guidance               │
#   │                                                                         │
#   └─────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# EXECUTION FLOW
# ═══════════════════════════════════════════════════════════════════════════════
#
#   ┌─────────────────────────────────────────────────────────────────────────┐
#   │                      MAIN EXECUTION SEQUENCE                            │
#   ├─────────────────────────────────────────────────────────────────────────┤
#   │                                                                         │
#   │  1. Check root privileges                                               │
#   │         │                                                               │
#   │         ▼                                                               │
#   │  2. Source all module scripts                                           │
#   │         │                                                               │
#   │         ▼                                                               │
#   │  3. Display welcome banner                                              │
#   │         │                                                               │
#   │         ▼                                                               │
#   │  4. Parse scope files (or interactive input)                            │
#   │         │                                                               │
#   │         ▼                                                               │
#   │  5. Configure network interfaces                                        │
#   │         │                                                               │
#   │         ▼                                                               │
#   │  6. Generate Kea DHCP4 configuration                                    │
#   │         │                                                               │
#   │         ▼                                                               │
#   │  7. Verify configuration                                                │
#   │         │                                                               │
#   │         ▼                                                               │
#   │  8. Display next steps                                                  │
#   │                                                                         │
#   └─────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# USAGE
# ═══════════════════════════════════════════════════════════════════════════════
#
#   Prerequisites:
#     • Run as root (sudo)
#     • Place .scope files in the same directory as this script
#
#   Basic Usage:
#     sudo ./dhcp_setup_script_v2.sh
#
#   Scope Files:
#     Create .scope files with KEY=VALUE pairs defining each network scope.
#     Example: dhcp192168100.scope, dhcp17216100.scope
#
#   Interactive Mode:
#     If no .scope files are found, the script will prompt for configuration.
#
# ═══════════════════════════════════════════════════════════════════════════════
# REFERENCES
# ═══════════════════════════════════════════════════════════════════════════════
#
#   RFC 2131 - Dynamic Host Configuration Protocol
#   RFC 2132 - DHCP Options and BOOTP Vendor Extensions
#   Kea DHCP Documentation - https://kea.readthedocs.io/
#
#######################################


# ═══════════════════════════════════════════════════════════════════════════════
# STRICT MODE
# ═══════════════════════════════════════════════════════════════════════════════
#
# Enable strict error handling for robust script execution.
#
# set -e : Exit immediately if a command exits with non-zero status
# set -u : Treat unset variables as errors
# set -o pipefail : Return the exit status of the last command in the pipe
#
set -euo pipefail


# ═══════════════════════════════════════════════════════════════════════════════
# DETERMINE SCRIPT LOCATION
# ═══════════════════════════════════════════════════════════════════════════════
#
# Resolve the directory containing this script.
# This is needed to locate the module scripts in libexec/dhcp/.
#
# BASH_SOURCE[0] : The path to this script (may be relative)
# dirname        : Extract the directory portion
# cd && pwd      : Convert to absolute path
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# ═══════════════════════════════════════════════════════════════════════════════
# DEFINE LIBRARY PATH
# ═══════════════════════════════════════════════════════════════════════════════
#
# The module scripts are stored in libexec/dhcp/ relative to the script.
#
LIB_DIR="${SCRIPT_DIR}/libexec/dhcp"


# ═══════════════════════════════════════════════════════════════════════════════
# SOURCE MODULE SCRIPTS
# ═══════════════════════════════════════════════════════════════════════════════
#
# Load all module scripts in order.
# Order matters because later modules depend on earlier ones.
#
# ─────────────────────────────────────────────────────────────────────────────
# HELPER FUNCTION: source_module()
# ─────────────────────────────────────────────────────────────────────────────
#
# Source a module script with error handling.
#
# Parameters:
#   $1 : Module filename (relative to LIB_DIR)
#
source_module() {
    local module_path="${LIB_DIR}/$1"
    
    if [[ -f "$module_path" ]]; then
        # shellcheck source=/dev/null
        source "$module_path"
    else
        echo "ERROR: Required module not found: $module_path" >&2
        echo "Please ensure all module scripts are in: $LIB_DIR" >&2
        exit 1
    fi
}


# ─────────────────────────────────────────────────────────────────────────────
# SOURCE ALL MODULES IN ORDER
# ─────────────────────────────────────────────────────────────────────────────
#
# The modules are numbered to indicate their dependency order.
# Each module may depend on functions from previous modules.
#
source_module "00_constants.sh"          # Global constants
source_module "01_output.sh"             # Output functions (success, error, etc.)
source_module "02_validation.sh"         # IP validation functions
source_module "03_interactive.sh"        # Interactive input functions
source_module "04_parser.sh"             # Scope file parser
source_module "05_configure_dhcp.sh"     # Kea configuration generator
source_module "06_configure_interface.sh" # Network interface configuration
source_module "07_verify.sh"             # Configuration verification
source_module "08_next_steps.sh"         # Post-installation guidance


#######################################
# check_root()
#######################################
#
# PURPOSE:
#   Verify that the script is running with root privileges.
#   Network and DHCP configuration requires root access.
#
# USAGE:
#   check_root
#
# RETURNS:
#   0 : Running as root
#   Exits with 1 if not root
#
#######################################
check_root() {
    # ─────────────────────────────────────────────────────────────────────────
    # CHECK EFFECTIVE USER ID
    # ─────────────────────────────────────────────────────────────────────────
    #
    # EUID is the Effective User ID.
    # Root user has EUID of 0.
    #
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        echo ""
        info "Usage: sudo $0"
        echo ""
        exit 1
    fi
}


#######################################
# display_banner()
#######################################
#
# PURPOSE:
#   Display a welcome banner when the script starts.
#   Provides visual context about what the script will do.
#
#######################################
display_banner() {
    echo ""
    echo -e "${C_CYAN}╔════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_CYAN}║                                                                            ║${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}   ${C_BOLD}KEA DHCP4 SERVER CONFIGURATION SCRIPT${C_RESET}                                   ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}   Multi-Scope Automated Configuration Tool                                 ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}║                                                                            ║${C_RESET}"
    echo -e "${C_CYAN}╠════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}                                                                            ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}   This script will:                                                        ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}     • Parse DHCP scope configuration from .scope files                     ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}     • Configure network interfaces with static IPs                         ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}     • Generate Kea DHCP4 server configuration                              ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}     • Verify all settings are correct                                      ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}║                                                                            ║${C_RESET}"
    echo -e "${C_CYAN}╚════════════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    
    academic "Script Directory: $SCRIPT_DIR"
    academic "Library Directory: $LIB_DIR"
    echo ""
}


#######################################
# main()
#######################################
#
# PURPOSE:
#   Main entry point for the script.
#   Orchestrates the execution of all configuration steps.
#
# EXECUTION STEPS:
#   1. Check root privileges
#   2. Display welcome banner
#   3. Parse scope files (or interactive input)
#   4. Configure network interfaces
#   5. Generate Kea DHCP4 configuration
#   6. Verify configuration
#   7. Display next steps
#
#######################################
main() {
    # ─────────────────────────────────────────────────────────────────────────
    # STEP 1: VERIFY ROOT PRIVILEGES
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Must be root to configure network interfaces and write to /etc/kea/
    #
    check_root
    
    # ─────────────────────────────────────────────────────────────────────────
    # STEP 2: DISPLAY WELCOME BANNER
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Show what the script will do
    #
    display_banner
    
    # ─────────────────────────────────────────────────────────────────────────
    # STEP 3: PARSE SCOPE CONFIGURATION
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Discover and parse .scope files, or fall back to interactive input.
    # This populates the C_SCOPES array.
    #
    parse_scope_files
    
    # ─────────────────────────────────────────────────────────────────────────
    # STEP 4: CONFIGURE NETWORK INTERFACES
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Assign static IP addresses to all interfaces defined in scopes.
    # This is required before the DHCP server can operate.
    #
    configure_network_interfaces
    
    # ─────────────────────────────────────────────────────────────────────────
    # STEP 5: GENERATE KEA DHCP4 CONFIGURATION
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Create the Kea configuration file with all subnet definitions.
    #
    configure_dhcp_server
    
    # ─────────────────────────────────────────────────────────────────────────
    # STEP 6: VERIFY CONFIGURATION
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Check that everything is properly configured.
    # This catches issues before the user tries to start the service.
    #
    verify_configuration
    
    # ─────────────────────────────────────────────────────────────────────────
    # STEP 7: DISPLAY NEXT STEPS
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Show the user what to do next (install, enable, test).
    #
    display_next_steps
    
    # ─────────────────────────────────────────────────────────────────────────
    # COMPLETED
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Exit successfully
    #
    exit 0
}


# ═══════════════════════════════════════════════════════════════════════════════
# SCRIPT ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════════
#
# Call main() to start execution.
# This pattern allows for clean organization and testing.
#
main "$@"
