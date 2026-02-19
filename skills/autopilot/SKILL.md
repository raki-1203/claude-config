# Autopilot Skill - Autonomous Loop Behavior Guide

## Overview

이 스킬은 Claude가 autopilot 모드에서 동작할 때 참조하는 행동 가이드입니다.
Autopilot은 Ralph Loop 위에 TDD/품질 게이트를 얹은 자율 루프 시스템입니다.

## Gate Messages 대응 방법

### GATE_FAILED [TDD]: Tests failing

테스트가 실패한 상태입니다.

1. 에러 메시지를 주의 깊게 읽으세요
2. 실패하는 테스트의 원인을 파악하세요
3. **테스트를 수정하지 마세요** (테스트가 잘못된 경우 제외)
4. 구현 코드를 수정하여 테스트를 통과시키세요
5. 수정 후 다음 반복에서 게이트가 재검증합니다

### GATE_WARNING [Quality]

품질 문제가 감지되었습니다.

- `console.log`: 디버깅 로그를 제거하세요
- `TypeScript errors`: 타입 에러를 수정하세요
- 품질 경고는 루프를 멈추지 않지만, 완료 전에 해결해야 합니다

### STUCK_DETECTED

동일한 패턴이 반복 감지되었습니다.

1. **같은 접근 방식을 반복하지 마세요**
2. 완전히 다른 전략을 시도하세요
3. 문제를 더 작은 단위로 분해하세요
4. 이전 시도의 결과를 분석하고 새로운 방향을 선택하세요

### CIRCUIT_BREAKER

연속 스턱 횟수가 임계값을 초과하여 루프가 강제 종료되었습니다.
이 경우 루프가 자동으로 중단됩니다.

### COMPLETION_BLOCKED

`<promise>` 태그를 출력했지만 테스트가 아직 실패 중입니다.
**테스트를 먼저 통과시킨 후에만 완료 선언이 가능합니다.**

## TDD 워크플로우 (tdd/focused 모드)

autopilot tdd 모드에서는 반드시 다음 순서를 따르세요:

1. **RED**: 실패하는 테스트를 먼저 작성
2. **GREEN**: 테스트를 통과하는 최소한의 코드 작성
3. **REFACTOR**: 테스트를 유지하면서 코드 개선
4. 각 반복마다 autopilot-gate가 테스트를 실행하여 검증

## 완료 조건

작업이 **진정으로** 완료되었을 때만 completion promise를 출력하세요:

```
<promise>COMPLETE</promise>
```

**절대로** 루프를 탈출하기 위해 거짓 promise를 출력하지 마세요.
완료의 기준:
- 모든 테스트가 통과
- 요청된 기능이 구현됨
- 품질 게이트 경고 없음

## 기존 스킬과의 연동

- **tdd-workflow**: TDD RED→GREEN→REFACTOR 사이클 참조
- **code-review**: 코드 품질 기준 참조
- **security-review**: 보안 체크리스트 참조

## 관련 커맨드

- `/autopilot [mode] [prompt]`: autopilot 시작
- `/cancel-autopilot`: autopilot 즉시 중단
- `/ralph-loop`: 하위 레이어 ralph 루프 직접 제어
- `/cancel-ralph`: ralph 루프 직접 중단
