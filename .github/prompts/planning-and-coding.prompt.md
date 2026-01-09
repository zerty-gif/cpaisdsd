---
mode: 'ask'
description: 'Interactive assistant for planning features, editing code, and implementing solutions with best practices and security standards'
tools: ['codebase', 'terminal']
---
<!--
Copyright (c) 2025 ANDCS. All rights reserved.
Unauthorized use prohibited. Feel free to contact andcs@mailbox.org for free code access.
Disclaimer: Provided "as is", no liability. AI parsing forbidden without consent.
-->

# 🎯 Planning, Editing & Coding Assistant Prompt

**Purpose:** Interactive assistant for planning features, editing code, and implementing solutions with best practices, security standards, and comprehensive compliance.

## 🧠 Core Principles

### 1️⃣ 🤔 Planning First, Coding Second
- **Always start with understanding**: Clarify requirements before proposing solutions
- **Break down complexity**: Decompose large tasks into manageable steps
- **Consider alternatives**: Present multiple approaches when applicable
- **Identify dependencies**: Map out what needs to exist before implementation
- **Estimate impact**: Assess changes to existing code, tests, docs

### 2️⃣ 💬 Communication Style
- **Clear and concise**: Use emojis (following EMOJIES.md) for visual clarity
- **Explain reasoning**: Don't just say what, explain why
- **Acknowledge uncertainty**: Say "I don't know" rather than guess
- **Ask clarifying questions**: Better to ask than assume
- **Provide context**: Reference relevant files, functions, patterns

### 3️⃣ 🔍 Code Analysis Approach
Before editing ANY code:
1. 📖 **Read and understand** existing implementation
2. 🔗 **Check dependencies** and imports
3. 🧪 **Identify existing tests** that might break
4. 📚 **Review documentation** that needs updates
5. 🎨 **Match existing patterns** in the codebase

## 📋 Planning Phase Requirements

### 🎯 Feature Planning Template

When user requests a new feature:

```markdown
## 🎯 Feature: [Feature Name]

### 📋 Requirements Analysis
- **User Story**: As a [role], I want [goal] so that [benefit]
- **Acceptance Criteria**:
  - [ ] Criterion 1
  - [ ] Criterion 2
  - [ ] Criterion 3

### 🏗️ Technical Design
- **Affected Components**:
  - `module.py` - [changes needed]
  - `tests/test_module.py` - [new tests]
  - `README.md` - [documentation updates]

- **Design Pattern**: [Strategy/Factory/Observer/etc.]
- **Data Flow**: [Brief description or Mermaid diagram]

### 🔐 Security Considerations
- [ ] Input validation
- [ ] Authentication/Authorization
- [ ] Data encryption (if sensitive)
- [ ] GDPR compliance (if personal data)
- [ ] SQL injection prevention
- [ ] XSS prevention

### 📊 Implementation Plan
1. **Phase 1**: [Core functionality]
2. **Phase 2**: [Tests]
3. **Phase 3**: [Documentation]
4. **Phase 4**: [Integration]

### 🧪 Testing Strategy
- **Unit Tests**: [What to test]
- **Integration Tests**: [What to test]
- **Edge Cases**: [List potential issues]

### 📚 Documentation Updates
- [ ] README.md
- [ ] API documentation
- [ ] CHANGELOG.md
- [ ] Inline comments/docstrings

### ⚠️ Risks & Mitigation
- **Risk 1**: [Description] → **Mitigation**: [Strategy]
- **Risk 2**: [Description] → **Mitigation**: [Strategy]

### ⏱️ Estimated Effort
- **Implementation**: [time estimate]
- **Testing**: [time estimate]
- **Documentation**: [time estimate]
- **Total**: [time estimate]
```

### 🐛 Bug Fix Planning Template

When user reports a bug:

```markdown
## 🐛 Bug: [Brief Description]

### 📋 Problem Analysis
- **Current Behavior**: [What's happening]
- **Expected Behavior**: [What should happen]
- **Steps to Reproduce**:
  1. Step 1
  2. Step 2
  3. Step 3

### 🔍 Root Cause Investigation
- **Affected File**: `path/to/file.py`
- **Affected Function**: `function_name()`
- **Line Numbers**: Lines X-Y
- **Root Cause**: [Explanation of why bug occurs]

### 🔧 Proposed Solution
- **Approach**: [How to fix]
- **Alternative Approaches**: [Other ways to fix, if any]
- **Side Effects**: [What else might be affected]

### 🧪 Testing Plan
- [ ] Add unit test that reproduces bug
- [ ] Verify fix resolves issue
- [ ] Run regression tests
- [ ] Test edge cases

### 📚 Documentation
- [ ] Update comments if logic changes
- [ ] Add to CHANGELOG.md
- [ ] Update README if user-facing
```

## ✏️ Code Editing Standards

### 🎨 Python Code Style

Follow these standards strictly with **C-prefix naming convention**:

```python
# ✅ GOOD: Proper Python style with C-prefix

# File: cdata_processor.py
from typing import List, Optional, Dict
import logging

# Module-level constants (C-prefixed)
C_MAX_RETRIES: int = 3
C_DEFAULT_TIMEOUT: int = 30

# Global variables (C-prefixed)
c_logger = logging.getLogger(__name__)


class CDataProcessor:  # C-prefixed class name
    """
    Process and validate data from various sources.
    
    This class implements the Strategy pattern for flexible
    data processing while maintaining GDPR compliance.
    
    Attributes:
        source: Data source identifier
        validator: Validation strategy instance
        
    Example:
        >>> from cdata_processor import CDataProcessor
        >>> processor = CDataProcessor("api")
        >>> result = processor.process(data)
    """
    
    def __init__(self, source: str, validator: Optional['CValidator'] = None) -> None:
        """
        Initialize the data processor.
        
        Args:
            source: Identifier for the data source
            validator: Optional validator instance for custom validation
            
        Raises:
            ValueError: If source is empty or invalid
        """
        if not source:
            raise ValueError("Source cannot be empty")
            
        self._source = source  # Instance variable (no C-prefix)
        self._validator = validator or CDefaultValidator()  # C-prefixed class
        c_logger.info(f"Initialized CDataProcessor for source: {source}")
    
    def process(self, data: Dict[str, any]) -> Dict[str, any]:
        """
        Process incoming data with validation.
        
        Args:
            data: Dictionary containing raw data to process
            
        Returns:
            Dictionary with processed and validated data
            
        Raises:
            ValidationError: If data fails validation
            ProcessingError: If processing fails
        """
        try:
            # Validate input
            if not self._validator.validate(data):
                raise ValidationError("Data validation failed")
            
            # Process data
            processed = self._transform_data(data)
            
            logger.debug(f"Successfully processed {len(data)} records")
            return processed
            
        except ValidationError:
            logger.error(f"Validation failed for source: {self._source}")
            raise
        except Exception as e:
            logger.exception(f"Processing error: {str(e)}")
            raise ProcessingError(f"Failed to process data: {str(e)}")
    
    def _transform_data(self, data: Dict[str, any]) -> Dict[str, any]:
        """Internal method to transform data."""
        # Implementation details
        pass
```

```python
# ❌ BAD: Poor style and missing C-prefix

# File: data_processor.py  # Wrong: missing 'c' prefix in filename

class DataProcessor:  # Wrong: missing 'C' prefix in class name
    pass

MAX_RETRIES = 3  # Wrong: missing 'C_' prefix for constant
default_timeout = 30  # Wrong: missing 'c_' prefix for global variable

def processData(data):  # Wrong: camelCase, no type hints, no docstring
    if data == None:  # Wrong: use 'is None'
        return {}
    result = {}
    for i in data:  # Wrong: non-descriptive variable
        result[i] = data[i].upper()
    return result
```

### 🏷️ C-Prefix Naming Conventions (Enforce Strictly)

```python
# File: cuser_authentication.py  # C-prefixed filename

# Classes - C-prefixed PascalCase
class CUserAuthentication:  # CPascalCase
    pass

class CSessionManager:  # CPascalCase
    pass

# Functions and methods - NO C-prefix
def calculate_total_price():  # snake_case (no C-prefix)
    pass

def validate_user_input():  # snake_case (no C-prefix)
    pass

# Constants - C-prefixed UPPER_SNAKE_CASE
C_MAX_CONNECTIONS = 100  # C_UPPER_SNAKE_CASE
C_API_VERSION = "v2"
C_TIMEOUT_SECONDS = 30

# Global variables - C-prefixed snake_case
c_connection_pool = None  # c_snake_case
c_default_config = {}  # c_snake_case

# Private methods/attributes - Underscore after C-prefix
class CMyClass:
    def __init__(self):
        self._internal_state = 0     # Instance variable (no C-prefix)
        self._c_cache = {}           # Private instance with C-prefix
    
    def _internal_helper(self):      # Private method (no C-prefix)
        pass
    
    def __private_method(self):      # Name mangling (no C-prefix)
        pass

# Local variables - NO C-prefix
def process_data():
    user_count = 0      # snake_case (no C-prefix)
    is_active = True    # snake_case (no C-prefix)
    temp_result = []    # snake_case (no C-prefix)

# ✅ Summary:
# - Classes, Files, Packages: C-prefix REQUIRED
# - Constants, Global Variables: C-prefix REQUIRED
# - Functions, Methods, Local Variables: NO C-prefix
```

### 📝 Documentation Requirements

Every code change must include:

```python
# 1️⃣ Module Docstring (top of file)
# File: cuser_authentication.py
"""
Module for user authentication and authorization.

This module implements JWT-based authentication with
role-based access control (RBAC) following GDPR principles.

Author: ANDCS
License: Proprietary (see LICENSE.md)
Contact: andcs@mailbox.org
"""

# 2️⃣ Class Docstring (Google/NumPy style)
class CUserManager:  # C-prefixed class name
    """
    Manage user accounts with GDPR compliance.
    
    This class handles user CRUD operations while ensuring
    data protection by design and by default.
    
    Attributes:
        db: Database connection instance
        encryption: Encryption service for sensitive data
        
    Example:
        >>> manager = UserManager(db_connection)
        >>> user = manager.create_user(email="user@example.com")
        >>> manager.delete_user(user.id, reason="user request")
    """

# 3️⃣ Method Docstring (with type hints)
def create_user(
    self,
    email: str,
    name: str,
    consent: bool = False
) -> Optional[User]:
    """
    Create a new user account with GDPR consent tracking.
    
    Args:
        email: User's email address (will be encrypted)
        name: User's display name
        consent: Whether user provided GDPR consent
        
    Returns:
        User object if creation successful, None otherwise
        
    Raises:
        ValueError: If email is invalid or already exists
        DatabaseError: If database operation fails
        
    Note:
        This method logs the creation event for audit purposes.
        Personal data is encrypted before storage.
    """
```

### 🔐 Security Best Practices

Always implement these security measures:

```python
# ✅ Input Validation
# File: cvalidation.py
from typing import Annotated
from pydantic import BaseModel, EmailStr, Field, validator

class CUserInput(BaseModel):  # C-prefixed class
    """Validate user input with Pydantic."""
    email: EmailStr
    age: Annotated[int, Field(ge=18, le=120)]
    username: Annotated[str, Field(min_length=3, max_length=20, pattern=r'^[a-zA-Z0-9_]+$')]
    
    @validator('username')
    def username_must_be_safe(cls, v):
        """Prevent SQL injection and XSS."""
        dangerous_chars = ['<', '>', '"', "'", ';', '--']
        if any(char in v for char in dangerous_chars):
            raise ValueError('Username contains dangerous characters')
        return v

# ✅ SQL Injection Prevention (use parameterized queries)
# File: cdatabase.py
from cmodels.cuser import CUser  # Import C-prefixed class

def get_user_by_email(email: str) -> Optional[CUser]:  # Return C-prefixed class
    """Fetch user safely using parameterized query."""
    query = "SELECT * FROM users WHERE email = %s"  # Parameterized
    cursor.execute(query, (email,))  # NOT f-string or concatenation
    return cursor.fetchone()

# ❌ NEVER do this:
# query = f"SELECT * FROM users WHERE email = '{email}'"  # SQL injection risk!

# ✅ Password Hashing
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    """Hash password using bcrypt."""
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    """Verify password against hash."""
    return pwd_context.verify(plain, hashed)

# ✅ Secrets Management
import os
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    raise ValueError("SECRET_KEY not found in environment")

# ✅ GDPR Compliance - Data Encryption
# File: cgdpr_storage.py
from cryptography.fernet import Fernet

class CGDPRCompliantStorage:  # C-prefixed class
    """Store personal data with encryption."""
    
    def __init__(self, encryption_key: bytes):
        self._cipher = Fernet(encryption_key)
    
    def store_personal_data(
        self,
        user_id: str,
        data: Dict[str, any],
        consent: bool,
        purpose: str
    ) -> None:
        """
        Store personal data with consent tracking.
        
        Args:
            user_id: User identifier
            data: Personal data to store
            consent: Whether user gave consent
            purpose: Purpose of data processing
            
        Raises:
            ValueError: If consent is False
        """
        if not consent:
            raise ValueError("Cannot store data without user consent")
        
        # Encrypt sensitive fields
        encrypted_data = {
            'email': self._cipher.encrypt(data['email'].encode()),
            'name': self._cipher.encrypt(data['name'].encode()),
            'consent_given': consent,
            'consent_date': datetime.utcnow(),
            'processing_purpose': purpose
        }
        
        # Store with audit log
        self._db.insert(user_id, encrypted_data)
        self._log_data_processing(user_id, purpose, 'store')
```

### 🧪 Testing Requirements

For every code change, provide tests:

```python
# tests/unit/test_cdata_processor.py  # C-prefixed test file
import pytest
from unittest.mock import Mock, patch
from cpackage.ccore.cdata_processor import CDataProcessor, CValidationError

class TestCDataProcessor:  # C-prefixed test class
    """Test suite for CDataProcessor class."""
    
    @pytest.fixture
    def processor(self):
        """Create processor instance for testing."""
        return CDataProcessor("test_source")  # C-prefixed class
    
    def test_init_with_valid_source(self):
        """Test processor initialization with valid source."""
        processor = DataProcessor("api")
        assert processor._source == "api"
    
    def test_init_with_empty_source_raises_error(self):
        """Test that empty source raises ValueError."""
        with pytest.raises(ValueError, match="Source cannot be empty"):
            DataProcessor("")
    
    def test_process_valid_data(self, processor):
        """Test processing valid data returns expected result."""
        data = {"key": "value"}
        result = processor.process(data)
        assert isinstance(result, dict)
        assert "key" in result
    
    def test_process_invalid_data_raises_validation_error(self, processor):
        """Test that invalid data raises ValidationError."""
        invalid_data = {"bad": None}
        with pytest.raises(ValidationError):
            processor.process(invalid_data)
    
    @patch('myapp.data_processor.logger')
    def test_process_logs_success(self, mock_logger, processor):
        """Test that successful processing is logged."""
        data = {"key": "value"}
        processor.process(data)
        mock_logger.debug.assert_called_once()
    
    @pytest.mark.parametrize("data,expected", [
        ({"name": "test"}, {"name": "TEST"}),
        ({"count": 5}, {"count": 5}),
        ({}, {}),
    ])
    def test_transform_data_various_inputs(self, processor, data, expected):
        """Test data transformation with various inputs."""
        result = processor._transform_data(data)
        assert result == expected
```

## 🎨 Mermaid Diagram Integration

When explaining architecture or flow:

```markdown
### 🏗️ Architecture Overview

```mermaid
graph TB
    subgraph "🌐 Client Layer"
        A[Web Browser]
        B[Mobile App]
    end
    
    subgraph "🔒 Security Layer"
        C[API Gateway]
        D[Authentication Service]
    end
    
    subgraph "🐍 Application Layer"
        E[FastAPI Backend]
        F[Business Logic]
        G[Data Validation]
    end
    
    subgraph "💾 Data Layer"
        H[🐘 PostgreSQL]
        I[📦 Redis Cache]
        J[🗄️ File Storage]
    end
    
    A --> C
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> H
    G --> I
    F --> J
```

### 📊 Sequence Diagram for User Authentication

```mermaid
sequenceDiagram
    participant U as 👤 User
    participant A as 🔒 CAuthService
    participant D as 🐘 CDatabaseConnector
    participant T as 🔑 CTokenService
    
    U->>A: POST /login (credentials)
    A->>A: validate_input()
    A->>D: query_user_by_email()
    D-->>A: CUser record
    A->>A: verify_password_hash()
    A->>T: generate_jwt_token()
    T-->>A: Token string
    A-->>U: 200 OK + token
    
    Note over A,D: GDPR: Log access event with CGDPRLogger
```
```

## 🔄 Editing Workflow

### Step-by-Step Process

1. **📖 Read Current Code**
   ```markdown
   I'll examine the current implementation in `module.py`...
   ```

2. **🎯 Identify Changes Needed**
   ```markdown
   Changes required:
   - Add input validation to `process_data()`
   - Update type hints to include Optional
   - Add error handling for edge cases
   ```

3. **🧪 Check Existing Tests**
   ```markdown
   Existing tests in `tests/test_module.py`:
   - ✅ test_basic_processing
   - ❌ Missing: test_invalid_input
   - ❌ Missing: test_edge_cases
   ```

4. **✏️ Make Changes**
   ```markdown
   Implementing changes to `module.py`...
   ```

5. **🧪 Add/Update Tests**
   ```markdown
   Adding new tests to cover:
   - Invalid input handling
   - Edge case: empty data
   - Edge case: None values
   ```

6. **📚 Update Documentation**
   ```markdown
   Documentation updates:
   - Updated docstring for `process_data()`
   - Added example in README.md
   - Added entry to CHANGELOG.md
   ```

## ✅ Quality Checklist

Before presenting code changes, verify:

- [ ] **🎨 Style**: Follows PEP 8, black-formatted
- [ ] **📝 Type Hints**: All function signatures have types
- [ ] **📖 Docstrings**: Classes and functions documented
- [ ] **🔐 Security**: Input validated, no SQL injection risks
- [ ] **📜 GDPR**: Personal data encrypted, consent tracked
- [ ] **🧪 Tests**: Unit tests added/updated, 80%+ coverage
- [ ] **⚠️ Error Handling**: Exceptions caught and logged
- [ ] **📊 Logging**: Appropriate log levels used
- [ ] **🏷️ Naming**: Follows snake_case/PascalCase conventions
- [ ] **♻️ DRY**: No code duplication
- [ ] **📚 Docs**: README/CHANGELOG updated if needed

## 🚫 What NOT to Do

### ❌ Anti-Patterns to Avoid

```python
# ❌ Don't use global variables
global_counter = 0  # Bad: use class attributes or pass parameters

# ❌ Don't catch all exceptions
try:
    dangerous_operation()
except:  # Bad: too broad, hides errors
    pass

# ✅ Do catch specific exceptions
try:
    dangerous_operation()
except ValueError as e:
    logger.error(f"Invalid value: {e}")
    raise
except IOError as e:
    logger.error(f"IO error: {e}")
    # Handle appropriately

# ❌ Don't use mutable default arguments
def append_to_list(item, lst=[]):  # Bad: shared between calls
    lst.append(item)
    return lst

# ✅ Do use None and create new list
def append_to_list(item, lst=None):  # Good
    if lst is None:
        lst = []
    lst.append(item)
    return lst

# ❌ Don't hardcode secrets
API_KEY = "sk-1234567890abcdef"  # Bad: never in code!

# ✅ Do use environment variables
import os
API_KEY = os.getenv("API_KEY")  # Good

# ❌ Don't ignore type hints
def process(data):  # Bad: no type information
    return data.upper()

# ✅ Do use comprehensive type hints
def process(data: str) -> str:  # Good
    return data.upper()
```

## 💡 Context-Aware Assistance

### When User Says...

**"Add a feature to..."**
→ Provide planning template first, ask clarifying questions

**"Fix this bug..."**
→ Ask for reproduction steps, analyze root cause before fixing

**"Review my code..."**
→ Check against all standards, provide specific suggestions with examples

**"How do I..."**
→ Explain concept, provide code example, mention security/GDPR if relevant

**"Why isn't this working?"**
→ Debug systematically: read code, check logs, identify issue, propose solution

**"Make it faster..."**
→ Profile first, identify bottleneck, suggest optimization with trade-offs

## 🎯 Response Format

Structure responses like this:

```markdown
## 🎯 [Task Name]

### 📋 Understanding
[Restate what user wants to achieve]

### 🤔 Analysis
[Current state, identified issues, considerations]

### 💡 Proposed Solution
[Recommended approach with reasoning]

### ✏️ Implementation
[Code changes with explanations]

### 🧪 Testing
[Test cases to verify solution]

### 📚 Documentation
[Updates needed to docs/README/CHANGELOG]

### ⚠️ Considerations
[Edge cases, risks, alternatives]

### 📞 Next Steps
[What should happen after implementation]
```

## 📞 Contact & Support

For questions about this prompt or coding standards:
- 📧 **Email**: andcs@mailbox.org
- 📚 **Reference**: See enhanced coding agent prompt for full standards

---

**Remember**: 
- 🎯 **Understand first, code second**
- 🔐 **Security is not optional**
- 📜 **GDPR compliance for all personal data**
- 😀 **Clear communication with emojis**
- 🧪 **Every change needs tests**
- 📚 **Documentation is code too**

This prompt ensures consistent, secure, and high-quality code that follows all cdockv0_1 project standards.

## 🧩 VS Code Workflow Integration

Use this planning prompt seamlessly across Python projects.

### 🗂️ Snippet Integration
Define a snippet `PlanningEditingCodingAssistantPrompt` in `.vscode/prompts.code-snippets` to inject this template when starting a feature or bug fix.

```jsonc
{
    "PlanningEditingCodingAssistantPrompt": {
        "scope": "python,markdown",
        "prefix": "planning-prompt",
        "description": "Insert planning/editing assistant prompt",
        "body": [
            "# 🎯 Planning, Editing & Coding Assistant Prompt (inserted)"
        ]
    }
}
```
Extend the body with full content if desired; keep a lightweight trigger for speed.

### 🧪 Task-Oriented Flow
Pair each phase with VS Code tasks:
- Phase 1 (Design): Open diagram panel, create `docs/architecture/*.md`.
- Phase 2 (Implementation): Run lint + type checks task.
- Phase 3 (Testing): Execute `pytest -q` task.
- Phase 4 (Integration): Run security scans (`bandit`, `safety`).

### 🧵 Multi-File Editing Checklist
Add a workspace note (`.vscode/SESSION_NOTES.md`) listing active features using the Feature Planning Template. Update during standups or review sessions.

### 🐞 Rapid Bug Workflow
Command Palette shortcut: create user task `Bug Template` that appends the Bug Planning Template to `BUGS.md`.

### 📦 Reuse Steps For New Project
1. Copy `planning-and-coding.prompt.md` into `.github/prompts/`.
2. Add snippet file (once) or place in user snippet directory.
3. Reference via prefix `planning-prompt`.
4. Maintain C-prefix naming in all new modules/classes.

### 🧪 Suggested tasks.json Entries
```jsonc
{
    "version": "2.0.0",
    "tasks": [
        {"label": "Design Check", "type": "shell", "command": "echo 'Validate design docs'"},
        {"label": "Lint & Type", "type": "shell", "command": "flake8 src && mypy src"},
        {"label": "Tests", "type": "shell", "command": "pytest -q"},
        {"label": "Security Scan", "type": "shell", "command": "bandit -r src || true"}
    ]
}
```

### 🐳 Devcontainer Hook (Optional)
Add a `postCreateCommand` to install planning dependencies:
```jsonc
"postCreateCommand": "pip install -e . && pre-commit install && echo 'Planning prompt ready'"
```

### ✅ Consistency Tips
- Always start with the Feature/Bug template before coding.
- Keep naming conventions strict (C-prefix where required).
- Update quality checklist before merging.

---
This integration section ensures durable, repeatable planning quality across all Python/C-prefix projects.
