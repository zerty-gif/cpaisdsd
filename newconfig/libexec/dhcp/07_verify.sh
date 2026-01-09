#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                    CONFIGURATION VERIFICATION MODULE                      ║
# ║             Comprehensive System and Service Validation                   ║
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
#   This module performs comprehensive verification of the DHCP server
#   configuration and the system state. It validates that all components
#   are properly configured and ready for operation.
#
#   VERIFICATION PHILOSOPHY:
#   ────────────────────────
#   "Trust, but verify" - This module checks:
#
#     1. Network interfaces are properly configured
#     2. Kea DHCP4 configuration file exists and is valid
#     3. Required services are installed
#     4. Port 67/UDP is available (DHCP server port)
#
#   VERIFICATION CATEGORIES:
#   ────────────────────────
#   ┌─────────────────────────────────────────────────────────────────────────┐
#   │ Category        │ What We Check                                        │
#   ├─────────────────┼──────────────────────────────────────────────────────┤
#   │ Network         │ Interface status, IP addresses, link state           │
#   │ Configuration   │ Kea config file exists, valid JSON syntax            │
#   │ Services        │ Kea packages installed, systemd unit exists          │
#   │ Ports           │ UDP port 67 not already in use                       │
#   └─────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# DHCP PORT REFERENCE
# ═══════════════════════════════════════════════════════════════════════════════
#
#   DHCP uses two UDP ports:
#
#   Port 67 (bootps) - DHCP Server:
#     The server listens on this port for client requests.
#     Only one process can bind to this port at a time.
#
#   Port 68 (bootpc) - DHCP Client:
#     Clients listen on this port for server responses.
#     Not relevant for server configuration.
#
# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════════
#
#   Requires:
#     • 00_constants.sh (C_SCOPES array)
#     • 01_output.sh    (panel functions, info, error, success, etc.)
#     • 02_validation.sh (netmask_to_cidr)
#
#######################################

#######################################
# verify_configuration()
#######################################
#
# PURPOSE:
#   Perform comprehensive verification of the DHCP server setup.
#   Checks network, configuration, and service readiness.
#
# VERIFICATION FLOW:
#   ┌─────────────────────────────────────────────────────────────────────────┐
#   │                     VERIFICATION SEQUENCE                               │
#   ├─────────────────────────────────────────────────────────────────────────┤
#   │                                                                         │
#   │  ┌─────────────────┐                                                    │
#   │  │ Check network   │──► Verify all scope interfaces are configured     │
#   │  │ interfaces      │    with correct IP addresses and UP state         │
#   │  └────────┬────────┘                                                    │
#   │           │                                                             │
#   │           ▼                                                             │
#   │  ┌─────────────────┐                                                    │
#   │  │ Check config    │──► Verify /etc/kea/kea-dhcp4.conf exists          │
#   │  │ file            │    and has valid JSON syntax                       │
#   │  └────────┬────────┘                                                    │
#   │           │                                                             │
#   │           ▼                                                             │
#   │  ┌─────────────────┐                                                    │
#   │  │ Check Kea       │──► Verify kea-dhcp4 binary is available           │
#   │  │ installation    │    and systemd unit exists                         │
#   │  └────────┬────────┘                                                    │
#   │           │                                                             │
#   │           ▼                                                             │
#   │  ┌─────────────────┐                                                    │
#   │  │ Check ports     │──► Verify UDP port 67 is available                │
#   │  └────────┬────────┘                                                    │
#   │           │                                                             │
#   │           ▼                                                             │
#   │  ┌─────────────────┐                                                    │
#   │  │ Generate        │──► Compile pass/fail summary                       │
#   │  │ report          │                                                    │
#   │  └─────────────────┘                                                    │
#   │                                                                         │
#   └─────────────────────────────────────────────────────────────────────────┘
#
# USAGE:
#   verify_configuration
#
# RETURNS:
#   0 : All verifications passed
#   1 : One or more verifications failed (warnings shown)
#
#######################################
verify_configuration() {
    # ─────────────────────────────────────────────────────────────────────────
    # DISPLAY MODULE HEADER
    # ─────────────────────────────────────────────────────────────────────────
    #
    panel_header "Configuration Verification"
    
    academic "Performing comprehensive system verification"
    academic "This ensures all components are ready for DHCP service"
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # INITIALIZE COUNTERS
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Track pass/fail counts for final summary.
    #
    local pass_count=0
    local fail_count=0
    local warn_count=0
    
    # ═══════════════════════════════════════════════════════════════════════════
    # SECTION 1: NETWORK INTERFACE VERIFICATION
    # ═══════════════════════════════════════════════════════════════════════════
    #
    # Check each configured interface:
    #   • Interface exists
    #   • Interface is UP
    #   • Correct IP address is assigned
    #
    info "Checking network interfaces..."
    separator
    
    # Track verified interfaces to avoid duplicates
    declare -A verified_interfaces
    
    for scope in "${C_SCOPES[@]}"; do
        # Parse scope string
        local interface network netmask pool_start pool_end host_address gateway dns_primary dns_secondary
        IFS=':' read -r interface network netmask pool_start pool_end host_address gateway dns_primary dns_secondary <<< "$scope"
        
        # Skip if already verified
        if [[ -v verified_interfaces[$interface] ]]; then
            continue
        fi
        verified_interfaces["$interface"]=1
        
        # ─────────────────────────────────────────────────────────────────────
        # CHECK INTERFACE EXISTS
        # ─────────────────────────────────────────────────────────────────────
        #
        if ! ip link show "$interface" &> /dev/null; then
            table_row "$interface" "❌ Interface not found"
            fail_count=$((fail_count + 1))
            continue
        fi
        
        # ─────────────────────────────────────────────────────────────────────
        # CHECK INTERFACE STATE
        # ─────────────────────────────────────────────────────────────────────
        #
        local link_state
        link_state=$(ip -br link show "$interface" | awk '{print $2}')
        
        if [[ ! "$link_state" =~ UP ]]; then
            table_row "$interface" "⚠️ Link state: $link_state"
            warn_count=$((warn_count + 1))
            continue
        fi
        
        # ─────────────────────────────────────────────────────────────────────
        # CHECK IP ADDRESS
        # ─────────────────────────────────────────────────────────────────────
        #
        local current_ip
        current_ip=$(ip -4 addr show dev "$interface" 2>/dev/null | grep -oP 'inet \K[\d.]+(?=/)')
        
        if [[ "$current_ip" == "$host_address" ]]; then
            table_row "$interface" "✅ ${host_address} (UP)"
            pass_count=$((pass_count + 1))
        else
            table_row "$interface" "⚠️ IP mismatch: expected $host_address, got ${current_ip:-none}"
            warn_count=$((warn_count + 1))
        fi
    done
    
    echo ""
    
    # ═══════════════════════════════════════════════════════════════════════════
    # SECTION 2: CONFIGURATION FILE VERIFICATION
    # ═══════════════════════════════════════════════════════════════════════════
    #
    # Check Kea configuration file:
    #   • File exists
    #   • File is not empty
    #   • JSON syntax is valid (if jq or kea-dhcp4 available)
    #
    info "Checking configuration files..."
    separator
    
    local kea_config="/etc/kea/kea-dhcp4.conf"
    
    # ─────────────────────────────────────────────────────────────────────────
    # CHECK CONFIG FILE EXISTS
    # ─────────────────────────────────────────────────────────────────────────
    #
    if [[ -f "$kea_config" ]]; then
        table_row "Config file" "✅ $kea_config exists"
        pass_count=$((pass_count + 1))
        
        # ─────────────────────────────────────────────────────────────────────
        # CHECK FILE IS NOT EMPTY
        # ─────────────────────────────────────────────────────────────────────
        #
        if [[ -s "$kea_config" ]]; then
            local file_size
            file_size=$(stat -c%s "$kea_config" 2>/dev/null || stat -f%z "$kea_config" 2>/dev/null)
            table_row "Config size" "✅ $file_size bytes"
            pass_count=$((pass_count + 1))
        else
            table_row "Config size" "❌ File is empty"
            fail_count=$((fail_count + 1))
        fi
        
        # ─────────────────────────────────────────────────────────────────────
        # VALIDATE JSON SYNTAX
        # ─────────────────────────────────────────────────────────────────────
        #
        # Kea config uses JSON-like format with C++ style comments.
        # We can try kea-dhcp4 -t for validation, or skip if not available.
        #
        if command -v kea-dhcp4 &> /dev/null; then
            if kea-dhcp4 -t "$kea_config" &> /dev/null; then
                table_row "Config syntax" "✅ Valid (kea-dhcp4 -t)"
                pass_count=$((pass_count + 1))
            else
                table_row "Config syntax" "❌ Invalid syntax"
                fail_count=$((fail_count + 1))
            fi
        else
            table_row "Config syntax" "⚠️ Cannot validate (kea-dhcp4 not installed)"
            warn_count=$((warn_count + 1))
        fi
    else
        table_row "Config file" "❌ $kea_config not found"
        fail_count=$((fail_count + 1))
    fi
    
    echo ""
    
    # ═══════════════════════════════════════════════════════════════════════════
    # SECTION 3: SERVICE INSTALLATION VERIFICATION
    # ═══════════════════════════════════════════════════════════════════════════
    #
    # Check if Kea DHCP4 is properly installed:
    #   • kea-dhcp4 binary exists
    #   • systemd service unit exists
    #
    info "Checking service installation..."
    separator
    
    # ─────────────────────────────────────────────────────────────────────────
    # CHECK KEA-DHCP4 BINARY
    # ─────────────────────────────────────────────────────────────────────────
    #
    if command -v kea-dhcp4 &> /dev/null; then
        local kea_version
        kea_version=$(kea-dhcp4 -V 2>&1 | head -1)
        table_row "kea-dhcp4" "✅ Installed"
        table_row "Version" "$kea_version"
        pass_count=$((pass_count + 1))
    else
        table_row "kea-dhcp4" "❌ Not installed"
        fail_count=$((fail_count + 1))
    fi
    
    # ─────────────────────────────────────────────────────────────────────────
    # CHECK SYSTEMD SERVICE UNIT
    # ─────────────────────────────────────────────────────────────────────────
    #
    # The service unit file enables systemd to manage the DHCP server.
    # Different distributions may use different unit names.
    #
    local service_names=("kea-dhcp4-server" "kea-dhcp4" "isc-kea-dhcp4-server")
    local service_found=false
    
    for service in "${service_names[@]}"; do
        if systemctl list-unit-files 2>/dev/null | grep -q "^${service}"; then
            table_row "Systemd unit" "✅ $service"
            pass_count=$((pass_count + 1))
            service_found=true
            break
        fi
    done
    
    if [[ "$service_found" == "false" ]]; then
        table_row "Systemd unit" "⚠️ Service unit not found"
        warn_count=$((warn_count + 1))
    fi
    
    echo ""
    
    # ═══════════════════════════════════════════════════════════════════════════
    # SECTION 4: PORT AVAILABILITY VERIFICATION
    # ═══════════════════════════════════════════════════════════════════════════
    #
    # Check if UDP port 67 (DHCP server port) is available.
    # Only one DHCP server can bind to this port.
    #
    info "Checking port availability..."
    separator
    
    # ─────────────────────────────────────────────────────────────────────────
    # CHECK UDP PORT 67
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Use 'ss' (modern replacement for netstat) to check if port 67 is in use.
    #
    # ss -uln : UDP, listening, numeric ports
    # grep ':67 ' : Match port 67 (with space to avoid matching 670, etc.)
    #
    if command -v ss &> /dev/null; then
        if ss -uln 2>/dev/null | grep -q ':67 '; then
            # Port is in use - identify the process
            local port_user
            port_user=$(ss -ulnp 2>/dev/null | grep ':67 ' | grep -oP 'users:\(\("\K[^"]+')
            table_row "Port 67/UDP" "⚠️ In use by: ${port_user:-unknown}"
            warn_count=$((warn_count + 1))
        else
            table_row "Port 67/UDP" "✅ Available"
            pass_count=$((pass_count + 1))
        fi
    else
        table_row "Port 67/UDP" "⚠️ Cannot check (ss command not found)"
        warn_count=$((warn_count + 1))
    fi
    
    echo ""
    
    # ═══════════════════════════════════════════════════════════════════════════
    # SECTION 5: SCOPE SUMMARY
    # ═══════════════════════════════════════════════════════════════════════════
    #
    # Display a summary of all configured scopes.
    #
    info "Configured scopes summary..."
    separator
    
    local scope_num=1
    for scope in "${C_SCOPES[@]}"; do
        local interface network netmask pool_start pool_end host_address gateway dns_primary dns_secondary
        IFS=':' read -r interface network netmask pool_start pool_end host_address gateway dns_primary dns_secondary <<< "$scope"
        
        local cidr
        cidr=$(netmask_to_cidr "$netmask")
        
        table_row "Scope $scope_num" "$network/$cidr on $interface"
        table_row "  Pool" "$pool_start - $pool_end"
        table_row "  Server" "$host_address"
        separator
        
        scope_num=$((scope_num + 1))
    done
    
    echo ""
    
    # ═══════════════════════════════════════════════════════════════════════════
    # FINAL SUMMARY
    # ═══════════════════════════════════════════════════════════════════════════
    #
    # Display overall verification results.
    #
    info "Verification Results:"
    echo ""
    table_row "Passed" "✅ $pass_count"
    table_row "Warnings" "⚠️ $warn_count"
    table_row "Failed" "❌ $fail_count"
    echo ""
    
    # ─────────────────────────────────────────────────────────────────────────
    # DETERMINE OVERALL STATUS
    # ─────────────────────────────────────────────────────────────────────────
    #
    if [[ $fail_count -eq 0 && $warn_count -eq 0 ]]; then
        success "All verifications passed! System is ready."
    elif [[ $fail_count -eq 0 ]]; then
        warning "Verification completed with warnings."
        warning "Review warnings above and address if necessary."
    else
        error "Verification completed with failures."
        error "Critical issues must be resolved before starting the DHCP server."
    fi
    
    panel_footer
    
    # Return appropriate exit code
    if [[ $fail_count -gt 0 ]]; then
        return 1
    fi
    
    return 0
}


#######################################
# MODULE LOAD CONFIRMATION
#######################################
# Uncomment for debugging module loading:
# echo "Module loaded: 07_verify.sh (Configuration Verification)"
