#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                      POST-INSTALLATION NEXT STEPS                         ║
# ║           User Guidance for Service Activation and Testing                ║
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
#   This module displays helpful post-installation guidance for the user.
#   After the DHCP server is configured, there are still manual steps the
#   user may need to perform:
#
#   1. Install Kea packages (if not already installed)
#   2. Enable and start the systemd service
#   3. Configure firewall rules
#   4. Test the configuration with a DHCP client
#
#   PURPOSE:
#   ────────
#   This module ensures users don't finish the script wondering "what now?"
#   It provides clear, actionable next steps with exact commands to run.
#
# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════════
#
#   Requires:
#     • 00_constants.sh (C_SCOPES array)
#     • 01_output.sh    (panel functions, info, success, etc.)
#     • 02_validation.sh (netmask_to_cidr)
#
#######################################

#######################################
# display_next_steps()
#######################################
#
# PURPOSE:
#   Display comprehensive guidance for completing the DHCP server setup.
#   Shows commands for installation, service management, firewall, and testing.
#
# USAGE:
#   display_next_steps
#
# PARAMETERS:
#   None (reads from global C_SCOPES array)
#
#######################################
display_next_steps() {
    # ─────────────────────────────────────────────────────────────────────────
    # DISPLAY MODULE HEADER
    # ─────────────────────────────────────────────────────────────────────────
    #
    panel_header "Next Steps"
    
    academic "Configuration is complete! Here's what to do next:"
    echo ""
    
    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 1: INSTALL KEA DHCP SERVER
    # ═══════════════════════════════════════════════════════════════════════════
    #
    info "📦 Step 1: Install Kea DHCP Server (if not installed)"
    separator
    
    # Check if Kea is already installed
    if command -v kea-dhcp4 &> /dev/null; then
        success "Kea DHCP4 is already installed"
    else
        echo ""
        academic "Install Kea DHCP4 server package:"
        echo ""
        echo "    sudo apt update"
        echo "    sudo apt install isc-kea-dhcp4-server"
        echo ""
    fi
    echo ""
    
    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 2: START AND ENABLE THE SERVICE
    # ═══════════════════════════════════════════════════════════════════════════
    #
    info "🚀 Step 2: Start and Enable the DHCP Service"
    separator
    echo ""
    
    academic "Enable the service to start at boot:"
    echo ""
    echo "    sudo systemctl enable kea-dhcp4-server"
    echo ""
    
    academic "Start the service now:"
    echo ""
    echo "    sudo systemctl start kea-dhcp4-server"
    echo ""
    
    academic "Check service status:"
    echo ""
    echo "    sudo systemctl status kea-dhcp4-server"
    echo ""
    
    academic "View live logs:"
    echo ""
    echo "    sudo journalctl -u kea-dhcp4-server -f"
    echo ""
    echo ""
    
    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 3: CONFIGURE FIREWALL
    # ═══════════════════════════════════════════════════════════════════════════
    #
    info "🔥 Step 3: Configure Firewall (if enabled)"
    separator
    echo ""
    
    academic "DHCP uses UDP ports 67 (server) and 68 (client)"
    echo ""
    
    academic "For UFW (Uncomplicated Firewall):"
    echo ""
    echo "    sudo ufw allow 67/udp comment 'DHCP Server'"
    echo ""
    
    academic "For iptables:"
    echo ""
    echo "    sudo iptables -A INPUT -p udp --dport 67 -j ACCEPT"
    echo "    sudo iptables-save | sudo tee /etc/iptables/rules.v4"
    echo ""
    
    academic "For firewalld:"
    echo ""
    echo "    sudo firewall-cmd --permanent --add-service=dhcp"
    echo "    sudo firewall-cmd --reload"
    echo ""
    echo ""
    
    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 4: TEST THE CONFIGURATION
    # ═══════════════════════════════════════════════════════════════════════════
    #
    info "🧪 Step 4: Test the DHCP Server"
    separator
    echo ""
    
    academic "Option A: Test with dhclient (from another machine on the network)"
    echo ""
    echo "    sudo dhclient -v <interface>"
    echo ""
    
    academic "Option B: Test with dhcpcd"
    echo ""
    echo "    sudo dhcpcd -T <interface>"
    echo ""
    
    academic "Option C: Use dhtest (a DHCP testing tool)"
    echo ""
    echo "    sudo apt install dhtest"
    echo "    sudo dhtest -i <interface> -m 00:11:22:33:44:55"
    echo ""
    echo ""
    
    # ═══════════════════════════════════════════════════════════════════════════
    # CONFIGURED SCOPES SUMMARY
    # ═══════════════════════════════════════════════════════════════════════════
    #
    info "📋 Configured Scopes Summary"
    separator
    echo ""
    
    local scope_num=1
    for scope in "${C_SCOPES[@]}"; do
        local interface network netmask pool_start pool_end host_address gateway dns_primary dns_secondary
        IFS=':' read -r interface network netmask pool_start pool_end host_address gateway dns_primary dns_secondary <<< "$scope"
        
        local cidr
        cidr=$(netmask_to_cidr "$netmask")
        
        echo "    ┌──────────────────────────────────────────────────────────────┐"
        echo "    │ Scope $scope_num: $network/$cidr"
        echo "    ├──────────────────────────────────────────────────────────────┤"
        echo "    │ Interface:     $interface"
        echo "    │ Server IP:     $host_address"
        echo "    │ Pool Range:    $pool_start - $pool_end"
        echo "    │ Gateway:       $gateway"
        echo "    │ DNS:           $dns_primary, $dns_secondary"
        echo "    └──────────────────────────────────────────────────────────────┘"
        echo ""
        
        scope_num=$((scope_num + 1))
    done
    
    # ═══════════════════════════════════════════════════════════════════════════
    # IMPORTANT FILES
    # ═══════════════════════════════════════════════════════════════════════════
    #
    info "📁 Important Files"
    separator
    echo ""
    
    table_row "Configuration" "/etc/kea/kea-dhcp4.conf"
    table_row "Leases" "/var/lib/kea/dhcp4.leases"
    table_row "Logs" "/var/log/kea/kea-dhcp4.log"
    echo ""
    
    # ═══════════════════════════════════════════════════════════════════════════
    # TROUBLESHOOTING TIPS
    # ═══════════════════════════════════════════════════════════════════════════
    #
    info "🔧 Troubleshooting Tips"
    separator
    echo ""
    
    academic "If the service fails to start:"
    echo "    1. Check configuration syntax: kea-dhcp4 -t /etc/kea/kea-dhcp4.conf"
    echo "    2. Check logs: journalctl -u kea-dhcp4-server"
    echo "    3. Verify interfaces exist: ip addr show"
    echo ""
    
    academic "If clients don't receive IP addresses:"
    echo "    1. Verify network connectivity between server and client"
    echo "    2. Check firewall rules: sudo iptables -L -n"
    echo "    3. Ensure no other DHCP server is on the network"
    echo "    4. Check lease file: cat /var/lib/kea/dhcp4.leases"
    echo ""
    
    academic "Monitoring active leases:"
    echo "    cat /var/lib/kea/dhcp4.leases | grep -E '^lease|^  hardware|^  client-hostname'"
    echo ""
    
    # ═══════════════════════════════════════════════════════════════════════════
    # FINAL MESSAGE
    # ═══════════════════════════════════════════════════════════════════════════
    #
    echo ""
    success "════════════════════════════════════════════════════════════════════"
    success "   DHCP Server Configuration Complete!"
    success "════════════════════════════════════════════════════════════════════"
    echo ""
    info "For questions or issues, contact: andcs@mailbox.org"
    info "Documentation: https://kea.readthedocs.io/"
    echo ""
    
    panel_footer
}


#######################################
# MODULE LOAD CONFIRMATION
#######################################
# Uncomment for debugging module loading:
# echo "Module loaded: 08_next_steps.sh (Post-Installation Guidance)"
