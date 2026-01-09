#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                      SCOPE FILE PARSER MODULE                             ║
# ║                    External Configuration File Reader                     ║
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
#   This module discovers and parses DHCP scope configuration files (.scope).
#   Each .scope file defines a single DHCP scope (subnet) that the server
#   will manage.
#
#   DISCOVERY PROCESS:
#   ──────────────────
#     1. Search for *.scope files in the script directory
#     2. If found: Parse each file and validate contents
#     3. If not found: Fall back to interactive input mode
#
#   FILE FORMAT:
#   ────────────
#     Scope files use a simple KEY=VALUE format:
#
#       # Comment lines start with #
#       INTERFACE=ens32
#       NETWORK=192.168.100.0
#       NETMASK=255.255.255.0
#       POOL_START=192.168.100.30
#       POOL_END=192.168.100.50
#       HOST_ADDRESS=192.168.100.1
#       GATEWAY=192.168.100.254
#       DNS_PRIMARY=192.168.100.1
#       DNS_SECONDARY=9.9.9.9
#
# ═══════════════════════════════════════════════════════════════════════════════
# PARSING ALGORITHM
# ═══════════════════════════════════════════════════════════════════════════════
#
#   ┌─────────────────────────────────────────────────────────────────────────┐
#   │                     SCOPE FILE PARSING FLOW                             │
#   ├─────────────────────────────────────────────────────────────────────────┤
#   │                                                                         │
#   │  ┌─────────────────┐                                                    │
#   │  │ Find *.scope    │                                                    │
#   │  │ files           │                                                    │
#   │  └────────┬────────┘                                                    │
#   │           │                                                             │
#   │           ▼                                                             │
#   │  ┌─────────────────┐     No files      ┌─────────────────┐              │
#   │  │ Files found?    │─────────────────►│ Interactive     │              │
#   │  └────────┬────────┘                   │ Input Mode      │              │
#   │           │ Yes                        └─────────────────┘              │
#   │           ▼                                                             │
#   │  ┌─────────────────┐                                                    │
#   │  │ For each file:  │                                                    │
#   │  │  • Read lines   │                                                    │
#   │  │  • Parse KEY=VAL│                                                    │
#   │  │  • Skip comments│                                                    │
#   │  └────────┬────────┘                                                    │
#   │           │                                                             │
#   │           ▼                                                             │
#   │  ┌─────────────────┐     Invalid       ┌─────────────────┐              │
#   │  │ Validate all    │─────────────────►│ Log error,      │              │
#   │  │ required fields │                   │ skip file       │              │
#   │  └────────┬────────┘                   └─────────────────┘              │
#   │           │ Valid                                                       │
#   │           ▼                                                             │
#   │  ┌─────────────────┐                                                    │
#   │  │ Add to          │                                                    │
#   │  │ C_SCOPES array  │                                                    │
#   │  └─────────────────┘                                                    │
#   │                                                                         │
#   └─────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════════
#
#   Requires:
#     • 00_constants.sh (C_SCRIPT_DIR, C_SCOPES array)
#     • 01_output.sh    (panel functions, info, error, success, etc.)
#     • 02_validation.sh (validate_ip, validate_netmask, netmask_to_cidr)
#     • 03_interactive.sh (get_user_input_for_scope)
#
#######################################

#######################################
# parse_scope_files()
#######################################
#
# PURPOSE:
#   Discover and parse all .scope configuration files in the script directory.
#   If no scope files are found, fall back to interactive input mode.
#
# SCOPE FILE DISCOVERY:
#   Uses the 'find' command to locate all files matching *.scope pattern
#   in the C_SCRIPT_DIR directory (non-recursive).
#
# PARSING RULES:
#   • Lines starting with # are comments (ignored)
#   • Empty lines are ignored
#   • KEY=VALUE pairs are parsed and stored
#   • Whitespace around = is NOT allowed (KEY=VALUE, not KEY = VALUE)
#
# REQUIRED FIELDS:
#   All of these must be present in a valid scope file:
#     • INTERFACE
#     • NETWORK
#     • NETMASK
#     • POOL_START
#     • POOL_END
#     • HOST_ADDRESS
#     • GATEWAY
#     • DNS_PRIMARY
#
# OPTIONAL FIELDS:
#     • DNS_SECONDARY (defaults to 9.9.9.9 if not specified)
#
# USAGE:
#   parse_scope_files
#   # After this call, C_SCOPES array contains all valid scopes
#
# PARAMETERS:
#   None
#
# RETURNS:
#   0 : At least one scope was successfully configured
#   Exits with 1 if no valid scopes could be configured
#
# SIDE EFFECTS:
#   Populates the global C_SCOPES array with scope configuration strings
#
#######################################
parse_scope_files() {
    # ─────────────────────────────────────────────────────────────────────────
    # DISPLAY MODULE HEADER
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Provide visual feedback that we're entering the scope discovery phase.
    # This helps users understand what the script is doing.
    #
    panel_header "Scope Configuration Discovery"
    
    academic "Searching for DHCP scope configuration files..."
    academic "Scope files define network segments the DHCP server will manage"
    academic "Looking in: ${C_SCRIPT_DIR}"
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # INITIALIZE LOCAL VARIABLES
    # ─────────────────────────────────────────────────────────────────────────
    #
    # scope_files: Array to hold discovered .scope file paths
    # scope_count: Counter for successfully parsed scopes
    #
    local scope_files=()
    local scope_count=0
    
    # ─────────────────────────────────────────────────────────────────────────
    # DISCOVER SCOPE FILES
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Use 'find' to locate all .scope files in the script directory.
    #
    # Options explained:
    #   -maxdepth 1   : Don't recurse into subdirectories
    #   -name "*.scope" : Match files ending with .scope
    #   -print0       : Use null character as delimiter (handles spaces in names)
    #
    # The while loop reads null-delimited output safely.
    # read -r -d '' reads until null character.
    #
    progress "Scanning for .scope files..."
    
    while IFS= read -r -d '' file; do
        scope_files+=("$file")
        debug "Found scope file: $file"
    done < <(find "$C_SCRIPT_DIR" -maxdepth 1 -name "*.scope" -print0 2>/dev/null)
    
    # ─────────────────────────────────────────────────────────────────────────
    # CHECK IF ANY SCOPE FILES WERE FOUND
    # ─────────────────────────────────────────────────────────────────────────
    #
    # If the scope_files array is empty, no .scope files exist.
    # Fall back to interactive mode to collect scope configuration.
    #
    if [[ ${#scope_files[@]} -eq 0 ]]; then
        # ═════════════════════════════════════════════════════════════════════
        # INTERACTIVE INPUT MODE
        # ═════════════════════════════════════════════════════════════════════
        #
        # No scope files found - prompt user to enter configuration manually.
        # This provides a fallback for first-time setup or missing files.
        #
        warning "No .scope files found in: $C_SCRIPT_DIR"
        echo ""
        info "Entering interactive configuration mode..."
        academic "You will be prompted to enter DHCP scope details manually"
        academic "To use file-based configuration, create .scope files in the script directory"
        echo ""
        
        # ─────────────────────────────────────────────────────────────────────
        # ASK HOW MANY SCOPES TO CONFIGURE
        # ─────────────────────────────────────────────────────────────────────
        #
        # Multi-scope support: allow user to configure multiple subnets.
        # Each scope represents a different network segment.
        #
        local num_scopes
        
        while true; do
            read -rp "How many DHCP scopes do you want to configure? " num_scopes
            
            # Validate: must be a positive integer
            # Regex: ^[1-9][0-9]*$ matches 1, 2, 10, 100, etc. (not 0 or negative)
            if [[ "$num_scopes" =~ ^[1-9][0-9]*$ ]]; then
                info "Will configure $num_scopes scope(s)"
                break
            fi
            
            error "Please enter a valid number (1 or greater)"
        done
        
        # ─────────────────────────────────────────────────────────────────────
        # COLLECT SCOPE DATA INTERACTIVELY
        # ─────────────────────────────────────────────────────────────────────
        #
        # Call get_user_input_for_scope() for each scope.
        # The function returns a colon-separated configuration string.
        #
        for ((i=1; i<=num_scopes; i++)); do
            local scope_data
            
            # get_user_input_for_scope outputs the scope string to stdout
            # We capture it with command substitution
            scope_data=$(get_user_input_for_scope "$i")
            
            # Add to the global C_SCOPES array
            C_SCOPES+=("$scope_data")
            scope_count=$((scope_count + 1))
            
            success "Scope #$i configured successfully"
        done
        
        echo ""
        success "Collected $scope_count scope(s) via interactive input"
        
    else
        # ═════════════════════════════════════════════════════════════════════
        # FILE-BASED CONFIGURATION MODE
        # ═════════════════════════════════════════════════════════════════════
        #
        # Scope files were found - parse each one.
        #
        success "Found ${#scope_files[@]} scope file(s)"
        echo ""
        
        # ─────────────────────────────────────────────────────────────────────
        # PARSE EACH SCOPE FILE
        # ─────────────────────────────────────────────────────────────────────
        #
        # Iterate through discovered files and parse each one.
        # Invalid files are logged and skipped (don't stop the entire process).
        #
        for scope_file in "${scope_files[@]}"; do
            # Display which file we're processing
            info "Parsing: $(basename "$scope_file")"
            
            # ─────────────────────────────────────────────────────────────────
            # INITIALIZE PARSING VARIABLES
            # ─────────────────────────────────────────────────────────────────
            #
            # Reset all variables for each file to prevent carryover
            # from previous files if a field is missing.
            #
            local interface="" network="" netmask="" pool_start="" pool_end=""
            local host_address="" gateway="" dns_primary="" dns_secondary=""
            
            # ─────────────────────────────────────────────────────────────────
            # READ AND PARSE THE SCOPE FILE
            # ─────────────────────────────────────────────────────────────────
            #
            # Read file line by line using a while loop.
            # IFS='=' splits each line on the equals sign.
            #
            # Line processing:
            #   1. Skip lines starting with # (comments)
            #   2. Skip empty lines
            #   3. Parse KEY=VALUE pairs
            #
            while IFS='=' read -r key value; do
                # ─────────────────────────────────────────────────────────────
                # SKIP COMMENTS
                # ─────────────────────────────────────────────────────────────
                #
                # Lines starting with # (with optional leading whitespace)
                # are treated as comments and ignored.
                #
                # Regex: ^[[:space:]]*# matches "# comment" or "  # comment"
                #
                [[ "$key" =~ ^[[:space:]]*# ]] && continue
                
                # ─────────────────────────────────────────────────────────────
                # SKIP EMPTY LINES
                # ─────────────────────────────────────────────────────────────
                #
                # If key is empty, skip this line.
                # This handles blank lines in the file.
                #
                [[ -z "$key" ]] && continue
                
                # ─────────────────────────────────────────────────────────────
                # TRIM WHITESPACE
                # ─────────────────────────────────────────────────────────────
                #
                # Remove all spaces from key and value.
                # This makes parsing more forgiving of formatting variations.
                #
                # Note: This means "KEY = VALUE" won't work correctly.
                # We expect "KEY=VALUE" format.
                #
                key="${key// /}"
                value="${value// /}"
                
                # ─────────────────────────────────────────────────────────────
                # MAP KEY TO VARIABLE
                # ─────────────────────────────────────────────────────────────
                #
                # Use a case statement to map recognized keys to variables.
                # Unknown keys are silently ignored (allows for future extensions).
                #
                case "$key" in
                    INTERFACE)     interface="$value" ;;
                    NETWORK)       network="$value" ;;
                    NETMASK)       netmask="$value" ;;
                    POOL_START)    pool_start="$value" ;;
                    POOL_END)      pool_end="$value" ;;
                    HOST_ADDRESS)  host_address="$value" ;;
                    GATEWAY)       gateway="$value" ;;
                    DNS_PRIMARY)   dns_primary="$value" ;;
                    DNS_SECONDARY) dns_secondary="$value" ;;
                esac
                
            done < "$scope_file"
            
            # ─────────────────────────────────────────────────────────────────
            # VALIDATE REQUIRED FIELDS
            # ─────────────────────────────────────────────────────────────────
            #
            # Check that all required fields were provided.
            # Build a list of missing fields for the error message.
            #
            local valid=true
            local missing=()
            
            # Check each required field
            [[ -z "$interface" ]]    && missing+=("INTERFACE")    && valid=false
            [[ -z "$network" ]]      && missing+=("NETWORK")      && valid=false
            [[ -z "$netmask" ]]      && missing+=("NETMASK")      && valid=false
            [[ -z "$pool_start" ]]   && missing+=("POOL_START")   && valid=false
            [[ -z "$pool_end" ]]     && missing+=("POOL_END")     && valid=false
            [[ -z "$host_address" ]] && missing+=("HOST_ADDRESS") && valid=false
            [[ -z "$gateway" ]]      && missing+=("GATEWAY")      && valid=false
            [[ -z "$dns_primary" ]]  && missing+=("DNS_PRIMARY")  && valid=false
            
            # DNS_SECONDARY is optional - default to Quad9 if not specified
            [[ -z "$dns_secondary" ]] && dns_secondary="9.9.9.9"
            
            # If any required fields are missing, log error and skip this file
            if [[ "$valid" == "false" ]]; then
                error "Scope file $(basename "$scope_file") is missing required fields:"
                error "  Missing: ${missing[*]}"
                warning "Skipping this scope file"
                echo ""
                continue
            fi
            
            # ─────────────────────────────────────────────────────────────────
            # VALIDATE IP ADDRESSES
            # ─────────────────────────────────────────────────────────────────
            #
            # Use validate_ip() to check each IP address field.
            # Invalid IPs cause the file to be skipped.
            #
            local validation_failed=false
            
            if ! validate_ip "$network"; then
                error "Invalid NETWORK IP in $(basename "$scope_file"): $network"
                validation_failed=true
            fi
            
            if ! validate_netmask "$netmask"; then
                error "Invalid NETMASK in $(basename "$scope_file"): $netmask"
                validation_failed=true
            fi
            
            if ! validate_ip "$pool_start"; then
                error "Invalid POOL_START IP in $(basename "$scope_file"): $pool_start"
                validation_failed=true
            fi
            
            if ! validate_ip "$pool_end"; then
                error "Invalid POOL_END IP in $(basename "$scope_file"): $pool_end"
                validation_failed=true
            fi
            
            if ! validate_ip "$host_address"; then
                error "Invalid HOST_ADDRESS IP in $(basename "$scope_file"): $host_address"
                validation_failed=true
            fi
            
            if ! validate_ip "$gateway"; then
                error "Invalid GATEWAY IP in $(basename "$scope_file"): $gateway"
                validation_failed=true
            fi
            
            if ! validate_ip "$dns_primary"; then
                error "Invalid DNS_PRIMARY IP in $(basename "$scope_file"): $dns_primary"
                validation_failed=true
            fi
            
            if ! validate_ip "$dns_secondary"; then
                error "Invalid DNS_SECONDARY IP in $(basename "$scope_file"): $dns_secondary"
                validation_failed=true
            fi
            
            # Skip file if any validation failed
            if [[ "$validation_failed" == "true" ]]; then
                warning "Skipping this scope file due to validation errors"
                echo ""
                continue
            fi
            
            # ─────────────────────────────────────────────────────────────────
            # ADD VALID SCOPE TO ARRAY
            # ─────────────────────────────────────────────────────────────────
            #
            # All validations passed - construct the scope string and add
            # it to the global C_SCOPES array.
            #
            local scope_string="${interface}:${network}:${netmask}:${pool_start}:${pool_end}:${host_address}:${gateway}:${dns_primary}:${dns_secondary}"
            
            C_SCOPES+=("$scope_string")
            scope_count=$((scope_count + 1))
            
            # ─────────────────────────────────────────────────────────────────
            # DISPLAY PARSED CONFIGURATION
            # ─────────────────────────────────────────────────────────────────
            #
            # Show the user what was parsed from this file.
            # Helps verify the configuration is correct.
            #
            local cidr
            cidr=$(netmask_to_cidr "$netmask")
            
            success "Scope parsed successfully:"
            table_row "Interface" "$interface"
            table_row "Network" "$network/$cidr"
            table_row "Pool" "$pool_start - $pool_end"
            table_row "Server IP" "$host_address"
            table_row "Gateway" "$gateway"
            table_row "DNS" "$dns_primary, $dns_secondary"
            separator
            echo ""
            
        done  # End of scope_files loop
        
        success "Parsed $scope_count valid scope(s) from configuration files"
    fi
    
    # ─────────────────────────────────────────────────────────────────────────
    # FINAL VALIDATION: ENSURE AT LEAST ONE SCOPE EXISTS
    # ─────────────────────────────────────────────────────────────────────────
    #
    # The script cannot proceed without at least one valid scope.
    # If no scopes were configured, exit with an error.
    #
    if [[ ${#C_SCOPES[@]} -eq 0 ]]; then
        echo ""
        error "No valid scopes configured. Cannot continue."
        error ""
        error "To fix this issue, either:"
        error "  1. Create .scope files in: $C_SCRIPT_DIR"
        error "  2. Re-run the script and use interactive mode"
        error ""
        error "See the example .scope files for the required format."
        panel_footer
        exit 1
    fi
    
    # ─────────────────────────────────────────────────────────────────────────
    # DISPLAY FINAL SUMMARY
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Show a summary of all configured scopes.
    # This provides a final confirmation before proceeding.
    #
    echo ""
    academic "Scope Discovery Complete"
    academic "Total scopes configured: ${#C_SCOPES[@]}"
    echo ""
    
    # List all configured interfaces
    local all_interfaces=""
    for scope in "${C_SCOPES[@]}"; do
        IFS=':' read -r iface _ <<< "$scope"
        if [[ -n "$all_interfaces" ]]; then
            all_interfaces="${all_interfaces}, ${iface}"
        else
            all_interfaces="$iface"
        fi
    done
    
    info "Interfaces that will be configured: $all_interfaces"
    
    panel_footer
}


#######################################
# MODULE LOAD CONFIRMATION
#######################################
# Uncomment for debugging module loading:
# echo "Module loaded: 04_parser.sh (Scope File Parser)"
