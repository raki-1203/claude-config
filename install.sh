#!/bin/bash

set -e

echo "🚀 Claude Code 설정 설치 시작..."

# Check if Claude Code is installed
if [ ! -d "$HOME/.claude" ]; then
    echo "❌ ~/.claude 폴더가 없습니다."
    echo "먼저 Claude Code를 설치하고 한 번 실행해주세요:"
    echo "  npm install -g @anthropic-ai/claude-code"
    echo "  claude"
    exit 1
fi

# Check jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ jq가 필요합니다. 설치해주세요:"
    echo "  brew install jq"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXISTING="$HOME/.claude/settings.json"
NEW="$SCRIPT_DIR/settings.json"

# Backup existing settings
if [ -f "$EXISTING" ]; then
    BACKUP="$HOME/.claude/settings.json.backup.$(date +%Y%m%d%H%M%S)"
    cp "$EXISTING" "$BACKUP"
    echo "📦 기존 설정 백업: $BACKUP"

    # Merge settings
    echo "🔀 기존 설정과 병합 중..."
    jq -s '
      .[0] as $existing | .[1] as $new |
      ($existing * $new) |
      .enabledPlugins = (($existing.enabledPlugins // {}) * ($new.enabledPlugins // {})) |
      .permissions.allow = ((($existing.permissions.allow // []) + ($new.permissions.allow // [])) | unique) |
      .hooks = (($existing.hooks // {}) * ($new.hooks // {}))
    ' "$EXISTING" "$NEW" > "$HOME/.claude/settings.merged.json"
    mv "$HOME/.claude/settings.merged.json" "$EXISTING"
    echo "✅ settings.json 병합 완료"
else
    cp "$NEW" "$EXISTING"
    echo "✅ settings.json 복사 완료"
fi

# Copy hooks
if [ -d "$SCRIPT_DIR/hooks" ]; then
    mkdir -p "$HOME/.claude/hooks"
    cp "$SCRIPT_DIR/hooks"/* "$HOME/.claude/hooks/"
    chmod +x "$HOME/.claude/hooks"/*.sh 2>/dev/null || true
    echo "✅ hooks 복사 완료"
fi

# Copy skills
if [ -d "$SCRIPT_DIR/skills" ]; then
    mkdir -p "$HOME/.claude/skills"
    cp -r "$SCRIPT_DIR/skills"/* "$HOME/.claude/skills/"
    echo "✅ skills 복사 완료"
fi

# Copy agents
if [ -d "$SCRIPT_DIR/agents" ]; then
    mkdir -p "$HOME/.claude/agents"
    cp -r "$SCRIPT_DIR/agents"/* "$HOME/.claude/agents/"
    echo "✅ agents 복사 완료"
fi

# Copy commands
if [ -d "$SCRIPT_DIR/commands" ]; then
    mkdir -p "$HOME/.claude/commands"
    cp -r "$SCRIPT_DIR/commands"/* "$HOME/.claude/commands/"
    echo "✅ commands 복사 완료"
fi

# Copy rules
if [ -d "$SCRIPT_DIR/rules" ]; then
    mkdir -p "$HOME/.claude/rules"
    cp -r "$SCRIPT_DIR/rules"/* "$HOME/.claude/rules/"
    echo "✅ rules 복사 완료"
fi

# Copy CLAUDE.md
if [ -f "$SCRIPT_DIR/CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    echo "✅ CLAUDE.md 복사 완료"
fi

echo ""
echo "🎉 설치 완료!"

# Show required plugins
if [ -f "$SCRIPT_DIR/plugins.txt" ]; then
    echo ""
    echo "📦 플러그인 설치가 필요합니다."
    echo "Claude Code 실행 후 다음 명령어를 입력하세요:"
    echo ""
    while IFS= read -r plugin || [ -n "$plugin" ]; do
        [ -z "$plugin" ] && continue
        echo "  /install $plugin"
    done < "$SCRIPT_DIR/plugins.txt"
fi

# Show required MCP servers
if [ -f "$SCRIPT_DIR/mcp-servers.txt" ]; then
    echo ""
    echo "🔌 MCP 서버 설치가 필요합니다."
    echo "다음 명령어를 터미널에서 실행하세요:"
    echo ""
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        [[ "$line" == \#* ]] && continue
        echo "  $line"
    done < "$SCRIPT_DIR/mcp-servers.txt"
fi

# Show required environment variables
if [ -f "$SCRIPT_DIR/env-template.txt" ]; then
    echo ""
    echo "⚠️  다음 환경변수를 ~/.zshrc에 추가하세요:"
    echo ""
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        [[ "$line" == \#* ]] && echo "  $line" && continue
        echo "  export $line"
    done < "$SCRIPT_DIR/env-template.txt"
fi

echo ""
echo "설정 후 새 터미널을 열거나 'source ~/.zshrc' 실행하세요."
