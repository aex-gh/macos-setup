# Claude Code Configuration

This directory contains configuration and documentation for Claude Code, Anthropic's official CLI for AI-assisted coding.

## Quick Start

To use Claude Code in any project:
```bash
cd /path/to/your/project
claude
```

## Features

- Interactive coding sessions with Claude
- Context-aware code generation and refactoring
- Integrated with your project files and codebase
- Supports multiple programming languages and frameworks

## Configuration

Claude Code configuration can be customised by creating a local `CLAUDE.md` file in your project root. This file can contain:

- Project-specific instructions for Claude
- Coding standards and conventions
- Architecture decisions and patterns
- Custom prompts and behaviours

## Tips

1. **Project Context**: Claude Code automatically reads your project structure and files
2. **Interactive Mode**: Use the interactive CLI for conversational coding sessions
3. **Code Generation**: Claude can generate boilerplate code, tests, and documentation
4. **Refactoring**: Ask Claude to help refactor existing code for better performance or readability

## Integration with macOS Setup

Claude Code is automatically installed as part of the Node.js global packages during the development environment setup. It requires Node.js 18 or newer.

To verify installation:
```bash
claude --version
```

## Resources

- [Official Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [GitHub Repository](https://github.com/anthropics/claude-code)
- [API Documentation](https://docs.anthropic.com/en/api)

---

Co-Authored-By: Claude <noreply@anthropic.com>