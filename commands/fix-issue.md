# Fix Issue Command

GitHub 이슈 번호를 받아 브랜치를 생성하고 이슈를 해결하는 워크플로우입니다.

**사용법**: `/fix-issue <이슈번호>`
**예시**: `/fix-issue 68`

## Arguments

- `$ARGUMENTS`: 해결할 GitHub 이슈 번호 (필수)

## 실행 절차

### 1. 이슈 정보 확인

```bash
gh issue view $ARGUMENTS
```

이슈의 title, labels, body를 분석하여 작업 범위를 파악합니다.

### 2. 브랜치 생성

이슈 번호와 제목을 기반으로 브랜치를 생성합니다:

```bash
# 브랜치 명명 규칙: {issue_number}-{kebab-case-title}
# 예: 68-fix-google-auth-profile-photo

git checkout main
git pull origin main
git checkout -b {issue_number}-{short-descriptive-name}
```

### 3. 이슈 분석 및 해결

1. **원인 파악**: 이슈에 명시된 재현 단계와 컨텍스트를 바탕으로 관련 코드 탐색
2. **수정 구현**: 최소한의 변경으로 버그 수정 또는 기능 구현
3. **테스트**: 관련 테스트 실행 및 필요시 테스트 추가

### 4. 커밋 및 푸시

```bash
# 변경사항 커밋 (Conventional Commits 형식)
git add .
git commit -m "fix: {이슈 요약} (#{issue_number})"

# 브랜치 푸시
git push -u origin {branch_name}
```

### 5. PR 생성

```bash
gh pr create --title "{PR 제목}" --body "Fixes #{issue_number}

## 변경 사항
- {변경 내용 요약}

## 테스트
- {테스트 방법}"
```

## 주의사항

1. **Bugfix Rule**: 버그 수정 시 최소한의 변경만 수행. 리팩토링 금지.
2. 수정 전 반드시 관련 코드를 읽고 기존 패턴 파악
3. 테스트 통과 확인 후 PR 생성
4. 이슈에 `Fixes #번호` 링크로 자동 클로즈 설정
