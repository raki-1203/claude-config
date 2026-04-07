# Global Development Principles

## 개발 워크플로우 (Superpowers)

| 상황 | 흐름 |
|------|------|
| **새 기능** | `/brainstorming` → `/writing-plans` → 구현 (TDD 자동 강제) → `/finishing-a-development-branch` |
| **버그 수정** | `/systematic-debugging` → 최소 변경 구현 → `/verification-before-completion` |
| **코드 리뷰 수신** | `/receiving-code-review` → 수정 |

- 버그 수정 시 리팩토링은 별도 작업으로 분리

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

- **플러그인**: `obsidian-wiki@obsidian-wiki-plugin`
- **스킬**: `wiki-ingest`, `wiki-query`, `wiki-lint`
- **Vault 경로**: `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/Vault`
- **구조**: Karpathy 3-Layer (raw/ → wiki/ → schema)

### Wrap-up → Wiki 규칙
작업 완료 시 (커밋, PR, 큰 태스크 마무리) 다음을 확인:
- 이 세션에서 **새로 알게 된 것** (도구, 패턴, 트러블슈팅)이 있는가?
- 위키에 아직 없는 내용인가?

해당되면 사용자에게 제안: "위키에 저장할까요? — {한 줄 요약}"
승인 시 wiki-ingest 스킬로 저장.
