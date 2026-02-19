---
name: gha
description: "GitHub Actions 실패 분석 및 근본 원인 파악. Use when: '/gha [url]', 'CI 실패', 'GitHub Actions 오류', 'workflow failed'."
argument-hint: <GitHub Actions URL>
---

# GitHub Actions 실패 분석

이 GitHub Actions URL을 조사합니다: $ARGUMENTS

gh CLI를 사용하여 워크플로우 실행을 분석합니다.

## 조사 절차

### 1. 기본 정보 및 실제 실패 원인 파악
- 어떤 워크플로우/잡이 실패했는지, 언제, 어떤 커밋에서
- 전체 로그를 읽고 **구체적으로** exit code 1을 유발한 원인 파악
- 경고/비치명적 에러와 실제 실패 구분
- `failing:`, `fatal:`, 또는 exit 1을 결정하는 스크립트 로직 확인

### 2. 플래키(flaky) 여부 확인
동일한 실패 잡의 최근 10-20회 실행 이력 확인:
```bash
gh run list --workflow=<workflow-name>
gh run view <run-id> --json jobs
```
- 일회성 실패인지 반복 패턴인지
- 해당 잡의 최근 성공률
- 마지막으로 통과한 시점

### 3. 원인 커밋 식별 (반복 실패 시)
- 해당 잡이 처음 실패한 실행과 마지막으로 통과한 실행 사이의 커밋 확인
- 해당 커밋 이후 모든 실행에서 실패하는지, 이전에는 모두 통과했는지 검증

### 4. 근본 원인 분석
로그, 이력, 원인 커밋을 종합하여 실패 원인 분석

### 5. 기존 수정 PR 확인
```bash
gh pr list --state open --search "<관련 키워드>"
```

## 최종 보고서

- **실패 요약**: exit code 1을 유발한 구체적 원인
- **플래키 평가**: 일회성 vs 반복, 성공률
- **원인 커밋**: 식별 및 검증된 경우
- **근본 원인 분석**: 실제 실패 트리거 기반
- **기존 수정 PR**: 발견된 경우 (PR 번호 + 링크)
- **권장 조치**: 기존 수정 PR가 없는 경우에만
