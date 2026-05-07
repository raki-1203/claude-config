# Global Development Principles

## Karpathy 4 Principles

비사소한 코딩 작업에 적용 (1줄 수정·오타는 판단껏). **속도보다 신중함.** [원문](https://x.com/karpathy/status/2015883857489522876).

### 1. Think Before Coding
> Don't assume. Don't hide confusion. Surface tradeoffs.

불확실하면 묻는다. 해석이 여러 개면 모두 제시 (혼자 고르지 않는다). 더 단순한 길이 보이면 push back. 이해 안 되면 멈추고 무엇이 헷갈리는지 짚는다.

### 2. Simplicity First
> Minimum code that solves the problem. Nothing speculative.

요청 안 한 기능·추상화·"유연성"·"불가능 시나리오 에러 처리" 금지. 한 번 쓰는 코드에 추상화 X. 200줄을 50줄로 줄일 수 있으면 재작성. **자가 검증**: "시니어가 보면 과한가?"

### 3. Surgical Changes
> Touch only what you must. Clean up only your own mess.

인접 코드·주석·포맷 "개선" 금지. 망가지지 않은 거 리팩토링 X. 기존 스타일 유지. 무관한 데드 코드는 **언급만**, 직접 삭제 X. 본인 변경으로 생긴 orphan만 제거. **버그 수정 ≠ 리팩토링 — 분리.**

### 4. Goal-Driven Execution
> Define success criteria. Loop until verified.

명령형 → 검증형으로 변환: "버그 수정" → "버그 재현 테스트 작성 → 통과시키기". 다단계는 짧은 계획부터 (`1. [step] → verify: [check]`). 약한 기준("작동하게 해줘")은 끊임없는 명확화를 부른다.

## 개발 워크플로우 (Superpowers)

| 상황 | 흐름 |
|------|------|
| **새 기능** | `/brainstorming` → `/writing-plans` → 구현 → `/finishing-a-development-branch` |
| **버그 수정** | `/systematic-debugging` → `/verification-before-completion` |
| **코드 리뷰 수신** | `/receiving-code-review` → 수정 |

## Python (`pyproject.toml` | `uv.lock` 있을 때)

`uv` only. `uv add <pkg>` (dev: `uv add --dev`), `uv run python3 …`. bare `python3`/`pip` 금지. 쉘 스크립트에서 python 호출 시 `command -v uv` 사전 검사.

## GitHub

SSH only — `git@github.com:raki-1203/{repo}.git`. HTTPS이면 `git remote set-url origin git@…`로 전환. 계정: `raki-1203`.

## Obsidian LLM Wiki

- **Vault**: `~/Nextcloud/Vault` (Karpathy 3-Layer: `raw/` → `wiki/` → `outputs/`)
- **위키 작업은 항상 `rakis:*` 스킬**: `wiki-query`(검색) · `source-analyze`(URL/파일/repo 분석) · `wiki-ingest`(저장) · `wiki-wrap-up`(세션 마무리) · `wiki-lint`(주1회 점검) · `setup`(최초 의존성)
- **낯선 주제 작업 전**: `rakis:wiki-query`로 vault 확인 → 중복 조사 방지
- **프로젝트 작업 시작 시**: `wiki/projects/{프로젝트명}.md` 있으면 읽기
- **Wrap-up**: 세션에서 새로 알게 된 게 위키에 없으면 "위키에 저장할까요? — {요약}" 제안

## graphify

- `/graphify` 트리거 시 `~/.claude/skills/graphify/SKILL.md` Skill 호출
- **`graphify claude install` 실행 금지** (CLAUDE.md/훅을 건드림). 사용은 graph.json + git hooks만.
