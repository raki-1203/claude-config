#!/bin/bash
# post-tool-buffer-reminder.sh
# Hook: PostToolUse, matcher: "Write OR Edit"
# Write/Edit 10회마다 Claude에게 Obsidian Daily에 직접 세션 기록 요청

COUNTER_FILE="$HOME/.claude/growth/.tool-counter"
mkdir -p "$(dirname "$COUNTER_FILE")"

COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

if [ $((COUNT % 10)) -ne 0 ]; then
    echo '{"suppressOutput": true}'
    exit 0
fi

# 마지막 기록 시간 확인 (10분 이내면 스킵)
LAST_RECORD_FILE="$HOME/.claude/growth/.last-daily-record"
if [ -f "$LAST_RECORD_FILE" ]; then
    NOW=$(date +%s)
    MOD=$(stat -f %m "$LAST_RECORD_FILE" 2>/dev/null || echo "0")
    DIFF=$((NOW - MOD))
    if [ "$DIFF" -lt 600 ]; then
        echo '{"suppressOutput": true}'
        exit 0
    fi
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(cd "$PROJECT_DIR" 2>/dev/null && git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||')
[ -z "$PROJECT_NAME" ] && PROJECT_NAME=$(basename "$PROJECT_DIR")

# Obsidian CLI 사용 가능한지 확인
OBSIDIAN_AVAILABLE="false"
if command -v obsidian &>/dev/null; then
    if obsidian eval code="1" &>/dev/null 2>&1; then
        OBSIDIAN_AVAILABLE="true"
    fi
fi

if [ "$OBSIDIAN_AVAILABLE" = "true" ]; then
    # 타임스탬프 기록 (다음 스킵 판단용)
    touch "$LAST_RECORD_FILE"

    echo "{\"result\": \"[Obsidian Daily 기록] Write/Edit ${COUNT}회. 지금까지 작업 내용을 Obsidian Daily 노트에 기록하세요. obsidian daily:append 명령으로 아래 형식을 따르세요:\\n\\n### 세션: ${PROJECT_NAME} ($(date '+%H:%M'))\\n- 작업 내용 요약 (2-5줄)\\n- 주요 결정과 이유\\n- wikilink([[개념명]]) 사용\\n- 태그: #session #${PROJECT_NAME}\\n\\n중복 주의: 이전에 같은 세션에서 이미 기록했으면 이전 내용을 포함하되 업데이트된 내용으로 새 블록을 추가하세요.\", \"suppressOutput\": false}"
else
    echo '{"suppressOutput": true}'
fi
