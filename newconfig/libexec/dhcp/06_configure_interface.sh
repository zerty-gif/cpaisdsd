#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                  NETWORK INTERFACE CONFIGURATION MODULE                   ║
# ║            Static IP Assignment for DHCP Server Interfaces                ║
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
#   This module configures the network interfaces on which the DHCP server
#   will operate. Each interface is assigned a static IP address (the server's
#   address for that scope) to ensure the DHCP server can properly respond
#   to client requests on each network segment.
#
#   WHY STATIC IPS FOR DHCP SERVERS?
#   ────────────────────────────────
#   A DHCP server MUST have a static IP address because:
#
#     1. DHCP servers cannot request their own IP via DHCP (chicken-and-egg)
#     2. Clients need a predictable server address for lease renewal
#     3. DHCP packets reference the server's IP in the siaddr field
#     4. Reliability: the server must always be reachable at the same address
#
#   CONFIGURATION METHOD:
#   ─────────────────────
#   This module uses the 'ip' command from iproute2 to configure interfaces.
#   This is the modern approach (replaces deprecated ifconfig).
#
#   Commands used:
#     • ip addr flush dev <iface>  : Remove existing IP addresses
#     • ip addr add <ip>/<cidr> dev <iface> : Assign new IP address
#     • ip link set <iface> up     : Bring interface up
#
# ═══════════════════════════════════════════════════════════════════════════════
# NETWORK INTERFACE STATES
# ═══════════════════════════════════════════════════════════════════════════════
#
#   An interface can be in several states:
#
#   ┌─────────────────────────────────────────────────────────────────────────┐
#   │ State      │ Description                 │ Can receive packets?        │
#   ├────────────┼─────────────────────────────┼─────────────────────────────┤
#   │ DOWN       │ Interface disabled          │ No                          │
#   │ UP         │ Interface enabled           │ Only if configured          │
#   │ NO-CARRIER │ No physical link            │ No                          │
#   │ LOWER_UP   │ Physical link present       │ Yes, if IP assigned         │
#   └─────────────────────────────────────────────────────────────────────────┘
#
#   For DHCP to work, the interface must be:
#     • State: UP
#     • Has valid IP address assigned
#     • Has physical link (for wired) or association (for wireless)
#
# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════════
#
#   Requires:
#     • 00_constants.sh  (C_SCOPES array)
#     • 01_output.sh     (panel functions, info, error, success, etc.)
#     • 02_validation.sh (netmask_to_cidr)
#
#   System Requirements:
#     • iproute2 package (provides 'ip' command)
#     • Root privileges (required for interface configuration)
#
#######################################

#######################################
# configure_network_interfaces()
#######################################
#
# PURPOSE:
#   Configure all network interfaces defined in the C_SCOPES array with
#   their respective static IP addresses.
#
# CONFIGURATION PROCESS:
#   ┌─────────────────────────────────────────────────────────────────────────┐
#   │                   INTERFACE CONFIGURATION FLOW                          │
#   ├─────────────────────────────────────────────────────────────────────────┤
#   │                                                                         │
#   │  For each scope in C_SCOPES:                                            │
#   │                                                                         │
#   │  ┌─────────────────┐                                                    │
#   │  │ Parse scope     │──► Extract interface and host_address             │
#   │  │ string          │                                                    │
#   │  └────────┬────────┘                                                    │
#   │           │                                                             │
#   │           ▼                                                             │
#   │  ┌─────────────────┐     No           ┌─────────────────┐               │
#   │  │ Interface       │─────────────────►│ Skip with       │               │
#   │  │ exists?         │                  │ warning         │               │
#   │  └────────┬────────┘                  └─────────────────┘               │
#   │           │ Yes                                                         │
#   │           ▼                                                             │
#   │  ┌─────────────────┐     Already done  ┌─────────────────┐              │
#   │  │ Already         │──────────────────►│ Skip            │              │
#   │  │ configured?     │                   │ (no duplicate)  │              │
#   │  └────────┬────────┘                   └─────────────────┘              │
#   │           │ No                                                          │
#   │           ▼                                                             │
#   │  ┌─────────────────┐                                                    │
#   │  │ Flush existing  │──► Remove any existing IP addresses               │
#   │  │ addresses       │                                                    │
#   │  └────────┬────────┘                                                    │
#   │           │                                                             │
#   │           ▼                                                             │
#   │  ┌─────────────────┐                                                    │
#   │  │ Assign static   │──► ip addr add <ip>/<cidr> dev <iface>            │
#   │  │ IP address      │                                                    │
#   │  └────────┬────────┘                                                    │
#   │           │                                                             │
#   │           ▼                                                             │
#   │  ┌─────────────────┐                                                    │
#   │  │ Bring interface │──► ip link set <iface> up                          │
#   │  │ up              │                                                    │
#   │  └─────────────────┘                                                    │
#   │                                                                         │
#   └─────────────────────────────────────────────────────────────────────────┘
#
# USAGE:
#   configure_network_interfaces
#
# PARAMETERS:
#   None (reads from global C_SCOPES array)
#
# RETURNS:
#   0 : All interfaces configured successfully
#   Exits with 1 if critical failure occurs
#
#######################################
configure_network_interfaces() {
    # ─────────────────────────────────────────────────────────────────────────
    # DISPLAY MODULE HEADER
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Provide visual feedback about what we're doing.
    #
    panel_header "Network Interface Configuration"
    
    academic "Configuring network interfaces for DHCP server operation"
    academic "Each interface will be assigned a static IP from its scope"
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # VERIFY IP COMMAND IS AVAILABLE
    # ─────────────────────────────────────────────────────────────────────────
    #
    # The 'ip' command from iproute2 is required for interface configuration.
    # It should be present on all modern Linux systems.
    #
    if ! command -v ip &> /dev/null; then
        error "The 'ip' command (iproute2) is not installed"
        error "Please install: apt install iproute2"
        panel_footer
        exit 1
    fi
    
    # ─────────────────────────────────────────────────────────────────────────
    # TRACK CONFIGURED INTERFACES
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Use an associative array to track which interfaces we've already
    # configured. This prevents duplicate configuration if the same
    # interface appears in multiple scopes.
    #
    declare -A configured_interfaces
    local success_count=0
    local fail_count=0
    
    # ─────────────────────────────────────────────────────────────────────────
    # PROCESS EACH SCOPE
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Iterate through all scopes and configure their interfaces.
    #
    for scope in "${C_SCOPES[@]}"; do
        # ─────────────────────────────────────────────────────────────────────
        # PARSE SCOPE STRING
        # ─────────────────────────────────────────────────────────────────────
        #
        # Extract interface, host_address, and netmask from the scope string.
        #
        local interface network netmask pool_start pool_end host_address gateway dns_primary dns_secondary
        IFS=':' read -r interface network netmask pool_start pool_end host_address gateway dns_primary dns_secondary <<< "$scope"
        
        # ─────────────────────────────────────────────────────────────────────
        # CHECK IF ALREADY CONFIGURED
        # ─────────────────────────────────────────────────────────────────────
        #
        # Skip if we've already configured this interface in this run.
        # This handles cases where multiple scopes use the same interface
        # (not typical, but possible in advanced configurations).
        #
        if [[ -v configured_interfaces[$interface] ]]; then
            debug "Interface $interface already configured, skipping"
            continue
        fi
        
        info "Configuring interface: $interface"
        
        # ─────────────────────────────────────────────────────────────────────
        # VERIFY INTERFACE EXISTS
        # ─────────────────────────────────────────────────────────────────────
        #
        # Check if the interface exists in the system.
        # 'ip link show <iface>' returns 0 if interface exists.
        #
        if ! ip link show "$interface" &> /dev/null; then
            warning "Interface $interface does not exist on this system"
            warning "Available interfaces:"
            
            # List available interfaces for troubleshooting
            ip -br link show | while read -r line; do
                warning "  $line"
            done
            
            fail_count=$((fail_count + 1))
            echo ""
            continue
        fi
        
        # ─────────────────────────────────────────────────────────────────────
        # CONVERT NETMASK TO CIDR
        # ─────────────────────────────────────────────────────────────────────
        #
        # The 'ip' command uses CIDR notation (e.g., /24) instead of
        # dotted decimal netmask (e.g., 255.255.255.0).
        #
        local cidr
        cidr=$(netmask_to_cidr "$netmask")
        
        academic "Target configuration: ${host_address}/${cidr}"
        
        # ─────────────────────────────────────────────────────────────────────
        # FLUSH EXISTING IP ADDRESSES
        # ─────────────────────────────────────────────────────────────────────
        #
        # Remove any existing IP addresses from the interface.
        # This ensures a clean slate before assigning the new address.
        #
        # 'ip addr flush dev <iface>':
        #   Removes all IP addresses from the specified interface.
        #   This is a destructive operation - use with care!
        #
        progress "Removing existing IP configuration..."
        
        if ! ip addr flush dev "$interface" 2>/dev/null; then
            warning "Could not flush existing addresses (may be normal)"
        fi
        
        # ─────────────────────────────────────────────────────────────────────
        # ASSIGN STATIC IP ADDRESS
        # ─────────────────────────────────────────────────────────────────────
        #
        # Add the DHCP server's IP address to the interface.
        #
        # 'ip addr add <ip>/<cidr> dev <iface>':
        #   Assigns an IP address in CIDR notation to the interface.
        #
        # This is the critical step - the server must have an IP in the
        # subnet it's serving to properly respond to DHCP requests.
        #
        progress "Assigning IP address: ${host_address}/${cidr}"
        
        if ! ip addr add "${host_address}/${cidr}" dev "$interface" 2>/dev/null; then
            # Check if address already exists
            if ip addr show dev "$interface" | grep -q "$host_address"; then
                info "Address ${host_address} already assigned to $interface"
            else
                error "Failed to assign IP address to $interface"
                error "Command: ip addr add ${host_address}/${cidr} dev $interface"
                fail_count=$((fail_count + 1))
                continue
            fi
        fi
        
        # ─────────────────────────────────────────────────────────────────────
        # BRING INTERFACE UP
        # ─────────────────────────────────────────────────────────────────────
        #
        # Ensure the interface is in the UP state.
        # An interface must be UP to transmit/receive packets.
        #
        # 'ip link set <iface> up':
        #   Sets the interface state to UP (enabled).
        #
        progress "Bringing interface up..."
        
        if ! ip link set "$interface" up 2>/dev/null; then
            error "Failed to bring interface $interface up"
            fail_count=$((fail_count + 1))
            continue
        fi
        
        # ─────────────────────────────────────────────────────────────────────
        # VERIFY CONFIGURATION
        # ─────────────────────────────────────────────────────────────────────
        #
        # Confirm the IP address was successfully assigned.
        # Parse the output of 'ip addr show' to verify.
        #
        local current_ip
        current_ip=$(ip -4 addr show dev "$interface" | grep -oP 'inet \K[\d.]+(?=/)')
        
        if [[ "$current_ip" == "$host_address" ]]; then
            success "Interface $interface configured: ${host_address}/${cidr}"
            configured_interfaces["$interface"]=1
            success_count=$((success_count + 1))
        else
            error "Verification failed for $interface"
            error "Expected: $host_address, Got: $current_ip"
            fail_count=$((fail_count + 1))
        fi
        
        # ─────────────────────────────────────────────────────────────────────
        # DISPLAY INTERFACE STATUS
        # ─────────────────────────────────────────────────────────────────────
        #
        # Show brief status of the configured interface.
        #
        local link_status
        link_status=$(ip -br link show "$interface" | awk '{print $2}')
        
        table_row "Interface" "$interface"
        table_row "IP Address" "${host_address}/${cidr}"
        table_row "Status" "$link_status"
        separator
        echo ""
        
    done  # End of C_SCOPES loop
    
    # ─────────────────────────────────────────────────────────────────────────
    # DISPLAY SUMMARY
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Report the overall result of interface configuration.
    #
    echo ""
    info "Interface configuration summary:"
    table_row "Successful" "$success_count"
    table_row "Failed" "$fail_count"
    
    if [[ $fail_count -gt 0 ]]; then
        warning "Some interfaces could not be configured"
        warning "Please verify network hardware and interface names"
    fi
    
    if [[ $success_count -eq 0 ]]; then
        error "No interfaces were configured successfully"
        error "DHCP server cannot start without configured interfaces"
        panel_footer
        exit 1
    fi
    
    success "Network interface configuration complete"
    
    panel_footer
}


#######################################
# get_interface_info()
#######################################
#
# PURPOSE:
#   Retrieve detailed information about a network interface.
#   Useful for diagnostics and verification.
#
# USAGE:
#   get_interface_info "ens32"
#
# PARAMETERS:
#   $1 : Interface name (e.g., "ens32", "eth0")
#
# OUTPUT:
#   Prints interface details to stdout
#
# RETURNS:
#   0 : Interface exists and info was displayed
#   1 : Interface does not exist
#
#######################################
get_interface_info() {
    # ─────────────────────────────────────────────────────────────────────────
    # VALIDATE PARAMETERS
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Ensure an interface name was provided.
    #
    local interface="${1:-}"
    
    if [[ -z "$interface" ]]; then
        error "get_interface_info: No interface name provided"
        return 1
    fi
    
    # ─────────────────────────────────────────────────────────────────────────
    # CHECK IF INTERFACE EXISTS
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Verify the interface exists before trying to query it.
    #
    if ! ip link show "$interface" &> /dev/null; then
        error "Interface $interface does not exist"
        return 1
    fi
    
    # ─────────────────────────────────────────────────────────────────────────
    # GATHER INTERFACE INFORMATION
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Collect various pieces of information about the interface.
    #
    
    # Get link status (UP/DOWN)
    local link_status
    link_status=$(ip -br link show "$interface" | awk '{print $2}')
    
    # Get MAC address
    local mac_address
    mac_address=$(ip link show "$interface" | grep -oP 'link/ether \K[0-9a-f:]+')
    
    # Get IP address(es)
    local ip_addresses
    ip_addresses=$(ip -4 addr show "$interface" | grep -oP 'inet \K[\d./]+')
    
    # Get MTU
    local mtu
    mtu=$(ip link show "$interface" | grep -oP 'mtu \K\d+')
    
    # ─────────────────────────────────────────────────────────────────────────
    # DISPLAY INFORMATION
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Output the gathered information in a formatted display.
    #
    info "Interface: $interface"
    table_row "Status" "$link_status"
    table_row "MAC Address" "${mac_address:-N/A}"
    table_row "IP Address(es)" "${ip_addresses:-None}"
    table_row "MTU" "${mtu:-1500}"
    
    return 0
}


#######################################
# MODULE LOAD CONFIRMATION
#######################################
# Uncomment for debugging module loading:
# echo "Module loaded: 06_configure_interface.sh (Network Interface Configuration)"
