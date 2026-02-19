---
name: codex-review
description: "OpenAI Codex CLI로 코드 리뷰 수행. Claude의 code-reviewer와 다른 관점의 크로스 리뷰 제공. Use when: '/codex-review', 'codex 리뷰', 'cross review', '크로스 리뷰', 'second opinion'."
---

# Codex CLI 코드 리뷰

OpenAI Codex CLI의 `codex review` 명령으로 코드 리뷰를 수행합니다.
Claude의 code-reviewer와 다른 AI 모델(OpenAI)의 관점에서 크로스 리뷰를 제공합니다.

## 사용법

```
/codex-review                    # uncommitted 변경사항 리뷰
/codex-review --base main        # main 브랜치 대비 변경사항 리뷰
/codex-review --commit abc123    # 특정 커밋 리뷰
```

## 리뷰 모드

### 1. Uncommitted 변경사항 리뷰 (기본)
```bash
codex review --uncommitted
```

### 2. 브랜치 대비 리뷰
```bash
codex review --base main
```

### 3. 특정 커밋 리뷰
```bash
codex review --commit <SHA>
```

### 4. 커스텀 지시사항 포함 리뷰
```bash
codex review --uncommitted "보안 취약점과 성능 이슈에 집중해서 리뷰해줘"
```

## 실행 절차

1. **인자 파싱**: `$ARGUMENTS`에서 리뷰 모드 결정
   - 인자 없음 → `--uncommitted`
   - `--base`, `--commit` 등 → 그대로 전달
   - 텍스트만 → `--uncommitted` + 해당 텍스트를 커스텀 지시사항으로

2. **Codex 리뷰 실행**: Bash 도구로 `codex review` 실행
   - 타임아웃: 120초 (기본)
   - 출력이 길면 핵심만 요약

3. **결과 분석 및 보고**: Codex 리뷰 결과를 읽고 사용자에게 보고
   - Critical/High/Medium/Low로 분류
   - Claude code-reviewer와 겹치는 부분과 Codex만 발견한 부분 구분
   - 수정이 필요한 항목은 구체적 수정 방안 제시

## 크로스 리뷰 워크플로우

Claude code-reviewer와 Codex를 함께 사용하면 더 강력합니다:

```
1. Claude code-reviewer로 1차 리뷰
2. /codex-review로 2차 크로스 리뷰
3. 두 리뷰 결과를 종합하여 최종 판단
```

이를 통해 한 모델이 놓칠 수 있는 이슈를 다른 모델이 잡아내는 보완 효과를 얻습니다.
