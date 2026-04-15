# Global Development Principles

## 개발 워크플로우 (Superpowers)

| 상황 | 흐름 |
|------|------|
| **새 기능** | `/brainstorming` → `/writing-plans` → 구현 (TDD 자동 강제) → `/finishing-a-development-branch` |
| **버그 수정** | `/systematic-debugging` → 최소 변경 구현 → `/verification-before-completion` |
| **코드 리뷰 수신** | `/receiving-code-review` → 수정 |

- 버그 수정 시 리팩토링은 별도 작업으로 분리

## Claude Code 작업 원칙

### Plan 모드 우선
- 2개 이상 파일을 건드리거나 아키텍처 결정이 필요한 작업은 무조건 Plan 모드 시작
- 계획 확정 후 Shift+Tab으로 auto-accept 전환 → 1-shot 완성
- 잘못된 시도로 context 50% 낭비 방지

### Context 관리 — 50% 규칙
- 40~60% 구간은 "Dumb zone" — **50% 넘기 전 수동 `/compact`**
- 새 작업 전환 시에는 `/clear`로 완전 리셋
- 큰 조사·수정은 "use subagents"로 위임 — 메인 context 청결 유지

### CLAUDE.md 진화
- Claude가 같은 실수 반복 시: "다음엔 실수하지 않게 CLAUDE.md 업데이트해" 지시
- 하루 2회 이상 반복 작업은 Slash Command/Skill로 승격

## Python (Python 프로젝트에만 적용)

- **패키지 매니저**: `uv` 사용 (pip, pip3 사용 금지)
- **Python 실행**: `uv run python3` 사용 (bare `python3` 사용 금지)
- **패키지 설치**: `uv add <package>` (dev: `uv add --dev <package>`)
- **스크립트 내 python 호출**: `uv run python3 -c "..."` 형식으로 통일
- 쉘 스크립트에서 python 사용 시 `command -v uv` 사전 검사 필수
- Python 프로젝트 판별: `pyproject.toml` 또는 `uv.lock` 존재 여부로 확인

## GitHub

- **인증 방식**: SSH (HTTPS 사용 금지 — 인증 에러 발생)
- **remote URL 형식**: `git@github.com:raki-1203/{repo}.git`
- HTTPS URL(`https://github.com/...`)로 되어있으면 SSH로 전환: `git remote set-url origin git@github.com:raki-1203/{repo}.git`
- GitHub 계정: `raki-1203`

## Obsidian LLM Wiki

- **플러그인**: `rakis@raki-claude-plugins`
- **Vault 경로**: `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/Vault`
- **구조**: Karpathy 3-Layer (raw/ → wiki/ → schema)

### 스킬 사용 (필수)

위키 관련 작업은 항상 rakis 플러그인 스킬을 사용한다. 직접 파일 조작은 스킬이 로드되지 않은 환경에서만.

| 상황 | 스킬 |
|------|------|
| 이전에 조사/저장한 내용 검색·질문 | `rakis:wiki-query` |
| URL·파일·repo 분석 | `rakis:source-analyze` |
| 새 지식을 위키에 저장 | `rakis:wiki-ingest` |
| 세션 마무리 시 학습 기록 | `rakis:wiki-wrap-up` |
| 위키 건강 점검 (주 1회) | `rakis:wiki-lint` |
| 프로젝트 코드 구조 분석 | `/graphify` (graphify 자체 스킬) |
| 플러그인 의존성 설치 (최초 1회) | `rakis:setup` |

### 위키 자동 참조 규칙

**낯선 주제를 만나면 위키부터 확인**:
- 새 기술/라이브러리/프로젝트에 대해 작업하기 전, `rakis:wiki-query`로 위키에 관련 내용이 있는지 먼저 확인
- 이전 세션에서 축적한 분석/결정/gotchas를 참고하면 중복 조사를 방지할 수 있다

**프로젝트 작업 시작 시 프로젝트 위키 확인**:
- 현재 프로젝트명으로 `wiki/projects/{프로젝트명}.md`가 있는지 확인
- 있으면 읽어서 이전 아키텍처 결정, 패턴, 삽질 기록을 참고한 뒤 작업 시작
- 없으면 무시 (작업 중 기록할 만한 내용이 생기면 wiki-ingest로 생성)

### Wrap-up → Wiki 규칙
작업 완료 시 (커밋, PR, 큰 태스크 마무리) 다음을 확인:
- 이 세션에서 **새로 알게 된 것** (도구, 패턴, 트러블슈팅)이 있는가?
- 위키에 아직 없는 내용인가?

해당되면 사용자에게 제안: "위키에 저장할까요? — {한 줄 요약}"
승인 시 wiki-ingest 스킬로 저장.
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
- **`graphify claude install` 실행 금지**: CLAUDE.md 수정 + PreToolUse 훅 등록을 하는데, 프로젝트 파일을 건드리므로 사용자가 명시적으로 요청하지 않는 한 실행하지 말 것. graphify는 graph.json + git hooks만 사용.
