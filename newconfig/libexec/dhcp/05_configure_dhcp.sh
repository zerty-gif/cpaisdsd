#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                    KEA DHCP4 CONFIGURATION MODULE                         ║
# ║             Dynamic Multi-Subnet Configuration Generator                  ║
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
#   This module generates the Kea DHCP4 server configuration file dynamically
#   based on the scopes defined in the C_SCOPES array. It supports multiple
#   subnets and creates a fully RFC 2131/2132 compliant configuration.
#
#   KEA DHCP4 OVERVIEW:
#   ───────────────────
#   Kea is the modern DHCP server developed by ISC (Internet Systems Consortium)
#   as the successor to ISC DHCP. It uses JSON for configuration, which provides:
#     • Strong type checking
#     • Clear structure
#     • Easy programmatic generation
#     • Better validation
#
#   CONFIGURATION STRUCTURE:
#   ────────────────────────
#   The generated configuration follows this structure:
#
#     {
#       "Dhcp4": {
#         "interfaces-config": { ... },    // Which interfaces to listen on
#         "lease-database": { ... },       // Where to store leases
#         "valid-lifetime": ...,           // Default lease duration
#         "renew-timer": ...,              // When clients should renew
#         "rebind-timer": ...,             // When clients should rebind
#         "subnet4": [                     // Array of subnet definitions
#           { "id": 1, "subnet": "...", "pools": [...], "option-data": [...] },
#           { "id": 2, "subnet": "...", "pools": [...], "option-data": [...] }
#         ]
#       }
#     }
#
# ═══════════════════════════════════════════════════════════════════════════════
# DHCP OPTION REFERENCE (RFC 2132)
# ═══════════════════════════════════════════════════════════════════════════════
#
#   OPTION 1 - Subnet Mask:
#     Defines the network mask for the subnet.
#     Example: "255.255.255.0" for a /24 network.
#
#   OPTION 3 - Router (Default Gateway):
#     IP address(es) of the default gateway(s).
#     Clients will use this to reach other networks.
#
#   OPTION 6 - DNS Servers:
#     List of DNS servers for name resolution.
#     Order matters - clients try first listed server first.
#
#   OPTION 51 - Lease Time:
#     How long (in seconds) the IP assignment is valid.
#     After this time, the client must renew or stop using the IP.
#
# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════════
#
#   Requires:
#     • 00_constants.sh (C_SCOPES, C_VALID_LIFETIME, C_RENEW_TIMER, C_REBIND_TIMER)
#     • 01_output.sh    (panel functions, info, error, success, etc.)
#     • 02_validation.sh (netmask_to_cidr)
#
#   System Requirements:
#     • Kea DHCP4 server package: isc-kea-dhcp4-server
#     • Write access to: /etc/kea/
#
#######################################

#######################################
# configure_dhcp_server()
#######################################
#
# PURPOSE:
#   Generate and install a complete Kea DHCP4 configuration file based on
#   the scopes defined in the C_SCOPES array.
#
# GENERATION PROCESS:
#   ┌─────────────────────────────────────────────────────────────────────────┐
#   │                   CONFIGURATION GENERATION FLOW                         │
#   ├─────────────────────────────────────────────────────────────────────────┤
#   │                                                                         │
#   │  ┌─────────────────┐                                                    │
#   │  │ Build interface │──► Collect unique interfaces from all scopes      │
#   │  │ list            │                                                    │
#   │  └────────┬────────┘                                                    │
#   │           │                                                             │
#   │           ▼                                                             │
#   │  ┌─────────────────┐                                                    │
#   │  │ Generate header │──► interfaces-config, lease-database, timers      │
#   │  └────────┬────────┘                                                    │
#   │           │                                                             │
#   │           ▼                                                             │
#   │  ┌─────────────────┐                                                    │
#   │  │ For each scope: │──► Generate subnet4 entry with:                    │
#   │  │                 │    • Unique ID (1, 2, 3, ...)                       │
#   │  │                 │    • Subnet in CIDR notation                       │
#   │  │                 │    • Pool definition                               │
#   │  │                 │    • DHCP options (router, DNS, etc.)              │
#   │  └────────┬────────┘                                                    │
#   │           │                                                             │
#   │           ▼                                                             │
#   │  ┌─────────────────┐                                                    │
#   │  │ Write config    │──► /etc/kea/kea-dhcp4.conf                         │
#   │  │ file            │                                                    │
#   │  └────────┬────────┘                                                    │
#   │           │                                                             │
#   │           ▼                                                             │
#   │  ┌─────────────────┐                                                    │
#   │  │ Validate syntax │──► kea-dhcp4 -t (test mode)                        │
#   │  └─────────────────┘                                                    │
#   │                                                                         │
#   └─────────────────────────────────────────────────────────────────────────┘
#
# USAGE:
#   configure_dhcp_server
#
# PARAMETERS:
#   None (reads from global C_SCOPES array)
#
# RETURNS:
#   0 : Configuration generated and validated successfully
#   Exits with 1 on failure
#
# OUTPUT:
#   Creates /etc/kea/kea-dhcp4.conf with the generated configuration
#
#######################################
configure_dhcp_server() {
    # ─────────────────────────────────────────────────────────────────────────
    # DISPLAY MODULE HEADER
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Show clear visual feedback about what we're doing.
    #
    panel_header "Kea DHCP4 Server Configuration"
    
    academic "Generating Kea DHCP4 configuration for ${#C_SCOPES[@]} scope(s)"
    academic "Configuration will be written to: /etc/kea/kea-dhcp4.conf"
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # DEFINE CONFIGURATION PATH
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Kea's default configuration directory is /etc/kea/
    # The main DHCP4 configuration file is kea-dhcp4.conf
    #
    # Allow overriding destination directory for debugging (non-root runs)
    # If KEA_DIR is set in environment, write config there; else use /etc/kea
    # In SAFE_MODE, default to /tmp for testing without root privileges
    local kea_dir="${KEA_DIR:-/etc/kea}"
    if [[ "${SAFE_MODE:-0}" == "1" ]]; then
        kea_dir="${KEA_DIR:-/tmp/kea}"
    fi
    local kea_config="${kea_dir}/kea-dhcp4.conf"
    
    # ─────────────────────────────────────────────────────────────────────────
    # ENSURE KEA CONFIGURATION DIRECTORY EXISTS
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Create the directory if it doesn't exist.
    # This handles fresh installations where Kea might not be configured yet.
    # Also ensure the directory has proper permissions for kea-dhcp4 access.
    #
    if [[ ! -d "$kea_dir" ]]; then
        info "Creating Kea configuration directory: $kea_dir"
        if ! mkdir -p "$kea_dir" 2>/dev/null; then
            error "Failed to create directory: $kea_dir"
            error "Are you running with root privileges?"
            panel_footer
            exit 1
        fi
    fi
    
    # Fix directory permissions to allow kea-dhcp4 to traverse it
    # The kea directory must be readable and executable by all users
    chmod 755 "$kea_dir" 2>/dev/null || true
    
    # ─────────────────────────────────────────────────────────────────────────
    # BACKUP EXISTING CONFIGURATION (IF EXISTS)
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Always create a backup before overwriting.
    # Timestamped backup allows recovery of previous configurations.
    #
    if [[ -f "$kea_config" ]]; then
        local backup_file="${kea_config}.backup.$(date +%Y%m%d_%H%M%S)"
        info "Backing up existing configuration to: $backup_file"
        cp "$kea_config" "$backup_file"
        success "Backup created"
    fi
    
    # ─────────────────────────────────────────────────────────────────────────
    # COLLECT UNIQUE INTERFACES
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Build a list of all unique interfaces from the scopes.
    # Kea needs to know which interfaces to listen on for DHCP requests.
    #
    # Using an associative array to track unique interfaces:
    #   - Keys are interface names
    #   - Values are "1" (presence indicator)
    #
    progress "Collecting interfaces from scopes..."
    
    declare -A unique_interfaces
    local interface_list=""
    
    for scope in "${C_SCOPES[@]}"; do
        # ─────────────────────────────────────────────────────────────────────
        # PARSE SCOPE STRING
        # ─────────────────────────────────────────────────────────────────────
        #
        # The scope string format is:
        #   interface:network:netmask:pool_start:pool_end:host:gateway:dns1:dns2
        #
        # We use IFS=':' to split by colon.
        # read -r assigns each field to a variable.
        #
        local interface network netmask pool_start pool_end host_address gateway dns_primary dns_secondary
        IFS=':' read -r interface network netmask pool_start pool_end host_address gateway dns_primary dns_secondary <<< "$scope"
        
        # Add to unique interfaces if not already present
        if [[ ! -v unique_interfaces[$interface] ]]; then
            unique_interfaces["$interface"]=1
            
            # Build the interface list string for JSON
            # Format: "interface1", "interface2", ...
            if [[ -n "$interface_list" ]]; then
                interface_list="${interface_list}, \"${interface}\""
            else
                interface_list="\"${interface}\""
            fi
            
            debug "Added interface: $interface"
        fi
    done
    
    success "Interfaces to configure: ${!unique_interfaces[*]}"
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # BUILD SUBNET CONFIGURATIONS
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Generate JSON for each subnet in the C_SCOPES array.
    # Each subnet gets a unique ID starting from 1.
    #
    progress "Generating subnet configurations..."
    
    local subnet_json=""
    local subnet_id=1
    
    for scope in "${C_SCOPES[@]}"; do
        # Parse the scope string (same as above)
        local interface network netmask pool_start pool_end host_address gateway dns_primary dns_secondary
        IFS=':' read -r interface network netmask pool_start pool_end host_address gateway dns_primary dns_secondary <<< "$scope"
        
        # ─────────────────────────────────────────────────────────────────────
        # CONVERT NETMASK TO CIDR NOTATION
        # ─────────────────────────────────────────────────────────────────────
        #
        # Kea requires subnet in CIDR format: "192.168.100.0/24"
        # netmask_to_cidr converts "255.255.255.0" to "24"
        #
        local cidr
        cidr=$(netmask_to_cidr "$netmask")
        
        # ─────────────────────────────────────────────────────────────────────
        # BUILD SUBNET JSON BLOCK
        # ─────────────────────────────────────────────────────────────────────
        #
        # Each subnet4 entry contains:
        #   • id: Unique identifier
        #   • subnet: Network in CIDR notation
        #   • pools: Range of addresses to distribute
        #   • option-data: DHCP options (gateway, DNS, etc.)
        #   • interface: Which interface this subnet is for
        #
        # Note: JSON doesn't allow trailing commas, so we add commas
        # between entries but not after the last one.
        #
        
        # Add comma separator if this isn't the first subnet
        if [[ -n "$subnet_json" ]]; then
            subnet_json="${subnet_json},"
        fi
        
        # ─────────────────────────────────────────────────────────────────────
        # GENERATE SUBNET JSON
        # ─────────────────────────────────────────────────────────────────────
        #
        # We use cat with a heredoc for readable multi-line JSON generation.
        # The heredoc content is indented for readability in the final config.
        #
        subnet_json="${subnet_json}
    {
        \"comment\": \"Subnet ${subnet_id}: ${network}/${cidr} on ${interface}\",
        \"id\": ${subnet_id},
        \"subnet\": \"${network}/${cidr}\",
        \"pools\": [
        {
            \"pool\": \"${pool_start}-${pool_end}\",
            \"comment\": \"Address pool for ${interface}\"
        }
        ],
        \"option-data\": [
        {
            \"name\": \"routers\",
            \"data\": \"${gateway}\",
            \"comment\": \"Default gateway (RFC 2132, Option 3)\"
        },
        {
            \"name\": \"domain-name-servers\",
            \"data\": \"${dns_primary}, ${dns_secondary}\",
            \"comment\": \"DNS servers (RFC 2132, Option 6)\"
        }
        ]
    }"
        
        info "Generated subnet #${subnet_id}: ${network}/${cidr}"
        table_row "Interface" "$interface"
        table_row "Pool Range" "${pool_start} - ${pool_end}"
        table_row "Gateway" "$gateway"
        table_row "DNS" "${dns_primary}, ${dns_secondary}"
        separator
        
        # Increment subnet ID for next iteration
        subnet_id=$((subnet_id + 1))
    done
    
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # BUILD COMPLETE CONFIGURATION FILE
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Assemble the full Kea DHCP4 configuration.
    # This includes:
    #   • Header with interfaces configuration
    #   • Lease database settings
    #   • Global timing parameters
    #   • All subnet definitions
    #
    progress "Writing configuration file..."
    
    # Write the configuration file using a heredoc
    # The heredoc allows for clean, readable multi-line content
    #
    cat > "$kea_config" << 'EOF'
{
    "Dhcp4": {
        "interfaces-config": {
            "interfaces": [ __INTERFACES__ ],
            "service-sockets-require-all": false
        },
        
        "lease-database": {
            "type": "memfile",
            "lfc-interval": 3600,
            "persist": true
        },
        
        "valid-lifetime": __VALID_LIFETIME__,
        "renew-timer": __RENEW_TIMER__,
        "rebind-timer": __REBIND_TIMER__,
        
        "subnet4": [__SUBNETS__
        ],
        
        "loggers": [
            {
                "name": "kea-dhcp4",
                "output_options": [
                    {
                        "output": "/var/log/kea/kea-dhcp4.log",
                        "pattern": "%D{%Y-%m-%d %H:%M:%S.%q} %-5p [%c/%i] %m\\n"
                    }
                ],
                "severity": "INFO",
                "debuglevel": 0
            }
        ]
    }
}
EOF
    
    # Replace placeholders with actual values using a safer method
    # We use a temporary file to avoid sed delimiter issues with JSON content
    {
        sed "s/__INTERFACES__/${interface_list}/g" "$kea_config"
    } > "${kea_config}.tmp" && mv "${kea_config}.tmp" "$kea_config"
    
    {
        sed "s/__VALID_LIFETIME__/${C_VALID_LIFETIME}/g" "$kea_config"
    } > "${kea_config}.tmp" && mv "${kea_config}.tmp" "$kea_config"
    
    {
        sed "s/__RENEW_TIMER__/${C_RENEW_TIMER}/g" "$kea_config"
    } > "${kea_config}.tmp" && mv "${kea_config}.tmp" "$kea_config"
    
    {
        sed "s/__REBIND_TIMER__/${C_REBIND_TIMER}/g" "$kea_config"
    } > "${kea_config}.tmp" && mv "${kea_config}.tmp" "$kea_config"
    
    # For subnet JSON, use awk/printf to safely insert it
    {
        awk -v subnet="$subnet_json" '{gsub(/__SUBNETS__/, subnet); print}' "$kea_config"
    } > "${kea_config}.tmp" && mv "${kea_config}.tmp" "$kea_config"
    
    # Check if file was created successfully
    if [[ ! -f "$kea_config" ]]; then
        error "Failed to write configuration file: $kea_config"
        panel_footer
        exit 1
    fi
    
    # Verify file size (should not be empty)
    if [[ ! -s "$kea_config" ]]; then
        error "Configuration file is empty: $kea_config"
        panel_footer
        exit 1
    fi
    
    success "Configuration file written: $kea_config"
    
    # ─────────────────────────────────────────────────────────────────────────
    # SET PROPER FILE PERMISSIONS AND OWNERSHIP
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Configuration file should be readable by the kea user/group.
    # Mode 644: Owner (root) can read/write, others can read (required for _kea).
    # Ownership: Set to root:_kea so kea daemon can read the file.
    #
    progress "Setting file permissions..."
    chmod 644 "$kea_config" 2>/dev/null || true
    chown root:_kea "$kea_config" 2>/dev/null || true
    success "Permissions set: 644 (rw-r--r--), Owner: root:_kea"
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # ENSURE LOG AND LEASE DIRECTORIES EXIST WITH PROPER PERMISSIONS
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Create the log and lease directories if they don't exist.
    # Kea won't start if it can't write to its log file or lease database.
    # Ensure permissions allow the kea daemon user to read/write.
    #
    local log_dir="/var/log/kea"
    local lease_dir="/var/lib/kea"
    
    if [[ ! -d "$log_dir" ]]; then
        info "Creating log directory: $log_dir"
        mkdir -p "$log_dir"
        chmod 755 "$log_dir"
    fi
    
    if [[ ! -d "$lease_dir" ]]; then
        info "Creating lease directory: $lease_dir"
        mkdir -p "$lease_dir"
        chmod 755 "$lease_dir"
    else
        # Ensure existing directories have correct permissions for kea daemon
        chmod 755 "$lease_dir" 2>/dev/null || true
        chmod 755 "$log_dir" 2>/dev/null || true
    fi
    
    # ─────────────────────────────────────────────────────────────────────────
    # VALIDATE CONFIGURATION SYNTAX
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Use Kea's built-in configuration test mode to validate the JSON syntax
    # and semantic correctness of the configuration.
    #
    # kea-dhcp4 -t : Test mode, validates config without starting server
    #
    progress "Validating configuration syntax..."
    
    # Check if kea-dhcp4 is available
    if command -v kea-dhcp4 &> /dev/null; then
        # Run configuration test and show output to aid debugging
        if output=$(kea-dhcp4 -t "$kea_config" 2>&1); then
            success "Configuration syntax validated successfully"
        else
            warning "Configuration validation failed. Details:"
            echo "$output"
            warning "Please review the above errors and configuration file."
        fi
    else
        warning "kea-dhcp4 command not found - skipping syntax validation"
        warning "Configuration will be validated when Kea is installed/started"
    fi
    
    echo ""
    success "Kea DHCP4 configuration complete"
    
    panel_footer
}


#######################################
# MODULE LOAD CONFIRMATION
#######################################
# Uncomment for debugging module loading:
# echo "Module loaded: 05_configure_dhcp.sh (Kea DHCP4 Configuration)"
