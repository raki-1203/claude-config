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
git -C "$SCRIPT_DIR" pull || echo "⚠️  git pull 실패 (오프라인이거나 권한 문제일 수 있습니다)"

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

# Copy agents (exclude .gitkeep)
if [ -d "$SCRIPT_DIR/agents" ]; then
    mkdir -p "$HOME/.claude/agents"
    find "$SCRIPT_DIR/agents" -maxdepth 1 -type f ! -name ".gitkeep" -exec cp {} "$HOME/.claude/agents/" \; 2>/dev/null || true
    echo "✅ agents 복사 완료"
fi

# Copy commands (exclude .gitkeep)
if [ -d "$SCRIPT_DIR/commands" ]; then
    mkdir -p "$HOME/.claude/commands"
    find "$SCRIPT_DIR/commands" -maxdepth 1 -type f ! -name ".gitkeep" -exec cp {} "$HOME/.claude/commands/" \; 2>/dev/null || true
    echo "✅ commands 복사 완료"
fi

# Copy rules (exclude .gitkeep)
if [ -d "$SCRIPT_DIR/rules" ]; then
    mkdir -p "$HOME/.claude/rules"
    find "$SCRIPT_DIR/rules" -maxdepth 1 -type f ! -name ".gitkeep" -exec cp {} "$HOME/.claude/rules/" \; 2>/dev/null || true
    echo "✅ rules 복사 완료"
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

echo ""
echo "🎉 Claude Code 설정 설치 완료!"

# ============================================
# OpenCode 설정 설치
# ============================================
echo ""
echo "🚀 OpenCode 설정 설치 시작..."

OPENCODE_DIR="$HOME/.config/opencode"
OPENCODE_SRC="$SCRIPT_DIR/opencode"

if [ -d "$OPENCODE_SRC" ]; then
    mkdir -p "$OPENCODE_DIR"

    if [ -f "$OPENCODE_SRC/opencode.json" ]; then
        if [ -f "$OPENCODE_DIR/opencode.json" ]; then
            BACKUP="$OPENCODE_DIR/opencode.json.backup.$(date +%Y%m%d%H%M%S)"
            cp "$OPENCODE_DIR/opencode.json" "$BACKUP"
            echo "📦 기존 opencode.json 백업: $BACKUP"
        fi
        
        cp "$OPENCODE_SRC/opencode.json" "$OPENCODE_DIR/opencode.json"
        
        if [ -n "$QUOTIO_API_KEY" ]; then
            sed -i '' "s|\${QUOTIO_API_KEY}|$QUOTIO_API_KEY|g" "$OPENCODE_DIR/opencode.json"
            echo "✅ opencode.json 복사 완료 (QUOTIO_API_KEY 자동 설정)"
        else
            echo "✅ opencode.json 복사 완료"
            echo "⚠️  QUOTIO_API_KEY 환경변수가 없습니다. 수동으로 설정하세요."
        fi
    fi

    # Install oh-my-opencode.json (merge with existing)
    if [ -f "$OPENCODE_SRC/oh-my-opencode.json" ]; then
        if [ -f "$OPENCODE_DIR/oh-my-opencode.json" ]; then
            BACKUP="$OPENCODE_DIR/oh-my-opencode.json.backup.$(date +%Y%m%d%H%M%S)"
            cp "$OPENCODE_DIR/oh-my-opencode.json" "$BACKUP"
            echo "📦 기존 oh-my-opencode.json 백업: $BACKUP"
            
            jq -s '.[0] * .[1]' "$OPENCODE_DIR/oh-my-opencode.json" "$OPENCODE_SRC/oh-my-opencode.json" > "$OPENCODE_DIR/oh-my-opencode.merged.json"
            mv "$OPENCODE_DIR/oh-my-opencode.merged.json" "$OPENCODE_DIR/oh-my-opencode.json"
            echo "✅ oh-my-opencode.json 병합 완료"
        else
            cp "$OPENCODE_SRC/oh-my-opencode.json" "$OPENCODE_DIR/oh-my-opencode.json"
            echo "✅ oh-my-opencode.json 복사 완료"
        fi
    fi

    if [ -f "$OPENCODE_SRC/antigravity.json" ]; then
        cp "$OPENCODE_SRC/antigravity.json" "$OPENCODE_DIR/antigravity.json"
        echo "✅ antigravity.json 복사 완료"
    fi

    echo "🎉 OpenCode 설정 설치 완료!"
else
    echo "⏭️  opencode/ 폴더 없음 (OpenCode 설정 건너뜀)"
fi

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
