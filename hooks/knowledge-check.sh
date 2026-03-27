#!/bin/bash
# knowledge-check.sh - 세션 전환 감지 및 pending insights 처리 지시
# Hook: UserPromptSubmit (timeout: 5s)
# 세션 ID가 변경되었고 pending insights가 있으면 Claude에게 처리 지시 출력

PENDING_DIR="$HOME/.claude/growth/pending-insights"
LAST_SESSION_FILE="$HOME/.claude/growth/.last-session-id"

# stdin에서 현재 세션 정보 읽기
HOOK_INPUT=$(cat)
CURRENT_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null)

# 이전 세션 ID 읽기
LAST_SESSION=$(cat "$LAST_SESSION_FILE" 2>/dev/null || echo "")

# 현재 세션 ID 저장
if [ -n "$CURRENT_SESSION" ]; then
    mkdir -p "$(dirname "$LAST_SESSION_FILE")"
    echo "$CURRENT_SESSION" > "$LAST_SESSION_FILE"
fi

# pending insights 확인
if [ ! -d "$PENDING_DIR" ]; then
    echo '{"suppressOutput": true}'
    exit 0
fi

PENDING_COUNT=$(find "$PENDING_DIR" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')

# 세션이 전환됐고 pending이 있을 때만 출력
if [ "$PENDING_COUNT" -gt 0 ] && [ "$CURRENT_SESSION" != "$LAST_SESSION" ]; then
    # pending 파일 목록 수집 (최대 5개)
    PENDING_LIST=""
    for f in $(find "$PENDING_DIR" -name "*.json" -type f 2>/dev/null | head -5); do
        if [ -n "$PENDING_LIST" ]; then
            PENDING_LIST="$PENDING_LIST, "
        fi
        PENDING_LIST="$PENDING_LIST$(cat "$f" 2>/dev/null)"
    done

    # Claude에게 처리 지시 출력 (suppressOutput: false)
    cat <<HOOKEOF
{"result": "[Knowledge Extractor] 미처리 세션 ${PENDING_COUNT}건. knowledge-extractor 스킬을 invoke하여 인사이트를 추출하세요. Pending: [${PENDING_LIST}]", "suppressOutput": false}
HOOKEOF
else
    echo '{"suppressOutput": true}'
fi
