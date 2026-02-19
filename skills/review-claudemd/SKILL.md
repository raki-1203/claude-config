---
name: review-claudemd
description: "최근 대화 이력을 분석하여 CLAUDE.md 개선점 제안. Use when: '/review-claudemd', 'CLAUDE.md 리뷰', 'CLAUDE.md 개선'."
---

# CLAUDE.md 리뷰 - 대화 이력 기반 개선

최근 대화를 분석하여 글로벌/로컬 CLAUDE.md 파일의 개선점을 찾습니다.

## Step 1: 대화 이력 찾기

```bash
PROJECT_PATH=$(pwd | sed 's|/|-|g' | sed 's|^-||')
CONVO_DIR=~/.claude/projects/-${PROJECT_PATH}
ls -lt "$CONVO_DIR"/*.jsonl | head -20
```

## Step 2: 최근 대화 추출

최근 15-20개 대화를 임시 디렉토리에 추출:

```bash
SCRATCH=/tmp/claudemd-review-$(date +%s)
mkdir -p "$SCRATCH"

for f in $(ls -t "$CONVO_DIR"/*.jsonl | head -20); do
  basename=$(basename "$f" .jsonl)
  cat "$f" | jq -r '
    if .type == "user" then
      "USER: " + (.message.content // "")
    elif .type == "assistant" then
      "ASSISTANT: " + ((.message.content // []) | map(select(.type == "text") | .text) | join("\n"))
    else
      empty
    end
  ' 2>/dev/null | grep -v "^ASSISTANT: $" > "$SCRATCH/${basename}.txt"
done
```

## Step 3: 서브에이전트로 분석

Sonnet 서브에이전트를 병렬로 스폰하여 대화 분석:

각 에이전트가 읽을 파일:
- 글로벌 CLAUDE.md: `~/.claude/CLAUDE.md`
- 로컬 CLAUDE.md: `./CLAUDE.md` (있으면)
- 대화 파일 배치

분석 관점:
1. 기존 규칙 중 위반된 것 (강화 필요)
2. 로컬 CLAUDE.md에 추가할 프로젝트별 패턴
3. 글로벌 CLAUDE.md에 추가할 범용 패턴
4. 오래되거나 불필요한 항목

배치 크기:
- 대용량 (>100KB): 에이전트당 1-2개
- 중간 (10-100KB): 에이전트당 3-5개
- 소용량 (<10KB): 에이전트당 5-10개

## Step 4: 결과 종합

모든 에이전트 결과를 다음 섹션으로 정리:

1. **위반된 규칙** - 기존 규칙인데 안 지켜진 것 (문구 강화 필요)
2. **로컬 추가 제안** - 프로젝트에만 해당하는 패턴
3. **글로벌 추가 제안** - 모든 프로젝트에 적용할 패턴
4. **삭제/수정 제안** - 더 이상 유효하지 않은 항목

사용자에게 테이블/불릿으로 제시하고, 수정 적용 여부를 확인합니다.
