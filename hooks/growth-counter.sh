#!/bin/bash
# growth-counter.sh - Stop hook에서 세션 카운터 증가
COUNTER_FILE="$HOME/.claude/growth/session-counter"
mkdir -p "$(dirname "$COUNTER_FILE")"
count=$(($(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1))
echo "$count" > "$COUNTER_FILE"
echo '{"suppressOutput": true}'
