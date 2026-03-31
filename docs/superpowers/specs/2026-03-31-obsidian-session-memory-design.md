# Obsidian Session Memory System

Claude Code 세션의 작업 내역을 자동으로 Obsidian에 기록하고, 다음 세션에서 맥락을 자동 로드하며, 컨텍스트 컴팩션 시에도 작업 연속성을 유지하는 시스템.

## 배경

### 해결하는 문제

1. **세션 단절**: 세션이 끝나면 "무엇을 했는지, 왜 그렇게 결정했는지, 다음에 뭘 해야 하는지"가 사라짐
2. **컴팩션 망각**: 긴 세션에서 컨텍스트 압축 시 진행 중인 작업 맥락을 잃음
3. **지식 축적 부재**: 해결한 문제와 배운 것이 체계적으로 쌓이지 않음

### 설계 원칙

- **쓰기는 Obsidian CLI** — wikilink 자동 갱신, Properties, 백링크 등 Obsidian 고유 가치 활용
- **읽기는 파일시스템** — hook의 5초 제한 내에서 확실하게 (`cat` < 10ms)
- **Claude 자율 의존 최소화** — hook 기반 반강제 메커니즘으로 신뢰성 확보
- **Obsidian 미실행 시 graceful degradation** — 파이프라인 중단 없이 fallback

## 아키텍처

```
┌─ 세션 중 ─────────────────────────────────────────────┐
│                                                        │
│  Claude 작업 진행                                       │
│    │                                                   │
│    ├─ [PostToolUse hook] Write/Edit 10회마다            │
│    │   → "session-buffer.md 업데이트하라" 메시지 주입    │
│    │                                                   │
│    ├─ [Claude] session-buffer.md 업데이트               │
│    │   (현재 작업, 진행 상황, 결정, 수정 파일, 다음 할일) │
│    │                                                   │
│    ├─ [PreCompact hook] 컴팩션 직전                     │
│    │   → buffer 최신 여부 확인, stale이면 메타데이터 보강 │
│    │                                                   │
│    └─ [PostCompact hook] 컴팩션 직후                    │
│        → "session-buffer.md 읽어서 맥락 복원하라" 주입   │
│                                                        │
└────────────────────────────────────────────────────────┘
                    │ 세션 종료
                    ▼
┌─ SessionEnd hook (5초) ───────────────────────────────┐
│  1. session-buffer.md 읽기 (파일시스템 직접)            │
│  2. Obsidian daily note에 flush (CLI)                  │
│     - wikilink로 개념 연결: [[Redis 캐시]], [[JWT]]     │
│     - Properties: project, session_id, date            │
│  3. ContextSummary.md 재생성 (파일시스템 직접 쓰기)     │
│  4. session-buffer.md 초기화                           │
│  * Obsidian 미실행 시 → 2번 스킵, 나머지 정상 실행     │
└───────────────────────────────────────────────────────┘
                    │ 다음 세션
                    ▼
┌─ UserPromptSubmit hook (첫 메시지, 5초) ──────────────┐
│  1. ContextSummary.md 읽기 (파일시스템 직접)            │
│  2. 컨텍스트로 주입                                    │
└───────────────────────────────────────────────────────┘
```

## 파일 구조

### 프로젝트별 격리

```
~/.claude/growth/sessions/
  {project-name}/
    session-buffer.md      # 현재 세션 상태 (1개, 덮어쓰기)
    context-summary.md     # 다음 세션 로드용 (SessionEnd에서 재생성)

Obsidian vault:
  Daily/
    2026-03-31.md          # daily note (세션 기록 append)
  1-Projects/
    {project-name}.md      # 프로젝트 노트 (현재 상태, 다음 할 일)
```

### session-buffer.md

Claude가 세션 중 업데이트하는 작업 상태 파일. 컴팩션 복원의 핵심.

```markdown
---
project: kt-innovation-hub
session_id: abc-123
session_start: 2026-03-31T18:00:00
last_update: 2026-03-31T19:23:00
update_count: 5
---

## 현재 작업
JWT refresh 미들웨어 구현

## 진행 상황
- [x] 토큰 검증 로직 작성 (`src/middleware/auth.ts`)
- [x] refresh 엔드포인트 추가 (`src/routes/auth.ts`)
- [ ] [[Redis 캐시]] 연동

## 주요 결정
- RS256 선택 — 멀티서비스 환경에서 공개키만으로 검증 가능
- refresh token은 httpOnly cookie에 저장 — XSS 방지

## 수정한 파일
- `src/middleware/auth.ts` — [[JWT]] 검증 미들웨어 추가
- `src/routes/auth.ts` — `/refresh` 엔드포인트

## 다음 할 일
- [[Redis 캐시]] 연동 후 통합 테스트 작성
- 만료 시간 설정값 환경변수로 분리
```

### context-summary.md

SessionEnd hook이 생성. 다음 세션의 UserPromptSubmit hook이 읽음.

```markdown
---
updated: 2026-03-31T19:30:00
project: kt-innovation-hub
---

## 마지막 세션 (2026-03-31 18:00-19:30)
JWT refresh 미들웨어 구현. RS256 선택, httpOnly cookie 사용.
남은 작업: [[Redis 캐시]] 연동 + 통합 테스트.

## 이전 세션 (최근 3건)

### 2026-03-28
토큰 refresh [[race condition]] 디버깅 완료.
원인: 동시 요청 시 refresh token 이중 사용.

### 2026-03-25
초기 스캐폴딩. [[FastAPI]] + [[React]] 기본 구조 세팅.
```

### Obsidian daily note에 flush되는 형태

```markdown
### 세션: kt-innovation-hub (18:00-19:30)
- JWT refresh 미들웨어 구현 완료
- RS256 선택 (멀티서비스 대응), httpOnly cookie
- 수정: `src/middleware/auth.ts`, `src/routes/auth.ts`
- 다음: [[Redis 캐시]] 연동, 통합 테스트
- 결정 배경: [[JWT]] RS256 vs HS256 → 공개키 검증이 서비스 간 공유에 유리
```

wikilink(`[[Redis 캐시]]`, `[[JWT]]`)를 사용하여 Obsidian의 백링크/그래프 기능 활용.

## Hook 설계

### 1. PostToolUse hook — 반강제 buffer 업데이트

Write/Edit 도구 사용 횟수를 카운트하고, 10회마다 Claude에게 업데이트 요청.

```bash
# post-tool-buffer-reminder.sh
# Hook: PostToolUse, matcher: "Write OR Edit"

COUNTER_FILE="$HOME/.claude/growth/.tool-counter"
COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

if [ $((COUNT % 10)) -eq 0 ]; then
    PROJECT_NAME=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")
    BUFFER="$HOME/.claude/growth/sessions/$PROJECT_NAME/session-buffer.md"
    
    if [ ! -f "$BUFFER" ] || [ "$(stat -f %m "$BUFFER" 2>/dev/null || echo 0)" -lt "$(date -v-10M +%s 2>/dev/null || echo 999999999)" ]; then
        echo "{\"result\": \"[Session Buffer] Write/Edit ${COUNT}회 실행됨. ~/.claude/growth/sessions/${PROJECT_NAME}/session-buffer.md를 현재 작업 상태로 업데이트하세요.\", \"suppressOutput\": false}"
    else
        echo '{"suppressOutput": true}'
    fi
else
    echo '{"suppressOutput": true}'
fi
```

### 2. PreCompact hook — 컴팩션 전 안전장치

buffer가 비어있거나 오래됐으면 최소 메타데이터라도 기록.

```bash
# pre-compact.sh
# Hook: PreCompact

PROJECT_NAME=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")
BUFFER="$HOME/.claude/growth/sessions/$PROJECT_NAME/session-buffer.md"
mkdir -p "$(dirname "$BUFFER")"

# buffer가 없거나 비어있으면 최소 정보 기록
if [ ! -s "$BUFFER" ]; then
    # 최근 수정된 파일 목록을 git에서 추출
    MODIFIED=$(cd "${CLAUDE_PROJECT_DIR:-$(pwd)}" && git diff --name-only HEAD 2>/dev/null | head -10 | sed 's/^/- /' || echo "- (추적 불가)")
    
    cat > "$BUFFER" << BUFEOF
---
project: $PROJECT_NAME
session_start: unknown
last_update: $(date '+%Y-%m-%dT%H:%M:%S')
source: pre-compact-fallback
---

## 현재 작업
(컴팩션 전 자동 캡처 — Claude가 buffer를 업데이트하지 않았음)

## 수정한 파일
$MODIFIED

## 다음 할 일
(buffer 미업데이트로 정보 부족)
BUFEOF
fi

echo "{\"result\": \"[PreCompact] 컨텍스트 압축 시작. 압축 후 ~/.claude/growth/sessions/${PROJECT_NAME}/session-buffer.md를 읽어 작업 맥락을 복원하세요.\", \"suppressOutput\": false}"
```

### 3. PostCompact hook — 컴팩션 후 복원 강제

```bash
# post-compact.sh
# Hook: PostCompact

PROJECT_NAME=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")
BUFFER="$HOME/.claude/growth/sessions/$PROJECT_NAME/session-buffer.md"

if [ -f "$BUFFER" ]; then
    CONTENT=$(cat "$BUFFER" | head -50)
    echo "{\"result\": \"[PostCompact] 컨텍스트가 압축되었습니다. 작업 연속성을 위해 아래 session-buffer를 읽고 작업을 이어가세요:\\n${CONTENT}\", \"suppressOutput\": false}"
else
    echo "{\"result\": \"[PostCompact] 컨텍스트 압축됨. session-buffer 없음 — 사용자에게 현재 작업을 확인하세요.\", \"suppressOutput\": false}"
fi
```

### 4. SessionEnd hook — Obsidian flush + context-summary 재생성

```bash
# session-digest.sh (수정)
# Hook: SessionEnd (timeout: 5)

PROJECT_NAME=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")
SESSIONS_DIR="$HOME/.claude/growth/sessions/$PROJECT_NAME"
BUFFER="$SESSIONS_DIR/session-buffer.md"
SUMMARY="$SESSIONS_DIR/context-summary.md"
DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M:%S')

mkdir -p "$SESSIONS_DIR"

# 1. session-log.jsonl 기록 (기존 유지)
# ... (생략, 기존 코드)

# 2. Obsidian daily note에 flush
if [ -s "$BUFFER" ] && command -v obsidian &>/dev/null; then
    if obsidian eval code="1" &>/dev/null 2>&1; then
        # buffer에서 frontmatter 제외한 본문 추출
        BODY=$(sed '1,/^---$/d' "$BUFFER" | sed '1,/^---$/d')
        FLUSH_CONTENT="\n### 세션: ${PROJECT_NAME} (${TIME})\n${BODY}"
        obsidian daily:append content="$FLUSH_CONTENT" silent 2>/dev/null
    fi
fi

# 3. context-summary.md 재생성
if [ -s "$BUFFER" ]; then
    # 현재 buffer 내용을 "마지막 세션"으로
    BUFFER_BODY=$(sed '1,/^---$/d' "$BUFFER" | sed '1,/^---$/d')
    
    # 기존 summary의 "마지막 세션"을 "이전 세션"으로 이동
    PREV_SESSIONS=""
    if [ -f "$SUMMARY" ]; then
        PREV_SESSIONS=$(sed -n '/^## 이전 세션/,$ p' "$SUMMARY" | head -30)
        LAST_SESSION=$(sed -n '/^## 마지막 세션/,/^## 이전 세션/ p' "$SUMMARY" | head -10)
        if [ -n "$LAST_SESSION" ]; then
            PREV_SESSIONS="### ${DATE}\n$(echo "$LAST_SESSION" | tail -n +2)\n\n${PREV_SESSIONS}"
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
$(echo -e "$PREV_SESSIONS" | head -40)
SUMEOF
fi

# 4. buffer 초기화
echo "" > "$BUFFER"

# 5. tool counter 리셋
echo "0" > "$HOME/.claude/growth/.tool-counter"

echo '{"suppressOutput": true}'
```

### 5. UserPromptSubmit hook — 세션 시작 시 맥락 로드

```bash
# knowledge-check.sh (수정)
# Hook: UserPromptSubmit (timeout: 5)

LAST_SESSION_FILE="$HOME/.claude/growth/.last-session-id"
HOOK_INPUT=$(cat)
CURRENT_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null)
LAST_SESSION=$(cat "$LAST_SESSION_FILE" 2>/dev/null || echo "")

if [ -n "$CURRENT_SESSION" ]; then
    mkdir -p "$(dirname "$LAST_SESSION_FILE")"
    echo "$CURRENT_SESSION" > "$LAST_SESSION_FILE"
fi

# 같은 세션이면 스킵
if [ "$CURRENT_SESSION" = "$LAST_SESSION" ]; then
    echo '{"suppressOutput": true}'
    exit 0
fi

# 첫 메시지: context-summary.md 로드 (파일시스템 직접 읽기)
PROJECT_NAME=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")
SUMMARY="$HOME/.claude/growth/sessions/$PROJECT_NAME/context-summary.md"

if [ -f "$SUMMARY" ] && [ -s "$SUMMARY" ]; then
    CONTENT=$(head -50 "$SUMMARY")
    jq -n --arg ctx "[Obsidian Session Memory] 이전 세션 맥락:\n$CONTENT" \
        '{"result": $ctx, "suppressOutput": false}'
else
    echo '{"suppressOutput": true}'
fi
```

## CLAUDE.md 규칙

`~/CLAUDE.md`에 추가:

```markdown
## Obsidian Session Memory

### session-buffer.md 업데이트
- PostToolUse hook이 Write/Edit 10회마다 알림을 주면 `~/.claude/growth/sessions/{project}/session-buffer.md`를 업데이트
- 업데이트 내용: 현재 작업, 진행 상황(체크리스트), 주요 결정과 이유, 수정한 파일, 다음 할 일
- wikilink 사용: 개념/기술에 `[[개념명]]` 형태로 — Obsidian 지식 그래프 연결용
- Obsidian 미실행 시에도 buffer 파일은 정상 업데이트 (파일시스템 기반)

### 컴팩션 복원
- PostCompact hook이 "session-buffer를 읽어라" 지시를 주면 즉시 파일을 읽고 작업 맥락 복원
- 복원 후 중단된 작업을 이어서 진행

### 세션 시작
- UserPromptSubmit hook이 주입한 이전 세션 맥락(context-summary.md)을 참고하여 작업 연속성 유지
```

## 엣지 케이스 처리

### 동시 세션 (tmux)
- 프로젝트별 디렉토리 분리로 해결
- 같은 프로젝트에서 2개 세션 → session-buffer.md에 `session_id` 포함, 마지막 쓰기 우선 (last-write-wins)
- 완벽한 동시성 제어는 비용 대비 효과 낮으므로 하지 않음

### 비정상 종료 (crash, 네트워크 끊김)
- SessionEnd hook 미실행 → buffer에 stale 데이터 잔존
- 다음 세션 시작 시 UserPromptSubmit hook이 context-summary.md를 로드 (이전 정상 세션 기준)
- stale buffer 감지: `session_id`가 현재와 다르면 이전 세션의 미완료 작업으로 처리

### Obsidian 미실행
- SessionEnd hook: Obsidian flush 단계만 스킵, context-summary.md는 파일시스템으로 정상 생성
- buffer 업데이트: 영향 없음 (파일시스템 기반)
- daily note flush: Obsidian 실행 후 수동 또는 다음 세션에서 처리

### session-log.jsonl 증가 (현재 413KB)
- 즉시 대응 불필요 — 읽기 대상이 아님 (hook이 읽는 건 context-summary.md뿐)
- 향후 월 1회 로테이션으로 충분

## 주기적 압축 (Phase 2, 향후 구현)

주 1회 cron 또는 수동:

```
Daily entries (7일치) → Weekly summary (LLM 요약)
Weekly summaries (4주치) → Monthly summary
3개월 이상 daily entries → archive 폴더로 이동
```

context-summary.md는 항상 "최근 3건"만 유지하므로 자동으로 크기 제한됨.

## Smart Connections MCP (Phase 3, 향후 검토)

Obsidian에 노트가 충분히 쌓이면 (100+ 세션 노트) 시맨틱 검색 도입:
- `semantic_search("race condition 해결")` → 과거 관련 세션 자동 발견
- 기존 Smart Connections 임베딩 재사용 (재인덱싱 불필요)
- UserPromptSubmit hook에서 현재 프로젝트 + 작업 키워드로 관련 노트 검색

## 구현 범위

### Phase 1 (이번 구현)
1. session-buffer.md 구조 및 CLAUDE.md 규칙
2. PostToolUse hook (반강제 buffer 업데이트)
3. PreCompact / PostCompact hook (컴팩션 복원)
4. SessionEnd hook 수정 (Obsidian flush + context-summary 생성)
5. UserPromptSubmit hook 수정 (context-summary 로드)
6. 기존 pending-insights 시스템 제거

### Phase 2 (향후)
- 주간/월간 압축 cron
- Obsidian 프로젝트 노트 자동 업데이트

### Phase 3 (향후)
- Smart Connections MCP 연동
- 시맨틱 검색 기반 맥락 로드
