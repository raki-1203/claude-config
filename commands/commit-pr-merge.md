# Commit, PR & Merge Command

변경사항을 커밋하고 PR을 생성/업데이트한 후 merge까지 수행합니다.

**사용법**: `/commit-pr-merge [옵션]`

## Arguments

- `$ARGUMENTS`: merge 제외 옵션 (예: `머지하지마`, `no merge`, `no-merge`, `skip merge`)

## Helper Script

`~/.claude/scripts/git-pr-merge.sh` 유틸리티 사용:

```bash
~/.claude/scripts/git-pr-merge.sh <command> [args]
# Commands: get-branch, get-issue-number, get-default-branch, get-existing-pr,
#           get-pr-state, cleanup-stale-prs, close-issue, merge, cleanup-local
```

## 실행 절차

### 1. 상태 확인 및 변경사항 분석

```bash
git status && git branch --show-current && git log --oneline -3
```

### 2. 커밋 (변경사항 있을 때만)

```bash
git add . && git commit -m "{type}: {description}"
```

커밋 타입: `feat`, `fix`, `refactor`, `chore`, `docs`, `perf`, `test`

### 3. 이슈/PR 번호 추출

```bash
branch=$(git branch --show-current)
issue_number=$(echo "$branch" | grep -oE '^[0-9]+')
```

### 4. 기존 PR 확인 및 처리

```bash
existing_pr=$(gh pr list --head "$branch" --json number -q '.[0].number // empty')
```

**분기 처리:**
- PR 없음 → 새 PR 생성 (5단계)
- PR 있음 (OPEN) → push 후 기존 PR merge (6단계)
- PR 있음 (MERGED/CLOSED) → push만 진행

### 5. PR 생성 (기존 PR 없을 때)

```bash
git push -u origin $branch
gh pr create --title "{제목}" --body "$(cat <<'EOF'
Fixes #{issue_number}

## Summary
- {요약}

## Changes
- {상세}
EOF
)"
```

**이슈 번호 없으면** `Fixes #` 라인 제외

### 6. Merge 처리

**Merge 제외 조건**: `$ARGUMENTS`에 `머지하지마`, `no merge`, `no-merge`, `skip merge` 포함 시 건너뜀

```bash
gh pr merge {PR번호} --squash --delete-branch
```

### 7. Stale PR 정리 (CRITICAL)

**Merge 후 반드시 실행** - 커밋은 main에 있지만 PR이 열려있는 경우 정리:

```bash
~/.claude/scripts/git-pr-merge.sh cleanup-stale-prs main
```

### 8. 이슈 닫기

```bash
~/.claude/scripts/git-pr-merge.sh close-issue {issue_number} {pr_number}
```

### 9. 브랜치 정리

```bash
git checkout main && git pull origin main
git branch -d {merged_branch}
```

### 10. 결과 보고

| 항목 | 값 |
|------|-----|
| 커밋 | {hash} |
| PR | #{number} - {url} |
| Merge | 완료/건너뜀 |
| Stale PR 정리 | {count}개 닫힘 |
| 이슈 | 닫힘/해당없음 |
| 브랜치 | 삭제됨/건너뜀 |

## 예시

```bash
/commit-pr-merge              # 전체 실행
/commit-pr-merge 머지하지마    # merge 제외
/commit-pr-merge no-merge     # merge 제외
```

## 주의사항

1. 기본 브랜치(main)에서는 PR 생성 없이 직접 push
2. 변경사항 없으면 커밋 단계 건너뜀
3. **기존 PR 있으면 새로 생성하지 않고 기존 PR merge**
4. Merge conflict 시 해결 후 재시도
5. **Stale PR 자동 정리**: 커밋이 이미 main에 있는 열린 PR 자동 닫기
6. 브랜치 이름 `{번호}-{설명}` 형식이면 해당 이슈 자동 닫기
