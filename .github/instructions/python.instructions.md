---
applyTo: "**/*.py"
---
# Python Code Instructions

## 🐍 Language Standards
- **Python 3.11+** required
- Follow **PEP 8** style guide
- Follow **PEP 257** docstring conventions
- Use **PEP 484/585** type hints

## 🏷️ C-Prefix Naming Convention

**Required C-prefix:**
- Classes: `CPascalCase` (e.g., `CDataProcessor`, `CUserManager`)
- Constants: `C_UPPER_SNAKE_CASE` (e.g., `C_MAX_RETRIES`, `C_API_VERSION`)
- Global variables: `c_snake_case` (e.g., `c_default_config`)
- Source files: `cmodule_name.py` (e.g., `cvalidator.py`)
- Packages: `cpackage_name/` (e.g., `ccore/`, `cutils/`)

**NO C-prefix:**
- Functions/methods: `snake_case` (e.g., `get_user_data`)
- Local variables: `snake_case` (e.g., `user_count`)
- Instance variables: `snake_case` (e.g., `self._source`)

## 🎨 Terminal Output (Rich Style)

For Python CLI tools, use Rich-inspired patterns:

```python
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.progress import Progress


def display_results(data: list) -> None:
    """Display results using Rich formatting."""
    console = Console()
    
    # Status messages
    console.print("[green]✅ Success[/green]")
    console.print("[red]❌ Error[/red]")
    console.print("[yellow]⚠️ Warning[/yellow]")
    
    # Tables
    table = Table(title="Results")
    table.add_column("Name")
    table.add_column("Status")
    for item in data:
        table.add_row(item["name"], item["status"])
    console.print(table)
    
    # Panels
    console.print(Panel("Content here", title="Title"))


def show_progress(items: list) -> None:
    """Display progress for long-running operations."""
    with Progress() as progress:
        task = progress.add_task("Processing...", total=len(items))
        for item in items:
            # process item...
            progress.advance(task)
```

## 📝 Documentation

### Module Docstring
```python
"""
Module description.

Author: ANDCS
License: See LICENSE.md
Contact: andcs@mailbox.org
"""
```

### Function Docstring (Google Style)
```python
def process_data(data: dict) -> dict:
    """
    Process incoming data.
    
    Args:
        data: Dictionary containing raw data
        
    Returns:
        Dictionary with processed data
        
    Raises:
        ValueError: If data is invalid
    """
```

## 🔐 Security

- Validate all input with pydantic
- Use parameterized queries (no f-strings in SQL)
- Hash passwords with bcrypt
- Load secrets from environment variables
- Encrypt sensitive data (GDPR compliance)

## 🧪 Testing

- Write pytest tests with 80%+ coverage
- Use fixtures for common setup
- Test edge cases and error paths
- Mock external dependencies
