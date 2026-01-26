#!/bin/bash

# Claude Code Question Notification Script
# Sends Slack notification when Sisyphus asks a question

# Get terminal info
TERMINAL_NAME="${TERM_PROGRAM:-Unknown Terminal}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")

# Get tab/window name based on terminal type
TAB_NAME=""
if [ -n "$TMUX" ] || tmux info &>/dev/null; then
    # tmux: get current window name
    TAB_NAME=$(tmux display-message -p '#W' 2>/dev/null || echo "")
elif [ "$TERMINAL_NAME" = "WarpTerminal" ]; then
    # Warp: get tab name via System Events (requires accessibility permission)
    TAB_NAME=$(osascript -e 'tell application "System Events" to get name of first window of process "Warp"' 2>/dev/null || echo "")
fi

# Read hook input from stdin (for potential future use)
HOOK_INPUT=$(cat)

# Slack Webhook Notification
SLACK_WEBHOOK_URL="${CLAUDE_SLACK_WEBHOOK_URL:-}"

if [ -n "$SLACK_WEBHOOK_URL" ]; then
    # Tab name fallback
    TAB_DISPLAY="${TAB_NAME:-Unknown}"

    SLACK_PAYLOAD=$(jq -n \
        --arg terminal "$TERMINAL_NAME" \
        --arg tab "$TAB_DISPLAY" \
        --arg project "$PROJECT_NAME" \
        --arg path "$PROJECT_DIR" \
        '{
            "text": "*\($terminal)* : \($tab) 질문 대기중 \u2753\n*프로젝트* : \($project)\n*경로* : \($path)\n============================================"
        }')

    curl -s -X POST -H 'Content-type: application/json' \
        --data "$SLACK_PAYLOAD" \
        "$SLACK_WEBHOOK_URL" > /dev/null 2>&1
fi

# Output success
echo '{"suppressOutput": true}'
