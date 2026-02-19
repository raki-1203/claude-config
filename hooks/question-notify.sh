#!/bin/bash

# Notify type: "question" (default) or "permission" (set via NOTIFY_TYPE env var)
NOTIFY_TYPE="${NOTIFY_TYPE:-question}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] question-notify.sh called (type=$NOTIFY_TYPE)" >> /tmp/claude-hook-debug.log

# Get terminal info
TERMINAL_NAME="${TERM_PROGRAM:-Unknown Terminal}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")

# Get tab/window name based on terminal type
TAB_NAME=""
if [ -n "$TMUX_PANE" ]; then
    # tmux: get window name for the pane where Claude Code is running
    # TMUX_PANE contains the pane ID (e.g., %0, %1, etc.)
    WINDOW_ID=$(tmux list-panes -a -F '#{pane_id} #{window_id}' 2>/dev/null | grep "^${TMUX_PANE} " | awk '{print $2}')
    if [ -n "$WINDOW_ID" ]; then
        TAB_NAME=$(tmux list-windows -a -F '#{window_id} #{window_name}' 2>/dev/null | grep "^${WINDOW_ID} " | cut -d' ' -f2-)
    fi
elif [ -n "$TMUX" ] || tmux info &>/dev/null; then
    # Fallback: tmux session exists but no TMUX_PANE
    TAB_NAME=$(tmux display-message -p '#W' 2>/dev/null || echo "")
elif [ "$TERMINAL_NAME" = "WarpTerminal" ]; then
    # Warp: get tab name via System Events (requires accessibility permission)
    TAB_NAME=$(osascript -e 'tell application "System Events" to get name of first window of process "Warp"' 2>/dev/null || echo "")
fi

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract tool name for permission requests
TOOL_NAME=""
if [ "$NOTIFY_TYPE" = "permission" ]; then
    TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // .tool // empty' 2>/dev/null || echo "")
fi

# Build notification message based on type
if [ "$NOTIFY_TYPE" = "permission" ]; then
    EMOJI="\\u26a0\\ufe0f"
    if [ -n "$TOOL_NAME" ]; then
        STATUS_MSG="권한 승인 대기중 ($TOOL_NAME)"
    else
        STATUS_MSG="권한 승인 대기중"
    fi
else
    EMOJI="\\u2753"
    STATUS_MSG="질문 대기중"
fi

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
        --arg status "$STATUS_MSG" \
        --arg emoji "$EMOJI" \
        '{
            "text": "*\($terminal)* : \($tab) \($status) \($emoji)\n*프로젝트* : \($project)\n*경로* : \($path)\n============================================"
        }')

    curl -s -X POST -H 'Content-type: application/json' \
        --data "$SLACK_PAYLOAD" \
        "$SLACK_WEBHOOK_URL" > /dev/null 2>&1
fi

# Output success
echo '{"suppressOutput": true}'
