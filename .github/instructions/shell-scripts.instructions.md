---
applyTo: "**/*.sh,bin/*,libexec/*.sh,libexec/**/*.sh"
---
# Shell Scripting Instructions

> **Note**: This applies to all `.sh` files and scripts in `bin/` (which may not have extensions).

## 🐚 POSIX Compliance
- Write POSIX-compliant shell scripts
- Use `#!/usr/bin/env bash` or `#!/bin/sh` shebang
- Validate syntax with `bash -n` before committing

## 🎨 Terminal UI Style (Textual/Rich)

Follow [Textual](https://github.com/Textualize/textual) and [Rich](https://github.com/Textualize/rich) visual patterns for terminal output:

### Colors and Styles
```bash
# Color codes for consistent output
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[1;33m'
readonly C_BLUE='\033[0;34m'
readonly C_MAGENTA='\033[0;35m'
readonly C_CYAN='\033[0;36m'
readonly C_BOLD='\033[1m'
readonly C_RESET='\033[0m'
```

### Status Messages
```bash
# Rich-style status output
success() { echo -e "${C_GREEN}✅ [SUCCESS]${C_RESET} $*"; }
error()   { echo -e "${C_RED}❌ [ERROR]${C_RESET} $*" >&2; }
warning() { echo -e "${C_YELLOW}⚠️  [WARNING]${C_RESET} $*"; }
info()    { echo -e "${C_BLUE}📋 [INFO]${C_RESET} $*"; }
```

### Progress Indicators
```bash
# Spinner for async operations
spin() {
    local -r chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    while :; do
        for (( i=0; i<${#chars}; i++ )); do
            echo -ne "${C_CYAN}${chars:$i:1}${C_RESET} Processing...\r"
            sleep 0.1
        done
    done
}
```

### Panels and Boxes
```bash
# Panel-style headers (Rich-inspired box drawing)
panel_header() {
    local title="$1"
    local width=50
    local line
    line=$(printf '%*s' "$width" '' | tr ' ' '─')
    echo -e "${C_BOLD}╭${line}╮${C_RESET}"
    printf "${C_BOLD}│${C_RESET} %-*s ${C_BOLD}│${C_RESET}\n" $((width-2)) "$title"
    echo -e "${C_BOLD}╰${line}╯${C_RESET}"
}
```

### Tables
```bash
# Table-style output
table_row() {
    printf "${C_CYAN}│${C_RESET} %-20s ${C_CYAN}│${C_RESET} %-30s ${C_CYAN}│${C_RESET}\n" "$1" "$2"
}
```

## 🔍 ShellCheck Compliance

- Run ShellCheck with `--severity=warning`
- Use `# shellcheck disable=SC2034` for intentional config constants
- Fix all warnings except documented exceptions

## 📁 File Structure

- Executables in `bin/` (symlinks to `libexec/`)
- Implementation scripts in `libexec/`
- Use `readonly` for constants
- Include copyright header in all files

## 🔐 Security

- Validate and sanitize all input
- Use `set -euo pipefail` for strict mode
- Quote all variables: `"$var"` not `$var`
- Avoid eval and command injection vulnerabilities

## 📝 Documentation

- Include header comment with purpose and usage
- Document all functions with comments
- Add examples for complex operations
