#!/bin/bash
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/vault"
[ -d "$VAULT" ] || exit 0

PROJECT=""
if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  PROJECT=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null)
fi
[ -z "$PROJECT" ] && PROJECT=$(basename "$PWD")

PAGE="$VAULT/projects/${PROJECT}.md"

cat << ENDMSG
[필수] 세션 종료 전 위키 업데이트를 수행하라.

프로젝트: ${PROJECT}
위키 경로: ${PAGE}

이 세션에서 다음 중 하나라도 해당되면 반드시 위키에 기록하라:
- 아키텍처/설계 결정을 내렸다
- 버그를 해결했다 (원인과 해결책)
- 삽질했다 (다음에 피할 교훈)
- 새로운 패턴/기술을 사용했다
- 프로젝트 상태가 변했다

해당 사항이 없으면 기록하지 않아도 된다.

파일이 없으면 새로 생성하고, 있으면 해당 섹션에 append하라.
기록 후 log.md에도 한 줄 추가하라.
ENDMSG
