---
name: tdd-guide
description: "Test-Driven Development (TDD) specialist enforcing write-tests-first methodology. MUST USE when: fixing bugs (버그 수정), implementing new features (기능 구현), refactoring code, '/fix-issue' invoked, user mentions 'test', 'TDD', '테스트', '테스트 먼저'. Ensures 80%+ test coverage with RED-GREEN-REFACTOR cycle."
---

# TDD Guide

Test-Driven Development specialist: 테스트 먼저, 코드 나중.

## TDD Cycle: RED → GREEN → REFACTOR

```
1. RED     - 실패하는 테스트 작성
2. GREEN   - 테스트 통과하는 최소 코드
3. REFACTOR - 코드 정리 (테스트 유지)
```

---

## Step 1: Write Test First (RED)

**테스트가 먼저. 코드는 나중.**

### Bug Fix 예시

```typescript
// 버그: "로그인 버튼이 비활성화 안됨"
describe('LoginButton', () => {
  it('should be disabled when email is empty', () => {
    render(<LoginButton email="" password="123" />)
    expect(screen.getByRole('button')).toBeDisabled()
  })

  it('should be disabled when password is empty', () => {
    render(<LoginButton email="test@test.com" password="" />)
    expect(screen.getByRole('button')).toBeDisabled()
  })
})
```

### New Feature 예시

```typescript
// 기능: "검색 결과 5개 반환"
describe('searchMarkets', () => {
  it('returns 5 semantically similar markets', async () => {
    const results = await searchMarkets('election')
    
    expect(results).toHaveLength(5)
    expect(results[0].similarity).toBeGreaterThan(0.8)
  })
})
```

---

## Step 2: Verify Test FAILS

```bash
# 테스트 실행 → 반드시 실패해야 함
npm test
# 또는
flutter test
# 또는
pytest
```

**중요**: 테스트가 통과하면 잘못된 테스트! 다시 작성.

---

## Step 3: Write Minimal Code (GREEN)

**테스트 통과하는 최소한의 코드만 작성**

```typescript
// 최소 구현
function LoginButton({ email, password }) {
  const isDisabled = !email || !password
  return <button disabled={isDisabled}>Login</button>
}
```

**하지 말 것:**
- 미래를 위한 코드 추가
- 관련 없는 리팩토링
- 최적화

---

## Step 4: Verify Test PASSES

```bash
npm test
# ✅ All tests pass
```

---

## Step 5: Refactor (IMPROVE)

테스트가 통과한 상태에서:
- 중복 제거
- 이름 개선
- 구조 정리

```bash
# 리팩토링 후 테스트 재실행
npm test
# ✅ Still passing
```

---

## Step 6: Verify Coverage

```bash
npm test -- --coverage
# 또는
flutter test --coverage
# 또는
pytest --cov
```

**목표: 80%+ coverage**

---

## Test Types (필수)

### 1. Unit Tests (항상 필수)

개별 함수/컴포넌트 테스트:

```typescript
describe('calculateSimilarity', () => {
  it('returns 1.0 for identical embeddings', () => {
    const embedding = [0.1, 0.2, 0.3]
    expect(calculateSimilarity(embedding, embedding)).toBe(1.0)
  })

  it('handles null gracefully', () => {
    expect(() => calculateSimilarity(null, [])).toThrow()
  })
})
```

### 2. Integration Tests (API/DB 있으면 필수)

```typescript
describe('GET /api/users', () => {
  it('returns 200 with valid results', async () => {
    const response = await request(app).get('/api/users')
    
    expect(response.status).toBe(200)
    expect(response.body.users).toBeInstanceOf(Array)
  })

  it('returns 401 without auth', async () => {
    const response = await request(app)
      .get('/api/users')
      .set('Authorization', '')
    
    expect(response.status).toBe(401)
  })
})
```

### 3. E2E Tests (중요 플로우만)

```typescript
// Playwright
test('user can login', async ({ page }) => {
  await page.goto('/login')
  await page.fill('input[name="email"]', 'test@test.com')
  await page.fill('input[name="password"]', 'password')
  await page.click('button[type="submit"]')
  
  await expect(page).toHaveURL('/dashboard')
})
```

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

## Mocking External Dependencies

### Mock API/DB

```typescript
jest.mock('@/lib/db', () => ({
  query: jest.fn(() => Promise.resolve([
    { id: 1, name: 'Test' }
  ]))
}))
```

### Mock HTTP

```typescript
jest.mock('axios', () => ({
  get: jest.fn(() => Promise.resolve({ data: mockData }))
}))
```

---

## Quality Checklist

테스트 완료 전 확인:

- [ ] 모든 public 함수에 테스트
- [ ] Edge cases 커버 (null, empty, error)
- [ ] Error paths 테스트 (happy path만 X)
- [ ] Mocks 사용 (외부 의존성)
- [ ] 테스트 독립적 (순서 무관)
- [ ] 80%+ coverage

---

## Anti-Patterns (하지 말 것)

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

---

## Framework Commands

| Framework | Run Tests | Coverage |
|-----------|-----------|----------|
| Jest | `npm test` | `npm test -- --coverage` |
| Vitest | `npm test` | `npm test -- --coverage` |
| Pytest | `pytest` | `pytest --cov` |
| Flutter | `flutter test` | `flutter test --coverage` |
| Go | `go test ./...` | `go test -cover ./...` |

---

## Integration with fix-issue

```
/fix-issue 68
    │
    ├─ 이슈 분석
    │
    ├─ TDD 적용 (이 skill)
    │   ├─ 버그 재현 테스트 작성 (RED)
    │   ├─ 테스트 실패 확인
    │   ├─ 최소 수정 (GREEN)
    │   ├─ 테스트 통과 확인
    │   └─ 리팩토링 (REFACTOR)
    │
    └─ 커밋 + PR
```

---

**Remember**: 테스트 없이 코드 없다. 테스트가 안전망이다.
