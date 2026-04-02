#!/bin/bash
# knowledge-check.sh - 세션 시작 시:
#   1. context-summary.md 로드 (이전 세션 맥락)
#   2. Daily digest 미처리 감지 → Claude에게 정리 지시
# Hook: UserPromptSubmit (timeout: 5s)

LAST_SESSION_FILE="$HOME/.claude/growth/.last-session-id"
DIGEST_LAST_FILE="$HOME/.claude/growth/.daily-digest-last"

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

# --- 결과 수집 ---
RESULTS=()

# --- 1. context-summary.md 로드 ---
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(cd "$PROJECT_DIR" 2>/dev/null && git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||')
[ -z "$PROJECT_NAME" ] && PROJECT_NAME=$(basename "$PROJECT_DIR")
SUMMARY="$HOME/.claude/growth/sessions/$PROJECT_NAME/context-summary.md"

if [ -f "$SUMMARY" ] && [ -s "$SUMMARY" ]; then
    CONTENT=$(head -50 "$SUMMARY")
    RESULTS+=("[Session Memory] 이전 세션 맥락 (${PROJECT_NAME}):\n$CONTENT")
fi

# --- 2. Daily digest 미처리 감지 ---
TODAY=$(date '+%Y-%m-%d')
LAST_DIGEST=$(cat "$DIGEST_LAST_FILE" 2>/dev/null || echo "")

if [ "$TODAY" != "$LAST_DIGEST" ]; then
    # Obsidian vault의 Daily 폴더에서 미처리 날짜 탐색
    VAULT_DAILY="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/vault/Daily"

    if [ -d "$VAULT_DAILY" ]; then
        UNPROCESSED=()
        for daily_file in "$VAULT_DAILY"/*.md; do
            [ -f "$daily_file" ] || continue
            FNAME=$(basename "$daily_file" .md)
            # 오늘 날짜는 스킵 (아직 작업 중)
            [ "$FNAME" = "$TODAY" ] && continue
            # 마지막 처리 이후 날짜만
            if [ -z "$LAST_DIGEST" ] || [[ "$FNAME" > "$LAST_DIGEST" ]]; then
                # 세션 블록이 있는 파일만 (빈 daily 스킵)
                if grep -q '### 세션:' "$daily_file" 2>/dev/null; then
                    UNPROCESSED+=("$FNAME")
                fi
            fi
        done

        if [ ${#UNPROCESSED[@]} -gt 0 ]; then
            DATES_STR=$(IFS=', '; echo "${UNPROCESSED[*]}")
            RESULTS+=("[Daily Digest] 미처리 Daily 노트 발견: ${DATES_STR}\n→ /daily-digest 스킬을 실행하여 프로젝트별 세션 노트와 개념 노트를 생성해주세요.")
        fi
    fi
fi

# --- 결과 출력 ---
if [ ${#RESULTS[@]} -gt 0 ]; then
    COMBINED=""
    for r in "${RESULTS[@]}"; do
        COMBINED="${COMBINED}${r}\n\n"
    done
    if command -v jq &>/dev/null; then
        jq -n --arg ctx "$COMBINED" \
            '{"result": $ctx, "suppressOutput": false}'
    else
        echo "{\"result\": \"[Session Memory + Digest] 로드됨\", \"suppressOutput\": false}"
    fi
else
    echo '{"suppressOutput": true}'
fi
