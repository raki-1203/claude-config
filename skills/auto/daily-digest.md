---
name: daily-digest
description: "전날 Daily 노트를 분석하여 프로젝트별 세션 노트 + 개념 노트를 Obsidian에 생성"
auto-generated: true
created: 2026-04-01
scope: global
trigger: "knowledge-check.sh 훅이 미처리 Daily 감지 시 자동 안내"
---

# Daily Digest — Obsidian 지식 정리

세션 종료 시 Daily 노트에 쌓인 세션 로그를 프로젝트별로 분류하고, 개념 노트를 추출하여 Obsidian 지식 그래프를 구축한다.

## 실행 조건

- `knowledge-check.sh` 훅이 미처리 Daily 노트를 감지하면 이 스킬 실행을 안내함
- 안내 메시지에 미처리 날짜 목록이 포함됨

## 처리 절차

### 1단계: Daily 노트 로드

```bash
# Obsidian vault 경로
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/vault"

# 해당 날짜의 Daily 노트 읽기
cat "$VAULT/Daily/YYYY-MM-DD.md"
```

Read 도구로 직접 읽어도 됨. Obsidian CLI 불필요.

### 2단계: 프로젝트별 세션 분류

Daily 노트에서 `### 세션: {프로젝트명} ({시간})` 블록을 기준으로 파싱.
각 블록을 프로젝트명으로 그룹핑.

### 3단계: 프로젝트 세션 노트 생성

각 프로젝트에 대해:

```bash
# 프로젝트 폴더 확인/생성
obsidian create \
  name="YYYY-MM-DD" \
  path="1-Projects/{프로젝트명}/sessions/YYYY-MM-DD.md" \
  content="..." \
  silent
```

**노트 형식:**

```markdown
---
date: YYYY-MM-DD
project: {프로젝트명}
tags: [session-log]
---

# YYYY-MM-DD 세션

## 작업 내용
- {세션에서 한 일을 2-5줄로 요약}

## 주요 결정
- {왜 이렇게 했는지, 어떤 선택을 했는지}

## 관련 개념
- [[개념 A]]
- [[개념 B]]
```

**작성 규칙:**
- Daily 원문을 그대로 복사하지 않음. 핵심만 추출하여 재구성
- "작업 내용"은 동작 변화 중심 (코드 diff 나열 X)
- "주요 결정"은 왜 그 방향을 택했는지 이유 포함
- 같은 날 같은 프로젝트에 여러 세션이 있으면 하나로 합침

### 4단계: 개념 노트 추출

세션 내용을 분석하여 지식으로 남길 만한 개념을 추출.

**추출 대상:**
1. 새로 알게 된 개념/패턴/도구
2. 문제 해결 과정 (삽질 → 해결 흐름)
3. 설계 결정과 그 이유
4. 실패에서 배운 것

**추출 제외:**
- 단순 파일 수정 이력 (git log로 충분)
- 이미 Obsidian에 노트로 존재하는 내용 (중복 방지)
- 공식 문서에 있는 기본 사용법
- 단순 설정 변경/오타 수정

**추출 개수:**
- 짧은 세션: 0-1개
- 보통 세션: 1-3개
- 긴 세션: 2-5개
- 배운 게 없으면 0개. 억지로 만들지 않는다.

**중복 체크:**

```bash
# 생성 전 기존 노트 검색
obsidian search query="{개념 키워드}" limit=5
```

이미 존재하면 append, 없으면 create.

**개념 노트 형식:**

```bash
obsidian create \
  name="{개념 이름}" \
  path="3-Resources/{개념 이름}.md" \
  content="..." \
  silent
```

```markdown
---
tags: [resource]
created: YYYY-MM-DD
related_projects: [{프로젝트명}]
---

# {개념 이름}

{1-3문장 핵심 설명}

## 핵심 내용
- {배운 것 1}
- {배운 것 2}

## 맥락
{어떤 작업에서 이걸 알게 됐는지 1-2문장}

## 연결
- [[관련 개념 1]]
- [[관련 개념 2]]
```

**기존 노트에 추가 시:**

```bash
obsidian append \
  path="3-Resources/{개념 이름}.md" \
  content="\n\n## YYYY-MM-DD 추가\n- {새로 배운 것}\n- 출처: [[1-Projects/{프로젝트}/sessions/YYYY-MM-DD]]" \
  silent
```

### 5단계: 처리 완료 기록

모든 날짜 처리 후:

```bash
echo "YYYY-MM-DD" > ~/.claude/growth/.daily-digest-last
```

마지막으로 처리한 날짜를 기록. 다음 세션에서는 이 날짜 이후만 처리.

## Obsidian 미실행 시

`obsidian` CLI 실행 실패하면:
1. `open -a Obsidian` 실행
2. 3초 대기
3. 재시도
4. 그래도 실패하면 사용자에게 알리고 중단

## 실행 예시

사용자가 아침에 Claude Code 재시작하면:

```
[Daily Digest] 미처리 Daily 노트 발견: 2026-03-31
→ /daily-digest 스킬을 실행하여 프로젝트별 세션 노트와 개념 노트를 생성해주세요.
```

이 메시지를 받으면:
1. 이 스킬의 절차에 따라 처리
2. 처리 결과를 사용자에게 간략히 보고:
   - 생성된 세션 노트 목록
   - 생성된 개념 노트 목록
   - 처리 완료 날짜
