#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                       IP VALIDATION FUNCTIONS MODULE                      ║
# ║                    Network Address Validation Utilities                   ║
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
#   This module provides validation functions for IPv4 network addresses.
#   All user-provided IP addresses should be validated before use to prevent:
#
#     • Configuration errors from malformed addresses
#     • Security issues from unexpected input
#     • Runtime failures in DHCP server configuration
#
#   FUNCTIONS PROVIDED:
#   ───────────────────
#     validate_ip()       - Validate IPv4 address format and range
#     validate_netmask()  - Validate subnet mask is valid
#     netmask_to_cidr()   - Convert dotted netmask to CIDR notation
#
#   VALIDATION APPROACH:
#   ────────────────────
#   We use a two-stage validation:
#     1. Regex pattern matching for format validation
#     2. Numeric range checking for value validation
#
#   This catches both format errors ("192.168.1" - missing octet)
#   and range errors ("192.168.256.1" - invalid octet value).
#
# ═══════════════════════════════════════════════════════════════════════════════
# IPv4 ADDRESS STRUCTURE (RFC 791)
# ═══════════════════════════════════════════════════════════════════════════════
#
#   An IPv4 address is a 32-bit number, typically written as four
#   decimal octets separated by periods (dotted-decimal notation).
#
#   STRUCTURE:
#   ┌─────────────────────────────────────────────────────────────────────────┐
#   │                          IPv4 Address                                   │
#   ├─────────────┬─────────────┬─────────────┬─────────────────────────────┤
#   │   Octet 1   │   Octet 2   │   Octet 3   │          Octet 4            │
#   │  (8 bits)   │  (8 bits)   │  (8 bits)   │          (8 bits)           │
#   ├─────────────┼─────────────┼─────────────┼─────────────────────────────┤
#   │   0-255     │    0-255    │    0-255    │           0-255             │
#   └─────────────┴─────────────┴─────────────┴─────────────────────────────┘
#
#   Example: 192.168.100.1
#     • Binary:  11000000.10101000.01100100.00000001
#     • Decimal: 192.168.100.1
#     • Integer: 3232261121
#
#   SPECIAL ADDRESSES:
#   ──────────────────
#     0.0.0.0         : "This host" or default route
#     255.255.255.255 : Limited broadcast
#     127.0.0.1       : Loopback (localhost)
#     x.x.x.0         : Network address (when x.x.x is network portion)
#     x.x.x.255       : Broadcast address (for /24 network)
#
# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════════
#
#   Requires: Bash 4.0+ (for regex matching with =~)
#   Optional: 01_output.sh (for debug output function)
#
#######################################

#######################################
# validate_ip()
#######################################
#
# PURPOSE:
#   Validate that a string is a properly formatted IPv4 address
#   with each octet in the valid range (0-255).
#
# ALGORITHM:
#   1. Check format using regex pattern matching
#   2. Split into octets and verify each is 0-255
#
# USAGE:
#   if validate_ip "192.168.100.1"; then
#       echo "Valid IP"
#   else
#       echo "Invalid IP"
#   fi
#
# PARAMETERS:
#   $1 : The IP address string to validate
#
# RETURNS:
#   0 : Valid IPv4 address
#   1 : Invalid IPv4 address
#
# EXAMPLES:
#   validate_ip "192.168.1.1"    → returns 0 (valid)
#   validate_ip "192.168.1.256"  → returns 1 (invalid: 256 > 255)
#   validate_ip "192.168.1"      → returns 1 (invalid: only 3 octets)
#   validate_ip "192.168.1.1.1"  → returns 1 (invalid: 5 octets)
#   validate_ip "192.168.a.1"    → returns 1 (invalid: non-numeric)
#   validate_ip ""               → returns 1 (invalid: empty)
#
# REGEX PATTERN EXPLANATION:
# ──────────────────────────
#   ^                     : Start of string
#   ([0-9]{1,3}\.){3}    : Three groups of 1-3 digits followed by dot
#   [0-9]{1,3}           : One group of 1-3 digits
#   $                     : End of string
#
#   This matches the FORMAT but not the RANGE.
#   We must also check that each octet is ≤ 255.
#
#######################################
validate_ip() {
    # Store the input IP address
    local ip="$1"
    
    # ─────────────────────────────────────────────────────────────────────────
    # STAGE 1: FORMAT VALIDATION (Regex)
    # ─────────────────────────────────────────────────────────────────────────
    #
    # This regex ensures the string has the correct structure:
    #   - Exactly 4 groups of digits
    #   - Groups separated by dots
    #   - Each group has 1-3 digits
    #
    # Note: This does NOT validate the numeric range (0-255)
    #       We do that in Stage 2.
    #
    local ip_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    # Bash regex matching using =~ operator
    # If the pattern doesn't match, return 1 (invalid)
    if [[ ! $ip =~ $ip_regex ]]; then
        return 1
    fi
    
    # ─────────────────────────────────────────────────────────────────────────
    # STAGE 2: RANGE VALIDATION (Each octet must be 0-255)
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Split the IP into octets using IFS (Internal Field Separator)
    # IFS='.' tells read to split on dots instead of whitespace
    #
    # The -r flag prevents backslash interpretation
    # The -a flag reads into an array
    #
    IFS='.' read -r -a octets <<< "$ip"
    
    # Iterate through each octet and validate range
    for octet in "${octets[@]}"; do
        # Check if octet exceeds maximum value (255)
        # Using arithmetic comparison with -gt
        if [[ $octet -gt 255 ]]; then
            return 1
        fi
    done
    
    # All checks passed - IP is valid
    return 0
}


#######################################
# validate_netmask()
#######################################
#
# PURPOSE:
#   Validate that a string is a valid IPv4 subnet mask.
#   Valid subnet masks must be contiguous 1s followed by contiguous 0s.
#
# SUBNET MASK BINARY STRUCTURE:
# ─────────────────────────────
#   Valid:   11111111.11111111.11111111.00000000 = 255.255.255.0
#   Valid:   11111111.11111111.11110000.00000000 = 255.255.240.0
#   Invalid: 11111111.11111111.10101010.00000000 = 255.255.170.0
#            (non-contiguous 1s are not valid in a subnet mask)
#
# APPROACH:
#   Rather than converting to binary and checking contiguity,
#   we use a lookup table of all valid subnet masks.
#   There are only 33 possible valid masks (0-32 bits), making
#   a lookup table more efficient and clearer than computation.
#
# USAGE:
#   if validate_netmask "255.255.255.0"; then
#       echo "Valid netmask"
#   fi
#
# PARAMETERS:
#   $1 : The subnet mask to validate
#
# RETURNS:
#   0 : Valid subnet mask
#   1 : Invalid subnet mask
#
# VALID SUBNET MASKS TABLE:
# ┌─────────────────────┬──────┬───────────────────────────────────────────────┐
# │ Dotted Decimal      │ CIDR │ Binary                                        │
# ├─────────────────────┼──────┼───────────────────────────────────────────────┤
# │ 255.255.255.255     │ /32  │ 11111111.11111111.11111111.11111111           │
# │ 255.255.255.254     │ /31  │ 11111111.11111111.11111111.11111110           │
# │ 255.255.255.252     │ /30  │ 11111111.11111111.11111111.11111100           │
# │ 255.255.255.248     │ /29  │ 11111111.11111111.11111111.11111000           │
# │ 255.255.255.240     │ /28  │ 11111111.11111111.11111111.11110000           │
# │ 255.255.255.224     │ /27  │ 11111111.11111111.11111111.11100000           │
# │ 255.255.255.192     │ /26  │ 11111111.11111111.11111111.11000000           │
# │ 255.255.255.128     │ /25  │ 11111111.11111111.11111111.10000000           │
# │ 255.255.255.0       │ /24  │ 11111111.11111111.11111111.00000000           │
# │ 255.255.254.0       │ /23  │ 11111111.11111111.11111110.00000000           │
# │ 255.255.252.0       │ /22  │ 11111111.11111111.11111100.00000000           │
# │ 255.255.248.0       │ /21  │ 11111111.11111111.11111000.00000000           │
# │ 255.255.240.0       │ /20  │ 11111111.11111111.11110000.00000000           │
# │ 255.255.224.0       │ /19  │ 11111111.11111111.11100000.00000000           │
# │ 255.255.192.0       │ /18  │ 11111111.11111111.11000000.00000000           │
# │ 255.255.128.0       │ /17  │ 11111111.11111111.10000000.00000000           │
# │ 255.255.0.0         │ /16  │ 11111111.11111111.00000000.00000000           │
# │ 255.254.0.0         │ /15  │ 11111111.11111110.00000000.00000000           │
# │ 255.252.0.0         │ /14  │ 11111111.11111100.00000000.00000000           │
# │ 255.248.0.0         │ /13  │ 11111111.11111000.00000000.00000000           │
# │ 255.240.0.0         │ /12  │ 11111111.11110000.00000000.00000000           │
# │ 255.224.0.0         │ /11  │ 11111111.11100000.00000000.00000000           │
# │ 255.192.0.0         │ /10  │ 11111111.11000000.00000000.00000000           │
# │ 255.128.0.0         │ /9   │ 11111111.10000000.00000000.00000000           │
# │ 255.0.0.0           │ /8   │ 11111111.00000000.00000000.00000000           │
# └─────────────────────┴──────┴───────────────────────────────────────────────┘
#
#######################################
validate_netmask() {
    local netmask="$1"
    
    # ─────────────────────────────────────────────────────────────────────────
    # LOOKUP TABLE OF VALID SUBNET MASKS
    # ─────────────────────────────────────────────────────────────────────────
    #
    # This array contains all valid subnet masks in dotted-decimal notation.
    # A subnet mask is valid if and only if its binary representation is
    # contiguous 1s followed by contiguous 0s.
    #
    # We include /25 through /32 (most common for host networks)
    # and /8 through /24 (common for larger networks)
    #
    local valid_netmasks=(
        # /32 to /25 (last octet varies)
        "255.255.255.255"   # /32 - Single host
        "255.255.255.254"   # /31 - Point-to-point link (RFC 3021)
        "255.255.255.252"   # /30 - 2 usable hosts
        "255.255.255.248"   # /29 - 6 usable hosts
        "255.255.255.240"   # /28 - 14 usable hosts
        "255.255.255.224"   # /27 - 30 usable hosts
        "255.255.255.192"   # /26 - 62 usable hosts
        "255.255.255.128"   # /25 - 126 usable hosts
        
        # /24 to /17 (third octet varies)
        "255.255.255.0"     # /24 - Class C (254 usable hosts) - MOST COMMON
        "255.255.254.0"     # /23 - 510 usable hosts
        "255.255.252.0"     # /22 - 1022 usable hosts
        "255.255.248.0"     # /21 - 2046 usable hosts
        "255.255.240.0"     # /20 - 4094 usable hosts
        "255.255.224.0"     # /19 - 8190 usable hosts
        "255.255.192.0"     # /18 - 16382 usable hosts
        "255.255.128.0"     # /17 - 32766 usable hosts
        
        # /16 to /9 (second octet varies)
        "255.255.0.0"       # /16 - Class B
        "255.254.0.0"       # /15
        "255.252.0.0"       # /14
        "255.248.0.0"       # /13
        "255.240.0.0"       # /12
        "255.224.0.0"       # /11
        "255.192.0.0"       # /10
        "255.128.0.0"       # /9
        
        # /8 (first octet varies)
        "255.0.0.0"         # /8 - Class A
    )
    
    # ─────────────────────────────────────────────────────────────────────────
    # LOOKUP: Check if input matches any valid mask
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Iterate through the array and compare each valid mask
    # to the input. If we find a match, return 0 (valid).
    #
    for valid in "${valid_netmasks[@]}"; do
        if [[ "$netmask" == "$valid" ]]; then
            return 0  # Found a match - valid netmask
        fi
    done
    
    # No match found - invalid netmask
    return 1
}


#######################################
# netmask_to_cidr()
#######################################
#
# PURPOSE:
#   Convert a dotted-decimal subnet mask to CIDR notation (prefix length).
#
# CIDR (CLASSLESS INTER-DOMAIN ROUTING):
# ──────────────────────────────────────
#   CIDR notation expresses the subnet mask as a single number
#   representing the count of network bits (1s in the binary mask).
#
#   Example:
#     255.255.255.0 (binary: 11111111.11111111.11111111.00000000)
#     Has 24 ones, so CIDR notation is /24
#
# ALGORITHM:
#   For each octet, count the 1-bits based on the octet value.
#   We use a lookup approach since there are only 9 possible
#   values in a valid subnet mask octet: 255, 254, 252, 248, 240, 224, 192, 128, 0
#
# USAGE:
#   cidr=$(netmask_to_cidr "255.255.255.0")
#   echo "CIDR: /$cidr"  # Output: CIDR: /24
#
# PARAMETERS:
#   $1 : The subnet mask in dotted-decimal notation
#
# OUTPUT:
#   Prints the CIDR prefix length (0-32) to stdout
#
# RETURNS:
#   0 (always succeeds - assumes valid input)
#
# EXAMPLES:
#   netmask_to_cidr "255.255.255.0"   → prints "24"
#   netmask_to_cidr "255.255.255.128" → prints "25"
#   netmask_to_cidr "255.255.0.0"     → prints "16"
#   netmask_to_cidr "255.0.0.0"       → prints "8"
#
# OCTET TO BITS MAPPING:
# ┌─────────┬──────────────┬───────┐
# │ Decimal │ Binary       │ Bits  │
# ├─────────┼──────────────┼───────┤
# │   255   │ 11111111     │   8   │
# │   254   │ 11111110     │   7   │
# │   252   │ 11111100     │   6   │
# │   248   │ 11111000     │   5   │
# │   240   │ 11110000     │   4   │
# │   224   │ 11100000     │   3   │
# │   192   │ 11000000     │   2   │
# │   128   │ 10000000     │   1   │
# │     0   │ 00000000     │   0   │
# └─────────┴──────────────┴───────┘
#
#######################################
netmask_to_cidr() {
    local netmask="$1"
    
    # Initialize the CIDR counter
    local cidr=0
    
    # ─────────────────────────────────────────────────────────────────────────
    # SPLIT NETMASK INTO OCTETS
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Use IFS='.' to split on dots
    # Read into array 'octets'
    #
    IFS='.' read -r -a octets <<< "$netmask"
    
    # ─────────────────────────────────────────────────────────────────────────
    # COUNT 1-BITS IN EACH OCTET
    # ─────────────────────────────────────────────────────────────────────────
    #
    # For each octet value, add the corresponding number of 1-bits
    # to the CIDR counter. We use a case statement for efficient lookup.
    #
    for octet in "${octets[@]}"; do
        case $octet in
            # Full octet (all 1s)
            255) cidr=$((cidr + 8)) ;;
            
            # Partial octets (some 1s)
            254) cidr=$((cidr + 7)) ;;
            252) cidr=$((cidr + 6)) ;;
            248) cidr=$((cidr + 5)) ;;
            240) cidr=$((cidr + 4)) ;;
            224) cidr=$((cidr + 3)) ;;
            192) cidr=$((cidr + 2)) ;;
            128) cidr=$((cidr + 1)) ;;
            
            # Empty octet (all 0s)
            0) ;;
            # Note: We don't add anything for 0
            
            # Any other value means invalid netmask
            # But we assume input is already validated
        esac
    done
    
    # Output the CIDR value
    echo "$cidr"
}


#######################################
# MODULE LOAD CONFIRMATION
#######################################
# Uncomment for debugging module loading:
# echo "Module loaded: 02_validation.sh (IP Validation Functions)"
