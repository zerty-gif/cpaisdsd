# 📋 DHCP Server Setup and Configuration

> **Academic DHCP Configuration Course Module**  
> A comprehensive, educational Kea DHCP4 server deployment script with verbose documentation.

## 🎯 Purpose

This module provides an automated setup script for deploying a **Kea DHCP4 server** on Debian/Parrot OS systems. The script is designed as an **educational resource** for understanding DHCP concepts, with extensive RFC-referenced comments explaining every configuration decision.

## 🌐 Network Topology

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          NETWORK TOPOLOGY: 192.168.10.0/24                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    ┌──────────────────┐                                                     │
│    │   DHCP Server    │ ens33: 192.168.10.200/24                            │
│    │   (This Host)    │ ens32: DHCP (external connectivity)                 │
│    │   Kea DHCP4      │                                                     │
│    └────────┬─────────┘                                                     │
│             │                                                               │
│    ─────────┴──────────────────────────────────────────────────────         │
│             │              192.168.10.0/24 Network                          │
│             │                                                               │
│    ┌────────┴─────────────────────────────────────────────────────┐         │
│    │                                                              │         │
│    ▼                           ▼                        ▼         ▼         │
│ ┌──────────┐            ┌──────────┐            ┌──────────┐  ┌────────┐    │
│ │   ds1    │            │   ds3    │            │  Dynamic │  │ Router │    │
│ │ Reserved │            │ Reserved │            │   Pool   │  │        │    │
│ │ .100     │            │ .120     │            │ .30-.50  │  │ .254   │    │
│ └──────────┘            └──────────┘            └──────────┘  └────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 📦 Components

| File | Description |
|------|-------------|
| `dhcp_setup_script_.sh` | Main installation and configuration script |
| `README.md` | This documentation file |
| `TODO.md` | Task list and future enhancements |

## 🔧 Prerequisites

- **Operating System**: Debian-based (Debian 11+, Parrot OS, Ubuntu 22.04+)
- **Privileges**: Root access (run with `sudo`)
- **Network**: Interface `ens33` available for DHCP services
- **Packages**: Script will install required packages automatically

## 🚀 Quick Start

```bash
# Navigate to the configuration directory
cd /path/to/newconfig

# Make the script executable
chmod +x dhcp_setup_script_.sh

# Run with sudo privileges
sudo ./dhcp_setup_script_.sh
```

## 📖 DHCP Concepts Covered

The script includes educational comments explaining:

### 1. DHCP Lease Lifecycle (RFC 2131)
- Initial discovery (DORA: Discover, Offer, Request, Acknowledge)
- Lease timers: T1 (renew), T2 (rebind), valid-lifetime
- State transitions: INIT → SELECTING → REQUESTING → BOUND → RENEWING → REBINDING

### 2. DHCP Options (RFC 2132)
- Option 3: Default Gateway (Routers)
- Option 6: DNS Servers
- Option 15: Domain Name
- Option 51: Lease Time

### 3. Kea DHCP4 Architecture
- Control socket for runtime management
- Memfile lease database with LFC (Lease File Cleanup)
- Subnet4 configuration with pools and reservations
- Host reservations by MAC address (hw-address)

### 4. Network Interface Configuration
- Static IP assignment for server interface
- Proper gateway and DNS configuration
- Interface persistence across reboots

## 🔐 Security Considerations

- **DNS**: Uses Quad9 (9.9.9.9) as secondary DNS for malware blocking
- **Socket Permissions**: Kea control socket restricted to kea:kea user/group
- **Input Validation**: All configuration values validated before application
- **Backup Strategy**: Original configs backed up before modification

## 📊 Configuration Summary

| Parameter | Value | RFC Reference |
|-----------|-------|---------------|
| Subnet | 192.168.10.0/24 | RFC 950 |
| DHCP Pool | 192.168.10.30 - 192.168.10.50 | RFC 2131 |
| Valid Lifetime | 3200 seconds (~53 min) | RFC 2131 §4.4.1 |
| Renew Timer (T1) | 1800 seconds (50% of lease) | RFC 2131 §4.4.5 |
| Rebind Timer (T2) | 2700 seconds (~84% of lease) | RFC 2131 §4.4.5 |
| Default Gateway | 192.168.10.254 | RFC 2132 Option 3 |
| DNS Servers | 192.168.10.200, 9.9.9.9 | RFC 2132 Option 6 |

## 🖥️ Host Reservations

| Hostname | MAC Address | Reserved IP |
|----------|-------------|-------------|
| ds1 | 00:0c:29:14:cd:90 | 192.168.10.100 |
| ds3 | 00:0c:29:bd:6f:36 | 192.168.10.120 |

## 📚 References

- [RFC 2131 - DHCP Protocol](https://datatracker.ietf.org/doc/html/rfc2131)
- [RFC 2132 - DHCP Options](https://datatracker.ietf.org/doc/html/rfc2132)
- [Kea DHCP Documentation](https://kea.readthedocs.io/)
- [ISC Kea Administrator Reference Manual](https://kea.isc.org/docs/kea-guide.html)

## 📞 Contact

For questions about project standards: andcs@mailbox.org

---

*Last Updated: January 2026*
