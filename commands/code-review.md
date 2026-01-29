# /code-review

Systematically review uncommitted code changes for security and quality issues.

## Process

1. Identifies modified files using `git diff --name-only HEAD`
2. Scans changed files against security and quality criteria
3. Categorizes findings from Critical to Low severity
4. Provides specific remediation suggestions for each issue

## Review Categories

### Security (Blocking)
- Hardcoded credentials, API keys, tokens
- SQL injection vulnerabilities
- XSS vulnerabilities
- Missing input validation
- Authentication bypasses

### Quality Standards
- Functions > 50 lines
- Excessive nesting (>4 levels)
- Missing error handling
- Test coverage gaps

### Best Practices
- Mutation patterns
- Test coverage
- Accessibility standards
- Documentation

## Enforcement Mechanism

Critical or high-severity findings automatically block commits until resolved. This approach prioritizes security above all else, ensuring vulnerable code never reaches production while maintaining standards for maintainability and best practices.

## Example Usage

```
/code-review
```

This will analyze all uncommitted changes and provide a comprehensive report of issues found.
