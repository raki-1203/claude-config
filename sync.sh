#!/bin/bash

# Claude Code 설정을 claude-config 저장소로 동기화
# 사용법: ./sync.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "🔄 Claude Code 설정 동기화 시작..."
echo ""

# Sync settings.json (remove personal data)
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    # Extract only shareable fields
    jq '{
        statusLine: .statusLine,
        permissions: .permissions,
        enabledPlugins: .enabledPlugins,
        hooks: .hooks,
        alwaysThinkingEnabled: .alwaysThinkingEnabled,
        promptSuggestionEnabled: .promptSuggestionEnabled
    } | with_entries(select(.value != null))' "$CLAUDE_DIR/settings.json" > "$SCRIPT_DIR/settings.json"
    echo "✅ settings.json 동기화 완료"
fi

# Sync hooks
if [ -d "$CLAUDE_DIR/hooks" ]; then
    mkdir -p "$SCRIPT_DIR/hooks"
    cp "$CLAUDE_DIR/hooks"/* "$SCRIPT_DIR/hooks/" 2>/dev/null || true
    echo "✅ hooks 동기화 완료"
fi

# Sync skills
if [ -d "$CLAUDE_DIR/skills" ]; then
    rm -rf "$SCRIPT_DIR/skills"
    mkdir -p "$SCRIPT_DIR/skills"
    cp -r "$CLAUDE_DIR/skills"/* "$SCRIPT_DIR/skills/" 2>/dev/null || true
    echo "✅ skills 동기화 완료"
fi

# Sync agents (from ~/.claude/agents and plugin cache)
sync_agents() {
    rm -rf "$SCRIPT_DIR/agents"
    mkdir -p "$SCRIPT_DIR/agents"
    touch "$SCRIPT_DIR/agents/.gitkeep"
    local FOUND_AGENTS=false

    # Copy from ~/.claude/agents
    if [ -d "$CLAUDE_DIR/agents" ]; then
        for f in "$CLAUDE_DIR/agents"/*; do
            [ -e "$f" ] || continue
            [[ "$(basename "$f")" == ".gitkeep" ]] && continue
            cp -r "$f" "$SCRIPT_DIR/agents/"
            FOUND_AGENTS=true
        done
    fi

    # Extract from plugin cache
    local PLUGINS_CACHE="$CLAUDE_DIR/plugins/cache"
    if [ -d "$PLUGINS_CACHE" ]; then
        while IFS= read -r -d '' agent_file; do
            local agent_name=$(basename "$agent_file")
            cp "$agent_file" "$SCRIPT_DIR/agents/$agent_name"
            FOUND_AGENTS=true
        done < <(find "$PLUGINS_CACHE" -path "*/agents/*.md" -type f -print0 2>/dev/null)
    fi

    if [ "$FOUND_AGENTS" = true ]; then
        echo "✅ agents 동기화 완료"
    else
        echo "✅ agents 동기화 완료 (비어있음)"
    fi
}

sync_agents

# Sync commands
if [ -d "$CLAUDE_DIR/commands" ]; then
    rm -rf "$SCRIPT_DIR/commands"
    mkdir -p "$SCRIPT_DIR/commands"
    cp -r "$CLAUDE_DIR/commands"/* "$SCRIPT_DIR/commands/" 2>/dev/null || true
    echo "✅ commands 동기화 완료"
fi

# Sync rules
if [ -d "$CLAUDE_DIR/rules" ]; then
    rm -rf "$SCRIPT_DIR/rules"
    mkdir -p "$SCRIPT_DIR/rules"
    cp -r "$CLAUDE_DIR/rules"/* "$SCRIPT_DIR/rules/" 2>/dev/null || true
    echo "✅ rules 동기화 완료"
fi

# Sync CLAUDE.md (user-level)
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    cp "$CLAUDE_DIR/CLAUDE.md" "$SCRIPT_DIR/CLAUDE.md"
    echo "✅ CLAUDE.md 동기화 완료"
fi

# Generate plugins.txt from installed plugins
PLUGINS_FILE="$CLAUDE_DIR/plugins/installed_plugins.json"
if [ -f "$PLUGINS_FILE" ]; then
    jq -r '.plugins | keys[]' "$PLUGINS_FILE" > "$SCRIPT_DIR/plugins.txt"
    echo "✅ plugins.txt 생성 완료"
    echo "   설치된 플러그인:"
    while IFS= read -r plugin; do
        echo "   - $plugin"
    done < "$SCRIPT_DIR/plugins.txt"
fi

# Generate mcp-servers.txt (collect from all sources, no API keys)
echo "# MCP 서버 설치 명령어" > "$SCRIPT_DIR/mcp-servers.txt"
echo "# API 키는 환경변수로 설정하세요" >> "$SCRIPT_DIR/mcp-servers.txt"
echo "" >> "$SCRIPT_DIR/mcp-servers.txt"

MCP_FOUND=false

if [ -f "$HOME/.claude.json" ]; then
    # User-level mcpServers
    USER_MCP=$(jq -r '.mcpServers // {}' "$HOME/.claude.json" 2>/dev/null)
    if [ "$USER_MCP" != "{}" ] && [ "$USER_MCP" != "null" ] && [ -n "$USER_MCP" ]; then
        echo "# User-level MCP servers" >> "$SCRIPT_DIR/mcp-servers.txt"
        echo "$USER_MCP" | jq -r 'to_entries[] | "claude mcp add \(.key) -s user -- \(.value.command) \(.value.args | join(" "))"' >> "$SCRIPT_DIR/mcp-servers.txt" 2>/dev/null || true
        MCP_FOUND=true
    fi

    # Project-level mcpServers (collect unique servers from all projects)
    PROJECT_MCP=$(jq -r '[.projects | to_entries[] | .value.mcpServers // {} | to_entries[]] | unique_by(.key) | from_entries' "$HOME/.claude.json" 2>/dev/null)
    if [ "$PROJECT_MCP" != "{}" ] && [ "$PROJECT_MCP" != "null" ] && [ -n "$PROJECT_MCP" ]; then
        echo "" >> "$SCRIPT_DIR/mcp-servers.txt"
        echo "# Project-level MCP servers" >> "$SCRIPT_DIR/mcp-servers.txt"
        echo "$PROJECT_MCP" | jq -r 'to_entries[] | "claude mcp add \(.key) -s user -- \(.value.command) \(.value.args | join(" "))"' >> "$SCRIPT_DIR/mcp-servers.txt" 2>/dev/null || true
        MCP_FOUND=true
    fi
fi

if [ "$MCP_FOUND" = false ]; then
    echo "# 설치된 MCP 서버가 없습니다" >> "$SCRIPT_DIR/mcp-servers.txt"
fi

echo "✅ mcp-servers.txt 생성 완료"

# Generate env-template.txt
cat > "$SCRIPT_DIR/env-template.txt" << 'EOF'
# Slack 알림용 Webhook URL
CLAUDE_SLACK_WEBHOOK_URL="your-slack-webhook-url"

# OpenCode Quotio API 키 (Quotio 앱에서 발급)
QUOTIO_API_KEY="quotio-local-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

# MCP 서버 API 키 (사용하는 경우)
# HYPERBROWSER_API_KEY="your-api-key"
EOF
echo "✅ env-template.txt 생성 완료"

echo ""
echo "🎉 Claude Code 동기화 완료!"

OPENCODE_DIR="$HOME/.config/opencode"
OPENCODE_DEST="$SCRIPT_DIR/opencode"

if [ -d "$OPENCODE_DIR" ]; then
    echo ""
    echo "🔄 OpenCode 설정 동기화 시작..."
    
    mkdir -p "$OPENCODE_DEST"

    if [ -f "$OPENCODE_DIR/opencode.json" ]; then
        jq 'walk(if type == "object" and has("apiKey") then .apiKey = "${QUOTIO_API_KEY}" else . end)' \
            "$OPENCODE_DIR/opencode.json" > "$OPENCODE_DEST/opencode.json"
        echo "✅ opencode.json 동기화 완료 (API 키 제거됨)"
    fi

    if [ -f "$OPENCODE_DIR/oh-my-opencode.json" ]; then
        cp "$OPENCODE_DIR/oh-my-opencode.json" "$OPENCODE_DEST/oh-my-opencode.json"
        echo "✅ oh-my-opencode.json 동기화 완료"
    fi

    if [ -f "$OPENCODE_DIR/antigravity.json" ]; then
        cp "$OPENCODE_DIR/antigravity.json" "$OPENCODE_DEST/antigravity.json"
        echo "✅ antigravity.json 동기화 완료"
    fi

    echo "🎉 OpenCode 동기화 완료!"
else
    echo ""
    echo "⏭️  ~/.config/opencode 폴더 없음 (OpenCode 동기화 건너뜀)"
fi

echo ""
echo "🎉 전체 동기화 완료!"
echo ""

# Git commit and push
cd "$SCRIPT_DIR"

if git diff --quiet && git diff --cached --quiet; then
    echo "📝 변경사항 없음"
else
    echo "📦 Git 커밋 및 푸시 중..."
    git status
    git add .
    git commit -m "Update Claude Code settings"
    git push
    echo "✅ Git push 완료!"
fi
