#!/bin/bash
# Hermes claude-bridge Stop hook.
# Reads {session_id, transcript_path} from stdin payload and signals the bridge
# daemon by dropping a <request_id>.done file in the queue. The daemon resolves
# request_id from its in-memory map keyed by session_id.
# No-op for sessions the bridge isn't tracking (mapping done in daemon).

set -u

QUEUE_DIR="$HOME/.hermes/claude-bridge/queue"
mkdir -p "$QUEUE_DIR"

HOOK_INPUT=$(cat)

SESSION_ID=$(printf '%s' "$HOOK_INPUT" | /usr/bin/python3 -c 'import sys,json
try:
    d=json.load(sys.stdin)
    print(d.get("session_id") or "")
except Exception:
    print("")' 2>/dev/null)

TRANSCRIPT_PATH=$(printf '%s' "$HOOK_INPUT" | /usr/bin/python3 -c 'import sys,json
try:
    d=json.load(sys.stdin)
    print(d.get("transcript_path") or "")
except Exception:
    print("")' 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
    echo '{"suppressOutput": true}'
    exit 0
fi

DONE_FILE="$QUEUE_DIR/${SESSION_ID}.done"
TMP="${DONE_FILE}.tmp"
/usr/bin/python3 - <<PYEOF >"$TMP"
import json
print(json.dumps({
    "session_id": "$SESSION_ID",
    "transcript_path": "$TRANSCRIPT_PATH",
}))
PYEOF
mv "$TMP" "$DONE_FILE"

echo '{"suppressOutput": true}'
