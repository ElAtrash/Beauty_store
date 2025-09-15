# Beauty Store - Claude Documentation

This directory contains comprehensive documentation of work done by Claude Code assistant to provide context for future development and maintenance.

## Documentation Structure

```
.claude/docs/
├── README.md                           # This file - documentation index
├── implementations/                    # Major feature implementations
│   └── unified-popup-system.md        # Popup system overhaul (Sep 2025)
├── refactors/                         # Code refactoring documentation
├── bug-fixes/                         # Bug fix documentation
├── architecture/                      # System architecture decisions
└── context/                          # Additional context files
```

## Quick Reference

### Recent Work (Latest First)

#### 🎯 Major Implementations
- **[Unified Popup System](implementations/unified-popup-system.md)** (Sep 2025)
  - Complete popup system overhaul using ViewComponent + Stimulus + Turbo
  - Replaced legacy modal system with sophisticated, reusable architecture
  - Comprehensive cleanup of deprecated code
  - Status: ✅ Complete and Production Ready

### Future Documentation

As new work is completed, documentation should be organized into appropriate categories:

- **implementations/**: Major feature additions or system overhauls
- **refactors/**: Significant code reorganization or modernization
- **bug-fixes/**: Important bug fixes with context and solution details
- **architecture/**: Architectural decisions and system design documentation
- **context/**: Additional context files for complex scenarios

## Usage Guidelines

### For Claude Code Assistant
- Always check existing documentation in `.claude/docs/` before starting related work
- Reference previous implementations for established patterns and conventions
- Add new documentation after completing significant work
- Update this README when adding new documentation categories

### For Developers
- Review relevant documentation before making changes to documented systems
- Use existing implementations as reference for consistent patterns
- Update documentation when making significant changes to documented systems

## Documentation Standards

### File Naming
- Use kebab-case for filenames
- Include date or version when relevant
- Be descriptive but concise

### Content Structure
- Always include problem statement and solution overview
- Document technical specifications and API details
- Include file paths and code examples
- Note any breaking changes or compatibility considerations
- Provide usage guidelines and best practices

---

**Last Updated**: September 2025