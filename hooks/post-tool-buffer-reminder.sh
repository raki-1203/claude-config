#!/bin/bash
# post-tool-buffer-reminder.sh
# Hook: PostToolUse, matcher: "Write OR Edit"
# Write/Edit 10회마다 Claude에게 session-buffer.md 업데이트 요청

COUNTER_FILE="$HOME/.claude/growth/.tool-counter"
mkdir -p "$(dirname "$COUNTER_FILE")"

COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

if [ $((COUNT % 10)) -ne 0 ]; then
    echo '{"suppressOutput": true}'
    exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")
BUFFER="$HOME/.claude/growth/sessions/$PROJECT_NAME/session-buffer.md"

# buffer가 최근 10분 이내 업데이트됐으면 스킵
if [ -f "$BUFFER" ]; then
    NOW=$(date +%s)
    MOD=$(stat -f %m "$BUFFER" 2>/dev/null || echo "0")
    DIFF=$((NOW - MOD))
    if [ "$DIFF" -lt 600 ]; then
        echo '{"suppressOutput": true}'
        exit 0
    fi
fi

mkdir -p "$(dirname "$BUFFER")"
echo "{\"result\": \"[Session Buffer] Write/Edit ${COUNT}회 실행. ~/.claude/growth/sessions/${PROJECT_NAME}/session-buffer.md를 현재 작업 상태로 업데이트하세요 (현재 작업, 진행 상황, 주요 결정, 수정 파일, 다음 할 일). wikilink([[개념명]]) 사용.\", \"suppressOutput\": false}"
