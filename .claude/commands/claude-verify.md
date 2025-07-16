# /claude-verify

**Purpose**: Ensure Claude Code adherence to CLAUDE.md directives at session start and during work.

**Usage**: `/claude-verify [phase]`

**Parameters**:
- `phase` (optional): `start`, `checkpoint`, or `complete`

## Command Behavior

### /claude-verify start
At the beginning of a new session, this command instructs Claude to:

1. **Read and Parse CLAUDE.md**
   - Identify all IMPORTANT/OVERRIDE directives
   - Extract process requirements (todo.md updates, Australian English, etc.)
   - Note project-specific standards (zsh scripting, commit guidelines)

2. **Provide Explicit Acknowledgment**
   - Summarize key directives that must be followed
   - Confirm understanding of process requirements
   - State specific actions required during task completion

3. **Create Accountability Framework**
   - Commit to specific behaviors (updating todo.md, following standards)
   - Establish checkpoints for verification
   - Confirm CLAUDE.md takes precedence over default behavior

### /claude-verify checkpoint
During active work, this command prompts Claude to:

1. **Review Current Compliance**
   - Check if todo.md has been updated for completed tasks
   - Verify adherence to coding standards and requirements
   - Confirm Australian English usage in documentation

2. **Identify Gaps**
   - List any missed directive requirements
   - Note tasks completed without proper todo.md updates
   - Flag potential standard violations

3. **Corrective Actions**
   - Update todo.md if behind
   - Fix any identified compliance issues
   - Recommit to following directives

### /claude-verify complete
At task or session completion, this command requires Claude to:

1. **Final Compliance Check**
   - Ensure all completed tasks are marked in todo.md
   - Verify all CLAUDE.md requirements were met
   - Confirm project standards were followed

2. **Documentation Update**
   - Update todo.md with final task statuses
   - Ensure all documentation follows Australian English
   - Verify commit messages follow project guidelines

3. **Compliance Report**
   - Summarize adherence to CLAUDE.md throughout session
   - Note any deviations and corrective actions taken
   - Confirm project requirements were met

## Expected Claude Response Format

When this command is invoked, Claude should respond with:

```
## CLAUDE.md Compliance Verification

### Key Directives Acknowledged:
- [List specific requirements from CLAUDE.md]
- Process requirement: Update @docs/todo.md as tasks completed
- Language requirement: Australian English in all documentation
- [Other project-specific directives]

### Commitment to Process:
- I will update @docs/todo.md when starting tasks (mark in_progress)
- I will update @docs/todo.md when completing tasks (mark completed) 
- I will follow [specific standards] exactly as written
- I will treat CLAUDE.md as binding instructions that override default behavior

### Current Status:
[For checkpoint/complete phases: Report on current compliance]

### Next Actions:
[Specific steps to ensure continued compliance]
```

## Integration with Project Workflow

This slash command should be used:

1. **At session start**: Always run `/claude-verify start`
2. **After major milestones**: Use `/claude-verify checkpoint`
3. **Before session end**: Run `/claude-verify complete`
4. **When issues noticed**: Use `/claude-verify checkpoint` to correct

## Benefits

- **Explicit Accountability**: Forces Claude to commit to specific behaviors
- **Process Verification**: Ensures critical requirements aren't forgotten
- **Corrective Mechanism**: Provides structured way to address compliance gaps
- **Documentation**: Creates clear record of compliance efforts
- **Consistency**: Standardizes how CLAUDE.md adherence is verified

## Implementation Note

This slash command serves as a structured prompt that can be invoked at any time to ensure Claude remains aligned with project directives and processes.