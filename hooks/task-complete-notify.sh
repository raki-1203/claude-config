#!/bin/bash

# Claude Code Task Completion Notification Script
# Sends Slack notification when Claude Code task completes

# Get terminal info
TERMINAL_NAME="${TERM_PROGRAM:-Unknown Terminal}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")

# Get Warp tab name via System Events (requires accessibility permission)
TAB_NAME=""
if [ "$TERMINAL_NAME" = "WarpTerminal" ]; then
    TAB_NAME=$(osascript -e 'tell application "System Events" to get name of first window of process "Warp"' 2>/dev/null || echo "")
fi

# Read hook input from stdin
HOOK_INPUT=$(cat)
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // "Unknown"')
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')

# Slack Webhook Notification
SLACK_WEBHOOK_URL="${CLAUDE_SLACK_WEBHOOK_URL:-}"

if [ -n "$SLACK_WEBHOOK_URL" ]; then
    # Tab name fallback
    TAB_DISPLAY="${TAB_NAME:-Unknown}"

    SLACK_PAYLOAD=$(jq -n \
        --arg terminal "$TERMINAL_NAME" \
        --arg tab "$TAB_DISPLAY" \
        --arg project "$PROJECT_NAME" \
        '{
            "text": "============================================\n*\($terminal)* : \($tab) 작업 완료 ✅\n*프로젝트* : \($project)\n============================================"
        }')

    curl -s -X POST -H 'Content-type: application/json' \
        --data "$SLACK_PAYLOAD" \
        "$SLACK_WEBHOOK_URL" > /dev/null 2>&1
fi

# Output success
echo '{"suppressOutput": true}'
