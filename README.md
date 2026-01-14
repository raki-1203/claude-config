# Claude Code 개인 설정

Claude Code 설정을 여러 기기에서 공유하기 위한 저장소입니다.

## 빠른 시작

```bash
# 1. Claude Code 설치 (먼저)
npm install -g @anthropic-ai/claude-code
claude  # 첫 실행 및 로그인

# 2. jq 설치
brew install jq

# 3. 이 저장소 클론 후 설치
git clone <repository-url> ~/claude-config
cd ~/claude-config
./install.sh
```

## 포함된 설정

### 자동 설치 (install.sh)

| 항목 | 설명 |
|------|------|
| **settings.json** | 권한, hooks, 플러그인 활성화 (기존 설정과 병합) |
| **hooks/** | 작업 완료 Slack 알림 |
| **skills/** | kent-beck-refactor, playwright-test |
| **agents/** | 커스텀 에이전트 (있는 경우) |
| **commands/** | 커스텀 슬래시 커맨드 (있는 경우) |
| **rules/** | 커스텀 규칙 (있는 경우) |
| **CLAUDE.md** | 전역 지침 (있는 경우) |

### 수동 설치 안내 (install.sh 실행 시 출력)

| 항목 | 파일 |
|------|------|
| **플러그인** | plugins.txt |
| **MCP 서버** | mcp-servers.txt |
| **환경변수** | env-template.txt |

## 스크립트

### install.sh - 설정 설치
```bash
./install.sh
```
- ~/.claude/ 폴더에 설정 복사
- 기존 settings.json과 병합 (덮어쓰기 X)
- 필요한 플러그인/MCP/환경변수 안내

### sync.sh - 설정 동기화
```bash
./sync.sh
```
- 현재 ~/.claude/ 설정을 이 저장소로 복사
- plugins.txt, mcp-servers.txt 자동 생성
- 개인 정보(API 키 등) 제외

## 파일 구조

```
claude-config/
├── settings.json       # 권한, hooks, 플러그인 활성화
├── hooks/
│   └── task-complete-notify.sh
├── skills/
│   ├── kent-beck-refactor/
│   └── playwright-test/
├── agents/             # (있는 경우)
├── commands/           # (있는 경우)
├── rules/              # (있는 경우)
├── CLAUDE.md           # (있는 경우)
├── plugins.txt         # 설치할 플러그인 목록
├── mcp-servers.txt     # MCP 서버 설치 명령어
├── env-template.txt    # 필요한 환경변수
├── install.sh          # 설치 스크립트
├── sync.sh             # 동기화 스크립트
└── README.md
```

## 공유 가능 여부

### ✅ Git으로 공유 가능
- settings.json, hooks, skills, agents, commands, rules
- CLAUDE.md
- .mcp.json (프로젝트용, API 키는 환경변수로)

### ❌ 공유 불가 (개인 정보)
- settings.local.json (자동 gitignore)
- ~/.claude.json (개인 MCP, 통계)
- API 키, Webhook URL 등

## 알림 형식

작업 완료 시 Slack:
```
============================================
*WarpTerminal* : 탭이름 작업 완료 ✅
*프로젝트* : project-name
============================================
```

## 설정 변경 시

1. Claude Code에서 설정 변경
2. `./sync.sh` 실행
3. 변경사항 커밋
```bash
cd ~/claude-config
./sync.sh
git add . && git commit -m "Update settings"
git push
```

## 다른 기기에서 업데이트 받기

```bash
cd ~/claude-config
git pull
./install.sh
```
