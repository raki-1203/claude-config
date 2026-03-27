---
name: knowledge-extractor
description: "세션 트랜스크립트에서 인사이트를 추출하여 Obsidian 개념 노트를 생성하는 스킬"
auto-generated: true
created: 2026-03-27
scope: global
---

# Knowledge Extractor

세션 트랜스크립트를 읽고, 배운 개념/인사이트를 Obsidian 개념 노트로 변환한다.
UserPromptSubmit hook(knowledge-check.sh)이 pending 세션을 감지하면 이 스킬이 호출된다.

## 처리 절차

1. pending 파일에서 transcript 경로 읽기
2. 트랜스크립트 JSONL 파일 읽기 (Read 도구 사용)
3. 인사이트 추출 (아래 규칙에 따라)
4. Obsidian CLI로 개념 노트 생성
5. Daily 노트에 "오늘 배운 것" 섹션 추가/업데이트
6. 처리 완료된 pending 파일 삭제

## 인사이트 추출 규칙

### 추출할 것

1. **새로 알게 된 개념** — 처음 접했거나 이해가 깊어진 기술/패턴/도구
2. **문제 해결 과정** — 어떤 문제를 어떻게 풀었는지 (삽질 포함)
3. **설계 결정과 이유** — 왜 A를 선택하고 B를 버렸는지
4. **실패에서 배운 것** — 안 된 접근과 그 이유

### 추출하지 않을 것

- 단순 파일 수정 이력 (git log로 충분)
- 이미 Obsidian에 노트로 존재하는 내용 (중복 방지 — `obsidian search`로 확인)
- 일반적으로 알려진 상식 (공식 문서에 있는 기본 사용법 등)
- 단순 설정 변경이나 오타 수정

### 추출 개수 가이드

- 짧은 세션 (대화 10턴 이하): 0-1개
- 보통 세션 (10-30턴): 1-3개
- 긴 세션 (30턴 이상): 2-5개
- 배운 게 없으면 0개도 정상. 억지로 만들지 않는다.

## 개념 노트 생성

Obsidian CLI 사용:

```bash
# 노트 생성 (3-Resources/ 폴더에)
obsidian create name="개념이름" path="3-Resources/개념이름.md" content="..." silent

# 이미 존재하면 append
obsidian append path="3-Resources/개념이름.md" content="..." silent
```

### 노트 형식

```markdown
---
tags: [resource]
created: "{{날짜}}"
source_session: "{{세션ID}}"
source_project: "{{프로젝트명}}"
related_files: [{{관련 파일들}}]
---

# {{개념 이름}}

{{1-3문장 핵심 설명}}

## 핵심 내용
- {{배운 것 1}}
- {{배운 것 2}}

## 맥락
{{어떤 작업에서 이걸 알게 됐는지 1-2문장}}

## 연결
- [[관련 개념 1]]
- [[관련 개념 2]]
```

## Daily 노트 업데이트

```bash
# Daily 노트에 배운 것 추가
obsidian daily:append content="\n## 오늘 배운 것\n- [[개념A]] — 한줄 요약\n- [[개념B]] — 한줄 요약" silent
```

이미 "오늘 배운 것" 섹션이 있으면 해당 섹션에 항목만 추가.
Daily 노트가 없으면 Daily 템플릿으로 먼저 생성.

## 질문 응답 모드 (읽기 B)

사용자가 "이거 어떻게 했어?", "왜 이렇게 했어?" 류 질문을 하면:

1. `obsidian search query="{{관련 키워드}}" limit=10` 으로 관련 노트 검색
2. 관련 노트의 `source_session` 메타데이터로 원본 트랜스크립트 추적
3. 트랜스크립트에서 해당 부분 읽기
4. 작업 맥락 + 결정 이유를 포함한 설명 생성

## Obsidian 미실행 시

`obsidian` CLI 실행 실패 시:
1. `open -a Obsidian` 실행
2. 3초 대기
3. 재시도
4. 그래도 실패하면 pending 파일 유지하고 다음 세션에서 재시도

## pending 파일 정리

모든 노트 생성 완료 후:
```bash
rm ~/.claude/growth/pending-insights/{{세션ID}}.json
```
