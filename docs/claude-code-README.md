# Claude Code MCP Setup Guide

## Overview

The `install-claude-code.zsh` script provides a comprehensive setup for Claude Code with full MCP (Model Context Protocol) server configuration. This guide explains how to use the enhanced installation script to set up Claude Code with all essential MCP servers on a new Mac.

## Quick Start

### Basic Installation (Recommended)
```bash
./scripts/install-claude-code.zsh
```

This installs:
- Claude Code CLI tool
- Essential MCP servers (FileSystem, Sequential Thinking, Context7, Memory Bank, MarkItDown, Puppeteer, Desktop Commander)
- Dotfiles configuration (if available)

### Installation with Optional MCP Servers
```bash
./scripts/install-claude-code.zsh --optional-mcp
```

This additionally prompts for API keys and installs:
- GitHub MCP server (requires GitHub token)
- Brave Search MCP server (requires Brave API key)
- PostgreSQL MCP server (requires database URL)

## Command Line Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-v, --verbose` | Enable verbose output |
| `-f, --force` | Force reinstall even if already installed |
| `-s, --skip-dotfiles` | Skip dotfiles configuration |
| `-m, --skip-mcp` | Skip MCP server configuration |
| `-o, --optional-mcp` | Install optional MCP servers (requires API keys) |
| `-V, --version` | Show version information |

## MCP Servers Installed

### Core Servers (Always Installed)

1. **FileSystem** - Local file system access
   - Package: `@modelcontextprotocol/server-filesystem`
   - Directories: `~/Documents`, `~/Desktop`, `~/Downloads`, `~/Projects`, `~/Developer`

2. **Sequential Thinking** - Dynamic problem-solving through thought sequences
   - Package: `@modelcontextprotocol/server-sequential-thinking`

3. **Context7** - Up-to-date documentation and code examples
   - Package: `@upstash/context7-mcp`

4. **Memory Bank** - Persistent memory management for AI agents
   - Package: `@alioshr/memory-bank-mcp`
   - Storage: `~/.claude/memory-bank`

5. **MarkItDown** - Convert documents to Markdown format
   - Package: `@microsoft/markitdown-mcp`

6. **Puppeteer** - Web automation and browser control
   - Package: `@modelcontextprotocol/server-puppeteer`

7. **Desktop Commander** - Terminal control and file system operations
   - Package: `@wonderwhy-er/desktop-commander-mcp`

### Optional Servers (Installed with `--optional-mcp`)

1. **GitHub** - Repository integration and management
   - Package: `@modelcontextprotocol/server-github`
   - Requires: GitHub Personal Access Token

2. **Brave Search** - Web search capabilities
   - Package: `@modelcontextprotocol/server-brave-search`
   - Requires: Brave Search API key

3. **PostgreSQL** - Database queries and management
   - Package: `@modelcontextprotocol/server-postgres`
   - Requires: PostgreSQL connection string

## API Key Setup

### GitHub Token
1. Go to https://github.com/settings/tokens
2. Create a new token with appropriate permissions
3. Copy the token when prompted during installation

### Brave Search API Key
1. Go to https://api.search.brave.com/
2. Sign up for an account
3. Generate an API key
4. Copy the key when prompted during installation

### PostgreSQL Connection
Format: `postgresql://username:password@host:port/database`

Example: `postgresql://user:pass@localhost:5432/mydb`

## Configuration Files

### MCP Configuration
- **Location**: `~/.claude/claude_desktop_config.json`
- **Purpose**: Defines all MCP servers and their configuration
- **Auto-generated**: Yes, based on installed servers and API keys

### Environment Variables
- **Location**: `~/.zshrc` (automatically appended)
- **Variables**:
  - `MEMORY_BANK_ROOT`: Path to memory bank storage
  - `GITHUB_TOKEN`: GitHub API token (if provided)
  - `BRAVE_API_KEY`: Brave Search API key (if provided)
  - `DATABASE_URL`: PostgreSQL connection string (if provided)

### Template Files
- **MCP Config Template**: `configs/claude/claude_desktop_config.json.template`
- **Server Definitions**: `configs/claude/mcp-servers.json`

## Post-Installation

### Environment Setup
After installation, restart your terminal or run:
```bash
source ~/.zshrc
```

### Verification
Check Claude Code installation:
```bash
claude --version
```

List installed MCP servers:
```bash
claude mcp list
```

### Using MCP Servers
Within a Claude Code session:
- Check MCP status: `/mcp`
- Configure permissions: `/permissions`
- List available tools: `/tools`

## Troubleshooting

### Common Issues

1. **Node.js Version**: Ensure Node.js 18+ is installed
2. **npm Permissions**: May need to configure npm for global installs
3. **Environment Variables**: Restart terminal after installation
4. **API Keys**: Verify API keys are correctly set in environment

### Logs
Check installation logs in the terminal output. Use `-v` flag for verbose logging.

### Re-installation
Force reinstall with:
```bash
./scripts/install-claude-code.zsh --force
```

## Examples

### Basic Developer Setup
```bash
./scripts/install-claude-code.zsh
```

### Full Setup with GitHub Integration
```bash
./scripts/install-claude-code.zsh --optional-mcp
# Enter GitHub token when prompted
```

### Claude Code Only (No MCP)
```bash
./scripts/install-claude-code.zsh --skip-mcp
```

### Dotfiles + MCP (No Optional)
```bash
./scripts/install-claude-code.zsh --skip-dotfiles
```

## Support

For issues or questions:
1. Check the verbose output: `./scripts/install-claude-code.zsh -v`
2. Review the Claude Code documentation: https://docs.anthropic.com/en/docs/claude-code
3. Check MCP documentation: https://docs.anthropic.com/en/docs/claude-code/mcp