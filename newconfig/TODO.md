# 📝 TODO: DHCP Setup Script Enhancements

> **Task tracking for dhcp_setup_script_.sh development**

## ✅ Completed

- [x] **P0**: Resolve merge conflict markers (`=======`) in original script
- [x] **P0**: Define missing `execute_sudo` function (consolidated to root-based execution)
- [x] **P0**: Remove duplicate configuration blocks (Kea JSON, interfaces)
- [x] **P1**: Add strict mode (`set -euo pipefail`)
- [x] **P1**: Add copyright header with SPDX license identifier
- [x] **P1**: Add Kea 2.6.x `"id"` field to subnet4 configuration
- [x] **P1**: Fix network config (static IP for DHCP server interface)
- [x] **P2**: Implement Rich-style terminal output (colors, panels, status functions)
- [x] **P2**: Add academic DHCP comments with RFC references
- [x] **P2**: Add verbose runtime logging with progress indicators
- [x] **P3**: Add ShellCheck compliance directives
- [x] **P3**: Create README.md documentation
- [x] **P3**: Create TODO.md task list

## 🔄 In Progress

- [ ] None currently

## 📋 Backlog

### High Priority (P1)

- [ ] Add configuration validation function (JSON syntax check for Kea config)
- [ ] Implement automatic rollback on failure (restore from `.bak` files)
- [ ] Add pre-flight checks (interface existence, package availability)
- [ ] Implement proper signal handling (trap for cleanup on CTRL+C)

### Medium Priority (P2)

- [ ] Add DDNS (Dynamic DNS) integration with BIND9
- [ ] Support multiple network interfaces (configurable via parameters)
- [ ] Add Kea statistics collection and reporting
- [ ] Implement lease monitoring dashboard output
- [ ] Add support for Kea HA (High Availability) configuration

### Low Priority (P3)

- [ ] Create companion systemd service file for health monitoring
- [ ] Add Prometheus metrics export capability
- [ ] Support IPv6 with Kea DHCP6
- [ ] Create Ansible playbook version for multi-host deployment
- [ ] Add interactive mode with whiptail/dialog menus

### Documentation (P3)

- [ ] Add Mermaid diagrams for DHCP state machine
- [ ] Create troubleshooting guide
- [ ] Document Kea control socket commands
- [ ] Add network packet capture examples (tcpdump/wireshark)

## 🐛 Known Issues

| Issue | Status | Notes |
|-------|--------|-------|
| Script requires ens33 interface | ⚠️ Hardcoded | Future: make configurable |
| No support for NetworkManager | ⚠️ Limitation | Uses ifupdown only |
| Kea version not checked | ⚠️ Risk | May fail on older Kea versions |

## 💡 Enhancement Ideas

1. **Configuration Templates**: Support multiple network profiles (lab, production, DMZ)
2. **Dry-Run Mode**: `--dry-run` flag to show what would be configured without applying
3. **Backup Management**: Rotate backups, keep last N configurations
4. **Integration Tests**: Automated testing with network namespaces
5. **Container Support**: Dockerfile for containerized DHCP server

## 📊 Progress Metrics

| Category | Total | Done | Remaining |
|----------|-------|------|-----------|
| Critical (P0) | 3 | 3 | 0 |
| High (P1) | 7 | 4 | 4 |
| Medium (P2) | 8 | 3 | 5 |
| Low (P3) | 9 | 3 | 6 |

---

*Last Updated: January 2026*
