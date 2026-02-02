---
name: playwright-test
description: Automated browser testing using Playwright MCP. Use this when user requests to test a web application, run E2E tests, verify UI functionality, or check web service behavior with a browser.
---

# Playwright Test Skill

Automated browser testing using Playwright MCP for comprehensive web application testing.

## When to Use

Use this skill when the user requests:
- "Test the web application"
- "Run E2E tests"
- "Check if the website works"
- "Verify UI functionality"
- "Test with a browser"
- "Run playwright tests"

## Prerequisites

Before testing, ensure:
1. The web application servers are running
2. You know the application URL (default: http://localhost:5173 for frontend)
3. Playwright MCP tools are available

## Testing Steps

### 1. Initial Setup

First, navigate to the application and take a snapshot:

```
Use mcp__playwright__browser_navigate to go to the application URL
Use mcp__playwright__browser_snapshot to capture the page state
```

### 2. Basic Navigation Test

- Navigate to the main page
- Take snapshot to verify page structure
- Check for key UI elements
- Look for any console errors using browser_console_messages

### 3. Interaction Testing

Based on the application features, test interactions:

**For form inputs:**
- Use browser_fill to enter data
- Use browser_click to submit
- Verify success messages or state changes

**For file uploads:**
- Use browser_upload_file with test files
- Verify file is processed correctly

**For dynamic content:**
- Use browser_wait_for to wait for content to appear
- Take snapshots before and after interactions
- Verify state changes

### 4. Visual Verification

- Use browser_take_screenshot for visual verification
- Compare screenshots before and after actions
- Check for visual regressions

### 5. Network and Performance

- Use browser_network_requests to check API calls
- Verify requests complete successfully
- Check for failed requests or errors

## Common Test Patterns

### File Upload Test
```
1. Navigate to page
2. Take snapshot to find upload element
3. Use browser_upload_file with test file path
4. Wait for processing
5. Verify upload success
```

### Form Submission Test
```
1. Navigate to form page
2. Take snapshot to find form fields
3. Use browser_fill_form to fill multiple fields
4. Use browser_click to submit
5. Wait for response
6. Verify success state
```

### Multi-Step Workflow Test
```
1. Navigate to start page
2. Complete step 1 (fill, click, etc.)
3. Wait for navigation or state change
4. Take snapshot to verify progress
5. Continue to next step
6. Verify final state
```

## Best Practices

1. **Always snapshot before clicking** - Get element references from snapshots
2. **Wait for dynamic content** - Use browser_wait_for for loading states
3. **Check console errors** - Use browser_console_messages to catch JS errors
4. **Verify network requests** - Use browser_network_requests for API verification
5. **Take screenshots sparingly** - Prefer snapshots for performance
6. **Handle dialogs** - Use browser_handle_dialog if popups appear

## Error Handling

If tests fail:
1. Check console messages for JavaScript errors
2. Review network requests for failed API calls
3. Take screenshot to see visual state
4. Verify element selectors from latest snapshot
5. Check if timing issues exist (add waits)

## Example Test Flow

For a typical web application:

1. **Start servers** (if not running)
2. **Navigate** to application URL
3. **Snapshot** to see page structure
4. **Interact** with elements (click, type, upload)
5. **Wait** for responses
6. **Verify** expected outcomes
7. **Check** console and network for errors
8. **Screenshot** final state

## Tools Reference

Key Playwright MCP tools to use:
- `browser_navigate` - Go to URL
- `browser_snapshot` - Get page structure (use before actions)
- `browser_click` - Click elements
- `browser_fill` - Type into inputs
- `browser_fill_form` - Fill multiple fields
- `browser_upload_file` - Upload files
- `browser_wait_for` - Wait for text/elements
- `browser_take_screenshot` - Visual verification
- `browser_console_messages` - Check for errors
- `browser_network_requests` - Check API calls
- `browser_evaluate` - Run custom JavaScript

## Tips

- Element `ref` and `uid` come from snapshots - always take snapshot first
- Use `browser_wait_for` liberally for dynamic content
- Check both successful and error scenarios
- Test with realistic data
- Verify end-to-end user workflows
