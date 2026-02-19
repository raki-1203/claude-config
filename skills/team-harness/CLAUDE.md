# Team Harness Skill Context

## Overview
이 스킬은 YAML 템플릿 기반으로 에이전트 팀을 자동 구성하고 TDD 워크플로우를 오케스트레이션합니다.

## Key Paths
- 글로벌 템플릿: `~/.claude/team-templates/*.yaml`
- 프로젝트 템플릿: `./.claude/team-templates/*.yaml`
- 프로젝트 기본: `./.claude/team.yaml`
- 에이전트 정의: `~/.claude/agents/*.md`

## Available Agents

### Leaders & Consultants (opus)
- `team-lead`: 읽기 전용 오케스트레이터, 코드 작성 안 함
- `oracle`: 읽기 전용 고급 컨설턴트, 아키텍처/디버깅/보안 상담
- `plan-reviewer`: 읽기 전용 계획 리뷰어, 완전성/실현가능성/리스크 검토

### Explorers (haiku, 항상 백그라운드 병렬 실행)
- `explorer`: 읽기 전용 코드베이스 내부 탐색 (Grep/Glob 기반)
- `librarian`: 읽기 전용 외부 레퍼런스 검색 (WebSearch/gh CLI 기반)

### Workers (sonnet)
- `python-developer`: Python 구현 전문가, GREEN phase 담당
- `tester`: TDD 테스트 전문가, RED phase 담당

### UI/UX (sonnet, 스킬 기반)
- `frontend-ui-ux`: UI/UX 전문가 (ui-ux-pro-max + vercel-react-best-practices 스킬 활용)

### Claude Reviewers (opus)
- `code-reviewer`: 코드 리뷰 (보안/품질/성능)
- `security-reviewer`: OWASP Top 10 보안 리뷰
- `database-reviewer`: DB 쿼리/스키마 리뷰

### Codex Reviewers (haiku, Codex CLI 실행)
- `codex-reviewer`: 범용 크로스 리뷰
- `codex-code-reviewer`: 코드 품질/패턴/성능 전문 프롬프트로 리뷰
- `codex-security-reviewer`: OWASP/시크릿/인증 전문 프롬프트로 리뷰
- `codex-db-reviewer`: 쿼리 최적화/스키마/인덱스 전문 프롬프트로 리뷰

### Built-in (기존 에이전트 재활용, sonnet)
- `e2e-runner`: Playwright E2E 테스트
- `doc-updater`: 문서/코드맵 업데이트
- `build-error-resolver`: 빌드 오류 해결
- `refactor-cleaner`: 데드코드 정리
- `code-simplifier`: 코드 단순화

## Workflow Patterns

### Standard TDD (python-backend, fullstack, minimal)
1. Plan → 2. RED (테스트 먼저) → 3. GREEN (구현) → 4. REFACTOR → 5. REVIEW → 6. FINALIZE

### Explore-First (explore-first 템플릿)
1. **Phase 0**: Explorer x2 + Librarian (병렬, 백그라운드) → 코드베이스 + 외부 레퍼런스 탐색
2. **Phase 1**: Leader → 탐색 결과 기반 계획 수립
3. **Phase 1.5**: Plan-Reviewer + Oracle (병렬) → 계획 검증
4. **Phase 2**: RED → GREEN → REFACTOR (TDD)
5. **Phase 3**: Claude-Reviewer + Codex-Reviewer (병렬 크로스 리뷰)
6. **Phase 4**: Leader → 종합 및 완료

모든 워크플로우에서 태스크 의존성(blockedBy)으로 순서가 강제되며, implement 태스크는 test-first 태스크가 완료되기 전까지 시작할 수 없습니다.

## Model Hierarchy
- **리더 (opus)**: 전략적 판단, 오케스트레이션, 태스크 분해
- **팀원 (sonnet)**: 구현, 테스트, 리뷰 등 실무 작업
- **하청 (haiku)**: 팀원이 스폰하는 보조 에이전트 (탐색, 간단한 분석)

## Package Manager
- Python 프로젝트: `uv` 사용 (pip 대신)
- Node.js 프로젝트: 프로젝트 설정에 따름 (npm/yarn/pnpm/bun)
