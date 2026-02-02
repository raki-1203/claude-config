# Kent Beck Refactor Skill - Test Scenarios

This document contains test scenarios to verify that the automatic triggering mechanism works correctly.

## Test Setup

**Location**: `~/.claude/skills/kent-beck-refactor/`
**Trigger Rules**: Defined in `/Users/raki-1203/workspace/KT/agent-based-design-app/AGENTS.md`

## Test Scenarios

### Scenario 1: TODO List Completion Trigger

**Given**: User has a TODO list with multiple items
**When**: All TODO items are marked as `completed`
**Then**: AI should automatically invoke `skill(name="kent-beck-refactor")`

**Test Steps**:
1. Create TODO list with 3 items
2. Mark all items as completed
3. Observe AI behavior

**Expected Behavior**:
```
AI: "모든 TODO 항목이 완료되었습니다. 코드 품질 개선을 시작합니다."
[Invokes kent-beck-refactor skill]
[Executes 5-phase refactoring workflow]
```

---

### Scenario 2: Feature Completion (Korean)

**Given**: User just finished implementing a feature
**When**: User says "기능 완료"
**Then**: AI should detect completion keyword and invoke refactoring skill

**Test Input**:
```
User: "로그인 기능 구현 완료했어"
```

**Expected Behavior**:
```
AI: "기능 구현 완료를 확인했습니다. 코드 품질 개선을 위해 리팩토링을 시작하겠습니다."
[Invokes kent-beck-refactor skill]
```

**Variations to Test**:
- "요구사항 완료"
- "구현 완료"
- "작업 완료"
- "개발 끝"

---

### Scenario 3: Feature Completion (English)

**Given**: User finished implementing a feature
**When**: User says "feature complete"
**Then**: AI should invoke refactoring skill

**Test Input**:
```
User: "User authentication feature complete"
```

**Expected Behavior**:
```
AI: "Feature implementation complete. Starting code quality improvement process."
[Invokes kent-beck-refactor skill]
```

**Variations to Test**:
- "implementation done"
- "work complete"
- "requirement complete"

---

### Scenario 4: Speckit Task Completion

**Given**: User is using speckit.implement
**When**: All tasks in a User Story phase are completed (`- [X] [US1] ...`)
**Then**: AI should automatically invoke refactoring

**Test Steps**:
1. Run `speckit.implement` on a phase
2. Complete all [US1] tasks
3. Observe AI behavior after last task completion

**Expected Behavior**:
```
AI: "User Story 1의 모든 작업이 완료되었습니다."
[Detects all [US1] tasks are [X]]
[Invokes kent-beck-refactor skill]
"리팩토링 및 코드 품질 개선을 진행합니다..."
```

---

### Scenario 5: Manual Refactor Request (Korean)

**Given**: User wants to manually trigger refactoring
**When**: User says "리팩토링해줘"
**Then**: AI should immediately invoke the skill

**Test Input**:
```
User: "이 파일 복잡도 너무 높아. 리팩토링해줘"
```

**Expected Behavior**:
```
AI: "복잡도 분석을 시작합니다..."
[Invokes kent-beck-refactor skill]
[Analyzes complexity]
[Applies refactoring patterns]
```

**Variations to Test**:
- "켄트백 스타일로 리팩토링"
- "복잡도 낮춰줘"
- "clean code로 개선해줘"

---

### Scenario 6: Manual Refactor Request (English)

**Given**: User requests refactoring manually
**When**: User says "refactor this"
**Then**: AI should invoke the skill

**Test Input**:
```
User: "This function is too complex. Refactor and commit."
```

**Expected Behavior**:
```
AI: "Starting complexity analysis..."
[Invokes kent-beck-refactor skill]
```

**Variations to Test**:
- "reduce complexity"
- "improve code quality"
- "clean code"
- "refactor and commit"

---

### Scenario 7: Suppress Auto-Trigger

**Given**: User completes feature but wants to skip refactoring
**When**: User says "구현 완료. 리팩토링은 나중에"
**Then**: AI should NOT invoke the skill

**Test Input**:
```
User: "회원가입 기능 구현 완료. 리팩토링은 나중에 할게"
```

**Expected Behavior**:
```
AI: "구현 완료를 확인했습니다. 리팩토링은 나중에 진행하시겠습니다."
[Does NOT invoke kent-beck-refactor]
```

**Suppression Keywords**:
- "나중에" / "later"
- "스킵" / "skip"
- "하지 마" / "don't"
- "필요없어" / "not needed"

---

### Scenario 8: Speckit Phase Completion

**Given**: Multiple phases in speckit workflow
**When**: Phase N completes with all tasks checked
**Then**: AI should invoke refactoring before moving to next phase

**Test Steps**:
1. Run `speckit.implement Phase 1`
2. Complete all Phase 1 tasks
3. Observe behavior before Phase 2 starts

**Expected Behavior**:
```
AI: "Phase 1 완료. 코드 품질 검증을 시작합니다."
[Invokes kent-beck-refactor skill]
[Completes refactoring]
"Phase 1 리팩토링 완료. Phase 2로 진행하시겠습니까?"
```

---

## Verification Checklist

Use this checklist to verify the trigger system works:

- [ ] **TODO Completion**: Triggers when all TODOs marked complete
- [ ] **Korean Phrases**: Detects "요구사항 완료", "기능 완료", etc.
- [ ] **English Phrases**: Detects "feature complete", "implementation done", etc.
- [ ] **Speckit Tasks**: Triggers after User Story completion
- [ ] **Speckit Phases**: Triggers after phase completion
- [ ] **Manual Korean**: Responds to "리팩토링해줘", "복잡도 낮춰줘"
- [ ] **Manual English**: Responds to "refactor this", "clean code"
- [ ] **Suppression**: Does NOT trigger when user says "나중에" / "later"
- [ ] **No Duplicates**: Does not trigger multiple times for same changes
- [ ] **Workflow Execution**: Successfully completes all 5 phases

---

## Expected Workflow Output

When the skill is invoked, expect this workflow:

```
1. 📊 Phase 1: Analyzing complexity...
   - Running radon/ESLint analysis
   - Cyclomatic Complexity: file.py::func (15 → Target: <10)
   
2. ✏️ Phase 2: Applying refactoring patterns...
   - Extract Method pattern applied
   - Guard Clauses pattern applied
   
3. ✅ Phase 3: Verifying changes...
   - Type check: PASS
   - Lint check: PASS
   - Tests: 45 passed
   
4. 💾 Phase 4: Committing changes...
   - Commit created: "refactor: simplify validation logic"
   
5. 🚀 Phase 5: Creating Pull Request...
   - PR created: #123
   - Link: https://github.com/.../pull/123
```

---

## Debugging Failed Triggers

If the skill doesn't trigger when expected:

### Check 1: Skill File Exists
```bash
ls -la ~/.claude/skills/kent-beck-refactor/SKILL.md
```

### Check 2: AGENTS.md Contains Rules
```bash
grep "Kent Beck Refactor Skill" /Users/raki-1203/workspace/KT/agent-based-design-app/AGENTS.md
```

### Check 3: Skill Metadata Correct
```bash
head -10 ~/.claude/skills/kent-beck-refactor/SKILL.md
```

Expected YAML frontmatter:
```yaml
---
name: kent-beck-refactor
description: Kent Beck style refactoring workflow...
allowed-tools: Read, Grep, Glob, Bash, LSP, Edit, Git
---
```

### Check 4: OpenCode/Sisyphus Restart
Restart OpenCode to reload skills:
```bash
# Skills are loaded at startup
# Restart OpenCode/Claude Desktop to pick up new skills
```

---

## Integration Test Script

```bash
#!/bin/bash
# test-refactor-trigger.sh

echo "Testing Kent Beck Refactor Skill Triggers"
echo "=========================================="

# Test 1: Check skill file exists
echo "✓ Test 1: Skill file exists"
if [ -f ~/.claude/skills/kent-beck-refactor/SKILL.md ]; then
    echo "  PASS: Skill file found"
else
    echo "  FAIL: Skill file not found"
    exit 1
fi

# Test 2: Check AGENTS.md has trigger rules
echo "✓ Test 2: AGENTS.md contains trigger rules"
if grep -q "Kent Beck Refactor Skill" /Users/raki-1203/workspace/KT/agent-based-design-app/AGENTS.md; then
    echo "  PASS: Trigger rules found in AGENTS.md"
else
    echo "  FAIL: Trigger rules not found"
    exit 1
fi

# Test 3: Verify skill metadata
echo "✓ Test 3: Skill metadata is valid"
if grep -q "name: kent-beck-refactor" ~/.claude/skills/kent-beck-refactor/SKILL.md; then
    echo "  PASS: Skill metadata valid"
else
    echo "  FAIL: Invalid metadata"
    exit 1
fi

echo ""
echo "All integration tests passed!"
echo "Ready for manual trigger testing with AI"
```

---

## Manual Testing Guide

### Step 1: Create Test Feature
```python
# test_feature.py
def complex_function(user_data):
    if user_data.get("type") == "admin":
        if user_data.get("verified"):
            if user_data.get("active"):
                if user_data.get("premium"):
                    return {"status": "success", "level": "premium"}
                return {"status": "success", "level": "standard"}
    return {"status": "failed"}
```

### Step 2: Test Trigger Phrase
Say to AI: **"이 함수 구현 완료"**

### Step 3: Verify AI Response
AI should:
1. Detect "완료" keyword
2. Invoke `kent-beck-refactor` skill
3. Analyze complexity (should find CC > 10)
4. Apply refactoring patterns
5. Run tests and commit
6. Create PR

### Step 4: Verify Refactored Code
```python
# test_feature.py (after refactoring)
def complex_function(user_data):
    if not is_valid_admin_user(user_data):
        return {"status": "failed"}
    
    return get_user_level(user_data)

def is_valid_admin_user(user_data):
    return (
        user_data.get("type") == "admin"
        and user_data.get("verified")
        and user_data.get("active")
    )

def get_user_level(user_data):
    if user_data.get("premium"):
        return {"status": "success", "level": "premium"}
    return {"status": "success", "level": "standard"}
```

---

## Success Criteria

The trigger system is working correctly when:

1. ✅ AI automatically detects completion signals
2. ✅ Skill is invoked without manual prompt
3. ✅ All 5 phases execute successfully
4. ✅ Code complexity is reduced (CC ≤ 10)
5. ✅ Tests pass after refactoring
6. ✅ Commit is created with proper message
7. ✅ PR is generated with metrics
8. ✅ No duplicate triggers occur
9. ✅ Suppression keywords prevent unwanted triggers
10. ✅ Manual triggers still work

---

## Rollback Plan

If the trigger system causes issues:

```bash
# 1. Disable the skill (rename to disable)
mv ~/.claude/skills/kent-beck-refactor ~/.claude/skills/kent-beck-refactor.disabled

# 2. Remove trigger rules from AGENTS.md
# Edit AGENTS.md and remove the "Kent Beck Refactor Skill" section

# 3. Restart OpenCode
```

To re-enable:
```bash
# Restore the skill
mv ~/.claude/skills/kent-beck-refactor.disabled ~/.claude/skills/kent-beck-refactor

# Re-add trigger rules to AGENTS.md

# Restart OpenCode
```

---

**Last Updated**: 2026-01-08
**Version**: 1.0
