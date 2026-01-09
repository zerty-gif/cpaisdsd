# GitHub Copilot Custom Instructions

Welcome Copilot! Here are the core practices and conventions for working in this repository.

## 📋 Project Overview

This is the **cpostinstallparrot** project - a post-installation automation toolkit for Parrot OS. The project follows:
- Linux Filesystem Hierarchy Standard (FHS)
- C-prefix naming conventions for custom code
- Security-first approach with CIS benchmark compliance
- GDPR/RGPD compliance requirements

## 🏗️ Project Structure

```
project-root/
├── bin/                    # 🔧 Executable scripts (symlinks to libexec/)
├── libexec/                # 🛠️ Program executables (not in PATH)
├── etc/                    # ⚙️ Configuration files
├── var/                    # 🗄️ Variable data files (logs, cache, tmp)
├── docs/                   # 📚 Documentation
├── tests/                  # 🧪 Test suite
└── .github/                # GitHub workflows and Copilot instructions
```

## 🐚 Shell Scripting Standards

### Terminal User Interface
For all shell work that requires user interface, use [Textual](https://github.com/Textualize/textual) and [Rich](https://github.com/Textualize/rich) style patterns:

- **Rich-style output**: Use colored, styled console output with clear formatting
- **Progress indicators**: Show progress bars for long-running operations  
- **Tables**: Display data in well-formatted tables
- **Panels**: Group related information in styled panels
- **Markdown rendering**: Support markdown in terminal where appropriate
- **Spinner animations**: Use spinners for async operations

### Shell Script Best Practices
- **POSIX-compliant** scripts in `.sh` files
- Use ShellCheck for linting (suppress SC2034 for intentional config constants)
- Include copyright headers in all scripts
- Validate bash syntax with `bash -n`

### Example Shell Output Style
```bash
# Use colors and symbols for status
echo "✅ [SUCCESS] Operation completed"
echo "❌ [ERROR] Operation failed"
echo "⚠️ [WARNING] Attention needed"
echo "📋 [INFO] Information message"
echo "🔄 [PROGRESS] Processing..."
```

## 🏷️ C-Prefix Naming Conventions

All custom classes, constants, and modules use C-prefix:

- **Classes**: `CPascalCase` (e.g., `CDataProcessor`)
- **Constants**: `C_UPPER_SNAKE_CASE` (e.g., `C_MAX_RETRIES`)
- **Global variables**: `c_snake_case` (e.g., `c_default_config`)
- **Source files**: `cmodule_name.py` (e.g., `cvalidator.py`)
- **Functions/methods**: `snake_case` (NO C-prefix)
- **Local variables**: `snake_case` (NO C-prefix)

## 🐍 Python Standards

- **Python 3.11+** required
- Follow **PEP 8** (style), **PEP 257** (docstrings), **PEP 484/585** (type hints)
- Use **pyproject.toml** for packaging (PEP 518/621)
- Apply OOP principles and design patterns

## 🔐 Security Requirements

- CIS Benchmarks compliance for containers
- GDPR/RGPD data protection by design
- Input validation on all user input
- No secrets in code - use environment variables
- Consider using secure DNS (e.g., Quad9: 9.9.9.9) for enhanced security
- Non-root execution in containers

## 🧪 Testing & Quality

- Unit tests with 80%+ coverage using pytest
- ShellCheck for shell scripts (severity: warning)
- Type checking with mypy (strict mode)
- Security scanning with bandit

## 📝 Documentation

- Include docstrings for all classes and functions
- Use Google/NumPy style docstrings
- Include Mermaid diagrams for architecture
- Keep CHANGELOG.md updated

## 📞 Contact

For questions about project standards: andcs@mailbox.org
