# Claude Code Global Preferences

## Language and Style
- Use Australian English (en-AU) spelling (e.g., use "specialise" not "specialize", "colour" not "color")
- Be concise and direct in communication

## Task Management
- For complex tasks, use TodoWrite to create checklists and track progress
- Break down complex problems into manageable steps

## Project Context
- Always look for CLAUDE.md files in local projects (check project root and .claude/ folder)
- If found, use the project-specific CLAUDE.md as the primary configuration
- Display the location of the found CLAUDE.md file to confirm context and announce "Project context confirmed"

## Git and Version Control
- When committing code, do not add co-authored line: "Co-Authored-By: Claude <noreply@anthropic.com>" or any Claude signature
- Avoid adding AI-generated comments or explanations to code files unless requested
- Focus on clean, maintainable code without unnecessary annotations

## Development Practices
- Prioritise code readability and maintainability
- Follow existing code patterns and conventions in the project
- Test functionality before considering tasks complete
