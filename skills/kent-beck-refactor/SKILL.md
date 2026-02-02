---
name: kent-beck-refactor
description: "Kent Beck style refactoring workflow for code quality improvement. Triggers automatically after completing features, tasks, or phases. Analyzes cyclomatic complexity (≤10) and cognitive complexity (≤15), refactors code following TDD principles, runs tests, commits logically, and creates PRs. Use when: 리팩토링해줘, 켄트백 스타일로, refactor and commit, 리팩토링하고 PR, 복잡도 낮춰줘, clean code, 테스트하고 커밋, 커밋하고 PR, 요구사항 완료, 기능 완료, task 완료, phase 완료, feature complete, task complete, phase complete"
allowed-tools: Read, Grep, Glob, Bash, LSP, Edit, Git
---

# Kent Beck Refactor Skill

You are a code quality expert who follows Kent Beck's refactoring principles and TDD (Test-Driven Development) practices. Your mission is to systematically improve code quality after feature implementation.

## Core Philosophy

> "Make it work, make it right, make it fast." - Kent Beck

This skill focuses on the **"make it right"** phase after features are implemented. Apply refactoring in small, safe steps with continuous test verification.

## When to Trigger

### Automatic Triggers (Post-Implementation)
- After completing a feature or requirement
- When a task is marked as complete
- After finishing a phase in a multi-phase project
- When user says completion phrases like:
  - "요구사항 완료", "기능 완료", "task 완료", "phase 완료"
  - "feature complete", "task complete", "phase complete"

### Manual Triggers (On-Demand)
- "리팩토링해줘", "켄트백 스타일로", "refactor this"
- "복잡도 낮춰줘", "reduce complexity"
- "clean code", "improve code quality"
- "refactor and commit", "리팩토링하고 PR"
- "테스트하고 커밋", "test and commit", "commit and PR"

## Workflow

### Phase 1: Analyze (분석)

**Objective**: Identify code that needs refactoring and measure complexity.

#### 1.1 Identify Changed Files
```bash
# Check what files were modified
git status
git diff --name-only

# For Python: Find functions with high complexity
radon cc <file> -s -a

# For TypeScript/JavaScript: Check with ESLint
npx eslint <file> --format json
```

#### 1.2 Complexity Metrics

**Refactoring Needed When:**
- **Cyclomatic Complexity** > 10 (too many branches/loops)
- **Cognitive Complexity** > 15 (too hard to understand)
- **Function Length** > 50 lines
- **Nesting Depth** > 4 levels
- **Duplicate Code** detected

**Tools by Language:**

```bash
# Python
radon cc <file> -s        # Cyclomatic complexity
radon mi <file>            # Maintainability index

# TypeScript/JavaScript
npx eslint <file> --rule 'complexity: ["error", 10]'
npx eslint <file> --rule 'max-depth: ["error", 4]'
```

#### 1.3 Create Refactoring Plan

Document what needs improvement:
```markdown
## Refactoring Plan

### File: <filename>
- Function: <function_name> (CC: 15 → Target: <10)
  - Issue: Too many nested conditionals
  - Pattern: Extract Method, Guard Clauses
  
### File: <filename2>
- Function: <function_name2> (CC: 12 → Target: <8)
  - Issue: Complex business logic
  - Pattern: Strategy Pattern, Replace Conditional with Polymorphism
```

### Phase 2: Refactor (리팩토링)

**Principle**: Small Steps + Continuous Testing

Kent Beck's refactoring patterns to apply:

#### 2.1 Extract Method
Break down large functions into smaller, focused ones.

**Python Example:**
```python
# BEFORE (CC: 12)
def process_order(order_data):
    if order_data.get("type") == "premium":
        if order_data.get("verified"):
            if order_data.get("in_stock"):
                discount = calculate_premium_discount(order_data)
                price = order_data["price"] * (1 - discount)
                if price > 1000:
                    shipping = 0
                else:
                    shipping = 10
                return {"price": price, "shipping": shipping, "status": "success"}
    return {"status": "failed"}

# AFTER (CC: 3)
def process_order(order_data):
    if not is_valid_premium_order(order_data):
        return {"status": "failed"}
    
    return calculate_order_details(order_data)

def is_valid_premium_order(order_data):
    return (
        order_data.get("type") == "premium"
        and order_data.get("verified")
        and order_data.get("in_stock")
    )

def calculate_order_details(order_data):
    discount = calculate_premium_discount(order_data)
    price = order_data["price"] * (1 - discount)
    shipping = get_shipping_cost(price)
    return {"price": price, "shipping": shipping, "status": "success"}

def get_shipping_cost(price):
    return 0 if price > 1000 else 10
```

#### 2.2 Simplify Conditionals
Use guard clauses and early returns.

**TypeScript Example:**
```typescript
// BEFORE (CC: 8)
function validateUser(user: User): ValidationResult {
  if (user) {
    if (user.email) {
      if (user.age >= 18) {
        if (user.verified) {
          return { valid: true };
        } else {
          return { valid: false, reason: "Not verified" };
        }
      } else {
        return { valid: false, reason: "Underage" };
      }
    } else {
      return { valid: false, reason: "No email" };
    }
  }
  return { valid: false, reason: "No user" };
}

// AFTER (CC: 4)
function validateUser(user: User): ValidationResult {
  if (!user) {
    return { valid: false, reason: "No user" };
  }
  if (!user.email) {
    return { valid: false, reason: "No email" };
  }
  if (user.age < 18) {
    return { valid: false, reason: "Underage" };
  }
  if (!user.verified) {
    return { valid: false, reason: "Not verified" };
  }
  return { valid: true };
}
```

#### 2.3 Replace Conditional with Polymorphism

**Python Example:**
```python
# BEFORE (CC: 10)
def calculate_shipping(order_type, weight, distance):
    if order_type == "express":
        base = 20
        rate = 2.5
    elif order_type == "standard":
        base = 10
        rate = 1.5
    elif order_type == "economy":
        base = 5
        rate = 0.8
    else:
        base = 0
        rate = 0
    
    return base + (weight * rate) + (distance * 0.1)

# AFTER (CC: 2 per class)
from abc import ABC, abstractmethod

class ShippingStrategy(ABC):
    @abstractmethod
    def calculate(self, weight: float, distance: float) -> float:
        pass

class ExpressShipping(ShippingStrategy):
    def calculate(self, weight: float, distance: float) -> float:
        return 20 + (weight * 2.5) + (distance * 0.1)

class StandardShipping(ShippingStrategy):
    def calculate(self, weight: float, distance: float) -> float:
        return 10 + (weight * 1.5) + (distance * 0.1)

class EconomyShipping(ShippingStrategy):
    def calculate(self, weight: float, distance: float) -> float:
        return 5 + (weight * 0.8) + (distance * 0.1)

STRATEGIES = {
    "express": ExpressShipping(),
    "standard": StandardShipping(),
    "economy": EconomyShipping(),
}

def calculate_shipping(order_type: str, weight: float, distance: float) -> float:
    strategy = STRATEGIES.get(order_type)
    if not strategy:
        return 0
    return strategy.calculate(weight, distance)
```

#### 2.4 Remove Duplication (DRY Principle)

Look for repeated code patterns and extract common logic.

```python
# BEFORE
def create_user(data):
    if not data.get("email"):
        logger.error("Missing email")
        raise ValueError("Email required")
    if not data.get("name"):
        logger.error("Missing name")
        raise ValueError("Name required")
    # ...

# AFTER
def validate_required_field(data: dict, field: str) -> None:
    if not data.get(field):
        logger.error(f"Missing {field}")
        raise ValueError(f"{field.capitalize()} required")

def create_user(data):
    validate_required_field(data, "email")
    validate_required_field(data, "name")
    # ...
```

#### 2.5 Rename for Clarity

Use intention-revealing names.

```python
# BEFORE
def f(x, y):
    return x * y * 0.1

# AFTER
def calculate_tax_amount(price: float, quantity: int) -> float:
    """Calculate tax amount (10% rate)."""
    return price * quantity * 0.1
```

### Phase 3: Verify (검증)

**Objective**: Ensure refactoring didn't break functionality.

#### 3.1 Type Check
```bash
# Python
uv run mypy . || { echo "Type check failed!"; exit 1; }

# TypeScript
npm run tsc --noEmit || { echo "Type check failed!"; exit 1; }
```

#### 3.2 Lint Check
```bash
# Python
uv run ruff check . || { echo "Lint failed!"; exit 1; }
uv run ruff format .

# TypeScript
npm run lint || { echo "Lint failed!"; exit 1; }
npm run lint:fix
```

#### 3.3 Run Tests
```bash
# Python
uv run pytest -v || { echo "Tests failed!"; exit 1; }

# TypeScript/JavaScript
npm test || { echo "Tests failed!"; exit 1; }
```

#### 3.4 Build Check (if applicable)
```bash
# Backend
uv run python -m compileall . || { echo "Build failed!"; exit 1; }

# Frontend
npm run build || { echo "Build failed!"; exit 1; }
```

**Critical Rule**: If ANY verification step fails, DO NOT proceed to commit. Fix issues first.

### Phase 4: Commit (커밋)

**Principle**: Commit logical, atomic changes with clear messages.

#### 4.1 Review Changes
```bash
git diff
git status
```

#### 4.2 Stage Changes
```bash
# Stage specific files
git add <file1> <file2>

# Or stage all if refactoring is cohesive
git add .
```

#### 4.3 Commit Message Format

Follow Conventional Commits:

```
<type>: <short summary>

<body - explain WHY, not WHAT>

<footer - references, metrics>
```

**Types:**
- `refactor`: Code restructuring (no behavior change)
- `perf`: Performance improvement
- `style`: Formatting, naming (no logic change)
- `chore`: Build config, tooling

**Good Commit Message Example:**
```
refactor: simplify order validation logic

Extracted nested conditionals into guard clauses and separate
validation functions. This improves readability and reduces
cyclomatic complexity.

Complexity metrics:
- process_order: CC 12 → 3
- validate_user: CC 8 → 4

Related: #123
```

#### 4.4 Execute Commit
```bash
git commit -m "refactor: <description>"
```

**Multiple Logical Changes?** Make separate commits:
```bash
# Commit 1: Extract methods
git add file1.py file2.py
git commit -m "refactor: extract validation methods"

# Commit 2: Simplify conditionals
git add file3.py
git commit -m "refactor: replace nested ifs with guard clauses"
```

### Phase 5: Pull Request (PR 생성)

**Objective**: Submit refactoring for code review.

#### 5.1 Push to Remote
```bash
# Create feature branch if not already on one
git checkout -b refactor/improve-complexity

# Push changes
git push origin refactor/improve-complexity
```

#### 5.2 Create PR with GitHub CLI
```bash
gh pr create --title "refactor: improve code complexity and maintainability" --body "$(cat <<'EOF'
## Summary
Post-implementation refactoring to improve code quality following Kent Beck principles.

## Refactoring Details

### Before
| File | Function | Cyclomatic Complexity |
|------|----------|----------------------|
| order.py | process_order | 12 |
| validation.py | validate_user | 8 |

### After
| File | Function | Cyclomatic Complexity |
|------|----------|----------------------|
| order.py | process_order | 3 |
| order.py | is_valid_premium_order | 2 |
| order.py | calculate_order_details | 2 |
| validation.py | validate_user | 4 |

**Complexity Reduction**: Average CC reduced from 10 to 2.75

## Refactoring Patterns Applied
- [x] Extract Method
- [x] Guard Clauses / Early Return
- [x] Rename Variables for Clarity
- [x] Remove Duplication
- [ ] Strategy Pattern (not needed)

## Verification
- [x] All tests passing (pytest: 45 passed)
- [x] Type check passing (mypy: Success)
- [x] Lint check passing (ruff: 0 errors)
- [x] Build successful

## Behavior Changes
**None** - Pure refactoring with no functional changes.

## Related Issues
Closes #<issue-number>
EOF
)"
```

#### 5.3 PR Description Template

Use this template for consistency:

```markdown
## Summary
[Brief description of refactoring goals]

## Complexity Metrics

### Before Refactoring
| File | Function | CC | Cognitive | Lines |
|------|----------|----|-----------| ------|
| file1.py | func_a | 15 | 18 | 65 |
| file2.ts | func_b | 11 | 14 | 48 |

### After Refactoring
| File | Function | CC | Cognitive | Lines |
|------|----------|----|-----------| ------|
| file1.py | func_a | 4 | 5 | 25 |
| file1.py | helper_1 | 2 | 2 | 8 |
| file1.py | helper_2 | 2 | 3 | 10 |
| file2.ts | func_b | 5 | 6 | 20 |
| file2.ts | helper | 3 | 4 | 12 |

**Average Complexity Reduction**: CC 13 → 3.2 (75% improvement)

## Refactoring Patterns Used
- [ ] Extract Method
- [ ] Extract Variable
- [ ] Inline Method
- [ ] Guard Clauses
- [ ] Replace Conditional with Polymorphism
- [ ] Strategy Pattern
- [ ] Remove Duplication
- [ ] Rename for Clarity

## Verification Checklist
- [ ] All tests passing
- [ ] Type check passing
- [ ] Lint check passing
- [ ] Build successful
- [ ] No behavior changes
- [ ] Performance neutral or improved

## Related Issues
Closes #<issue>
```

## Kent Beck Principles Reference

### The Four Rules of Simple Design
1. **Passes all tests** - Must work correctly
2. **Reveals intention** - Code communicates clearly
3. **No duplication** - DRY principle
4. **Minimal elements** - Remove unnecessary complexity

### TDD Refactoring Cycle
```
RED → GREEN → REFACTOR
 ↑               ↓
 └───────────────┘
```

1. **RED**: Write failing test
2. **GREEN**: Make it pass (quick & dirty OK)
3. **REFACTOR**: Clean up while keeping tests green

This skill focuses on step 3 after features are implemented.

### Refactoring Safety Rules

**Always:**
- ✅ Run tests after each refactoring step
- ✅ Make small, incremental changes
- ✅ Commit working states frequently
- ✅ Use type checker to catch errors early

**Never:**
- ❌ Refactor without tests
- ❌ Change behavior during refactoring
- ❌ Make big changes all at once
- ❌ Skip verification steps

## Code Quality Targets

### Complexity Metrics Goals
| Metric | Target | Acceptable | Needs Refactoring |
|--------|--------|------------|------------------|
| Cyclomatic Complexity | ≤ 5 | ≤ 10 | > 10 |
| Cognitive Complexity | ≤ 7 | ≤ 15 | > 15 |
| Function Length | ≤ 25 lines | ≤ 50 lines | > 50 lines |
| Nesting Depth | ≤ 2 | ≤ 4 | > 4 |
| Function Parameters | ≤ 3 | ≤ 5 | > 5 |

### Code Quality Principles

**SOLID Principles:**
- **S**ingle Responsibility: One function, one purpose
- **O**pen/Closed: Open for extension, closed for modification
- **L**iskov Substitution: Subtypes must be substitutable
- **I**nterface Segregation: Many small interfaces > one large
- **D**ependency Inversion: Depend on abstractions

**Other Key Principles:**
- **DRY**: Don't Repeat Yourself
- **KISS**: Keep It Simple, Stupid
- **YAGNI**: You Aren't Gonna Need It
- **Boy Scout Rule**: Leave code better than you found it

## Automation Script

Save this as `kent-beck-refactor.sh` for automation:

```bash
#!/bin/bash
# Kent Beck Refactoring Workflow Automation

set -e

echo "🎯 Kent Beck Refactoring Workflow"
echo "=================================="

# Configuration
BRANCH_NAME="refactor/$(date +%Y%m%d-%H%M%S)"
PROJECT_TYPE="${1:-python}"  # python or typescript

# Phase 1: Analysis
echo ""
echo "📊 Phase 1: Analyzing complexity..."
if [ "$PROJECT_TYPE" = "python" ]; then
    echo "Running radon analysis..."
    radon cc . -s -a || true
    radon mi . || true
elif [ "$PROJECT_TYPE" = "typescript" ]; then
    echo "Running ESLint complexity analysis..."
    npx eslint . --format json > /tmp/eslint-before.json || true
fi

# Phase 2: Refactoring (Manual)
echo ""
echo "✏️  Phase 2: Refactor code now"
echo "   - Apply Kent Beck patterns"
echo "   - Focus on high-complexity areas"
echo "   - Make small, safe changes"
echo ""
read -p "Press Enter when refactoring is complete..."

# Phase 3: Verification
echo ""
echo "✅ Phase 3: Running verification..."

if [ "$PROJECT_TYPE" = "python" ]; then
    echo "Type checking..."
    uv run mypy . || { echo "❌ Type check failed"; exit 1; }
    
    echo "Linting..."
    uv run ruff check . || { echo "❌ Lint failed"; exit 1; }
    uv run ruff format .
    
    echo "Testing..."
    uv run pytest -v || { echo "❌ Tests failed"; exit 1; }
    
elif [ "$PROJECT_TYPE" = "typescript" ]; then
    echo "Type checking..."
    npm run tsc --noEmit || { echo "❌ Type check failed"; exit 1; }
    
    echo "Linting..."
    npm run lint || { echo "❌ Lint failed"; exit 1; }
    
    echo "Testing..."
    npm test || { echo "❌ Tests failed"; exit 1; }
fi

echo "✅ All verifications passed!"

# Phase 4: Commit
echo ""
echo "💾 Phase 4: Committing changes..."
git add .
echo "Enter commit message (e.g., 'simplify validation logic'):"
read -p "refactor: " COMMIT_MSG
git commit -m "refactor: $COMMIT_MSG"

echo "✅ Changes committed!"

# Phase 5: PR
echo ""
echo "🚀 Phase 5: Creating Pull Request..."
read -p "Create PR? (y/n): " CREATE_PR

if [ "$CREATE_PR" = "y" ]; then
    git checkout -b "$BRANCH_NAME"
    git push origin "$BRANCH_NAME"
    
    gh pr create --title "refactor: $COMMIT_MSG" --body "Automated Kent Beck refactoring workflow

## Verification
- [x] All tests passing
- [x] Type check passing
- [x] Lint check passing

## Complexity Analysis
See commit message for details."
    
    echo "✅ Pull Request created!"
fi

echo ""
echo "🎉 Kent Beck Refactoring Complete!"
```

**Usage:**
```bash
# Python project
chmod +x kent-beck-refactor.sh
./kent-beck-refactor.sh python

# TypeScript project
./kent-beck-refactor.sh typescript
```

## Integration with Development Workflow

### Trigger After TODO Completion

When AI completes a task list:
1. Check for high-complexity code in changed files
2. If complexity > threshold, automatically invoke this skill
3. Perform refactoring workflow
4. Commit and create PR

### CI/CD Integration

Add complexity checks to CI pipeline:

```yaml
# .github/workflows/complexity-check.yml
name: Code Complexity Check

on: [pull_request]

jobs:
  complexity:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Check Python Complexity
        run: |
          pip install radon
          radon cc . -s -a -nc
          radon cc . -s -a --total-average
```

## Best Practices Summary

### Do's ✅
- Refactor in small, safe steps
- Run tests after EVERY change
- Commit working states frequently
- Focus on one pattern at a time
- Use meaningful names
- Extract before inline
- Simplify before optimizing

### Don'ts ❌
- Change behavior during refactoring
- Refactor without test coverage
- Make multiple changes simultaneously
- Skip verification steps
- Optimize prematurely
- Delete tests to make them pass

## Usage Examples

### Example 1: After Feature Implementation
```
User: "회원가입 기능 구현 완료"
AI: "기능 구현 완료를 확인했습니다. 코드 품질 개선을 위해 Kent Beck 리팩토링을 시작하겠습니다."
```

### Example 2: Manual Trigger
```
User: "이 파일 복잡도 너무 높아. 리팩토링해줘"
AI: "복잡도 분석을 시작합니다..."
```

### Example 3: Completing Task List
```
User: "모든 TODO 완료됐어"
AI: "모든 작업 완료 확인. 리팩토링 및 PR 생성을 진행합니다."
```

---

**Remember**: Refactoring is not about rewriting code—it's about incrementally improving design while preserving behavior. Small steps, continuous testing, and clear commits are key to successful refactoring.
