---
name: team-harness
description: "YAML 템플릿 기반 에이전트 팀 자동 구성 및 TDD 워크플로우 오케스트레이션. Use when: '/team [template] [task]', 'team harness', '팀 구성', '팀 실행'."
---

# Team Harness - 에이전트 팀 오케스트레이터

YAML 템플릿 기반으로 에이전트 팀을 자동 구성하고 TDD 워크플로우를 강제하는 시스템.

## 인자 형식

```
{template_name} {task_description}
```

- `template_name` (선택): 팀 템플릿 이름. 생략 시 프로젝트 자동 감지
- `task_description` (필수): 수행할 작업 설명

예시:
```
python-backend JWT 기반 사용자 인증 구현
fullstack Redis 검색 기능 추가
minimal 로그인 버그 수정
```

## Explore-First 패턴

`explore-first` 템플릿은 구현 전에 탐색 에이전트들이 먼저 조사하는 패턴입니다:

```
[Phase 0] Explorer x2 + Librarian (병렬, 백그라운드)
    ↓ 결과 수집
[Phase 1] Leader → 탐색 결과 기반 계획 수립
    ↓
[Phase 1.5] Plan-Reviewer + Oracle (병렬) → 계획 검증
    ↓
[Phase 2] Tester → Developer → Developer (TDD: RED → GREEN → REFACTOR)
    ↓
[Phase 3] Claude-Reviewer + Codex-Reviewer (병렬 크로스 리뷰)
    ↓
[Phase 4] Leader → 종합 및 완료
```

핵심: Explorer/Librarian은 **항상 백그라운드 + 병렬**로 실행. 결과를 기다린 후 계획 수립.

## 실행 절차

### Step 1: 인자 파싱

첫 번째 단어가 알려진 템플릿 이름인지 확인:
- 알려진 템플릿 → 해당 템플릿 사용, 나머지를 task_description으로
- 알려진 템플릿이 아님 → 전체를 task_description으로, 템플릿은 자동 감지

### Step 2: 템플릿 로딩

다음 순서로 YAML 템플릿을 검색 (Read 도구로 파일 읽기):

```
1. ./.claude/team.yaml              → 프로젝트 기본 템플릿
2. ./.claude/team-templates/{name}.yaml → 프로젝트 내 named 템플릿
3. ~/.claude/team-templates/{name}.yaml → 글로벌 템플릿
```

YAML 파일을 Read 도구로 읽은 후, 내용을 파싱하여 다음 정보를 추출:
- `name`: 팀 이름
- `leader`: 리더 에이전트 설정
- `members`: 팀원 목록 (role, agent, skills)
- `phases`: 작업 단계 목록 (name, description, assigned_to, depends_on)

### Step 3: 자동 감지 (템플릿 미지정 시)

프로젝트 파일을 확인하여 적합한 템플릿 결정:

```
pyproject.toml / setup.py / requirements.txt  → python-backend
package.json + (src/app/ or src/pages/ or app/) → fullstack
그 외                                           → minimal
```

Glob 도구로 파일 존재 여부 확인.

### Step 4: 프로젝트 컨텍스트

```
1. Read 도구로 ./CLAUDE.md 읽기 (있으면)
2. 프로젝트 컨벤션, 기술 스택, 규칙 파악
3. 이 정보를 팀원 지시에 포함
```

### Step 5: 팀 생성

TeamCreate 도구 호출:
```
team_name: "{template_name}-{YYYYMMDD}" (예: python-backend-20260219)
description: "{task_description}"
```

### Step 6: 태스크 생성

각 phase별로 TaskCreate 호출:

```
Phase: plan (depends_on 없음)
  → TaskCreate: subject="[plan] {task_description} - 요구사항 분석"

Phase: test-first (depends_on: [plan])
  → TaskCreate: subject="[RED] {task_description} - 실패 테스트 작성"
  → TaskUpdate: addBlockedBy=[plan_task_id]

Phase: implement (depends_on: [test-first])
  → TaskCreate: subject="[GREEN] {task_description} - 구현"
  → TaskUpdate: addBlockedBy=[test_task_id]

... (각 phase에 대해 반복)
```

### Step 7: 에이전트 스폰

각 멤버별로 Task 도구 호출하여 에이전트 스폰.

**모델 계층 규칙**:
- 리더 에이전트: `model: opus` (전략적 판단, 오케스트레이션)
- 팀원 에이전트: `model: sonnet` (구현, 테스트, 리뷰)
- 팀원이 하위 에이전트를 스폰할 때: `model: haiku` (보조 작업, 탐색, 간단한 분석)

```
리더:
  Task(
    subagent_type="{leader.agent}",
    team_name="{team_name}",
    name="{team_name}-leader",
    model="opus",
    prompt="당신은 {team_name} 팀의 리더입니다. 프로젝트 컨텍스트: {context}. 작업: {task_description}. TaskList를 확인하고 배정된 태스크부터 시작하세요. 하위 에이전트를 스폰할 때는 반드시 model='haiku'를 사용하세요.",
    run_in_background=true
  )

각 멤버:
  Task(
    subagent_type="{member.agent}",
    team_name="{team_name}",
    name="{team_name}-{member.role}",
    model="sonnet",
    prompt="당신은 {team_name} 팀의 {member.role}입니다. TaskList를 확인하고 배정된 태스크를 수행하세요. 완료되면 SendMessage로 리더에게 보고하세요. 하위 에이전트를 스폰할 때는 반드시 model='haiku'를 사용하세요.",
    run_in_background=true
  )
```

### Step 8: 초기 태스크 배정

의존성이 없는 태스크를 배정:

**explore-first 템플릿인 경우**:
```
1. explore-codebase 태스크 → explorer-1, explorer-2에게 병렬 배정 (run_in_background=true)
2. explore-references 태스크 → librarian에게 배정 (run_in_background=true)
3. 탐색 완료 대기 → plan 태스크를 leader에게 배정
```

**그 외 템플릿**:
```
TaskUpdate: taskId={plan_task_id}, owner="{team_name}-leader"
```

**parallel / parallel_with 처리**:
- `parallel: true` → 해당 role의 에이전트들을 동시에 스폰
- `parallel_with: [phase_name]` → 해당 phase와 동시에 실행 (같은 depends_on 공유)

### Step 9: 진행 모니터링

이후 메인 에이전트(오케스트레이터)의 역할:
1. 팀원 메시지 자동 수신 (시스템이 자동 전달)
2. 태스크 완료 확인 → 다음 unblocked 태스크 배정
3. 모든 태스크 완료 시 → Step 10으로

### Step 10: 완료 처리

```
1. 최종 결과 확인 (테스트 결과, 생성된 파일 등)
2. 팀원에게 shutdown_request 전송
3. TeamDelete 호출
4. 사용자에게 최종 보고
```

## 오류 처리

| 상황 | 처리 |
|------|------|
| 템플릿 파일 없음 | 사용 가능한 템플릿 목록 표시 |
| 에이전트 정의 없음 | general-purpose 에이전트로 대체 |
| 태스크 실패 | 리더에게 보고, 필요 시 재시도 |
| 커버리지 미달 | tester에게 추가 테스트 요청 |
| 리뷰 BLOCK | developer에게 수정 요청, 재리뷰 |

## 사용 가능한 템플릿

| 템플릿 | 팀원 수 | 단계 수 | 용도 |
|--------|---------|---------|------|
| explore-first | 12명 | 10단계 | **탐색 우선** - Explorer/Librarian 선행 + Codex 전문 분야별 크로스 리뷰 |
| python-backend | 4명 | 6단계 | Python 백엔드 개발 |
| fullstack | 6명 | 7단계 | 풀스택 개발 (UI/UX + 문서화 포함) |
| minimal | 2명 | 3단계 | 빠른 수정/소규모 기능 |
| custom-example | 5명 | 7단계 | 보안 강화 예시 |
