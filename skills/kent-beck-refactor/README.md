# Kent Beck Refactor Skill

## Overview

This skill implements Kent Beck's refactoring methodology to automatically improve code quality after feature implementation. It analyzes code complexity, applies refactoring patterns, verifies correctness, and creates pull requests.

## Installation

The skill is already installed at:
```
~/.claude/skills/kent-beck-refactor/SKILL.md
```

OpenCode/Sisyphus AI will automatically discover this skill on startup.

## How It Works

### Automatic Discovery

1. **Skill Location**: `~/.claude/skills/kent-beck-refactor/`
2. **Main File**: `SKILL.md` (UPPERCASE filename required)
3. **Metadata**: YAML frontmatter with `name` and `description`
4. **Discovery**: OpenCode scans this directory at startup and registers the skill

### Skill Invocation

The AI can invoke this skill in two ways:

#### Method 1: Direct Tool Call
```python
skill(name="kent-beck-refactor")
```

#### Method 2: Slash Command
```
/kent-beck-refactor
```

When invoked, the entire SKILL.md content is injected into the AI's context as instructions.

## Trigger Keywords

### Automatic Triggers (Post-Implementation)
The AI should automatically invoke this skill when detecting these phrases:

**Korean:**
- "요구사항 완료"
- "기능 완료"
- "task 완료"
- "phase 완료"

**English:**
- "feature complete"
- "task complete"
- "phase complete"
- "implementation done"

### Manual Triggers (User Request)
The user can explicitly request refactoring:

**Korean:**
- "리팩토링해줘"
- "켄트백 스타일로"
- "복잡도 낮춰줘"
- "테스트하고 커밋"
- "커밋하고 PR"

**English:**
- "refactor this"
- "refactor and commit"
- "reduce complexity"
- "clean code"
- "test and commit"
- "commit and PR"

## Workflow Phases

The skill implements a 5-phase workflow:

### Phase 1: Analyze 📊
- Identify changed files (`git status`, `git diff`)
- Measure complexity metrics (cyclomatic, cognitive)
- Create refactoring plan

**Tools Used:**
- `radon` (Python)
- `ESLint` (TypeScript/JavaScript)

### Phase 2: Refactor ✏️
Apply Kent Beck's refactoring patterns:
- Extract Method
- Guard Clauses / Early Return
- Replace Conditional with Polymorphism
- Strategy Pattern
- Remove Duplication (DRY)
- Rename for Clarity

### Phase 3: Verify ✅
Ensure no functionality is broken:
- Type check (`mypy`, `tsc`)
- Lint check (`ruff`, `eslint`)
- Run tests (`pytest`, `jest`)
- Build verification

**Critical**: If ANY step fails, stop and fix before committing.

### Phase 4: Commit 💾
- Review changes (`git diff`)
- Stage files (`git add`)
- Commit with conventional format
- Use clear, descriptive messages

### Phase 5: Pull Request 🚀
- Push to remote branch
- Create PR with GitHub CLI (`gh pr create`)
- Include complexity metrics in PR description
- Link related issues

## Complexity Targets

| Metric | Target | Acceptable | Needs Refactoring |
|--------|--------|------------|------------------|
| Cyclomatic Complexity | ≤ 5 | ≤ 10 | > 10 |
| Cognitive Complexity | ≤ 7 | ≤ 15 | > 15 |
| Function Length | ≤ 25 lines | ≤ 50 lines | > 50 lines |
| Nesting Depth | ≤ 2 | ≤ 4 | > 4 |
| Function Parameters | ≤ 3 | ≤ 5 | > 5 |

## Usage Examples

### Example 1: Automatic Trigger After Feature
```
User: "회원가입 기능 구현 완료"

AI Response:
"기능 구현을 완료하셨군요! 코드 품질 개선을 위해 Kent Beck 리팩토링을 시작하겠습니다."

[Invokes kent-beck-refactor skill]
[Analyzes complexity]
[Applies refactoring patterns]
[Runs tests]
[Creates commit and PR]
```

### Example 2: Manual Trigger
```
User: "이 파일 복잡도 높아. 리팩토링해줘"

AI Response:
[Invokes kent-beck-refactor skill]
"복잡도 분석 결과:
- process_order: CC 15 (너무 높음)
- validate_user: CC 8 (수용 가능)

리팩토링을 시작합니다..."
```

### Example 3: After TODO List Completion
```
AI Internal Logic:
1. User completes all TODO items
2. Detect completion trigger
3. Auto-invoke kent-beck-refactor skill
4. Perform full refactoring workflow
5. Create PR with metrics
```

## Integration with OpenCode

### How OpenCode Loads This Skill

1. **Startup**: OpenCode scans `~/.claude/skills/` directory
2. **Discovery**: Finds `kent-beck-refactor/SKILL.md`
3. **Parse Metadata**: Reads YAML frontmatter
4. **Register**: Adds to available skills list as `(user - Skill)`
5. **Ready**: Skill is now available for invocation

### Skill Metadata

From the YAML frontmatter:
```yaml
name: kent-beck-refactor
description: Kent Beck style refactoring workflow...
allowed-tools: Read, Grep, Glob, Bash, LSP, Edit, Git
```

### Verification

To verify the skill is loaded, check the system prompt for:
```xml
<available_skills>
  <skill>
    <name>kent-beck-refactor</name>
    <description>(user - Skill) Kent Beck style refactoring...</description>
  </skill>
</available_skills>
```

## Automation Script

An optional automation script is included in the skill for manual use:

**Location**: See `SKILL.md` for the `kent-beck-refactor.sh` script

**Usage:**
```bash
# Python project
./kent-beck-refactor.sh python

# TypeScript project
./kent-beck-refactor.sh typescript
```

This script automates the 5-phase workflow for command-line usage.

## Best Practices

### Do's ✅
- Refactor in small, safe steps
- Run tests after EVERY change
- Commit working states frequently
- Focus on one pattern at a time
- Use meaningful names

### Don'ts ❌
- Change behavior during refactoring
- Refactor without test coverage
- Make multiple changes simultaneously
- Skip verification steps
- Optimize prematurely

## Kent Beck Principles

This skill implements these core principles:

### Four Rules of Simple Design
1. **Passes all tests** - Functionality must work
2. **Reveals intention** - Code communicates clearly
3. **No duplication** - DRY principle
4. **Minimal elements** - Remove unnecessary complexity

### TDD Refactoring Cycle
```
RED → GREEN → REFACTOR
 ↑               ↓
 └───────────────┘
```

This skill focuses on the **REFACTOR** step after features are implemented.

## Troubleshooting

### Skill Not Recognized
**Problem**: AI doesn't recognize the skill

**Solution**:
1. Verify file location: `~/.claude/skills/kent-beck-refactor/SKILL.md`
2. Check filename is `SKILL.md` (UPPERCASE)
3. Verify YAML frontmatter format
4. Restart OpenCode/Claude Desktop

### Complexity Analysis Fails
**Problem**: Radon or ESLint not found

**Solution**:
```bash
# Python
pip install radon

# TypeScript/JavaScript
npm install -g eslint
```

### Tests Fail During Verification
**Problem**: Tests fail after refactoring

**Solution**:
1. **DO NOT commit** - Fix the code first
2. Review changes with `git diff`
3. Revert problematic changes
4. Apply refactoring in smaller steps
5. Run tests after each step

### Git Commands Fail
**Problem**: Git operations fail

**Solution**:
```bash
# Install GitHub CLI for PR creation
brew install gh
gh auth login

# Configure git user
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

## Customization

### Adjust Complexity Thresholds

Edit the complexity targets in `SKILL.md`:

```yaml
# Current thresholds
Cyclomatic Complexity: ≤ 10
Cognitive Complexity: ≤ 15

# Adjust as needed for your project
Cyclomatic Complexity: ≤ 8
Cognitive Complexity: ≤ 12
```

### Add Custom Refactoring Patterns

Add project-specific patterns to the SKILL.md file under "Phase 2: Refactor".

### Modify Commit Message Format

Customize the commit message template in the skill instructions.

## Related Skills

- **langgraph-developer**: LangGraph development assistance
- **phase-implementer**: Azure agent-based system design
- **playwright**: Browser automation and testing

## Support

### Documentation
- Full skill content: `~/.claude/skills/kent-beck-refactor/SKILL.md`
- This README: `~/.claude/skills/kent-beck-refactor/README.md`

### References
- Kent Beck: "Refactoring: Improving the Design of Existing Code"
- Martin Fowler: Refactoring Catalog
- Clean Code principles by Robert C. Martin

### Issues
If the skill doesn't work as expected:
1. Check the SKILL.md file exists and is formatted correctly
2. Verify tools (radon, eslint, git, gh) are installed
3. Ensure test suite is working
4. Check git repository is initialized

## Version History

- **v1.0** (2026-01-08): Initial release
  - 5-phase refactoring workflow
  - Python and TypeScript support
  - Automatic complexity analysis
  - GitHub PR integration
  - Kent Beck principles implementation

---

**Remember**: Refactoring is an incremental process. Small, safe steps with continuous testing lead to sustainable code quality improvements.
