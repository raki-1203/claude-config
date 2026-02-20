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

echo "📥 최신 설정 가져오는 중..."
git -C "$SCRIPT_DIR" fetch origin || echo "⚠️  git fetch 실패 (오프라인이거나 권한 문제일 수 있습니다)"
git -C "$SCRIPT_DIR" reset --hard origin/main || echo "⚠️  git reset 실패 (오프라인이거나 권한 문제일 수 있습니다)"

EXISTING="$HOME/.claude/settings.json"
NEW="$SCRIPT_DIR/settings.json"

# Backup existing settings only if different
if [ -f "$EXISTING" ]; then
    if ! cmp -s "$EXISTING" "$NEW"; then
        BACKUP="$HOME/.claude/settings.json.backup.$(date +%Y%m%d%H%M%S)"
        cp "$EXISTING" "$BACKUP"
        echo "📦 기존 설정 백업: $BACKUP"

        # Keep only the latest backup, delete older ones
        ls -t "$HOME/.claude/settings.json.backup."* 2>/dev/null | tail -n +2 | xargs -r rm
    fi
fi

# Copy repo settings (overwrite)
cp "$NEW" "$EXISTING"
if [ -f "$EXISTING" ]; then
    if cmp -s "$EXISTING" "$NEW"; then
        echo "✅ settings.json 적용 완료 (이미 최신 상태)"
    else
        echo "✅ settings.json 적용 완료 (저장소 기준)"
    fi
else
    echo "✅ settings.json 적용 완료 (저장소 기준)"
fi

# Copy scripts (hooks and libs)
if [ -d "$SCRIPT_DIR/scripts" ]; then
    mkdir -p "$HOME/.claude/scripts"
    cp -r "$SCRIPT_DIR/scripts"/* "$HOME/.claude/scripts/"
    chmod +x "$HOME/.claude/scripts/hooks"/*.js 2>/dev/null || true
    echo "✅ scripts 복사 완료"
fi

# Copy hooks (Slack notification hooks)
if [ -d "$SCRIPT_DIR/hooks" ]; then
    mkdir -p "$HOME/.claude/hooks"
    cp "$SCRIPT_DIR/hooks"/* "$HOME/.claude/hooks/"
    chmod +x "$HOME/.claude/hooks"/*.sh 2>/dev/null || true
    echo "✅ hooks 복사 완료"
fi

# Copy skills (replace completely)
if [ -d "$SCRIPT_DIR/skills" ]; then
    rm -rf "$HOME/.claude/skills"
    mkdir -p "$HOME/.claude/skills"
    cp -r "$SCRIPT_DIR/skills"/* "$HOME/.claude/skills/"
    echo "✅ skills 적용 완료 (저장소 기준)"
fi

# Copy agents (replace completely, exclude .gitkeep)
if [ -d "$SCRIPT_DIR/agents" ]; then
    rm -rf "$HOME/.claude/agents"
    mkdir -p "$HOME/.claude/agents"
    find "$SCRIPT_DIR/agents" -maxdepth 1 -type f ! -name ".gitkeep" -exec cp {} "$HOME/.claude/agents/" \; 2>/dev/null || true
    echo "✅ agents 적용 완료 (저장소 기준)"
fi

# Copy commands (replace completely, exclude .gitkeep)
if [ -d "$SCRIPT_DIR/commands" ]; then
    rm -rf "$HOME/.claude/commands"
    mkdir -p "$HOME/.claude/commands"
    find "$SCRIPT_DIR/commands" -maxdepth 1 -type f ! -name ".gitkeep" -exec cp {} "$HOME/.claude/commands/" \; 2>/dev/null || true
    echo "✅ commands 적용 완료 (저장소 기준)"
fi

# Copy rules (replace completely, exclude .gitkeep)
if [ -d "$SCRIPT_DIR/rules" ]; then
    rm -rf "$HOME/.claude/rules"
    mkdir -p "$HOME/.claude/rules"
    find "$SCRIPT_DIR/rules" -maxdepth 1 -type f ! -name ".gitkeep" -exec cp {} "$HOME/.claude/rules/" \; 2>/dev/null || true
    echo "✅ rules 적용 완료 (저장소 기준)"
fi

# Copy CLAUDE.md
if [ -f "$SCRIPT_DIR/CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    echo "✅ CLAUDE.md 복사 완료"
fi

# Extract agents from installed plugins
extract_plugin_agents() {
    local PLUGINS_CACHE="$HOME/.claude/plugins/cache"
    if [ -d "$PLUGINS_CACHE" ]; then
        mkdir -p "$HOME/.claude/agents"
        local FOUND_AGENTS=false

        # Find all agent .md files in plugin cache
        while IFS= read -r -d '' agent_file; do
            local agent_name=$(basename "$agent_file")
            cp "$agent_file" "$HOME/.claude/agents/$agent_name"
            FOUND_AGENTS=true
        done < <(find "$PLUGINS_CACHE" -path "*/agents/*.md" -type f -print0 2>/dev/null)

        if [ "$FOUND_AGENTS" = true ]; then
            echo "✅ 플러그인 agents 추출 완료"
        fi
    fi
}

extract_plugin_agents

# Copy tmux.conf
if [ -f "$SCRIPT_DIR/tmux.conf" ]; then
    if [ -f "$HOME/.tmux.conf" ]; then
        if ! cmp -s "$HOME/.tmux.conf" "$SCRIPT_DIR/tmux.conf"; then
            BACKUP="$HOME/.tmux.conf.backup.$(date +%Y%m%d%H%M%S)"
            cp "$HOME/.tmux.conf" "$BACKUP"
            echo "📦 기존 tmux.conf 백업: $BACKUP"
            ls -t "$HOME/.tmux.conf.backup."* 2>/dev/null | tail -n +2 | xargs -r rm
        fi
    fi
    cp "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"
    echo "✅ tmux.conf 적용 완료 (저장소 기준)"
fi

echo ""
echo "🎉 Claude Code 설정 설치 완료!"

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
