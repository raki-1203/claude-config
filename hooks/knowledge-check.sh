#!/bin/bash
# knowledge-check.sh - 세션 시작 시 context-summary.md 로드
# Hook: UserPromptSubmit (timeout: 5s)
# 세션 첫 메시지에서만 실행: 파일시스템에서 직접 읽기 (Obsidian CLI 의존 없음)

LAST_SESSION_FILE="$HOME/.claude/growth/.last-session-id"

HOOK_INPUT=$(cat)
CURRENT_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null)

LAST_SESSION=$(cat "$LAST_SESSION_FILE" 2>/dev/null || echo "")

if [ -n "$CURRENT_SESSION" ]; then
    mkdir -p "$(dirname "$LAST_SESSION_FILE")"
    echo "$CURRENT_SESSION" > "$LAST_SESSION_FILE"
fi

# 같은 세션이면 스킵 (첫 메시지에서만 실행)
if [ "$CURRENT_SESSION" = "$LAST_SESSION" ]; then
    echo '{"suppressOutput": true}'
    exit 0
fi

# context-summary.md 로드 (파일시스템 직접 읽기 — Obsidian 불필요)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")
SUMMARY="$HOME/.claude/growth/sessions/$PROJECT_NAME/context-summary.md"

if [ -f "$SUMMARY" ] && [ -s "$SUMMARY" ]; then
    CONTENT=$(head -50 "$SUMMARY")
    if command -v jq &>/dev/null; then
        jq -n --arg ctx "[Session Memory] 이전 세션 맥락 (${PROJECT_NAME}):\n$CONTENT" \
            '{"result": $ctx, "suppressOutput": false}'
    else
        echo "{\"result\": \"[Session Memory] context-summary 로드됨 (${PROJECT_NAME})\", \"suppressOutput\": false}"
    fi
else
    echo '{"suppressOutput": true}'
fi
