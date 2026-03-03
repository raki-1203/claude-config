#!/bin/bash

# 로컬 설정을 저장소로 동기화 (선택적)
# 주의: 저장소가 source of truth입니다.
# 저장소를 기준으로 여러 기기를 동기화하려면 install.sh를 사용하세요.
# 
# 사용법: ./sync.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "🔄 Claude Code 설정 동기화 시작..."
echo ""

# Counter for changed files
SYNC_COUNT=0

# Sync settings.json from local (only if changed)
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    if ! cmp -s "$CLAUDE_DIR/settings.json" "$SCRIPT_DIR/settings.json"; then
        cp "$CLAUDE_DIR/settings.json" "$SCRIPT_DIR/settings.json"
        echo "✅ settings.json 동기화 완료 (로컬 기준)"
        SYNC_COUNT=$((SYNC_COUNT + 1))
    else
        echo "✅ settings.json (변경 없음)"
    fi
fi

# Sync scripts (hooks and libs - replace completely)
if [ -d "$CLAUDE_DIR/scripts" ]; then
    rm -rf "$SCRIPT_DIR/scripts"
    mkdir -p "$SCRIPT_DIR/scripts"
    cp -r "$CLAUDE_DIR/scripts"/* "$SCRIPT_DIR/scripts/" 2>/dev/null || true
    echo "✅ scripts 동기화 완료 (로컬 기준)"
fi

# Sync hooks (Slack notification hooks - replace completely)
if [ -d "$CLAUDE_DIR/hooks" ]; then
    rm -rf "$SCRIPT_DIR/hooks"
    mkdir -p "$SCRIPT_DIR/hooks"
    cp "$CLAUDE_DIR/hooks"/* "$SCRIPT_DIR/hooks/" 2>/dev/null || true
    echo "✅ hooks 동기화 완료 (로컬 기준)"
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

# Sync CLAUDE.md (user-level, local source)
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    if ! cmp -s "$CLAUDE_DIR/CLAUDE.md" "$SCRIPT_DIR/CLAUDE.md" 2>/dev/null; then
        cp "$CLAUDE_DIR/CLAUDE.md" "$SCRIPT_DIR/CLAUDE.md"
        echo "✅ CLAUDE.md 동기화 완료 (로컬 기준)"
        SYNC_COUNT=$((SYNC_COUNT + 1))
    else
        echo "✅ CLAUDE.md (변경 없음)"
    fi
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

# Sync claude-hud config
HUD_CONFIG="$CLAUDE_DIR/plugins/claude-hud/config.json"
if [ -f "$HUD_CONFIG" ]; then
    mkdir -p "$SCRIPT_DIR/claude-hud"
    if ! cmp -s "$HUD_CONFIG" "$SCRIPT_DIR/claude-hud/config.json" 2>/dev/null; then
        cp "$HUD_CONFIG" "$SCRIPT_DIR/claude-hud/config.json"
        echo "✅ claude-hud config.json 동기화 완료"
        SYNC_COUNT=$((SYNC_COUNT + 1))
    else
        echo "✅ claude-hud config.json (변경 없음)"
    fi
fi

# Sync ~/.tmux.conf (only if changed)
if [ -f "$HOME/.tmux.conf" ]; then
    if ! cmp -s "$HOME/.tmux.conf" "$SCRIPT_DIR/tmux.conf" 2>/dev/null; then
        cp "$HOME/.tmux.conf" "$SCRIPT_DIR/tmux.conf"
        echo "✅ tmux.conf 동기화 완료 (로컬 기준)"
        SYNC_COUNT=$((SYNC_COUNT + 1))
    else
        echo "✅ tmux.conf (변경 없음)"
    fi
fi

# Generate env-template.txt
cat > "$SCRIPT_DIR/env-template.txt" << 'EOF'
# Slack 알림용 Webhook URL
CLAUDE_SLACK_WEBHOOK_URL="your-slack-webhook-url"

EOF
echo "✅ env-template.txt 생성 완료"

echo ""
echo "🎉 전체 동기화 완료! ($SYNC_COUNT 개 파일 변경됨)"
echo ""

# Git commit and push
cd "$SCRIPT_DIR"

# Check for changes (including untracked files)
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    echo "📝 변경사항 없음"
else
    echo ""
    echo "📊 변경 예정 항목:"
    echo "================================"

    git add .

    # Show diff summary + full diff (no pager)
    echo ""
    git --no-pager diff --cached --stat
    echo ""
    echo "📋 변경 내용 (diff):"
    echo "================================"
    git --no-pager diff --cached --color
    echo ""
    echo "================================"
    echo ""

    # Ask for confirmation before push
    read -p "변경사항을 커밋하고 푸시하시겠습니까? (y/n/d) [d=diff 다시 보기] " -n 1 -r
    echo ""

    # Allow re-viewing diff
    while [[ $REPLY =~ ^[Dd]$ ]]; do
        echo ""
        git --no-pager diff --cached --color
        echo ""
        read -p "변경사항을 커밋하고 푸시하시겠습니까? (y/n) " -n 1 -r
        echo ""
    done

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        FILES_CHANGED=$(git diff --cached --name-only | wc -l)

        # Generate detailed commit message based on what was changed
        COMMIT_MSG="chore: Sync Claude Code settings and configurations"

        # Check what was changed
        if git diff --cached --name-only | grep -q "skills/"; then
            COMMIT_MSG="$COMMIT_MSG

- Sync skill definitions"
        fi
        if git diff --cached --name-only | grep -q "settings.json"; then
            COMMIT_MSG="$COMMIT_MSG
- Update settings.json"
        fi
        if git diff --cached --name-only | grep -q "rules/"; then
            COMMIT_MSG="$COMMIT_MSG
- Update custom rules"
        fi
        if git diff --cached --name-only | grep -q "hooks/"; then
            COMMIT_MSG="$COMMIT_MSG
- Update hooks"
        fi
        if git diff --cached --name-only | grep -q "scripts/"; then
            COMMIT_MSG="$COMMIT_MSG
- Update scripts"
        fi

        git commit -m "$COMMIT_MSG"
        echo "✅ Git 커밋 완료! ($FILES_CHANGED 개 파일)"
        echo ""

        # Try to push with error handling
        if git push; then
            echo "✅ Git push 완료!"
        else
            echo "⚠️  git push 실패"
            echo "원인: 네트워크 연결 확인, 저장소 권한, 또는 원격 브랜치 문제"
            echo "해결 방법: git push --set-upstream origin main"
        fi
    else
        echo "❌ 푸시 취소됨. 변경사항은 준비되어 있습니다."
        echo "나중에 수동으로 푸시하려면: git push"
    fi
fi
