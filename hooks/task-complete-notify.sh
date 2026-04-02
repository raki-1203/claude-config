#!/bin/bash

# Claude Code Task Completion Notification Script
# Sends Slack notification when Claude Code task completes

# DEBUG: Log hook invocation
echo "[$(date '+%Y-%m-%d %H:%M:%S')] task-complete-notify.sh called" >> /tmp/claude-hook-debug.log
echo "[$(date '+%Y-%m-%d %H:%M:%S')] CLAUDE_SLACK_WEBHOOK_URL set: $([ -n \"$CLAUDE_SLACK_WEBHOOK_URL\" ] && echo 'YES' || echo 'NO')" >> /tmp/claude-hook-debug.log
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ENV: TERM_PROGRAM=$TERM_PROGRAM TMUX=$TMUX TMUX_PANE=$TMUX_PANE" >> /tmp/claude-hook-debug.log

# Get terminal info
TERMINAL_NAME="${TERM_PROGRAM:-Unknown Terminal}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(cd "$PROJECT_DIR" 2>/dev/null && git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||')
[ -z "$PROJECT_NAME" ] && PROJECT_NAME=$(basename "$PROJECT_DIR")

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
            "text": "*\($terminal)* : \($tab) 작업 완료 ✅\n*프로젝트* : \($project)\n*경로* : \($path)\n============================================"
        }')

    curl -s -X POST -H 'Content-type: application/json' \
        --data "$SLACK_PAYLOAD" \
        "$SLACK_WEBHOOK_URL" > /dev/null 2>&1
fi

# --- Daily 기록 체크: 이 세션에서 기록한 적 없으면 Claude에게 기록 지시 ---
LAST_RECORD_FILE="$HOME/.claude/growth/.last-daily-record"
TOOL_COUNTER_FILE="$HOME/.claude/growth/.tool-counter"
TOOL_COUNT=$(cat "$TOOL_COUNTER_FILE" 2>/dev/null || echo "0")

# Write/Edit가 1회 이상 있었는데 Daily 기록을 안 한 경우
if [ "$TOOL_COUNT" -gt 0 ]; then
    NEEDS_RECORD="false"
    if [ ! -f "$LAST_RECORD_FILE" ]; then
        NEEDS_RECORD="true"
    else
        # 마지막 기록이 오늘인지 확인
        TODAY=$(date '+%Y-%m-%d')
        LAST_MOD_DATE=$(date -r "$LAST_RECORD_FILE" '+%Y-%m-%d' 2>/dev/null || echo "")
        if [ "$LAST_MOD_DATE" != "$TODAY" ]; then
            NEEDS_RECORD="true"
        fi
    fi

    if [ "$NEEDS_RECORD" = "true" ] && command -v obsidian &>/dev/null; then
        if obsidian eval code="1" &>/dev/null 2>&1; then
            touch "$LAST_RECORD_FILE"
            echo "{\"result\": \"[Obsidian Daily 기록] 이 세션에서 아직 Daily에 기록하지 않았습니다. obsidian daily:append 로 이번 작업 내용을 기록하세요.\\n\\n### 세션: ${PROJECT_NAME} ($(date '+%H:%M'))\\n- 작업 내용 요약 (2-5줄)\\n- 주요 결정과 이유\\n- wikilink([[개념명]]) 사용\\n- 태그: #session #${PROJECT_NAME}\", \"suppressOutput\": false}"
            exit 0
        fi
    fi
fi

# Output success
echo '{"suppressOutput": true}'
