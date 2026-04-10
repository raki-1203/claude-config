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

# Copy skills (merge: templates를 덮어쓰되 auto/의 사용자 생성 스킬은 보존)
if [ -d "$SCRIPT_DIR/skills" ]; then
    mkdir -p "$HOME/.claude/skills/auto"
    mkdir -p "$HOME/.claude/skills/templates"
    if [ -d "$SCRIPT_DIR/skills/templates" ]; then
        cp -r "$SCRIPT_DIR/skills/templates"/* "$HOME/.claude/skills/templates/" 2>/dev/null || true
    fi
    echo "✅ skills 적용 완료 (auto/ 보존, templates 업데이트)"
fi

# Copy agents (merge: repo agents + preserve existing, plugin agents managed separately)
if [ -d "$SCRIPT_DIR/agents" ]; then
    mkdir -p "$HOME/.claude/agents"
    find "$SCRIPT_DIR/agents" -maxdepth 1 -type f ! -name ".gitkeep" -exec cp {} "$HOME/.claude/agents/" \; 2>/dev/null || true
    echo "✅ agents 적용 완료 (저장소 기준, 기존 보존)"
fi

# Copy commands (merge: repo commands + preserve existing, plugin commands managed separately)
if [ -d "$SCRIPT_DIR/commands" ]; then
    mkdir -p "$HOME/.claude/commands"
    find "$SCRIPT_DIR/commands" -maxdepth 1 -type f ! -name ".gitkeep" -exec cp {} "$HOME/.claude/commands/" \; 2>/dev/null || true
    echo "✅ commands 적용 완료 (저장소 기준, 기존 보존)"
fi

# Copy rules (replace completely, exclude .gitkeep)
if [ -d "$SCRIPT_DIR/rules" ]; then
    rm -rf "$HOME/.claude/rules"
    mkdir -p "$HOME/.claude/rules"
    find "$SCRIPT_DIR/rules" -maxdepth 1 -type f ! -name ".gitkeep" -exec cp {} "$HOME/.claude/rules/" \; 2>/dev/null || true
    echo "✅ rules 적용 완료 (저장소 기준)"
fi

# Create growth data directory
mkdir -p "$HOME/.claude/growth"
if [ ! -f "$HOME/.claude/growth/skill-registry.json" ]; then
    echo '{"skills":{},"last_review":null,"version":1}' > "$HOME/.claude/growth/skill-registry.json"
fi
echo "✅ growth 디렉토리 준비 완료"

# Copy CLAUDE.md
if [ -f "$SCRIPT_DIR/CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    echo "✅ CLAUDE.md 복사 완료"
fi

# Plugin agents are managed by plugin system — no manual extraction needed

# Restore claude-hud config
if [ -f "$SCRIPT_DIR/claude-hud/config.json" ]; then
    mkdir -p "$HOME/.claude/plugins/claude-hud"
    cp "$SCRIPT_DIR/claude-hud/config.json" "$HOME/.claude/plugins/claude-hud/config.json"
    echo "✅ claude-hud config.json 복원 완료"
fi

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

# Clean stale plugin cache before marketplace/plugin install
PLUGINS_CACHE_DIR="$HOME/.claude/plugins/cache"
if [ -d "$PLUGINS_CACHE_DIR" ]; then
    CACHE_CLEANED=0

    # 1. Remove temp directories (failed install/uninstall leftovers)
    for tmp_dir in "$PLUGINS_CACHE_DIR"/temp_*; do
        [ -d "$tmp_dir" ] || continue
        rm -rf "$tmp_dir"
        CACHE_CLEANED=$((CACHE_CLEANED + 1))
    done

    # 2. Remove cache dirs for uninstalled plugins (marketplace level)
    INSTALLED_FILE="$HOME/.claude/plugins/installed_plugins.json"
    if [ -f "$INSTALLED_FILE" ]; then
        ACTIVE_MARKETS=$(jq -r '.plugins | to_entries[] | .value[0].installPath' "$INSTALLED_FILE" 2>/dev/null | sed 's|.*/cache/||' | cut -d'/' -f1 | sort -u)
        for cache_dir in "$PLUGINS_CACHE_DIR"/*/; do
            [ -d "$cache_dir" ] || continue
            dir_name="$(basename "$cache_dir")"
            [[ "$dir_name" == temp_* ]] && continue
            if ! echo "$ACTIVE_MARKETS" | grep -q "^${dir_name}$"; then
                rm -rf "$cache_dir"
                CACHE_CLEANED=$((CACHE_CLEANED + 1))
            fi
        done
    fi

    [ "$CACHE_CLEANED" -gt 0 ] && echo "🧹 플러그인 캐시 정리: ${CACHE_CLEANED}개 stale 항목 제거"
fi

# Auto-install marketplaces (declarative: install missing + remove extra)
# Single source of truth: settings.json extraKnownMarketplaces
if command -v claude &> /dev/null; then
    echo ""
    echo "🏪 커스텀 마켓플레이스 동기화 중..."
    MP_INSTALL_COUNT=0
    MP_SKIP_COUNT=0
    MP_REMOVE_COUNT=0

    # Read desired marketplaces from settings.json extraKnownMarketplaces
    MP_NAMES=$(jq -r '.extraKnownMarketplaces // {} | keys[]' "$NEW" 2>/dev/null)
    for MP_NAME in $MP_NAMES; do
        REPO=$(jq -r ".extraKnownMarketplaces.\"$MP_NAME\".source.repo // empty" "$NEW" 2>/dev/null)
        [ -z "$REPO" ] && continue
        if [ -d "$HOME/.claude/plugins/marketplaces/$MP_NAME" ]; then
            MP_SKIP_COUNT=$((MP_SKIP_COUNT + 1))
        else
            echo "  📥 마켓플레이스 추가 중: $REPO"
            if claude plugin marketplace add "$REPO" 2>/dev/null; then
                MP_INSTALL_COUNT=$((MP_INSTALL_COUNT + 1))
            else
                echo "  ⚠️  추가 실패: $REPO"
            fi
        fi
    done

    # Remove marketplaces not in settings.json
    MP_DIR="$HOME/.claude/plugins/marketplaces"
    if [ -d "$MP_DIR" ]; then
        for mp_path in "$MP_DIR"/*/; do
            [ -d "$mp_path" ] || continue
            mp_name="$(basename "$mp_path")"
            # Skip official marketplaces (claude-plugins-official etc.)
            if ! echo "$MP_NAMES" | grep -q "^${mp_name}$"; then
                # Check if it's a custom marketplace (has source in extraKnownMarketplaces originally)
                # Only remove if it's not a built-in marketplace
                if [ -f "$mp_path/marketplace.json" ]; then
                    IS_OFFICIAL=$(jq -r '.official // false' "$mp_path/marketplace.json" 2>/dev/null)
                    [ "$IS_OFFICIAL" = "true" ] && continue
                fi
                echo "  🗑️  마켓플레이스 제거 중: $mp_name (settings.json에 없음)"
                rm -rf "$mp_path"
                MP_REMOVE_COUNT=$((MP_REMOVE_COUNT + 1))
            fi
        done
    fi

    echo "✅ 마켓플레이스: ${MP_INSTALL_COUNT}개 추가, ${MP_SKIP_COUNT}개 유지, ${MP_REMOVE_COUNT}개 제거"
fi

# Auto-install plugins (declarative: install missing + remove extra)
if [ -f "$SCRIPT_DIR/plugins.txt" ] && command -v claude &> /dev/null; then
    echo ""
    echo "📦 플러그인 동기화 시작..."

    INSTALLED_FILE="$HOME/.claude/plugins/installed_plugins.json"
    INSTALLED_LIST=""
    if [ -f "$INSTALLED_FILE" ]; then
        INSTALLED_LIST=$(jq -r '.plugins | keys[]' "$INSTALLED_FILE" 2>/dev/null)
    fi

    # Build desired plugin list from plugins.txt
    DESIRED_LIST=""
    while IFS= read -r plugin || [ -n "$plugin" ]; do
        [ -z "$plugin" ] && continue
        DESIRED_LIST="$DESIRED_LIST
$plugin"
    done < "$SCRIPT_DIR/plugins.txt"

    # 1. Install missing plugins
    INSTALL_COUNT=0
    SKIP_COUNT=0

    while IFS= read -r plugin || [ -n "$plugin" ]; do
        [ -z "$plugin" ] && continue
        if echo "$INSTALLED_LIST" | grep -q "^${plugin}$"; then
            SKIP_COUNT=$((SKIP_COUNT + 1))
        else
            echo "  📥 설치 중: $plugin"
            if claude plugin install "$plugin" 2>/dev/null; then
                INSTALL_COUNT=$((INSTALL_COUNT + 1))
            else
                echo "  ⚠️  설치 실패: $plugin (수동 설치 필요: /install $plugin)"
            fi
        fi
    done < "$SCRIPT_DIR/plugins.txt"

    # 2. Remove plugins not in plugins.txt
    REMOVE_COUNT=0
    for installed in $INSTALLED_LIST; do
        [ -z "$installed" ] && continue
        if ! echo "$DESIRED_LIST" | grep -q "^${installed}$"; then
            echo "  🗑️  제거 중: $installed (plugins.txt에 없음)"
            if claude plugin uninstall "$installed" 2>/dev/null; then
                REMOVE_COUNT=$((REMOVE_COUNT + 1))
            else
                echo "  ⚠️  제거 실패: $installed"
            fi
        fi
    done

    echo "✅ 플러그인: ${INSTALL_COUNT}개 설치, ${SKIP_COUNT}개 유지, ${REMOVE_COUNT}개 제거"
else
    if [ -f "$SCRIPT_DIR/plugins.txt" ]; then
        echo ""
        echo "📦 Claude Code CLI가 없어 플러그인 수동 설치가 필요합니다."
        echo "Claude Code 실행 후 다음 명령어를 입력하세요:"
        echo ""
        while IFS= read -r plugin || [ -n "$plugin" ]; do
            [ -z "$plugin" ] && continue
            echo "  /install $plugin"
        done < "$SCRIPT_DIR/plugins.txt"
    fi
fi

# Auto-install MCP servers
if [ -f "$SCRIPT_DIR/mcp-servers.txt" ] && command -v claude &> /dev/null; then
    echo ""
    echo "🔌 MCP 서버 설치 확인 중..."
    MCP_INSTALL_COUNT=0

    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        [[ "$line" == \#* ]] && continue

        # Extract server name from "claude mcp add <name> ..."
        SERVER_NAME=$(echo "$line" | sed -n 's/^claude mcp add \([^ ]*\).*/\1/p')
        if [ -n "$SERVER_NAME" ]; then
            # Check if already installed in ~/.claude.json
            if [ -f "$HOME/.claude.json" ] && jq -e ".mcpServers.\"$SERVER_NAME\" // .projects[].mcpServers.\"$SERVER_NAME\"" "$HOME/.claude.json" &>/dev/null; then
                continue
            fi
            echo "  📥 MCP 설치 중: $SERVER_NAME"
            eval "$line" 2>/dev/null && MCP_INSTALL_COUNT=$((MCP_INSTALL_COUNT + 1)) || echo "  ⚠️  설치 실패: $SERVER_NAME"
        fi
    done < "$SCRIPT_DIR/mcp-servers.txt"

    [ "$MCP_INSTALL_COUNT" -gt 0 ] && echo "✅ MCP 서버: ${MCP_INSTALL_COUNT}개 설치"
else
    if [ -f "$SCRIPT_DIR/mcp-servers.txt" ]; then
        echo ""
        echo "🔌 MCP 서버 수동 설치가 필요합니다:"
        while IFS= read -r line || [ -n "$line" ]; do
            [ -z "$line" ] && continue
            [[ "$line" == \#* ]] && continue
            echo "  $line"
        done < "$SCRIPT_DIR/mcp-servers.txt"
    fi
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
