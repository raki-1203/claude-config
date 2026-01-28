---
name: gh-issue
description: "Smart GitHub issue creation with codebase analysis, related issue search, and auto-suggested labels. Use when: '/gh-issue [description]', 'create issue', 'report bug', 'feature request', 'open issue', '이슈 등록', '버그 리포트', '기능 요청'. Analyzes user's description, searches for duplicate issues, suggests labels/priority, and creates well-structured issues."
---

# Smart GitHub Issue Creator

Create GitHub issues with intelligent analysis: detects issue type, searches related issues, analyzes codebase for relevant components, and suggests labels/priority.

## Quick Start

```
/gh-issue 로그인 버튼이 모바일에서 너무 작아서 터치가 어려워요
```

## Workflow

### Phase 1: Analyze Request

Extract from user description:

| Field | Description |
|-------|-------------|
| **Issue Type** | bug / feature / task / docs |
| **Problem** | What's wrong or needed |
| **Current Behavior** | How it works now (bugs) |
| **Expected Behavior** | Desired outcome |
| **Component Hints** | Keywords like "login", "mobile", "API" |

**Issue Type Detection:**

| Keywords | Type | Label |
|----------|------|-------|
| 버그, 안됨, 에러, 깨짐, 동작안함, crash, error, broken, not working | bug | `bug` |
| 기능, 추가, 만들어, 개선, 했으면, feature, add, implement, enhance | enhancement | `enhancement` |
| 문서, 설명, README, docs, documentation | docs | `documentation` |
| 리팩토링, 정리, 개선, refactor, cleanup | refactor | `refactor` |
| default | task | `task` |

### Phase 2: Search Related Issues

Check for duplicates and related issues:

```bash
# Search for similar issues
gh issue list --state all --search "[키워드]" --limit 10

# Check if exact duplicate exists
gh issue list --state open --search "[정확한 문제 설명]" --limit 5
```

**If duplicate found:**
```
⚠️ 유사한 이슈가 있습니다:
- #42: [이슈 제목] (open)
- #38: [이슈 제목] (closed)

새 이슈를 생성하시겠습니까? 아니면 기존 이슈에 코멘트를 추가하시겠습니까?
```

### Phase 3: Analyze Codebase (Optional)

If component hints exist, find related code:

```bash
# Find related files
find . -type f -name "*.py" -o -name "*.ts" -o -name "*.tsx" | xargs grep -l "[keyword]" | head -10

# Or use more specific search
grep -r "[component_name]" --include="*.py" --include="*.ts" --include="*.tsx" -l | head -10
```

This helps populate the "Related Components" section with actual file paths.

### Phase 4: Suggest Labels & Priority

**Auto-suggest labels based on analysis:**

```bash
# Get available labels
gh label list --limit 50
```

| Condition | Suggested Labels |
|-----------|-----------------|
| Issue type: bug | `bug` |
| Issue type: feature | `enhancement` |
| Mentions "UI", "button", "style" | `frontend` |
| Mentions "API", "endpoint", "server" | `backend` |
| Mentions "mobile", "responsive" | `mobile` |
| Mentions "security", "auth", "login" | `security` |
| Mentions "performance", "slow" | `performance` |

**Priority Assessment:**

| Condition | Priority | Label |
|-----------|----------|-------|
| Security issue, data loss | P0: Critical | `priority: critical` |
| Blocking workflow, major bug | P1: High | `priority: high` |
| Normal bug, feature request | P2: Medium | `priority: medium` |
| Minor improvement, nice-to-have | P3: Low | `priority: low` |

### Phase 5: Create Issue

#### Bug Template

```markdown
## 문제 (Problem)

[사용자가 설명한 버그 요약]

## 재현 방법 (Steps to Reproduce)

1. [단계 1]
2. [단계 2]
3. [문제 발생]

## 현재 동작 (Current Behavior)

- [현재 어떻게 동작하는지]

## 기대 동작 (Expected Behavior)

- [어떻게 동작해야 하는지]

## 환경 정보 (Environment)

- OS: [운영체제]
- Browser: [브라우저] (해당시)
- Version: [버전]

## 관련 컴포넌트 (Related Components)

- [코드베이스 분석 결과]

## 추가 정보 (Additional Context)

[스크린샷, 로그, 추가 컨텍스트]
```

#### Feature Template

```markdown
## 요약 (Summary)

[기능 요청 한 줄 설명]

## 동기 (Motivation)

[왜 이 기능이 필요한지]

## 상세 설명 (Detailed Description)

[기능의 상세 동작 설명]

## 대안 (Alternatives Considered)

- [고려한 다른 방법들]

## 관련 컴포넌트 (Related Components)

- [영향받는 코드 영역]

## 추가 정보 (Additional Context)

[목업, 레퍼런스, 추가 컨텍스트]
```

#### Task Template

```markdown
## 작업 내용 (Task Description)

[무엇을 해야 하는지]

## 완료 조건 (Acceptance Criteria)

- [ ] [조건 1]
- [ ] [조건 2]
- [ ] [조건 3]

## 관련 컴포넌트 (Related Components)

- [관련 파일/모듈]

## 참고 사항 (Notes)

[추가 컨텍스트]
```

### Phase 6: Execute Creation

```bash
# Create issue with labels
gh issue create \
  --title "[이슈 타입]: [간결한 제목]" \
  --body "$(cat <<'EOF'
[선택된 템플릿 본문]
EOF
)" \
  --label "[auto-suggested-labels]"
```

**Optional flags:**
- `--assignee @me` - Assign to self
- `--milestone "Sprint X"` - Add to milestone
- `--project "Project Name"` - Add to project

### Phase 7: Report Result

```
✅ 이슈 생성 완료

📌 #[번호]: [제목]
🔗 URL: [이슈 URL]
🏷️ Labels: [적용된 라벨들]
📊 Priority: [우선순위]

💡 관련 이슈:
- #[번호]: [관련 이슈 제목]
```

## Examples

### Example 1: Bug Report

**Input:**
```
/gh-issue 로그인 버튼이 모바일에서 너무 작아요
```

**Analysis:**
- Type: `bug` (UI 문제)
- Labels: `bug`, `frontend`, `mobile`
- Priority: P2 (Medium)

**Output Issue:**
```
Title: bug: 모바일 로그인 버튼 크기 문제

## 문제
모바일 환경에서 로그인 버튼이 터치하기 어려울 정도로 작게 표시됨

## 현재 동작
- 모바일에서 로그인 버튼이 작게 렌더링됨
- 터치 타겟이 충분하지 않음

## 기대 동작
- 모바일에서 최소 44x44px 터치 타겟 확보
- 터치하기 쉬운 크기로 표시

## 관련 컴포넌트
- frontend/components/auth/LoginButton.tsx
- frontend/styles/mobile.css
```

### Example 2: Feature Request

**Input:**
```
/gh-issue 다크모드 지원해주세요
```

**Analysis:**
- Type: `enhancement`
- Labels: `enhancement`, `frontend`
- Priority: P3 (Low)

**Output Issue:**
```
Title: feat: 다크모드 테마 지원

## 요약
사용자가 다크모드 테마를 선택할 수 있는 기능 추가

## 동기
- 어두운 환경에서 눈의 피로 감소
- 사용자 선호도 반영
- 배터리 절약 (OLED)

## 상세 설명
- 시스템 설정 자동 감지
- 수동 토글 옵션
- 로컬 스토리지에 선호도 저장

## 관련 컴포넌트
- frontend/contexts/ThemeContext.tsx
- frontend/styles/theme.css
```

### Example 3: Task with Context

**Input:**
```
/gh-issue UserService에 이메일 중복 체크 로직 추가
```

**Analysis:**
- Type: `task`
- Labels: `task`, `backend`
- Related: Search finds `backend/services/user_service.py`

**Output Issue:**
```
Title: task: UserService 이메일 중복 체크 로직 추가

## 작업 내용
UserService에 이메일 중복 여부를 확인하는 메서드 추가

## 완료 조건
- [ ] check_email_exists(email) 메서드 구현
- [ ] 관련 테스트 작성
- [ ] 회원가입 시 중복 체크 연동

## 관련 컴포넌트
- backend/services/user_service.py
- backend/tests/test_user_service.py
```

## Error Handling

| Situation | Action |
|-----------|--------|
| `gh` CLI not installed | Error: "gh CLI가 설치되어 있지 않습니다. `brew install gh` 실행" |
| Not authenticated | Error: "GitHub 인증 필요. `gh auth login` 실행" |
| No repo context | Error: "GitHub 레포지토리가 아닙니다. 레포 디렉토리에서 실행" |
| Duplicate issue exists | Warning: 유사 이슈 알림 후 사용자 확인 요청 |

## Integration with Other Commands

This skill works well with:
- `/fix-issue [번호]`: 생성된 이슈 해결
- `/commit-pr-merge`: 수정 후 PR 생성
