---
description: "현재 세션이나 프로젝트에서 반복 작업 패턴을 감지하여 재사용 가능한 스킬로 저장"
---

# Extract Skill

현재 작업 컨텍스트에서 반복적인 작업 패턴을 식별하고, 재사용 가능한 스킬로 저장합니다.

## 절차

### 1. 패턴 감지

다음 소스에서 반복 패턴을 탐색합니다:

- 현재 세션의 대화 흐름 (도구 호출 시퀀스, 반복된 작업)
- ~/.claude/growth/session-log.jsonl 의 최근 세션 통계
- 현재 프로젝트의 .claude/ 디렉토리 (기존 스킬, 메모리)

### 2. 후보 제안

발견된 패턴을 스킬 후보로 정리하여 사용자에게 제시합니다:

- 스킬 이름 (kebab-case)
- 한 줄 설명
- 언제 사용하는지 (트리거 조건)
- 절차 (단계별)
- 범용/프로젝트 특화 분류

### 3. 저장 위치 결정

사용자 승인 후 스킬 파일을 생성합니다:

- **범용 패턴** (여러 프로젝트에서 사용 가능)
  → ~/.claude/skills/auto/{skill-name}.md

- **프로젝트 특화 패턴** (현재 프로젝트에서만 유용)
  → {프로젝트}/.claude/skills/auto/{skill-name}.md
  → 디렉토리가 없으면 생성

### 4. 파일 생성

~/.claude/skills/templates/skill-template.md 포맷을 따릅니다:

```markdown
---
name: {skill-name}
description: {한 줄 설명}
auto-generated: true
created: {오늘 날짜}
times_used: 0
---

# {Skill Name}

## 언제 사용
{트리거 조건}

## 절차
1. ...
2. ...

## 주의사항
- ...
```

### 5. 레지스트리 업데이트

~/.claude/growth/skill-registry.json 에 새 스킬 메타데이터를 추가합니다.

## 참고

- 하나의 스킬은 하나의 명확한 작업 패턴을 담아야 합니다
- 너무 일반적이거나 너무 구체적인 스킬은 피합니다
- 기존 스킬과 중복되지 않는지 확인 후 생성합니다
