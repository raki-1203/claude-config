#!/bin/bash
# pre-compact.sh
# Hook: PreCompact
# 컴팩션 직전에 session-buffer.md가 비어있으면 최소 메타데이터 기록

HOOK_INPUT=$(cat)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")
BUFFER="$HOME/.claude/growth/sessions/$PROJECT_NAME/session-buffer.md"
mkdir -p "$(dirname "$BUFFER")"

DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M:%S')

# buffer가 이미 내용이 있으면 그대로 유지
if [ -s "$BUFFER" ]; then
    echo "{\"result\": \"[PreCompact] 컨텍스트 압축 시작. 압축 후 ~/.claude/growth/sessions/${PROJECT_NAME}/session-buffer.md를 읽어 작업 맥락을 복원하세요.\", \"suppressOutput\": false}"
    exit 0
fi

# buffer가 비어있으면 git diff에서 최소 정보 수집
MODIFIED=""
if [ -d "$PROJECT_DIR/.git" ] || git -C "$PROJECT_DIR" rev-parse --git-dir &>/dev/null 2>&1; then
    MODIFIED=$(cd "$PROJECT_DIR" && git diff --name-only HEAD 2>/dev/null | head -10 | sed 's/^/- `/' | sed 's/$/`/')
fi
if [ -z "$MODIFIED" ]; then
    MODIFIED="- (변경 파일 추적 불가)"
fi

cat > "$BUFFER" << BUFEOF
---
project: $PROJECT_NAME
session_start: unknown
last_update: ${DATE}T${TIME}
source: pre-compact-fallback
---

## 현재 작업
(컴팩션 전 자동 캡처 — Claude가 buffer를 업데이트하지 않음)

## 수정한 파일
$MODIFIED

## 다음 할 일
(buffer 미업데이트로 정보 부족 — 사용자에게 확인 필요)
BUFEOF

echo "{\"result\": \"[PreCompact] 컨텍스트 압축 시작. buffer가 비어있어 git diff 기반 fallback 생성. 압축 후 ~/.claude/growth/sessions/${PROJECT_NAME}/session-buffer.md를 읽어 작업 맥락을 복원하세요.\", \"suppressOutput\": false}"
