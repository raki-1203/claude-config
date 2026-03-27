#!/bin/bash

# session-digest.sh - 세션 종료 시 경량 메타데이터를 수집하여 session-log.jsonl에 기록
# Hook: SessionEnd (timeout: 5s)
# LLM 호출 없이 순수 shell로 동작

GROWTH_DIR="$HOME/.claude/growth"
LOG_FILE="$GROWTH_DIR/session-log.jsonl"

# growth 디렉토리 보장
mkdir -p "$GROWTH_DIR"

# stdin에서 hook input 읽기
HOOK_INPUT=$(cat)

# 프로젝트 정보
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")

# 날짜/시간
DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M:%S')

# session-stats에서 도구 사용 통계 추출 (있으면)
STATS_FILE="$HOME/.claude/.session-stats.json"
TOOL_STATS="{}"
if [ -f "$STATS_FILE" ] && command -v jq &>/dev/null; then
    TOOL_STATS=$(jq -c '.tool_counts // {}' "$STATS_FILE" 2>/dev/null || echo "{}")
fi

# 세션 ID (hook input에서 추출 시도, 없으면 타임스탬프 기반)
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")
if [ -z "$SESSION_ID" ]; then
    SESSION_ID="session-$(date '+%Y%m%d-%H%M%S')"
fi

# JSONL 한 줄 기록
if command -v jq &>/dev/null; then
    jq -n -c \
        --arg date "$DATE" \
        --arg time "$TIME" \
        --arg project "$PROJECT_DIR" \
        --arg project_name "$PROJECT_NAME" \
        --arg session_id "$SESSION_ID" \
        --argjson tools "$TOOL_STATS" \
        '{
            date: $date,
            time: $time,
            project: $project,
            project_name: $project_name,
            session_id: $session_id,
            tools: $tools
        }' >> "$LOG_FILE"
else
    # jq가 없으면 기본 형태로 기록
    echo "{\"date\":\"$DATE\",\"time\":\"$TIME\",\"project\":\"$PROJECT_DIR\",\"project_name\":\"$PROJECT_NAME\",\"session_id\":\"$SESSION_ID\"}" >> "$LOG_FILE"
fi

# --- Knowledge Extractor: pending insights 파일 생성 ---
PENDING_DIR="$GROWTH_DIR/pending-insights"
mkdir -p "$PENDING_DIR"

# transcript 경로 (hook input 또는 환경변수에서)
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")
if [ -z "$TRANSCRIPT_PATH" ]; then
    TRANSCRIPT_PATH="${CLAUDE_TRANSCRIPT_PATH:-}"
fi

# transcript 경로가 있고 파일이 존재하면 pending 생성
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    if command -v jq &>/dev/null; then
        jq -n -c \
            --arg session_id "$SESSION_ID" \
            --arg transcript "$TRANSCRIPT_PATH" \
            --arg project "$PROJECT_DIR" \
            --arg project_name "$PROJECT_NAME" \
            --arg date "$DATE" \
            --arg time "$TIME" \
            '{session_id: $session_id, transcript: $transcript, project: $project, project_name: $project_name, date: $date, time: $time}' \
            > "$PENDING_DIR/${SESSION_ID}.json"
    fi
fi

echo '{"suppressOutput": true}'
