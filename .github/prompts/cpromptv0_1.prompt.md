---
mode: 'agent'
description: 'Enhanced coding agent for creating production-ready Python projects following industry best practices, security standards, and compliance requirements'
tools: ['codebase', 'terminal', 'githubRepo']
---
<!--
Copyright (c) 2025 ANDCS. All rights reserved.
Unauthorized use prohibited. Feel free to contact andcs@mailbox.org for free code access.
Disclaimer: Provided "as is", no liability. AI parsing forbidden without consent.
-->

# 🤖 Enhanced Coding Agent Prompt

**Goal:** Create a production-ready Python project following industry best practices, security standards, and comprehensive compliance requirements.

## 📋 Core Requirements

### 1️⃣ 🐍 Language & Standards
- **Python 3.11+** with strict adherence to:
  - **PEP 8** - Style guide for Python code
  - **PEP 257** - Docstring conventions
  - **PEP 484/585** - Type hints and annotations
  - **PEP 518/621** - Modern packaging (pyproject.toml)
- Apply **OOP principles**: Encapsulation, Inheritance, Polymorphism, Abstraction
- Implement **Design Patterns** (minimum 1, recommend 2+):
  - Creational: Singleton, Factory, Builder, Prototype
  - Structural: Adapter, Decorator, Facade, Proxy
  - Behavioral: Observer, Strategy, Command, Template Method
- Include **POSIX-compliant shell scripts** (`.sh`) for automation tasks
- Use **PowerShell scripts** (`.ps1`) for Windows cross-compatibility

### 2️⃣ 📁 Project Structure & Organization

Follows **Linux FHS** (Filesystem Hierarchy Standard), **PEP standards**, and **C-prefix naming convention**:

```
project-root/
├── .github/
│   ├── workflows/          # CI/CD pipelines (GitHub Actions)
│   ├── prompts/            # AI agent prompts
│   └── ISSUE_TEMPLATE/     # Issue templates
├── bin/                    # 🔧 Executable scripts (FHS standard)
│   ├── README.md           # 📚 Directory documentation
│   ├── setup               # Symlink to ../libexec/setup.sh
│   └── deploy              # Symlink to ../libexec/deploy.sh
├── libexec/                # 🛠️ Program executables (not in PATH)
│   ├── README.md           # 📚 Directory documentation
│   ├── setup.sh            # POSIX-compliant setup script
│   ├── setup.ps1           # PowerShell setup script
│   ├── deploy.sh           # POSIX deployment script
│   └── deploy.ps1          # PowerShell deployment script
├── etc/                    # ⚙️ Configuration files (FHS standard)
│   ├── README.md           # 📚 Directory documentation
│   ├── config.yaml         # Application configuration
│   └── settings.json       # Additional settings
├── var/                    # 🗄️ Variable data files (FHS standard)
│   ├── README.md           # 📚 Directory documentation
│   ├── log/                # Log files
│   ├── cache/              # Cache data
│   └── tmp/                # Temporary files
├── docs/                   # 📚 Documentation
│   ├── README.md           # 📚 Documentation index
│   ├── CHANGELOG.md        # Version history for docs
│   ├── TODO.md             # Documentation tasks
│   ├── api/                # API documentation
│   ├── architecture/       # Architecture diagrams
│   └── guides/             # User guides
├── src/                    # 🐍 Python source code (PEP standard)
│   ├── README.md           # 📚 Source code documentation
│   ├── CHANGELOG.md        # Source code changes
│   ├── TODO.md             # Development tasks
│   └── cpackage_name/      # ⚠️ C-prefixed package name
│       ├── __init__.py
│       ├── README.md       # 📚 Package documentation
│       ├── ccore/          # 🎯 Core business logic
│       │   ├── __init__.py
│       │   ├── README.md
│       │   ├── cdata_processor.py    # C-prefixed module
│       │   └── cbusiness_logic.py
│       ├── cutils/         # 🔧 Utility functions
│       │   ├── __init__.py
│       │   ├── README.md
│       │   ├── chelpers.py
│       │   └── cvalidators.py
│       ├── cconfig/        # ⚙️ Configuration management
│       │   ├── __init__.py
│       │   ├── README.md
│       │   └── csettings.py
│       └── cmodels/        # 📊 Data models
│           ├── __init__.py
│           ├── README.md
│           ├── cuser.py    # C-prefixed model file
│           └── cproduct.py
├── tests/                  # 🧪 Test suite
│   ├── README.md           # 📚 Testing documentation
│   ├── CHANGELOG.md        # Test changes
│   ├── TODO.md             # Testing tasks
│   ├── unit/               # Unit tests
│   │   ├── README.md
│   │   └── test_cdata_processor.py
│   ├── integration/        # Integration tests
│   │   ├── README.md
│   │   └── test_capi.py
│   └── e2e/                # End-to-end tests
│       ├── README.md
│       └── test_cworkflow.py
├── docker/                 # 🐳 Docker configurations
│   ├── README.md           # 📚 Docker documentation
│   ├── CHANGELOG.md        # Docker changes
│   ├── TODO.md             # Docker tasks
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── .dockerignore
├── .gitignore
├── .env.example            # Environment template
├── LICENSE.md              # License (with copyright header)
├── README.md               # 😀 Emojified project documentation
├── CHANGELOG.md            # Version history (Keep a Changelog format)
├── TODO.md                 # Project-wide task tracker
├── CONTRIBUTING.md         # Contribution guidelines
├── SECURITY.md             # Security policy
├── EMOJIES.md              # 😀 Emoji usage guidelines
├── pyproject.toml          # Python project config (PEP 518/621)
└── requirements.txt        # Or use pyproject.toml dependencies
```

**Key Improvements:**
- ✅ **FHS Compliance**: `bin/`, `libexec/`, `etc/`, `var/` follow Linux Filesystem Hierarchy Standard
- ✅ **PEP Compliance**: `src/` layout follows PEP recommendations for Python packages
- ✅ **C-Prefix Convention**: All Python modules, classes, and packages prefixed with `c`
- ✅ **Documentation**: README.md, CHANGELOG.md, TODO.md in each major directory
- ✅ **Cross-Platform**: Separate `.sh` (POSIX) and `.ps1` (PowerShell) scripts
- ✅ **Separation**: User scripts in `bin/` (symlinks), implementation in `libexec/`

#### 🏷️ C-Prefix Naming Conventions

**All classes, global variables, constants, and source files MUST use C-prefix:**

- **Classes**: `CPascalCase` (e.g., `CDatabaseConnector`, `CUserManager`, `CDataProcessor`)
- **Source Files**: `cmodule_name.py` (e.g., `cperson.py`, `cdata_processor.py`, `cvalidator.py`)
- **Packages/Directories**: `cpackage_name/` (e.g., `ccore/`, `cutils/`, `cmodels/`)
- **Global Variables**: `c_snake_case` (e.g., `c_default_timeout`, `c_connection_pool`)
- **Constants**: `C_UPPER_SNAKE_CASE` (e.g., `C_MAX_RETRIES = 3`, `C_API_VERSION = "v2"`)
- **Functions/Methods**: `snake_case` - NO C-prefix (e.g., `get_user_data`, `process_input`)
- **Local Variables**: `snake_case` - NO C-prefix (e.g., `user_count`, `is_valid`)
- **Private members**: Prefix with `_` after C-prefix (e.g., `C_internal_method`, `_c_helper`)

**Examples:**
```python
# ✅ Correct C-prefix usage
from cmodels.cuser import CUser          # C-prefixed class from C-prefixed file
from ccore.cdata_processor import CDataProcessor

C_MAX_CONNECTIONS = 100                   # C-prefixed constant
c_default_db = "postgresql"               # C-prefixed global variable

class CUserManager:                       # C-prefixed class
    def __init__(self):
        self.users = []                   # Instance variable (no C-prefix)
        self._c_cache = {}                # Private instance variable
    
    def get_user(self, user_id: int):    # Method (no C-prefix)
        user_count = len(self.users)      # Local variable (no C-prefix)
        return user_count

# ❌ Incorrect - missing C-prefix
class Person:                             # Wrong: should be CPerson
    pass

MAX_RETRIES = 3                           # Wrong: should be C_MAX_RETRIES
default_timeout = 30                      # Wrong: should be c_default_timeout
```

**Rationale:**
- 🔍 **Namespace Clarity**: C-prefix distinguishes project code from library code
- 🛡️ **Collision Prevention**: Avoids naming conflicts with Python stdlib and third-party packages
- 📚 **Code Organization**: Instantly identifies custom classes, constants, and modules
- 🎯 **Standard Compliance**: Maintains PEP 8 style while adding project-specific prefix

### 3️⃣ 🔐 Security & Compliance

#### 🛡️ Security Standards
- **CIS Benchmarks** compliance for Docker containers:
  - Non-root user execution
  - Read-only root filesystem where possible
  - Minimal capabilities (`CAP_DROP ALL`, selective `CAP_ADD`)
  - No new privileges (`security_opt: no-new-privileges`)
  - Health checks for all services
  - Secrets via environment variables or secrets management
  - Regular vulnerability scanning (e.g., Trivy, Snyk)
- **Network Security**:
  - Use **Quad9 DNS** (9.9.9.9, 149.112.112.112) for enhanced security
  - TLS/SSL for all external communications
  - Network segmentation via Docker networks
  - Port mapping to non-standard ports (52000-53000 range)

#### 📜 GDPR/RGPD Compliance
- **Data Protection by Design**:
  - Minimal data collection principle
  - Data encryption at rest and in transit
  - Audit logging for data access/modification
  - Clear data retention policies
  - User consent management
- **Required Documentation**:
  - Privacy policy document
  - Data processing records
  - Cookie/tracking disclosure (if applicable)
  - Data controller contact information
- **User Rights Implementation**:
  - Right to access (data export)
  - Right to rectification (data update)
  - Right to erasure (data deletion)
  - Right to data portability

### 4️⃣ 📚 Documentation & Diagrams

#### 📖 README.md Structure
1. **Title & Badges** (build status, coverage, version)
2. **😀 Emojified Sections** (following EMOJIES.md guidelines)
3. **Overview** with key features
4. **🚀 Quick Start** guide
5. **📦 Installation** instructions
6. **🎯 Usage Examples** with code snippets
7. **🏗️ Architecture** with Mermaid diagrams:
   - System architecture diagram
   - Component diagram
   - Sequence diagram for key flows
   - ER diagram for data models
8. **🔧 Configuration** options
9. **🧪 Testing** guide
10. **🤝 Contributing** guidelines
11. **📄 License** information
12. **📞 Contact** and support

#### 🎨 Mermaid Diagram Examples
```markdown
## 🏗️ Architecture

### System Overview
```mermaid
graph TB
    A[🌐 Client] --> B[🔒 API Gateway]
    B --> C[🐍 Python Backend]
    C --> D[🐘 PostgreSQL]
    C --> E[🦙 Ollama LLM]
    C --> F[📦 Redis Cache]
```

### Class Diagram
```mermaid
classDiagram
    class CDataProcessor {
        +process_data()
        +validate_input()
        -_internal_logic()
    }
    class CDatabaseConnector {
        +connect()
        +execute_query()
    }
    CDataProcessor --> CDatabaseConnector
```
```

#### 📝 Code Documentation
- **Module docstrings**: Purpose, author, license
- **Class docstrings**: Description, attributes, methods
- **Method docstrings**: Args, Returns, Raises, Examples (Google/NumPy style)
- **Inline comments**: Complex logic only, avoid obvious comments
- **Type hints**: All function signatures

### 5️⃣ 🧪 Testing & Quality Assurance

#### Testing Strategy
- **Unit Tests**: 80%+ coverage (pytest, unittest)
- **Integration Tests**: API endpoints, database interactions
- **E2E Tests**: Critical user workflows
- **Performance Tests**: Load testing, profiling
- **Security Tests**: OWASP Top 10 checks

#### 🛠️ Code Quality Tools
- **Linters**: `pylint`, `flake8`, `black` (formatter)
- **Type Checking**: `mypy` (strict mode)
- **Security**: `bandit`, `safety` (dependency scanning)
- **Complexity**: `radon` (cyclomatic complexity < 10)
- **Pre-commit Hooks**: Automated checks before commits

### 6️⃣ 🐳 Containerization & Deployment

#### Dockerfile Best Practices
```dockerfile
# Multi-stage build for smaller images
FROM python:3.11-slim as builder
WORKDIR /app
COPY pyproject.toml .
RUN pip install --no-cache-dir -e .

FROM python:3.11-slim
# 👤 Non-root user
RUN useradd -m -u 1000 appuser
USER appuser
WORKDIR /app
COPY --from=builder /app /app
# 🔐 Read-only root filesystem
# 💾 Writable volume for data
VOLUME ["/data"]
HEALTHCHECK --interval=30s --timeout=3s \
  CMD python -c "import sys; sys.exit(0)"
CMD ["python", "-m", "package_name"]
```

#### 🚀 CI/CD Pipeline (GitHub Actions)
- Automated testing on push/PR
- Code quality checks
- Security scanning
- Docker image building
- Automated deployment (staging/production)
- Version tagging and releases

### 7️⃣ 📦 Version Control & Release Management

#### Git Workflow
- **Branching Strategy**: GitFlow or trunk-based
- **Commit Messages**: Conventional Commits format
  ```
  feat: add user authentication
  fix: resolve database connection timeout
  docs: update API documentation
  test: add unit tests for data processor
  ```
- **Semantic Versioning**: `MAJOR.MINOR.PATCH`
  - v0.1.0 - Initial development
  - v1.0.0 - First stable release
  - v1.1.0 - Backward-compatible features
  - v1.1.1 - Backward-compatible bug fixes

#### 📝 CHANGELOG.md Format
Follow **Keep a Changelog** (https://keepachangelog.com):
```markdown
## [1.1.0] - 2025-11-20
### Added
- 🚀 New feature X
### Changed
- ⬆️ Updated dependency Y to v2.0
### Fixed
- 🐛 Fixed bug Z
### Security
- 🔒 Patched vulnerability CVE-XXXX
```

### 8️⃣ 🌍 Environment Configuration

#### .env.example Template
```bash
# Copyright (c) 2025 ANDCS. All rights reserved.
# Environment configuration template

# 🐘 Database
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
POSTGRES_USER=postgres
POSTGRES_PASSWORD=change_me_in_production

# 🔑 Security
SECRET_KEY=generate_random_256bit_key
JWT_EXPIRATION=3600

# 🌐 API
API_HOST=0.0.0.0
API_PORT=8000
DEBUG=false

# 🦙 LLM Integration
OLLAMA_HOST=http://localhost:11434
OPENAI_API_KEY=sk-your-key-here

# 📧 Contact
ADMIN_EMAIL=andcs@mailbox.org
```

### 9️⃣ 🤝 Community & Contribution

#### CONTRIBUTING.md Contents
- Code of conduct
- How to report bugs
- How to suggest features
- Development setup guide
- Testing requirements
- Pull request process
- Code review guidelines

#### SECURITY.md Contents
- Supported versions
- Vulnerability reporting process
- Security contact: andcs@mailbox.org
- Disclosure policy
- Security best practices

### 🔟 📊 Monitoring & Observability

#### Logging Standards
- **Structured logging** (JSON format)
- **Log levels**: DEBUG, INFO, WARNING, ERROR, CRITICAL
- **Correlation IDs** for request tracing
- **GDPR compliance**: No PII in logs without encryption

#### Metrics & Health Checks
- Application health endpoint (`/health`)
- Readiness probe (`/ready`)
- Prometheus metrics endpoint (optional)
- Performance monitoring integration

## 🎯 Implementation Checklist

Before considering the project complete, verify:

- [ ] ✅ All PEP standards followed (8, 257, 484)
- [ ] 🏗️ Proper project structure implemented
- [ ] 🔐 CIS Docker benchmarks applied
- [ ] 📜 GDPR compliance documented
- [ ] 🧪 Tests written (80%+ coverage)
- [ ] 📚 Documentation complete with Mermaid diagrams
- [ ] 🐳 Dockerfile optimized and secure
- [ ] 🚀 CI/CD pipeline configured
- [ ] 📝 CHANGELOG.md maintained
- [ ] 🔒 Security scanning passed
- [ ] 😀 README emojified for readability
- [ ] ⚖️ LICENSE.md with copyright headers
- [ ] 📬 Contact information (andcs@mailbox.org)

## 💡 Additional Recommendations

### 🎨 Code Style Automation
```bash
# Format code
black src/ tests/

# Sort imports
isort src/ tests/

# Type check
mypy src/

# Lint
pylint src/
flake8 src/
```

### 🔧 Pre-commit Configuration (.pre-commit-config.yaml)
```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.11.0
    hooks:
      - id: black
  - repo: https://github.com/PyCQA/flake8
    rev: 6.1.0
    hooks:
      - id: flake8
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.7.0
    hooks:
      - id: mypy
```

### 📚 Reference Documentation
- **PEP Index**: https://peps.python.org/
- **CIS Benchmarks**: https://www.cisecurity.org/cis-benchmarks
- **GDPR Portal**: https://gdpr.eu/
- **Quad9 DNS**: https://www.quad9.net/
- **Keep a Changelog**: https://keepachangelog.com/
- **Semantic Versioning**: https://semver.org/
- **Conventional Commits**: https://www.conventionalcommits.org/

## 📞 Support & Contact

For questions, issues, or collaboration requests:
- 📧 **Email**: andcs@mailbox.org
- 🐙 **GitHub**: Review project issues and discussions

---

**Note**: This prompt reflects enterprise-grade Python development standards combining security, compliance, and modern best practices established in the cdockv0_1 project.

## 🧩 VS Code Profile Integration

To reuse this prompt across all Python projects, integrate it with your VS Code environment:

### 🔌 Recommended Extensions
- GitHub Copilot (`GitHub.copilot`)
- GitHub Copilot Chat (`GitHub.copilot-chat`)
- Python (`ms-python.python`)
- Pylance (`ms-python.vscode-pylance`)
- Docker (`ms-azuretools.vscode-docker`)
- Markdown All in One (`yzhang.markdown-all-in-one`)

Add these to `.vscode/extensions.json` (create if missing):
```jsonc
{
  "recommendations": [
    "GitHub.copilot",
    "GitHub.copilot-chat",
    "ms-python.python",
    "ms-python.vscode-pylance",
    "ms-azuretools.vscode-docker",
    "yzhang.markdown-all-in-one"
  ]
}
```

### ✂️ Snippet Usage
Create `.vscode/prompts.code-snippets` and add a snippet named `EnhancedCodingAgentPrompt` containing this file's content for quick insertion into new repos.

### 🧪 tasks.json Automation
Example tasks to enforce style & quality:
```jsonc
{
  "version": "2.0.0",
  "tasks": [
    {"label": "Format (black)", "type": "shell", "command": "black src tests"},
    {"label": "Lint (flake8)", "type": "shell", "command": "flake8 src tests"},
    {"label": "Type Check (mypy)", "type": "shell", "command": "mypy src"},
    {"label": "Security (bandit)", "type": "shell", "command": "bandit -r src"},
    {"label": "Tests (pytest)", "type": "shell", "command": "pytest -q"}
  ]
}
```

### 🐳 Dev Container (Optional)
`devcontainer/devcontainer.json`:
```jsonc
{
  "name": "Python Dev",
  "image": "mcr.microsoft.com/devcontainers/python:3.11",
  "features": {"ghcr.io/devcontainers/features/docker-in-docker:1": {}},
  "postCreateCommand": "pip install -e . && pre-commit install",
  "customizations": {"vscode": {"extensions": ["GitHub.copilot","ms-python.python","ms-python.vscode-pylance"]}}
}
```

### 🐞 Launch Config (Debug)
`.vscode/launch.json`:
```jsonc
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Run Package",
      "type": "python",
      "request": "launch",
      "module": "cpackage_name",
      "justMyCode": true,
      "envFile": "${workspaceFolder}/.env"
    }
  ]
}
```

### 🧷 Consistent Commit Messages
Use Conventional Commits + emoji:
```
feat: add CUserManager authorization layer 🔐
fix: correct CDataProcessor null handling 🐛
docs: update architecture diagram 🏗️
test: add tests for CValidator edge cases ✅
```

### 🔄 Reuse Strategy Across Projects
1. Copy this prompt file into new repo at `.github/prompts/`.
2. Add snippet file once; VS Code will share across workspaces (if placed in user snippets directory).
3. Reference snippet when bootstrapping new projects to maintain consistency (search for `cpromptv0_1`).

### 📌 Quick Actions
- Run "Format (black)" task before committing.
- Ensure Implementation Checklist items are green before release.
- Keep C-prefix convention strict to preserve namespace clarity.

---
This integration section enables universal reuse of the prompt while retaining the cdock-specific C-prefix conventions.
