---
name: fix-issue
description: "GitHub 이슈를 TDD 기반으로 해결. 브랜치 생성 → TDD → 리뷰 → (통과 시) 커밋/PR → 배포. 리뷰 실패 시 수정 후 재리뷰. Use when: '/fix-issue [이슈번호]', 'fix issue', '이슈 수정', '이슈 해결', 'resolve issue'. ALWAYS uses tdd-guide skill for test-first development."
---

# Fix Issue with TDD

GitHub 이슈 해결: TDD (테스트 먼저) + 자동 배포

## 핵심 원칙: 자동 진행 (심각한 경우 제외)

**일반적인 경우 사용자에게 물어보지 않고 끝까지 자동 진행한다.**

- ❌ BLOCK 리뷰 → 수정 후 재시도
- ⚠️ WARNING → 기록만 하고 자동 진행
- 배포 여부 → 프로젝트 설정(`.deploy.yaml`)에 따라 자동 결정
- 질문 금지: "진행할까요?", "배포할까요?" 등 확인 요청 하지 않음

### 예외: 심각한 이슈는 사용자 확인 필요

다음 경우에는 **반드시 사용자에게 확인** 후 진행:

| 심각도 | 예시 | 행동 |
|--------|------|------|
| 🔴 **보안** | 인증 우회, 권한 상승, 민감 데이터 노출 | 수정 방향 확인 후 진행 |
| 🔴 **데이터 손실** | DB 스키마 변경, 마이그레이션, 삭제 로직 | 롤백 계획 확인 후 진행 |
| 🔴 **Breaking Change** | API 시그니처 변경, 하위 호환성 깨짐 | 영향 범위 확인 후 진행 |
| 🔴 **대규모 변경** | 10+ 파일 수정, 아키텍처 변경 | 접근 방식 확인 후 진행 |

```
심각한 이슈 감지 시:
"⚠️ 이 이슈는 [보안/데이터/Breaking Change] 관련입니다.
제안 수정 방향: [요약]
진행해도 될까요?"
```

## Quick Start

```bash
/fix-issue 68
```

## Workflow Overview

```
이슈 분석 → 브랜치 생성 → TDD (테스트→수정→리팩토링) → 리뷰 → [통과] → 커밋 → PR → 배포
                                                    ↑         ↓
                                                    └─ [실패] ←┘ (수정 후 재리뷰)
```

## Required Skills

**자동 로드**: 이 skill 사용 시 `tdd-guide` skill도 함께 로드

```
delegate_task(load_skills=["fix-issue", "tdd-guide"], ...)
```

---

## Phase 1: Issue Analysis

```bash
gh issue view $ISSUE_NUMBER
```

Extract from issue:
- **Title**: 브랜치명 및 커밋 메시지용
- **Labels**: bug/feature/enhancement 분류
- **Body**: 재현 단계, 관련 컴포넌트 힌트

---

## Phase 2: Branch Creation

```bash
git checkout main
git pull origin main
git checkout -b {issue_number}-{kebab-case-title}
```

**Branch naming**: `68-fix-login-button-mobile`

---

## Phase 3: TDD-based Resolution

**핵심: 테스트 먼저, 코드 나중** (tdd-guide skill 참조)

### 3.1 Write Failing Test (RED)

이슈를 재현하는 테스트 작성:

```typescript
// Bug: "로그인 버튼이 비활성화 안됨"
describe('LoginButton', () => {
  it('should be disabled when email is empty', () => {
    render(<LoginButton email="" password="123" />)
    expect(screen.getByRole('button')).toBeDisabled()  // 이게 실패해야 함
  })
})
```

### 3.2 Verify Test FAILS

```bash
npm test  # 반드시 실패 확인
```

**테스트가 통과하면**: 잘못된 테스트 → 다시 작성

### 3.3 Write Minimal Fix (GREEN)

테스트 통과하는 **최소한의 코드**만 작성:

```typescript
// 최소 수정
function LoginButton({ email, password }) {
  const isDisabled = !email || !password  // 이 한 줄 추가
  return <button disabled={isDisabled}>Login</button>
}
```

### 3.4 Verify Test PASSES

```bash
npm test  # 이제 통과
```

### 3.5 Refactor (IMPROVE)

테스트 유지하며 코드 정리:
- 중복 제거
- 이름 개선
- OCP 원칙 적용

### 3.6 OCP Principle (Open-Closed Principle)

리팩토링 시 우선순위:

| 순위 | 접근 방식 | 예시 |
|-----|----------|------|
| 1순위 | 새 파일/클래스 추가 | 새 Provider, Service 생성 |
| 2순위 | 기존 인터페이스 확장 | 필드/메서드 추가 (시그니처 유지) |
| 3순위 | 기존 코드 최소 수정 | 호출부만 수정, 로직은 새 코드에 위임 |

### 3.7 Verify Coverage

```bash
npm test -- --coverage  # 80%+ 목표
```

---

## Phase 4: Code Review (커밋 전 필수)

**핵심: 리뷰 통과 전까지 커밋/PR 진행하지 않음**

### 4.1 code-reviewer 에이전트로 리뷰 수행

```bash
# code-reviewer 에이전트 활성화하여 변경사항 리뷰
delegate_task(
  subagent_type="code-reviewer",
  load_skills=["security-review"],
  prompt="Review the changes for issue #{issue_number}. Check: security, code quality, performance, best practices."
)
```

### 4.2 리뷰 항목

| 카테고리 | 체크 포인트 |
|---------|-----------|
| **보안** | 하드코딩된 자격증명, SQL 주입, XSS 취약점 |
| **코드 품질** | 함수 크기, 중첩 깊이, 에러 처리, 테스트 커버리지 |
| **성능** | 알고리즘 효율성, 캐싱, N+1 쿼리 패턴 |
| **모범 사례** | 명명 규칙, 문서화, 접근성 |

### 4.3 리뷰 결과 처리

```
✅ APPROVE → Phase 5 (커밋) 진행
⚠️ WARNING → 경고 사항 기록 후 Phase 5 자동 진행 (사용자 확인 없이 계속)
❌ BLOCK → 반드시 수정 후 Phase 4 재실행
```

### 4.4 리뷰 실패 시 수정 루프

```
리뷰 실패 (❌ BLOCK)
    ↓
지적 사항 분석
    ↓
코드 수정 (Phase 3의 TDD 방식 유지)
    ↓
테스트 재실행
    ↓
Phase 4 재실행 (재리뷰)
    ↓
통과할 때까지 반복
```

**재리뷰 시 이전 지적 사항이 해결되었는지 명시적으로 확인**

---

## Phase 5: Commit & Push (리뷰 통과 후)

**선행 조건: Phase 4 리뷰 ✅ APPROVE 또는 ⚠️ WARNING (자동 진행)**

```bash
git add .
git commit -m "{type}: {summary} (#{issue_number})"
git push -u origin {branch_name}
```

**Commit types:** fix, feat, refactor, chore, docs

---

## Phase 6: PR Creation

```bash
gh pr create --title "{type}: {title}" --body "$(cat <<'EOF'
Fixes #{issue_number}

## Changes
- {변경 내용}

## Testing
- {테스트 방법}

## Code Review
- ✅ Reviewed by code-reviewer agent
- {리뷰 결과 요약}
EOF
)"
```

---

## Phase 7: Auto Deploy

프로젝트 타입을 자동 감지하여 적절한 배포 수행.

### 7.1 Project Type Detection

```bash
# Detection order (first match wins)
if [ -f "pubspec.yaml" ]; then
    PROJECT_TYPE="flutter"
elif [ -d "*.xcodeproj" ] || [ -d "*.xcworkspace" ]; then
    PROJECT_TYPE="ios-native"
elif [ -f "package.json" ]; then
    PROJECT_TYPE="web"
fi
```

### 7.2 Custom Deploy Config (Optional)

프로젝트 루트에 `.deploy.yaml` 파일이 있으면 커스텀 설정 사용:

```yaml
# .deploy.yaml example
type: flutter  # flutter | ios-native | web
platform: ios  # ios | android | web

modes:
  local:
    commands:
      - flutter build ios --debug
      - flutter install
  
  remote:
    commands:
      - flutter build ipa --release
      - cd ios && fastlane beta
```

### 7.3 Deploy by Project Type

#### iOS/Flutter Projects

```bash
# Check USB connection
ios-deploy --detect 2>/dev/null

if [ $? -eq 0 ]; then
    # USB connected → Local install (fast)
    DEPLOY_MODE="local"
else
    # No USB → TestFlight (remote)
    DEPLOY_MODE="remote"
fi
```

**Local Deploy (USB):**
- Flutter: `flutter install`
- iOS Native: `ios-deploy --bundle build/ios/iphoneos/Runner.app`

**Remote Deploy (TestFlight):**
- Flutter: `flutter build ipa && cd ios && fastlane pilot upload`
- iOS Native: `fastlane pilot upload`

See [references/deploy-ios.md](references/deploy-ios.md) for detailed commands.

#### Web Projects

웹 프로젝트는 로컬 테스트가 쉬우므로 **배포 단계 스킵** (PR 생성으로 완료).

`.deploy.yaml`이 있는 경우에만 자동 배포 실행:
- Vercel: `vercel`
- Netlify: `netlify deploy`
- Custom: `.deploy.yaml` 설정에 따름

See [references/deploy-web.md](references/deploy-web.md) for detailed commands.

---

## Phase 8: Completion Report

```
✅ 이슈 #68 해결 완료

📌 Branch: 68-fix-login-button-mobile
🔀 PR: #69 (URL)
📱 Deploy: TestFlight (build 1.2.3)
🔍 Code Review: ✅ Approved

💡 다음 단계:
- PR 리뷰 요청
- TestFlight에서 테스트 확인
```

---

## Error Handling

| 상황 | 처리 |
|------|------|
| 이슈 없음 | "이슈 #N을 찾을 수 없습니다" |
| 브랜치 이미 존재 | 기존 브랜치 checkout |
| 빌드 실패 | 에러 로그 표시, 배포 스킵 |
| ios-deploy 미설치 | "npm install -g ios-deploy 실행" |
| fastlane 미설치 | "gem install fastlane 실행" |

---

## Examples

### Example 1: Flutter iOS Bug Fix (리뷰 통과)

```
/fix-issue 68

→ 이슈 분석: "로그인 버튼 모바일 크기 문제"
→ 브랜치: 68-fix-login-button-mobile
→ TDD: 테스트 작성 → 수정 → 테스트 통과
→ Code Review (code-reviewer): ✅ APPROVE
→ 커밋 & 푸시
→ PR #69 생성
→ USB 연결 감지됨 → flutter install
→ "iPhone에 설치 완료! 테스트해주세요"
```

### Example 2: 리뷰 실패 후 재수정

```
/fix-issue 42

→ 이슈 분석: "프로필 사진 업로드 실패"
→ 브랜치: 42-fix-profile-upload
→ TDD: 수정 완료, 테스트 통과
→ Code Review (code-reviewer): ❌ BLOCK
   - "보안 이슈: 파일 타입 검증 누락"
→ 수정: 파일 타입 검증 추가
→ 테스트 재실행 → 통과
→ Code Review (재리뷰): ✅ APPROVE
→ 커밋 & 푸시
→ PR #43 생성
→ TestFlight 업로드 완료
```

### Example 3: Web Project (경고 수준 자동 진행)

```
/fix-issue 15

→ 이슈 분석: "다크모드 토글 버그"
→ 브랜치: 15-fix-darkmode-toggle
→ 수정 완료
→ Code Review (code-reviewer): ⚠️ WARNING
   - "성능: 불필요한 리렌더링 있음 (권장 수정)"
→ 경고 기록 후 자동 진행
→ 커밋 & 푸시
→ PR #16 생성
→ 배포 스킵 (웹 프로젝트)
→ "완료! npm run dev로 로컬 테스트 가능"
```

---

## Integration

**Required Skills:**
- `tdd-guide`: TDD 워크플로우 (자동 로드)

**Related Agents:**
- `code-reviewer`: 커밋 전 자동 코드 리뷰 (Phase 4) - 리뷰 통과 필수

**Works with:**
- `/gh-issue`: 이슈 생성
- `/commit-pr-merge`: PR 머지
- `kent-beck-refactor`: 리팩토링 후처리
- `code-review`: 수동 코드 리뷰

---

## Bugfix Rule

**버그 수정 시 최소한의 변경만 수행. 리팩토링 금지.**

예외:
- 명백한 버그 수정 (로직/타입 오류)
- 보안 취약점 패치
- 잘못된 설계 (사전 협의 필요)
