---
name: TDD Development Rules
description: 모든 프로젝트에 적용되는 TDD 및 개발 원칙
globs: ["**/*.py", "**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx", "**/*.dart", "**/*.swift", "**/*.go"]
---

# TDD Development Rules

테스트 주도 개발 및 코드 품질 원칙. 모든 프로젝트에 적용.

## TDD Cycle: RED -> GREEN -> REFACTOR

### Step 1: Write Test First (RED)

**테스트가 먼저. 코드는 나중.**

```
1. 실패하는 테스트 작성
2. 테스트 실행 → 반드시 실패 확인
3. 테스트가 통과하면 잘못된 테스트 → 다시 작성
```

### Step 2: Write Minimal Code (GREEN)

**테스트 통과하는 최소한의 코드만 작성**

하지 말 것:
- 미래를 위한 코드 추가
- 관련 없는 리팩토링
- 최적화

### Step 3: Refactor (IMPROVE)

테스트가 통과한 상태에서:
- 중복 제거
- 이름 개선
- 구조 정리
- 테스트 재실행으로 녹색 유지 확인

---

## Bugfix Rule

**버그 수정 시 최소 변경만 수행. 리팩토링 금지.**

| 허용 | 금지 |
|------|------|
| 버그 원인 직접 수정 | 주변 코드 정리 |
| 관련 타입 오류 수정 | 변수명 리네이밍 |
| 보안 취약점 패치 | 구조 변경 |

예외:
- 명백한 로직/타입 오류 (버그와 직접 관련)
- 보안 취약점 패치 (즉시 필요)
- 잘못된 설계 (사전 협의 필요)

---

## Code Review (커밋 전 필수)

커밋 전 code-reviewer 에이전트로 검토:

| 카테고리 | 체크 포인트 |
|---------|-----------|
| **보안** | 하드코딩된 자격증명, SQL 주입, XSS |
| **코드 품질** | 함수 크기, 중첩 깊이, 에러 처리 |
| **성능** | 알고리즘 효율성, 캐싱, N+1 쿼리 |
| **모범 사례** | 명명 규칙, 문서화, 접근성 |

### 리뷰 결과 처리

```
✅ APPROVE → 커밋 진행
⚠️ WARNING → 권장 사항 검토 후 결정
❌ BLOCK → 반드시 수정 후 재리뷰
```

---

## OCP Principle (리팩토링 우선순위)

Open-Closed Principle 적용:

| 순위 | 접근 방식 | 예시 |
|-----|----------|------|
| 1순위 | 새 파일/클래스 추가 | 새 Provider, Service 생성 |
| 2순위 | 기존 인터페이스 확장 | 필드/메서드 추가 (시그니처 유지) |
| 3순위 | 기존 코드 최소 수정 | 호출부만 수정, 로직은 새 코드에 위임 |

---

## Coverage Target

```bash
# 목표: 80%+ 커버리지
npm test -- --coverage
pytest --cov
flutter test --coverage
```

---

## Test Types (필수)

### 1. Unit Tests (항상 필수)
개별 함수/컴포넌트 테스트

### 2. Integration Tests (API/DB 있으면 필수)
모듈 간 상호작용 테스트

### 3. E2E Tests (중요 플로우만)
사용자 시나리오 전체 흐름

---

## Edge Cases (반드시 테스트)

| Case | Example |
|------|---------|
| Null/Undefined | `input = null` |
| Empty | `input = ""` or `[]` |
| Invalid Type | `string` instead of `number` |
| Boundary | `0`, `-1`, `MAX_INT` |
| Error | Network failure, DB error |
| Special Chars | Unicode, emoji, SQL injection |

---

## Anti-Patterns

### ❌ Implementation 테스트
```typescript
// BAD: 내부 상태 테스트
expect(component.state.count).toBe(5)
```

### ✅ Behavior 테스트
```typescript
// GOOD: 사용자가 보는 것 테스트
expect(screen.getByText('Count: 5')).toBeInTheDocument()
```

### ❌ 테스트 간 의존
```typescript
// BAD: 이전 테스트에 의존
test('creates user', () => { /* ... */ })
test('updates same user', () => { /* 위 테스트 필요 */ })
```

### ✅ 독립적 테스트
```typescript
// GOOD: 각 테스트에서 데이터 생성
test('updates user', () => {
  const user = createTestUser()
  // ...
})
```
