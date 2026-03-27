---
name: unified-workflow
description: "작업 지시 시 ouroboros + superpowers 통합 파이프라인 자동 진행 (명확화 → 설계 → 계획 → 구현 → 검증 → 정리 → 완료)"
auto-generated: true
created: 2026-03-27
scope: global
---

# unified-workflow

Ouroboros와 Superpowers를 결합한 통합 개발 워크플로우.
사용자가 작업을 지시하면 유형을 판별하고, 정해진 순서로 스킬을 invoke하여 끝까지 자동 진행한다.

## 언제 사용

사용자가 다음과 같은 작업을 지시할 때:
- 새 기능 구현 ("~만들어", "~추가해", "~구현해")
- 기존 기능 개선 ("~개선해", "~리팩토링해")
- 버그 수정 ("~안 돼", "~오류", "~버그", "~고쳐")

## 파이프라인 개요

```
Phase 0: 작업 유형 판별
Phase 0.5: Knowledge Recall (관련 지식 검색)
Phase 1: 명확화(신규/개선) 또는 디버깅(버그)
Phase 2: 구현 계획
Phase 3: 구현 (TDD)
Phase 4: 검증
Phase 5: 코드 정리 + 리뷰
Phase 6: 브랜치 마무리
```

## 절차

### Phase 0 — 작업 유형 판별

사용자 입력의 의도를 분석하여 경로를 결정한다.

- **신규 기능 / 개선** → Phase 1A로 진행
- **버그 수정** → Phase 1B로 진행
- **판별 불가** → 사용자에게 한 번만 확인 후 진행

상태 표시: `[Phase 0/6] 작업 유형 판별...`

---

### Phase 0.5 — Knowledge Recall (지식 검색)

Obsidian 볼트에서 관련 지식을 검색하여 작업 컨텍스트에 반영한다.

1. 사용자 요청에서 핵심 키워드 2-3개 추출
2. Obsidian 검색 실행:
   ```bash
   obsidian search query="{{키워드1}}" limit=5
   obsidian search query="{{키워드2}}" limit=5
   ```
3. 관련 노트 발견 시:
   - 상위 3개 노트를 `obsidian read`로 읽기
   - "이전 학습 기록이 있습니다:" 형태로 사용자에게 제시
   - 해당 지식을 이후 단계에서 컨텍스트로 활용
4. 관련 노트 없으면 조용히 패스 (별도 알림 불필요)
5. Obsidian이 실행 중이 아니면 이 단계 스킵 (작업 블로킹 금지)

상태 표시: `[Phase 0.5/6] 관련 지식 검색...`

---

### Phase 1A — 명확화 (신규/개선)

순서대로 3개 스킬을 invoke한다. 각 스킬은 자체 절차를 따른다.

**1단계: 요구사항 명확화**
```
Skill invoke: ouroboros:interview
```
- 소크라틱 Q&A로 요구사항을 명확화한다
- 애매모호도(ambiguity) ≤ 0.2까지 진행
- brownfield 컨텍스트 자동 활용

**2단계: 스펙 생성**
```
Skill invoke: ouroboros:seed
```
- interview 결과를 seed YAML로 변환
- goal, constraints, acceptance_criteria 포함

**3단계: 구현 설계**
```
Skill invoke: superpowers:brainstorming
```
- seed를 입력(컨텍스트)으로 구현 설계 문서 작성
- 2-3 접근법 비교 후 설계 승인 받기
- `docs/superpowers/specs/`에 설계 문서 커밋
- 주의: brainstorming의 terminal state인 writing-plans 전환은 스킵 (Phase 2에서 처리)

상태 표시: `[Phase 1/6] 요구사항 명확화 → 스펙 생성 → 설계...`

---

### Phase 1B — 디버깅 (버그)

**1단계: 근본원인 분석**
```
Skill invoke: superpowers:systematic-debugging
```
- 4단계 근본원인 분석 (증상 수집 → 가설 수립 → 가설 검증 → 근본원인 확정)
- 분석 결과를 기반으로 수정 방향 결정

상태 표시: `[Phase 1/6] 버그 근본원인 분석...`

---

### Phase 2 — 구현 계획

```
Skill invoke: superpowers:writing-plans
```
- 입력: Phase 1A의 설계 문서 또는 Phase 1B의 디버그 분석 결과
- bite-sized 구현 계획 작성 (각 태스크 = failing test → minimal code → commit)
- 계획 파일을 `docs/superpowers/plans/`에 커밋
- 실행 방식 선택 시 subagent-driven-development를 자동 선택

상태 표시: `[Phase 2/6] 구현 계획 작성...`

---

### Phase 3 — 구현

```
Skill invoke: superpowers:subagent-driven-development
```
- 태스크별 서브에이전트가 구현
- 각 태스크 내부에서 TDD 적용 (red → green → refactor)
- 2단계 리뷰: spec reviewer → code quality reviewer
- 태스크별 커밋

상태 표시: `[Phase 3/6] 구현 중...`

---

### Phase 4 — 검증

**1단계: 증거 기반 완료 확인**
```
Skill invoke: superpowers:verification-before-completion
```
- 테스트 통과, 빌드 성공 등 증거 수집

**2단계: 3단계 자동 검증**
```
Skill invoke: ouroboros:evaluate
```
- Stage 1: Mechanical (lint, build, test, coverage)
- Stage 2: Semantic (AC 준수, goal alignment)
- Stage 3: Consensus (불확실 시에만, 선택적)

검증 실패 시 실패 단계와 원인을 보고하고, 사용자에게 재시도/수정 여부 확인.

상태 표시: `[Phase 4/6] 검증 중...`

---

### Phase 5 — 코드 정리 + 리뷰

**1단계: 코드 정리**
```
Skill invoke: simplify
```
- 변경된 코드의 재사용성, 품질, 효율성 리뷰
- 발견된 문제 자동 수정

**2단계: 코드 리뷰**
```
Skill invoke: superpowers:requesting-code-review
```
- 전체 구현에 대한 코드 리뷰 수행
- CRITICAL/HIGH 이슈 수정, MEDIUM 이슈는 가능한 범위에서 수정

상태 표시: `[Phase 5/6] 코드 정리 + 리뷰...`

---

### Phase 6 — 브랜치 마무리

```
Skill invoke: superpowers:finishing-a-development-branch
```
- 옵션 제시: 로컬 머지 / push + PR 생성 / 브랜치 유지 / 작업 폐기
- 사용자 선택에 따라 처리

상태 표시: `[Phase 6/6] 브랜치 마무리...`

---

### 완료 보고

모든 Phase 완료 후 출력:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  작업 완료
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

작업: {작업 설명}
브랜치: {브랜치명}
커밋: {커밋 수}개
테스트: {통과/전체}
검증: ✓ Mechanical / ✓ Semantic
코드 정리: ✓ simplify
코드 리뷰: ✓ 완료
```

## 자동 진행 규칙

1. 각 단계의 출력을 다음 단계의 입력으로 자동 전달
2. 결정이 필요한 경우에만 사용자에게 질문 (interview 중 질문, 설계 접근법 선택 등)
3. 단계 전환 시 상태 표시로 진행 상황 알림
4. 실패 시 해당 단계에서 멈추고 사용자에게 보고
5. 사용자가 중간에 개입하면 해당 단계부터 재개

## 주의사항

- 각 invoke된 스킬은 자체 절차를 완전히 따른다 (이 스킬은 순서만 제어)
- brainstorming 스킬이 writing-plans를 invoke하려 할 때, 이미 이 워크플로우가 Phase 2에서 처리하므로 brainstorming의 terminal state(writing-plans 전환)는 스킵하고 설계 문서 작성까지만 진행
- writing-plans 스킬이 실행 방식을 물을 때, subagent-driven-development를 자동 선택
- 이 스킬은 오케스트레이션만 담당하고, 실제 구현 로직은 각 개별 스킬에 위임
