# Obsidian Session Memory 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Claude Code 세션의 작업 상태를 자동 기록/복원하여 세션 간, 컴팩션 전후 작업 연속성을 유지하는 시스템 구현

**Architecture:** session-buffer.md(파일시스템)를 중심으로 PostToolUse hook이 반강제 업데이트, PreCompact/PostCompact hook이 컴팩션 복원, SessionEnd hook이 Obsidian flush + context-summary 생성, UserPromptSubmit hook이 다음 세션에서 맥락 로드

**Tech Stack:** Bash (hooks), Obsidian CLI (쓰기), jq (JSON 처리), 파일시스템 (읽기)

**Spec:** `docs/superpowers/specs/2026-03-31-obsidian-session-memory-design.md`

---

### Task 1: 프로젝트별 디렉토리 구조 생성

**Files:**
- Create: `~/.claude/hooks/post-tool-buffer-reminder.sh`
- Create: `~/.claude/hooks/pre-compact.sh`
- Create: `~/.claude/hooks/post-compact.sh`

- [ ] **Step 1: 디렉토리 구조 확인 및 생성**

```bash
mkdir -p ~/.claude/growth/sessions
ls -la ~/.claude/growth/sessions/
```

Expected: 빈 디렉토리 생성 확인

- [ ] **Step 2: Commit**

```bash
# 디렉토리만이므로 커밋 불필요 — 다음 Task에서 파일과 함께 커밋
```

---

### Task 2: PostToolUse hook — 반강제 buffer 업데이트 알림

**Files:**
- Create: `~/.claude/hooks/post-tool-buffer-reminder.sh`

- [ ] **Step 1: hook 스크립트 작성**

`~/.claude/hooks/post-tool-buffer-reminder.sh`:

```bash
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
```

- [ ] **Step 2: 실행 권한 부여**

```bash
chmod +x ~/.claude/hooks/post-tool-buffer-reminder.sh
```

- [ ] **Step 3: 수동 테스트**

```bash
# 카운터를 9로 설정하여 다음 호출에서 트리거 확인
echo "9" > ~/.claude/growth/.tool-counter
echo '{}' | CLAUDE_PROJECT_DIR=/Users/raki-1203/workspace/claude-config bash ~/.claude/hooks/post-tool-buffer-reminder.sh
```

Expected: `suppressOutput: false`와 함께 buffer 업데이트 요청 메시지 출력

```bash
# 카운터가 1일 때는 스킵 확인
echo "0" > ~/.claude/growth/.tool-counter
echo '{}' | CLAUDE_PROJECT_DIR=/Users/raki-1203/workspace/claude-config bash ~/.claude/hooks/post-tool-buffer-reminder.sh
```

Expected: `{"suppressOutput": true}`

---

### Task 3: PreCompact hook — 컴팩션 전 안전장치

**Files:**
- Create: `~/.claude/hooks/pre-compact.sh`

- [ ] **Step 1: hook 스크립트 작성**

`~/.claude/hooks/pre-compact.sh`:

```bash
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
```

- [ ] **Step 2: 실행 권한 부여 및 테스트**

```bash
chmod +x ~/.claude/hooks/pre-compact.sh

# 빈 buffer 상태에서 테스트
mkdir -p ~/.claude/growth/sessions/claude-config
echo "" > ~/.claude/growth/sessions/claude-config/session-buffer.md
echo '{}' | CLAUDE_PROJECT_DIR=/Users/raki-1203/workspace/claude-config bash ~/.claude/hooks/pre-compact.sh
cat ~/.claude/growth/sessions/claude-config/session-buffer.md
```

Expected: fallback 내용이 생성되고, `suppressOutput: false` 메시지 출력

---

### Task 4: PostCompact hook — 컴팩션 후 복원 강제

**Files:**
- Create: `~/.claude/hooks/post-compact.sh`

- [ ] **Step 1: hook 스크립트 작성**

`~/.claude/hooks/post-compact.sh`:

```bash
#!/bin/bash
# post-compact.sh
# Hook: PostCompact
# 컴팩션 완료 후 Claude에게 session-buffer.md 읽기를 강제 지시

HOOK_INPUT=$(cat)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")
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
```

- [ ] **Step 2: 실행 권한 부여 및 테스트**

```bash
chmod +x ~/.claude/hooks/post-compact.sh

# buffer에 테스트 내용 넣고 실행
cat > ~/.claude/growth/sessions/claude-config/session-buffer.md << 'EOF'
---
project: claude-config
last_update: 2026-03-31T19:00:00
---

## 현재 작업
Obsidian Session Memory 시스템 구현

## 진행 상황
- [x] 스펙 문서 작성
- [ ] hook 구현 중
EOF

echo '{}' | CLAUDE_PROJECT_DIR=/Users/raki-1203/workspace/claude-config bash ~/.claude/hooks/post-compact.sh
```

Expected: buffer 내용이 포함된 복원 메시지 출력

---

### Task 5: SessionEnd hook 수정 — buffer flush + context-summary 생성

**Files:**
- Modify: `~/.claude/hooks/session-digest.sh`

- [ ] **Step 1: session-digest.sh 전체 교체**

`~/.claude/hooks/session-digest.sh`:

```bash
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
PROJECT_NAME=$(basename "$PROJECT_DIR")
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
            # 이전 세션 블록 수 카운트 (### 로 시작하는 줄)
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
```

- [ ] **Step 2: 테스트**

```bash
# 테스트용 buffer 생성
cat > ~/.claude/growth/sessions/claude-config/session-buffer.md << 'TESTEOF'
---
project: claude-config
last_update: 2026-03-31T20:00:00
---

## 현재 작업
테스트 세션

## 진행 상황
- [x] 스펙 작성 완료

## 다음 할 일
- hook 구현
TESTEOF

# hook 실행 (SessionEnd 시뮬레이션)
echo '{"session_id": "test-123"}' | CLAUDE_PROJECT_DIR=/Users/raki-1203/workspace/claude-config bash ~/.claude/hooks/session-digest.sh

# context-summary 생성 확인
cat ~/.claude/growth/sessions/claude-config/context-summary.md

# buffer 초기화 확인
cat ~/.claude/growth/sessions/claude-config/session-buffer.md
```

Expected: context-summary.md에 "마지막 세션" 섹션 생성, buffer 초기화

---

### Task 6: UserPromptSubmit hook 수정 — context-summary 파일시스템 로드

**Files:**
- Modify: `~/.claude/hooks/knowledge-check.sh`

- [ ] **Step 1: knowledge-check.sh 전체 교체**

`~/.claude/hooks/knowledge-check.sh`:

```bash
#!/bin/bash
# knowledge-check.sh - 세션 시작 시 context-summary.md 로드
# Hook: UserPromptSubmit (timeout: 5s)
# 세션 첫 메시지에서만 실행: 파일시스템에서 직접 읽기 (Obsidian CLI 의존 없음)

LAST_SESSION_FILE="$HOME/.claude/growth/.last-session-id"

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

# context-summary.md 로드 (파일시스템 직접 읽기 — Obsidian 불필요)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")
SUMMARY="$HOME/.claude/growth/sessions/$PROJECT_NAME/context-summary.md"

if [ -f "$SUMMARY" ] && [ -s "$SUMMARY" ]; then
    CONTENT=$(head -50 "$SUMMARY")
    if command -v jq &>/dev/null; then
        jq -n --arg ctx "[Session Memory] 이전 세션 맥락 (${PROJECT_NAME}):\n$CONTENT" \
            '{"result": $ctx, "suppressOutput": false}'
    else
        echo "{\"result\": \"[Session Memory] context-summary 로드됨 (${PROJECT_NAME})\", \"suppressOutput\": false}"
    fi
else
    echo '{"suppressOutput": true}'
fi
```

- [ ] **Step 2: 테스트**

```bash
# 새 세션 시뮬레이션 (다른 session_id)
echo "old-session" > ~/.claude/growth/.last-session-id
echo '{"session_id": "new-session-456"}' | CLAUDE_PROJECT_DIR=/Users/raki-1203/workspace/claude-config bash ~/.claude/hooks/knowledge-check.sh
```

Expected: context-summary.md 내용이 포함된 `suppressOutput: false` 출력

```bash
# 같은 세션이면 스킵 확인
echo '{"session_id": "new-session-456"}' | CLAUDE_PROJECT_DIR=/Users/raki-1203/workspace/claude-config bash ~/.claude/hooks/knowledge-check.sh
```

Expected: `{"suppressOutput": true}`

---

### Task 7: settings.json에 새 hooks 등록

**Files:**
- Modify: `~/.claude/settings.json`

- [ ] **Step 1: PostToolUse hook 등록**

`settings.json`의 `hooks` 섹션에 추가:

```json
"PostToolUse": [
  {
    "matcher": "tool matches \"Write\" OR tool matches \"Edit\"",
    "hooks": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/post-tool-buffer-reminder.sh",
        "timeout": 5
      }
    ]
  }
],
```

- [ ] **Step 2: PreCompact hook 등록**

```json
"PreCompact": [
  {
    "matcher": "*",
    "hooks": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/pre-compact.sh",
        "timeout": 5
      }
    ]
  }
],
```

- [ ] **Step 3: PostCompact hook 등록**

```json
"PostCompact": [
  {
    "matcher": "*",
    "hooks": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/post-compact.sh",
        "timeout": 5
      }
    ]
  }
],
```

- [ ] **Step 4: JSON 유효성 검증**

```bash
cat ~/.claude/settings.json | jq . > /dev/null && echo "valid" || echo "invalid"
```

Expected: `valid`

---

### Task 8: CLAUDE.md 규칙 업데이트

**Files:**
- Modify: `~/CLAUDE.md`

- [ ] **Step 1: "Obsidian 자동 기록" 섹션을 "Session Memory" 섹션으로 교체**

기존:
```markdown
## Obsidian 자동 기록
- **작업 마일스톤**(커밋, PR, 기능 구현 완료, 버그 수정) 도달 시 Obsidian daily note에 기록:
  ...
```

교체:
```markdown
## Session Memory (Obsidian 연동)

### session-buffer.md 업데이트
- PostToolUse hook이 Write/Edit 10회마다 알림 → `~/.claude/growth/sessions/{project}/session-buffer.md` 업데이트
- 업데이트 내용: 현재 작업, 진행 상황(체크리스트), 주요 결정과 이유, 수정한 파일, 다음 할 일
- wikilink 사용: 개념/기술에 `[[개념명]]` 형태로 링크 — Obsidian 지식 그래프 연결
- hook 알림이 없어도 주요 마일스톤(기능 완성, 방향 전환) 시 자발적 업데이트 권장

### 컴팩션 복원
- PostCompact hook이 buffer 내용을 주입하면 즉시 읽고 작업 맥락 복원
- 복원 후 중단된 작업을 이어서 진행

### 세션 시작
- UserPromptSubmit hook이 주입한 이전 세션 맥락(context-summary.md)을 참고하여 연속성 유지
```

---

### Task 9: 기존 pending 시스템 정리

**Files:**
- Clean up: `~/.claude/growth/pending-insights/` (이미 정리됨)
- Modify: `~/.claude/skills/auto/knowledge-extractor.md` (deprecated 표시)

- [ ] **Step 1: pending 디렉토리 정리 확인**

```bash
ls ~/.claude/growth/pending-insights/ 2>/dev/null | wc -l
```

Expected: 0 (이미 이 세션에서 정리됨)

- [ ] **Step 2: knowledge-extractor 스킬에 deprecated 표시**

`~/.claude/skills/auto/knowledge-extractor.md` 상단에 추가:

```markdown
> **DEPRECATED**: Session Memory 시스템(session-buffer.md + hooks)으로 대체됨 (2026-03-31).
> 이 스킬은 더 이상 사용되지 않음. pending-insights 큐 방식은 제거됨.
```

- [ ] **Step 3: repo의 hooks 디렉토리에 새 파일 복사**

```bash
cp ~/.claude/hooks/post-tool-buffer-reminder.sh /Users/raki-1203/workspace/claude-config/hooks/
cp ~/.claude/hooks/pre-compact.sh /Users/raki-1203/workspace/claude-config/hooks/
cp ~/.claude/hooks/post-compact.sh /Users/raki-1203/workspace/claude-config/hooks/
cp ~/.claude/hooks/session-digest.sh /Users/raki-1203/workspace/claude-config/hooks/
cp ~/.claude/hooks/knowledge-check.sh /Users/raki-1203/workspace/claude-config/hooks/
```

---

### Task 10: E2E 검증

- [ ] **Step 1: 전체 흐름 시뮬레이션**

```bash
# 1. 깨끗한 상태에서 시작
echo "" > ~/.claude/growth/sessions/claude-config/session-buffer.md
echo "0" > ~/.claude/growth/.tool-counter
rm -f ~/.claude/growth/sessions/claude-config/context-summary.md

# 2. PostToolUse 10회 트리거
echo "9" > ~/.claude/growth/.tool-counter
echo '{}' | CLAUDE_PROJECT_DIR=/Users/raki-1203/workspace/claude-config bash ~/.claude/hooks/post-tool-buffer-reminder.sh
echo "--- PostToolUse: buffer 업데이트 요청 확인 ---"

# 3. buffer에 내용 작성 (Claude가 하는 부분 시뮬레이션)
cat > ~/.claude/growth/sessions/claude-config/session-buffer.md << 'EOF'
---
project: claude-config
session_start: 2026-03-31T20:00:00
last_update: 2026-03-31T20:30:00
update_count: 3
---

## 현재 작업
Obsidian Session Memory 시스템 구현

## 진행 상황
- [x] 스펙 문서 작성
- [x] hook 스크립트 작성
- [ ] settings.json 등록

## 주요 결정
- 읽기는 파일시스템, 쓰기는 [[Obsidian]] CLI — 하이브리드 방식
- [[PostToolUse]] hook으로 반강제 업데이트

## 수정한 파일
- `~/.claude/hooks/post-tool-buffer-reminder.sh` — 반강제 알림
- `~/.claude/hooks/pre-compact.sh` — 컴팩션 안전장치
- `~/.claude/hooks/post-compact.sh` — 컴팩션 복원

## 다음 할 일
- settings.json에 hook 등록
- E2E 테스트
EOF

# 4. PreCompact 시뮬레이션 (buffer가 있는 상태)
echo '{}' | CLAUDE_PROJECT_DIR=/Users/raki-1203/workspace/claude-config bash ~/.claude/hooks/pre-compact.sh
echo "--- PreCompact: 복원 안내 확인 ---"

# 5. PostCompact 시뮬레이션
echo '{}' | CLAUDE_PROJECT_DIR=/Users/raki-1203/workspace/claude-config bash ~/.claude/hooks/post-compact.sh
echo "--- PostCompact: buffer 내용 주입 확인 ---"

# 6. SessionEnd 시뮬레이션
echo '{"session_id": "e2e-test-001"}' | CLAUDE_PROJECT_DIR=/Users/raki-1203/workspace/claude-config bash ~/.claude/hooks/session-digest.sh
echo "--- SessionEnd: context-summary 생성 확인 ---"
cat ~/.claude/growth/sessions/claude-config/context-summary.md

# 7. 다음 세션 시뮬레이션
echo "old-session" > ~/.claude/growth/.last-session-id
echo '{"session_id": "e2e-test-002"}' | CLAUDE_PROJECT_DIR=/Users/raki-1203/workspace/claude-config bash ~/.claude/hooks/knowledge-check.sh
echo "--- UserPromptSubmit: 맥락 로드 확인 ---"
```

- [ ] **Step 2: 검증 기준**

| 단계 | 기대 결과 |
|------|----------|
| PostToolUse 10회 | buffer 업데이트 요청 메시지 출력 |
| PreCompact (buffer 있음) | 복원 안내 메시지 출력, buffer 유지 |
| PostCompact | buffer 내용이 포함된 복원 메시지 출력 |
| SessionEnd | context-summary.md 생성, buffer 초기화 |
| UserPromptSubmit (새 세션) | context-summary 내용 로드 |

- [ ] **Step 3: Commit**

```bash
git add hooks/ docs/
git commit -m "feat: Obsidian Session Memory 시스템 구현

- PostToolUse hook: Write/Edit 10회마다 buffer 업데이트 반강제
- PreCompact hook: 컴팩션 전 buffer 안전장치
- PostCompact hook: 컴팩션 후 맥락 복원 강제
- SessionEnd hook: buffer → Obsidian flush + context-summary 생성
- UserPromptSubmit hook: context-summary 파일시스템 로드"
```
