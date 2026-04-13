#!/bin/bash
set -eo pipefail

VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/vault"
[ -d "$VAULT" ] || exit 0

# Detect current project from git or directory name
PROJECT=""
if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  PROJECT=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null)
fi
[ -z "$PROJECT" ] && PROJECT=$(basename "$PWD")

# Load project wiki page if exists
PAGE="$VAULT/projects/${PROJECT}.md"
if [ -f "$PAGE" ]; then
  echo "## Wiki: ${PROJECT}"
  cat "$PAGE"
fi
