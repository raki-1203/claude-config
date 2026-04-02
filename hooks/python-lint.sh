#!/usr/bin/env bash
# Claude Code PreToolUse hook: git commit 전 Python lint 검사
# CI와 동일한 ruff 규칙(F821: undefined name, F811: redefined unused) 적용

# git commit 명령이 아니면 스킵
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

INPUT="$TOOL_INPUT"
# git commit 명령인지 확인
if ! echo "$INPUT" | grep -qE 'git commit'; then
  exit 0
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  exit 0
fi

# staged된 Python 파일 목록
PY_FILES=$(git diff --cached --name-only --diff-filter=ACM -- '*.py' 2>/dev/null)
if [ -z "$PY_FILES" ]; then
  exit 0
fi

# ruff 설치 여부 확인
if ! command -v ruff &>/dev/null; then
  if command -v uvx &>/dev/null; then
    RUFF_CMD="uvx ruff"
  else
    echo "ruff not found, skipping lint check"
    exit 0
  fi
else
  RUFF_CMD="ruff"
fi

# CI와 동일한 규칙으로 검사
cd "$REPO_ROOT"
RESULT=$($RUFF_CMD check --select=F821,F811 $PY_FILES 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "⚠️ Python lint 오류 발견 (ruff F821/F811):"
  echo "$RESULT"
  echo ""
  echo "커밋 전에 수정이 필요합니다."
  exit 2  # exit 2 = block the tool use
fi

exit 0
