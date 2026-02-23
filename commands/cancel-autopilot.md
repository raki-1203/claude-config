---
description: "Cancel active Autopilot loop"
allowed-tools: ["Bash(test:*)", "Bash(rm:*)", "Bash(cat:*)", "Read(*)", "Skill(cancel-ralph:*)"]
---

# Cancel Autopilot

To cancel the autopilot loop, follow these steps:

## Step 1: Check autopilot state

```!
test -f .claude/autopilot-state.local.json && echo "AUTOPILOT_EXISTS" || echo "AUTOPILOT_NOT_FOUND"
```

## Step 2: If AUTOPILOT_NOT_FOUND

Check if there's at least a ralph loop running:
```!
test -f .claude/ralph-loop.local.md && echo "RALPH_EXISTS" || echo "RALPH_NOT_FOUND"
```

- If both NOT_FOUND: Say "No active autopilot or ralph loop found."
- If only RALPH_EXISTS: Run `/cancel-ralph` and say "No autopilot state found, but cancelled active ralph loop."

## Step 3: If AUTOPILOT_EXISTS

1. Read the autopilot state to get current status:
```!
cat .claude/autopilot-state.local.json
```

2. Report the current status (mode, iteration, gate results)

3. Remove the autopilot state file:
```!
rm .claude/autopilot-state.local.json
```

4. Also cancel the ralph loop by using the Skill tool to call `cancel-ralph`

5. Report final summary:
```
Autopilot cancelled.
- Mode: MODE
- Iterations completed: N
- Last gate result: RESULT
```
