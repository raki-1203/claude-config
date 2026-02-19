---
description: "Start Autopilot - autonomous loop with quality gates"
argument-hint: "[MODE] PROMPT [--max-iterations N] [--completion-promise TEXT]"
allowed-tools: ["Bash(AUTOPILOT_MODE=*)", "Read(*)", "Skill(ralph-loop:*)"]
---

# Autopilot Command

You are now setting up Autopilot mode. Parse the arguments and configure the autonomous loop.

## Argument Parsing

From `$ARGUMENTS`, extract:
1. **MODE** (optional, first word if it matches: `tdd`, `focused`, `freestyle`, `review`). Default: `tdd`
2. **PROMPT** - the remaining text (the task description)
3. **--max-iterations N** - max loop iterations (default: 30)
4. **--completion-promise TEXT** - completion signal (default: "COMPLETE")

## Mode Definitions

| Mode | TDD Gate | Quality Gate | Description |
|------|----------|-------------|-------------|
| `tdd` (default) | Yes | Yes | Tests must pass each iteration |
| `focused` | Yes | Yes | TDD + stricter code review standards |
| `freestyle` | No | No | Pure ralph loop, no gates |
| `review` | No | Yes | Quality checks only, no test requirement |

## Setup Steps

### Step 1: Create autopilot state file

IMPORTANT: Pass values as environment variables to avoid shell injection.
Set the environment variables based on parsed arguments, then run:

```!
AUTOPILOT_MODE="<parsed_mode>" AUTOPILOT_PROMPT="<parsed_prompt>" AUTOPILOT_MAX_ITER="<parsed_max_iter>" AUTOPILOT_PROMISE="<parsed_promise>" node /Users/raki-1203/.claude/scripts/autopilot-setup.js
```

The script will output JSON with project detection results and state configuration.

### Step 2: Enhance the prompt

Build an enhanced prompt based on the mode:

**For `tdd` mode**, prepend:
```
[AUTOPILOT MODE: TDD]
You are in autopilot TDD mode. Follow this workflow STRICTLY:
1. Write failing tests FIRST (RED)
2. Write minimal code to pass (GREEN)
3. Refactor while keeping tests green (REFACTOR)
4. The autopilot gate checks test results each iteration.
5. If you see GATE_FAILED, fix the failing tests before proceeding.
6. If you see STUCK_DETECTED, try a completely different approach.
7. When genuinely done, output: <promise>COMPLETION_PROMISE</promise>

```

**For `focused` mode**, prepend:
```
[AUTOPILOT MODE: FOCUSED]
You are in autopilot focused mode. Follow TDD strictly AND:
1. Write failing tests FIRST (RED)
2. Write minimal code to pass (GREEN)
3. Refactor while keeping tests green (REFACTOR)
4. Ensure code meets review standards (no console.log, proper types, etc.)
5. If you see GATE_FAILED, fix issues before proceeding.
6. If you see STUCK_DETECTED, try a completely different approach.
7. When genuinely done, output: <promise>COMPLETION_PROMISE</promise>

```

**For `freestyle` mode**, prepend:
```
[AUTOPILOT MODE: FREESTYLE]
You are in autopilot freestyle mode. No quality gates enforced.
Work on the task iteratively. When done, output: <promise>COMPLETION_PROMISE</promise>

```

**For `review` mode**, prepend:
```
[AUTOPILOT MODE: REVIEW]
You are in autopilot review mode. Quality checks are active but no test requirement.
Focus on code quality, proper patterns, and clean implementation.
If you see GATE_WARNING, address the quality issues.
When genuinely done, output: <promise>COMPLETION_PROMISE</promise>

```

### Step 3: Launch Ralph Loop

Invoke the ralph-loop skill with the enhanced prompt:

Use the Skill tool to call `ralph-loop` with arguments:
```
ENHANCED_PROMPT --max-iterations MAX_ITER --completion-promise 'COMPLETION_PROMISE'
```

### Step 4: Report

Output a summary:
```
Autopilot activated!

Mode: MODE
Project: PROJECT_TYPE
Test command: TEST_CMD
Max iterations: N
Completion promise: PROMISE
Gates: TDD=yes/no, Quality=yes/no

The autopilot gate will check quality at each iteration.
Use /cancel-autopilot to stop at any time.
```
