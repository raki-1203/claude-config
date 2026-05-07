#!/bin/bash
# session-digest.sh - 세션 종료 시:
#   1. session-log.jsonl 기록
#   2. session-buffer.md → Obsidian daily note flush
#   3. context-summary.md 재생성
#   4. session-buffer.md + tool-counter 초기화
# Hook: SessionEnd (timeout: 5s)

GROWTH_DIR="$HOME/.claude/growth"
LOG_FILE="$GROWTH_DIR/session-log.jsonl"
mkdir -p "$GROWTH_DIR"

HOOK_INPUT=$(cat)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(cd "$PROJECT_DIR" 2>/dev/null && git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||')
[ -z "$PROJECT_NAME" ] && PROJECT_NAME=$(basename "$PROJECT_DIR")
SESSIONS_DIR="$GROWTH_DIR/sessions/$PROJECT_NAME"
BUFFER="$SESSIONS_DIR/session-buffer.md"
SUMMARY="$SESSIONS_DIR/context-summary.md"

DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M:%S')

SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")
if [ -z "$SESSION_ID" ]; then
    SESSION_ID="session-$(date '+%Y%m%d-%H%M%S')"
fi

mkdir -p "$SESSIONS_DIR"

# --- 1. session-log.jsonl 기록 ---
TOOL_STATS="{}"
STATS_FILE="$HOME/.claude/.session-stats.json"
if [ -f "$STATS_FILE" ] && command -v jq &>/dev/null; then
    TOOL_STATS=$(jq -c '.tool_counts // {}' "$STATS_FILE" 2>/dev/null || echo "{}")
fi

if command -v jq &>/dev/null; then
    jq -n -c \
        --arg date "$DATE" \
        --arg time "$TIME" \
        --arg project "$PROJECT_DIR" \
        --arg project_name "$PROJECT_NAME" \
        --arg session_id "$SESSION_ID" \
        --argjson tools "$TOOL_STATS" \
        '{date: $date, time: $time, project: $project, project_name: $project_name, session_id: $session_id, tools: $tools}' >> "$LOG_FILE"
fi

# --- 2. session-buffer.md → Obsidian daily note flush ---
if [ -s "$BUFFER" ]; then
    # buffer에서 frontmatter 제외한 본문 추출
    BODY=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$BUFFER")

    if [ -n "$BODY" ] && command -v obsidian &>/dev/null; then
        if obsidian eval code="1" &>/dev/null 2>&1; then
            FLUSH_CONTENT="\n### 세션: ${PROJECT_NAME} (${TIME})\n${BODY}"
            obsidian daily:append content="$FLUSH_CONTENT" silent 2>/dev/null
        fi
    fi
fi

# --- 3. context-summary.md 재생성 ---
if [ -s "$BUFFER" ]; then
    BUFFER_BODY=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$BUFFER")

    # 기존 summary에서 이전 세션 보존 (최근 3건 유지)
    PREV_SECTION=""
    if [ -f "$SUMMARY" ]; then
        # 기존 "마지막 세션" → 이전 세션으로 강등
        OLD_LAST=$(awk '/^## 마지막 세션/,/^## 이전 세션/' "$SUMMARY" | grep -v '^## ' | head -10)
        OLD_PREV=$(awk '/^## 이전 세션/,0' "$SUMMARY" | tail -n +2 | head -30)

        if [ -n "$OLD_LAST" ]; then
            # 이전 세션 블록 수 카운트
            BLOCK_COUNT=$(echo "$OLD_PREV" | grep -c '^### ' 2>/dev/null || echo "0")
            if [ "$BLOCK_COUNT" -ge 3 ]; then
                # 3건 이상이면 마지막 블록 제거
                OLD_PREV=$(echo "$OLD_PREV" | awk '/^### /{n++} n<=2{print}')
            fi
            PREV_SECTION="### ${DATE}\n${OLD_LAST}\n\n${OLD_PREV}"
        else
            PREV_SECTION="$OLD_PREV"
        fi
    fi

    cat > "$SUMMARY" << SUMEOF
---
updated: ${DATE}T${TIME}
project: $PROJECT_NAME
---

## 마지막 세션 (${DATE} ${TIME})
${BUFFER_BODY}

## 이전 세션 (최근 3건)
$(echo -e "$PREV_SECTION")
SUMEOF
fi

# --- 4. 초기화 ---
echo "" > "$BUFFER"
echo "0" > "$GROWTH_DIR/.tool-counter"

echo '{"suppressOutput": true}'
