# Obsidian Daily Digest — 프로젝트별 지식 정리 시스템

> 설계일: 2026-04-01

## 목적

Daily 노트에 쌓인 세션 로그를 하루 한번 분석하여:
1. 프로젝트별 세션 노트로 분류 (`1-Projects/{프로젝트}/sessions/`)
2. 개념/인사이트를 지식 노트로 추출 (`3-Resources/`)
3. wikilink로 연결하여 Obsidian 지식 그래프 구축

## 전체 흐름

```
아침 Claude Code 재시작
  → knowledge-check.sh: "미처리 날짜 있음" 감지
  → Claude에게 daily-digest 실행 지시 전달
  → Claude: obsidian daily-digest 스킬 로드
  → 전날(+밀린 날짜) Daily 노트 분석
  → 1-Projects/{프로젝트}/sessions/YYYY-MM-DD.md 생성
  → 3-Resources/{개념}.md 생성/업데이트
  → 처리 완료 플래그 저장 (.daily-digest-last)
```

## 컴포넌트

### 1. knowledge-check.sh 수정

기존 기능(이전 세션 맥락 로드) 유지. 아래 로직 추가:

- `~/.claude/growth/.daily-digest-last` 파일에서 마지막 처리 날짜 읽기
- 오늘 날짜와 비교
- 다르면 → Claude에게 "전날 Daily 노트를 분석해서 정리하라" 메시지 전달
- 같으면 → 스킵 (이미 처리됨)
- 여러 날 밀린 경우 미처리 날짜 목록도 전달

### 2. daily-digest 스킬

위치: `~/.claude/skills/auto/daily-digest.md`

**입력**: 처리할 날짜(들)

**처리 단계**:
1. `obsidian read` 또는 파일 직접 읽기로 해당 날짜 Daily 노트 로드
2. `### 세션: {프로젝트명} ({시간})` 블록 기준으로 프로젝트별 분류
3. 프로젝트별 세션 노트 생성 (`obsidian create`)
4. 세션 내용에서 개념/인사이트 추출
5. 개념 노트 생성 또는 업데이트 (`obsidian create` / `obsidian append`)
6. `~/.claude/growth/.daily-digest-last`에 처리 날짜 기록

**추출 기준** (knowledge-extractor 규칙 재활용):
- 새로 알게 된 개념/패턴/도구
- 문제 해결 과정 (삽질 포함)
- 설계 결정과 이유
- 실패에서 배운 것
- 배운 게 없으면 0개 — 억지로 만들지 않음

**추출 제외**:
- 단순 파일 수정 이력
- 이미 Obsidian에 존재하는 내용
- 공식 문서에 있는 기본 사용법
- 단순 설정 변경/오타 수정

### 3. 노트 형식

**프로젝트 세션 노트** (`1-Projects/{프로젝트}/sessions/YYYY-MM-DD.md`):

```markdown
---
date: YYYY-MM-DD
project: {프로젝트명}
tags: [session-log]
---

# YYYY-MM-DD 세션

## 작업 내용
- {세션에서 한 일 요약}

## 주요 결정
- {왜 이렇게 했는지}

## 관련 개념
- [[개념 A]]
- [[개념 B]]
```

**개념 노트** (`3-Resources/{개념}.md`):

```markdown
---
tags: [resource]
created: YYYY-MM-DD
related_projects: [{프로젝트명}]
---

# {개념 이름}

{1-3문장 핵심 설명}

## 핵심 내용
- {배운 것}

## 맥락
{어떤 작업에서 알게 됐는지}

## 연결
- [[관련 개념]]
```

### 4. 처리 완료 관리

- `~/.claude/growth/.daily-digest-last`: 마지막 처리 날짜 (YYYY-MM-DD)
- 하루에 한번만 실행
- 밀린 날짜: Daily 폴더에서 미처리 날짜 스캔하여 순서대로 처리

### 5. 변경 파일 목록

| 파일 | 변경 |
|------|------|
| `~/.claude/hooks/knowledge-check.sh` | Daily digest 미처리 감지 + 지시 메시지 추가 |
| `~/.claude/skills/auto/daily-digest.md` | 새 스킬 — Daily 분석 및 노트 생성 |
| `~/.claude/growth/.daily-digest-last` | 새 파일 — 마지막 처리 날짜 |

## 제약사항

- Obsidian CLI 필수 (`obsidian` 명령어 사용 가능해야 함)
- Obsidian 앱 실행 중이어야 CLI 동작
- Daily 노트에 `### 세션: {프로젝트명}` 형식이 유지되어야 파싱 가능
