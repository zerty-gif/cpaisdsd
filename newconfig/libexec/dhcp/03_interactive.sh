#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                    INTERACTIVE SCOPE INPUT MODULE                         ║
# ║                 User-Prompted DHCP Scope Configuration                    ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 cpostinstallparrot Project
# Author: ANDCS
# Contact: andcs@mailbox.org
#
# ═══════════════════════════════════════════════════════════════════════════════
# MODULE DESCRIPTION
# ═══════════════════════════════════════════════════════════════════════════════
#
#   This module provides interactive prompts for users to enter DHCP scope
#   configuration when no .scope files are found in the script directory.
#
#   The function guides users through entering all required parameters,
#   validates each input in real-time, and constructs a scope configuration
#   string suitable for the C_SCOPES array.
#
#   USER EXPERIENCE DESIGN:
#   ───────────────────────
#     • Clear prompts with example values
#     • Immediate validation feedback
#     • Error messages explaining what went wrong
#     • Retry on invalid input (no need to restart)
#     • Consistent styling with Rich/Textual patterns
#
# ═══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE INPUT FLOW
# ═══════════════════════════════════════════════════════════════════════════════
#
#   ┌─────────────────────────────────────────────────────────────────────────┐
#   │                    SCOPE CONFIGURATION WIZARD                          │
#   ├─────────────────────────────────────────────────────────────────────────┤
#   │                                                                         │
#   │  Step 1: Interface Selection                                            │
#   │    "Enter listening interface (e.g., ens33): " ─────────────► ens32     │
#   │                                                                         │
#   │  Step 2: Network Configuration                                          │
#   │    "Enter Network ID (e.g., 192.168.100.0): " ──────────► 192.168.100.0 │
#   │    "Enter Subnet Mask (e.g., 255.255.255.0): " ────────► 255.255.255.0  │
#   │                                                                         │
#   │  Step 3: DHCP Pool Range                                                │
#   │    "Enter Pool Start IP: " ─────────────────────────► 192.168.100.30    │
#   │    "Enter Pool End IP: " ───────────────────────────► 192.168.100.50    │
#   │                                                                         │
#   │  Step 4: Server Configuration                                           │
#   │    "Enter Server's IP on this interface: " ─────────► 192.168.100.1     │
#   │                                                                         │
#   │  Step 5: Gateway                                                        │
#   │    "Enter Gateway IP: " ────────────────────────────► 192.168.100.254   │
#   │                                                                         │
#   │  Step 6: DNS Servers                                                    │
#   │    "Enter Primary DNS Server IP: " ─────────────────► 192.168.100.1     │
#   │    "Enter Secondary DNS Server IP (or Enter for 9.9.9.9): " ──► 9.9.9.9 │
#   │                                                                         │
#   └─────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════════
#
#   Requires:
#     • 00_constants.sh (color codes: C_BOLD, C_CYAN, C_RESET)
#     • 01_output.sh    (error() function for validation feedback)
#     • 02_validation.sh (validate_ip(), validate_netmask())
#
#######################################

#######################################
# get_user_input_for_scope()
#######################################
#
# PURPOSE:
#   Interactively collect all configuration parameters for a single
#   DHCP scope from the user via terminal prompts.
#
# USER INTERFACE:
#   The function presents a structured wizard-style interface:
#
#   ═══════════════════════════════════════════════════════════════
#              Configuration for Scope #1
#   ═══════════════════════════════════════════════════════════════
#
#   Enter listening interface (e.g., ens33): _
#
# INPUT VALIDATION:
#   Each input is validated before proceeding to the next prompt.
#   Invalid inputs generate an error message and the prompt repeats.
#
#   Validation rules:
#     • INTERFACE   : Non-empty string (basic check)
#     • NETWORK     : Valid IPv4 address format
#     • NETMASK     : Valid subnet mask (contiguous 1s)
#     • POOL_START  : Valid IPv4 address format
#     • POOL_END    : Valid IPv4 address format
#     • HOST_ADDRESS: Valid IPv4 address format
#     • GATEWAY     : Valid IPv4 address format
#     • DNS_PRIMARY : Valid IPv4 address format
#     • DNS_SECONDARY: Valid IPv4 address format (defaults to 9.9.9.9)
#
# USAGE:
#   scope_data=$(get_user_input_for_scope 1)
#   C_SCOPES+=("$scope_data")
#
# PARAMETERS:
#   $1 : Scope number for display purposes (e.g., 1, 2, 3)
#
# OUTPUT:
#   Prints a colon-separated scope configuration string to stdout:
#   "interface:network:netmask:pool_start:pool_end:host_addr:gateway:dns1:dns2"
#
# RETURNS:
#   0 : Configuration collected successfully
#
# EXAMPLE OUTPUT:
#   "ens32:192.168.100.0:255.255.255.0:192.168.100.30:192.168.100.50:192.168.100.1:192.168.100.254:192.168.100.1:9.9.9.9"
#
#######################################
get_user_input_for_scope() {
    local scope_number="$1"
    
    # ─────────────────────────────────────────────────────────────────────────
    # DISPLAY SCOPE HEADER
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Provide a clear visual header so the user knows which scope
    # they are configuring, especially when creating multiple scopes.
    #
    echo ""
    echo -e "${C_BOLD}${C_CYAN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}           Configuration for Scope #${scope_number}${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # DECLARE LOCAL VARIABLES FOR SCOPE CONFIGURATION
    # ─────────────────────────────────────────────────────────────────────────
    #
    # These variables will hold the user's input after validation.
    # Using local scope to avoid polluting the global namespace.
    #
    local interface network netmask pool_start pool_end
    local host_address gateway dns_primary dns_secondary
    
    # ═════════════════════════════════════════════════════════════════════════
    # STEP 1: NETWORK INTERFACE
    # ═════════════════════════════════════════════════════════════════════════
    #
    # The interface is the network adapter on which Kea will listen
    # for DHCP requests. This MUST be a valid interface name.
    #
    # Common interface naming schemes:
    #   • Traditional: eth0, eth1
    #   • Systemd predictable: ens32, ens33, enp0s3
    #   • Virtual: veth0, br0, docker0
    #
    # VALIDATION: Non-empty string
    # (We don't check if the interface exists - that's verified later)
    #
    academic "Step 1: Network Interface"
    academic "This is the network adapter Kea will listen on for DHCP requests"
    echo ""
    
    while true; do
        # Read user input with prompt
        # -r: Don't interpret backslashes
        # -p: Prompt string
        read -rp "Enter listening interface (e.g., ens33): " interface
        
        # Trim whitespace by removing leading/trailing spaces
        interface="${interface// /}"
        
        # Validate: non-empty
        if [[ -n "$interface" ]]; then
            success "Interface set to: $interface"
            break
        fi
        
        error "Interface cannot be empty. Please enter a valid interface name."
    done
    echo ""
    
    # ═════════════════════════════════════════════════════════════════════════
    # STEP 2: NETWORK ID
    # ═════════════════════════════════════════════════════════════════════════
    #
    # The network ID is the base address of the subnet.
    # For a /24 network, this is typically x.x.x.0
    #
    # Examples:
    #   192.168.100.0 - Class C private network
    #   172.16.10.0   - Class B private network
    #   10.0.0.0      - Class A private network
    #
    # VALIDATION: Valid IPv4 address format
    #
    academic "Step 2: Network Configuration"
    academic "The Network ID is the base address of your subnet"
    echo ""
    
    while true; do
        read -rp "Enter Network ID (e.g., 192.168.100.0): " network
        
        # Use the validate_ip function from 02_validation.sh
        if validate_ip "$network"; then
            success "Network ID set to: $network"
            break
        fi
        
        error "Invalid IP address format. Please enter a valid IPv4 address."
        error "Example: 192.168.100.0"
    done
    echo ""
    
    # ═════════════════════════════════════════════════════════════════════════
    # STEP 3: SUBNET MASK
    # ═════════════════════════════════════════════════════════════════════════
    #
    # The subnet mask defines the network vs. host portions of the IP address.
    # Must be a valid contiguous mask.
    #
    # Common masks:
    #   255.255.255.0   (/24) - 254 hosts - Most common for small networks
    #   255.255.255.128 (/25) - 126 hosts
    #   255.255.0.0     (/16) - 65,534 hosts
    #
    # VALIDATION: Valid subnet mask (from lookup table)
    #
    academic "The subnet mask defines network vs. host portions"
    academic "Common: 255.255.255.0 (/24) for 254 usable hosts"
    echo ""
    
    while true; do
        read -rp "Enter Subnet Mask (e.g., 255.255.255.0): " netmask
        
        if validate_netmask "$netmask"; then
            local cidr
            cidr=$(netmask_to_cidr "$netmask")
            success "Subnet mask set to: $netmask (/$cidr)"
            break
        fi
        
        error "Invalid subnet mask. Must be contiguous 1s followed by 0s."
        error "Examples: 255.255.255.0, 255.255.255.128, 255.255.0.0"
    done
    echo ""
    
    # ═════════════════════════════════════════════════════════════════════════
    # STEP 4: DHCP POOL RANGE
    # ═════════════════════════════════════════════════════════════════════════
    #
    # The pool defines the range of IP addresses available for
    # dynamic allocation to DHCP clients.
    #
    # IMPORTANT CONSIDERATIONS:
    #   • Pool should be within the subnet
    #   • Pool should NOT include the server's IP
    #   • Pool should NOT include the gateway
    #   • Leave room for static IPs and infrastructure
    #
    # VALIDATION: Valid IPv4 addresses
    #
    academic "Step 3: DHCP Address Pool"
    academic "Define the range of IPs for dynamic allocation"
    academic "Tip: Leave room for static IPs outside the pool"
    echo ""
    
    # Pool start
    while true; do
        read -rp "Enter Pool Start IP: " pool_start
        
        if validate_ip "$pool_start"; then
            success "Pool start set to: $pool_start"
            break
        fi
        
        error "Invalid IP address format."
    done
    echo ""
    
    # Pool end
    while true; do
        read -rp "Enter Pool End IP: " pool_end
        
        if validate_ip "$pool_end"; then
            success "Pool end set to: $pool_end"
            break
        fi
        
        error "Invalid IP address format."
    done
    echo ""
    
    # ═════════════════════════════════════════════════════════════════════════
    # STEP 5: SERVER HOST ADDRESS
    # ═════════════════════════════════════════════════════════════════════════
    #
    # This is the IP address that will be assigned to THIS server
    # on the specified interface. This address will be configured
    # statically in /etc/network/interfaces.
    #
    # REQUIREMENTS:
    #   • Must be within the subnet
    #   • Must be OUTSIDE the DHCP pool
    #   • Typically at the start of the subnet (e.g., .1)
    #
    # VALIDATION: Valid IPv4 address
    #
    academic "Step 4: Server Host Address"
    academic "This is the IP assigned to THIS server on the interface"
    academic "Must be OUTSIDE the DHCP pool range"
    echo ""
    
    while true; do
        read -rp "Enter Server's IP on this interface: " host_address
        
        if validate_ip "$host_address"; then
            success "Server IP set to: $host_address"
            break
        fi
        
        error "Invalid IP address format."
    done
    echo ""
    
    # ═════════════════════════════════════════════════════════════════════════
    # STEP 6: DEFAULT GATEWAY
    # ═════════════════════════════════════════════════════════════════════════
    #
    # The gateway is the router that clients will use to reach
    # networks outside their local subnet.
    #
    # This value is sent to clients as DHCP Option 3 (Routers).
    # RFC 2132 Section 3.5 specifies this option.
    #
    # VALIDATION: Valid IPv4 address
    #
    academic "Step 5: Default Gateway"
    academic "The router address clients will use to reach other networks"
    academic "This is sent as DHCP Option 3 (Routers) per RFC 2132"
    echo ""
    
    while true; do
        read -rp "Enter Gateway IP: " gateway
        
        if validate_ip "$gateway"; then
            success "Gateway set to: $gateway"
            break
        fi
        
        error "Invalid IP address format."
    done
    echo ""
    
    # ═════════════════════════════════════════════════════════════════════════
    # STEP 7: DNS SERVERS
    # ═════════════════════════════════════════════════════════════════════════
    #
    # DNS servers are provided to clients as DHCP Option 6.
    # Clients use these servers to resolve hostnames to IP addresses.
    #
    # We collect two DNS servers:
    #   • Primary: First choice for DNS resolution
    #   • Secondary: Fallback if primary is unavailable
    #
    # DEFAULT SECONDARY: 9.9.9.9 (Quad9)
    #   Quad9 provides:
    #   • Malware domain blocking
    #   • DNSSEC validation
    #   • Privacy-focused (no logging)
    #
    # VALIDATION: Valid IPv4 addresses
    #
    academic "Step 6: DNS Servers"
    academic "Clients will use these servers for name resolution"
    academic "Sent as DHCP Option 6 per RFC 2132 Section 3.8"
    echo ""
    
    # Primary DNS
    while true; do
        read -rp "Enter Primary DNS Server IP: " dns_primary
        
        if validate_ip "$dns_primary"; then
            success "Primary DNS set to: $dns_primary"
            break
        fi
        
        error "Invalid IP address format."
    done
    echo ""
    
    # Secondary DNS (with default)
    academic "Secondary DNS provides failover if primary is unavailable"
    academic "Default: 9.9.9.9 (Quad9 - security-filtered public DNS)"
    echo ""
    
    while true; do
        read -rp "Enter Secondary DNS Server IP (or press Enter for 9.9.9.9): " dns_secondary
        
        # Apply default if empty
        dns_secondary="${dns_secondary:-9.9.9.9}"
        
        if validate_ip "$dns_secondary"; then
            success "Secondary DNS set to: $dns_secondary"
            break
        fi
        
        error "Invalid IP address format."
    done
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # DISPLAY CONFIGURATION SUMMARY
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Show the user a summary of what they entered before continuing.
    # This helps catch any errors before the configuration is applied.
    #
    local cidr
    cidr=$(netmask_to_cidr "$netmask")
    
    echo ""
    echo -e "${C_BOLD}${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}           Scope #${scope_number} Configuration Summary${C_RESET}"
    echo -e "${C_BOLD}${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo ""
    info "Interface    : $interface"
    info "Network      : $network/$cidr"
    info "DHCP Pool    : $pool_start - $pool_end"
    info "Server IP    : $host_address"
    info "Gateway      : $gateway"
    info "DNS Servers  : $dns_primary, $dns_secondary"
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # OUTPUT: COLON-SEPARATED SCOPE STRING
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Return the scope configuration as a colon-separated string.
    # This format matches the C_SCOPES array structure defined in 00_constants.sh
    #
    # Field order:
    #   0: interface
    #   1: network
    #   2: netmask
    #   3: pool_start
    #   4: pool_end
    #   5: host_address
    #   6: gateway
    #   7: dns_primary
    #   8: dns_secondary
    #
    echo "${interface}:${network}:${netmask}:${pool_start}:${pool_end}:${host_address}:${gateway}:${dns_primary}:${dns_secondary}"
}


#######################################
# MODULE LOAD CONFIRMATION
#######################################
# Uncomment for debugging module loading:
# echo "Module loaded: 03_interactive.sh (Interactive Scope Input)"
