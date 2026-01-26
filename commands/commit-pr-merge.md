# Commit, PR & Merge Command

변경사항을 커밋하고 PR을 생성한 후 merge까지 수행합니다.

**사용법**: `/commit-pr-merge [옵션]`

## Arguments

- `$ARGUMENTS`: merge 제외 옵션 (예: `머지하지마`, `no merge`, `no-merge`)

## 실행 절차

### 1. 현재 상태 확인

```bash
git status
git branch --show-current
git log --oneline -3
```

### 2. 변경사항 분석

- 변경된 파일 목록 확인
- staged/unstaged 변경사항 파악
- 커밋 메시지 초안 작성 (Conventional Commits 형식)

### 3. 커밋

```bash
git add .
git commit -m "{type}: {description}"
```

커밋 타입:
- `feat`: 새 기능
- `fix`: 버그 수정
- `refactor`: 리팩토링
- `chore`: 빌드, 설정 변경
- `docs`: 문서 변경

### 4. PR 생성

기본 브랜치 확인 후 PR 생성:

```bash
# 기본 브랜치 확인
gh repo view --json defaultBranchRef

# 현재 브랜치 push
git push -u origin {current_branch}

# PR 생성
gh pr create --title "{PR 제목}" --body "{PR 본문}"
```

**PR 본문 형식:**
```
## Summary
- {변경 사항 요약}

## Changes
- {상세 변경 내용}
```

### 5. Merge 처리

**Merge 제외 조건**: `$ARGUMENTS`에 다음 중 하나가 포함되면 merge를 건너뜁니다:
- `머지하지마`
- `no merge`
- `no-merge`
- `skip merge`

위 조건에 해당하지 않으면 자동으로 merge 진행:
```bash
gh pr merge {PR번호} --squash
```

### 6. 브랜치 정리

Merge 완료 후 브랜치 정리:
```bash
# main 브랜치로 전환 및 최신화
git checkout main
git pull origin main

# 로컬 브랜치 삭제
git branch -d {merged_branch}

# 원격 브랜치 삭제
git push origin --delete {merged_branch}
```

### 7. 결과 보고

- 커밋 해시
- PR URL
- Merge 상태 (완료/건너뜀)
- 브랜치 정리 상태 (삭제됨/건너뜀)

## 예시

```bash
# 커밋 + PR + Merge (기본)
/commit-pr-merge

# 커밋 + PR만 (merge 제외)
/commit-pr-merge 머지하지마
/commit-pr-merge no merge
/commit-pr-merge no-merge
```

## 주의사항

1. 현재 브랜치가 기본 브랜치인 경우 PR 생성 불필요 → 직접 push만 진행
2. 커밋할 변경사항이 없으면 중단
3. 이미 PR이 있는 경우 기존 PR 업데이트 후 merge
4. Merge conflict 발생 시 해결 후 재시도
5. Merge 후 자동으로 로컬/원격 브랜치 삭제 (main 브랜치로 전환됨)
