# Project Slash Commands

This directory contains custom slash commands for the macOS Setup Automation project.

## Available Commands

### /claude-verify
**Purpose**: Ensure Claude Code adherence to CLAUDE.md directives
**File**: `claude-verify.md`
**Usage**: `/claude-verify [start|checkpoint|complete]`

Provides structured verification that Claude is following project-specific requirements, particularly:
- Updating @docs/todo.md as tasks are completed
- Following Australian English requirements
- Adhering to zsh scripting standards
- Following commit guidelines

## Usage Instructions

1. **Save slash commands**: Copy the markdown files to your Claude Code slash commands directory
2. **Session start**: Always begin with `/claude-verify start`
3. **During work**: Use `/claude-verify checkpoint` after major tasks
4. **Session end**: Conclude with `/claude-verify complete`

## Creating New Slash Commands

To add new project-specific slash commands:

1. Create a new `.md` file in this directory
2. Use the format established in existing commands
3. Update this README with the new command
4. Test the command in a Claude Code session

## Integration with CLAUDE.md

These slash commands are designed to work with the project's CLAUDE.md file to ensure:
- Consistent behavior across sessions
- Explicit acknowledgment of project requirements
- Systematic verification of directive compliance
- Structured approach to project management