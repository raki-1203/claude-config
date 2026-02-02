# Security Review Skill

Comprehensive security guidance for code review and deployment.

## Core Areas

### Secrets Management
- Environment variables must protect all sensitive data
- No hardcoded API keys, tokens, or passwords
- Verify `.env.local` remains in `.gitignore`

### Input Validation
- Use schema validation (like Zod) for all user inputs
- File uploads require triple-checking: size limits, MIME types, and file extensions

### SQL Safety
- Always employ parameterized queries
- Direct string concatenation creates injection vulnerabilities

### Authentication
- Store tokens in httpOnly cookies rather than localStorage to prevent XSS attacks
- Always verify authorization before sensitive operations

### XSS Prevention
- Sanitize user-provided HTML using libraries like DOMPurify
- Configure Content Security Policy headers

### Additional Protections
- Implement CSRF tokens
- Rate limiting on sensitive endpoints
- Careful error messaging that avoids exposing internal system details

## When to Activate

Trigger this skill when handling:
- Authentication
- API endpoints
- File uploads
- Payment processing
- Sensitive data operations

## Pre-Deployment Checklist

17 critical items including:
- Dependency audits
- Proper header configuration
- Role-based access controls
- All mandatory before production release

**Remember**: Security is not optional. One vulnerability can compromise the entire platform.
