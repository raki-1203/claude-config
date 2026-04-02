#!/bin/bash
# post-compact.sh
# Hook: PostCompact
# 컴팩션 완료 후 Claude에게 session-buffer.md 읽기를 강제 지시

HOOK_INPUT=$(cat)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(cd "$PROJECT_DIR" 2>/dev/null && git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||')
[ -z "$PROJECT_NAME" ] && PROJECT_NAME=$(basename "$PROJECT_DIR")
BUFFER="$HOME/.claude/growth/sessions/$PROJECT_NAME/session-buffer.md"

if [ -f "$BUFFER" ] && [ -s "$BUFFER" ]; then
    # buffer 내용을 직접 주입 (50줄 제한)
    CONTENT=$(head -50 "$BUFFER")
    if command -v jq &>/dev/null; then
        jq -n --arg ctx "[PostCompact] 컨텍스트 압축 완료. 아래 session-buffer로 작업 맥락을 복원하고 중단된 작업을 이어가세요:\n\n$CONTENT" \
            '{"result": $ctx, "suppressOutput": false}'
    else
        echo "{\"result\": \"[PostCompact] 컨텍스트 압축 완료. ~/.claude/growth/sessions/${PROJECT_NAME}/session-buffer.md를 읽어 작업을 이어가세요.\", \"suppressOutput\": false}"
    fi
else
    echo "{\"result\": \"[PostCompact] 컨텍스트 압축 완료. session-buffer 없음 — 사용자에게 현재 작업을 확인하세요.\", \"suppressOutput\": false}"
fi
