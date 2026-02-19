#!/usr/bin/env node
/**
 * Autopilot Gate - Stop Hook for quality gate enforcement
 *
 * Runs BEFORE Ralph's stop-hook.sh in the Stop hook chain.
 * Reads autopilot state and enforces TDD/quality gates.
 *
 * Flow:
 * 1. Read autopilot-state.local.json (inactive → exit 0 immediately)
 * 2. Stuck detection: compare recent tool call patterns
 * 3. TDD gate: run test command if mode requires it
 * 4. Quality gate: check for console.log, TS errors
 * 5. Completion verification: if <promise> detected but tests fail, manipulate ralph state
 * 6. Output gate results as systemMessage via ralph state file
 */

const fs = require('fs');
const path = require('path');
const { readFile, writeFile, runCommand, log, readStdinJson } = require('../lib/utils');
const { detectProject } = require('../lib/project-detector');

const AUTOPILOT_STATE_PATH = path.join(process.cwd(), '.claude', 'autopilot-state.local.json');
const RALPH_STATE_PATH = path.join(process.cwd(), '.claude', 'ralph-loop.local.md');

// Circuit breaker triggers after N consecutive stuck iterations to prevent infinite loops
const CIRCUIT_BREAKER_THRESHOLD = 5;
// Warn user after N consecutive gate failures suggesting manual intervention
const MAX_GATE_FAILURES = 10;
// Similarity threshold (0-1) for stuck detection using Jaccard bigram comparison
const STUCK_SIMILARITY_THRESHOLD = 0.9;
// Test command timeout in milliseconds
const TEST_TIMEOUT_MS = 90000;

// Only these test commands are allowed to be executed by the gate
const ALLOWED_TEST_COMMANDS = new Set([
  'npm test', 'pnpm test', 'yarn test', 'bun test',
  'pytest', 'cargo test', 'go test ./...'
]);

async function main() {
  // 1. Check if autopilot is active
  const stateRaw = readFile(AUTOPILOT_STATE_PATH);
  if (!stateRaw) {
    // No autopilot state → not active, pass through
    process.exit(0);
  }

  let state;
  try {
    state = JSON.parse(stateRaw);
  } catch {
    log('[Autopilot Gate] Invalid state file, skipping');
    process.exit(0);
  }

  if (!state.active) {
    process.exit(0);
  }

  // Read stdin (hook input with transcript_path)
  let hookInput = {};
  try {
    hookInput = await readStdinJson();
  } catch {
    // If stdin fails, continue with limited functionality
  }

  const mode = state.mode || 'tdd';
  const gates = state.gates || {};
  const enableTdd = gates.tdd !== false && (mode === 'tdd' || mode === 'focused');
  const enableQuality = gates.quality !== false && (mode !== 'freestyle');

  // Initialize counters
  if (state.gate_failure_count === undefined) state.gate_failure_count = 0;
  if (state.stuck_count === undefined) state.stuck_count = 0;
  if (state.iteration === undefined) state.iteration = 0;
  state.iteration++;

  const gateMessages = [];
  let gateBlocked = false;

  // Restore blocked promise from previous iteration
  if (state._promise_blocked) {
    const ralphState = readFile(RALPH_STATE_PATH);
    if (ralphState) {
      const restored = ralphState.replace(/__BLOCKED_BY_GATE/g, '');
      if (restored !== ralphState) {
        const tmpPath = RALPH_STATE_PATH + '.tmp.' + process.pid;
        fs.writeFileSync(tmpPath, restored, 'utf8');
        fs.renameSync(tmpPath, RALPH_STATE_PATH);
      }
    }
    delete state._promise_blocked;
  }

  // 2. Stuck detection
  if (hookInput.transcript_path && fs.existsSync(hookInput.transcript_path)) {
    const stuckResult = detectStuck(hookInput.transcript_path, state);
    if (stuckResult.stuck) {
      state.stuck_count++;
      if (state.stuck_count >= (state.circuit_breaker_threshold || CIRCUIT_BREAKER_THRESHOLD)) {
        log(`[Autopilot Gate] CIRCUIT BREAKER: ${state.stuck_count} stuck iterations detected. Forcing stop.`);
        gateMessages.push(`CIRCUIT_BREAKER: Detected ${state.stuck_count} consecutive stuck iterations. Loop terminated.`);
        // Deactivate autopilot
        state.active = false;
        saveState(state);
        // Remove ralph state to stop the loop
        try { fs.unlinkSync(RALPH_STATE_PATH); } catch {}
        log('[Autopilot Gate] Loop force-terminated due to circuit breaker');
        process.exit(0);
      }
      gateMessages.push(`STUCK_DETECTED (${state.stuck_count}/${state.circuit_breaker_threshold || CIRCUIT_BREAKER_THRESHOLD}): Similar tool call patterns detected. Try a different approach.`);
    } else {
      state.stuck_count = 0;
    }
  }

  // 3. TDD Gate (cache result for reuse in completion verification)
  let testResult = null;
  const project = enableTdd ? detectProject() : null;

  if (enableTdd && project && project.testCommand) {
    if (!ALLOWED_TEST_COMMANDS.has(project.testCommand)) {
      log(`[Autopilot Gate] Rejected untrusted test command: ${project.testCommand}`);
    } else {
      testResult = runCommand(project.testCommand, {
        cwd: process.cwd(),
        timeout: TEST_TIMEOUT_MS
      });

      if (!testResult.success) {
        gateBlocked = true;
        state.gate_failure_count++;
        const truncatedOutput = (testResult.output || '').slice(-500);
        gateMessages.push(`GATE_FAILED [TDD]: Tests failing. Fix tests before continuing.\n${truncatedOutput}`);
      } else {
        gateMessages.push('GATE_PASSED [TDD]: All tests passing.');
        if (state.gate_failure_count > 0) state.gate_failure_count = 0;
      }
    }
  }

  // 4. Quality Gate
  if (enableQuality) {
    const qualityIssues = checkQuality();
    if (qualityIssues.length > 0) {
      gateMessages.push(`GATE_WARNING [Quality]: ${qualityIssues.join('; ')}`);
    }
  }

  // 5. Completion verification - reuse cached testResult
  if (hookInput.transcript_path && fs.existsSync(hookInput.transcript_path) && enableTdd) {
    const lastOutput = getLastAssistantOutput(hookInput.transcript_path);
    if (lastOutput && /<promise>/.test(lastOutput)) {
      // Promise tag detected - verify tests actually pass (reuse cached result)
      if (testResult && !testResult.success) {
        log('[Autopilot Gate] Promise detected but tests failing - blocking completion');
        gateMessages.push('COMPLETION_BLOCKED: You output a completion promise but tests are still failing. Fix tests first.');
        stripPromiseFromRalphState();
        gateBlocked = true;
      }
    }
  }

  // 6. Max gate failures warning
  if (state.gate_failure_count >= MAX_GATE_FAILURES) {
    log(`[Autopilot Gate] WARNING: ${state.gate_failure_count} consecutive gate failures`);
    gateMessages.push(`WARNING: ${state.gate_failure_count} consecutive gate failures. Consider /cancel-autopilot if stuck.`);
  }

  // Inject gate messages into ralph state file
  if (gateMessages.length > 0) {
    injectGateContext(gateMessages);
  }

  // Save updated state
  state.last_gate_result = gateBlocked ? 'failed' : 'passed';
  state.last_gate_messages = gateMessages;
  state.last_gate_time = new Date().toISOString();
  saveState(state);

  if (gateBlocked) {
    log(`[Autopilot Gate] Gate FAILED (iteration ${state.iteration}, failures: ${state.gate_failure_count})`);
  } else {
    log(`[Autopilot Gate] Gate PASSED (iteration ${state.iteration})`);
  }

  // Always exit 0 - we don't block the hook chain
  // Ralph's stop-hook.sh will handle the actual loop continuation
  process.exit(0);
}

/**
 * Detect stuck patterns by comparing recent assistant tool calls
 */
function detectStuck(transcriptPath, state) {
  try {
    const content = readFile(transcriptPath);
    if (!content) return { stuck: false };

    const lines = content.split('\n').filter(l => l.trim());
    const assistantMessages = [];

    for (const line of lines) {
      try {
        const entry = JSON.parse(line);
        if (entry.role === 'assistant' || entry.message?.role === 'assistant') {
          assistantMessages.push(entry);
        }
      } catch {}
    }

    // Need at least 3 messages to compare
    if (assistantMessages.length < 3) return { stuck: false };

    const recent = assistantMessages.slice(-3);
    const patterns = recent.map(msg => extractToolPattern(msg));

    // Compare patterns - if 90%+ similar, consider stuck
    if (patterns.length === 3 && patterns[0] && patterns[1] && patterns[2]) {
      const sim01 = similarity(patterns[0], patterns[1]);
      const sim12 = similarity(patterns[1], patterns[2]);
      const sim02 = similarity(patterns[0], patterns[2]);
      const avgSim = (sim01 + sim12 + sim02) / 3;

      if (avgSim >= STUCK_SIMILARITY_THRESHOLD) {
        return { stuck: true, similarity: avgSim };
      }
    }

    return { stuck: false };
  } catch {
    return { stuck: false };
  }
}

/**
 * Extract tool call pattern from an assistant message
 */
function extractToolPattern(msg) {
  const content = msg.message?.content || msg.content || [];
  const toolCalls = [];

  if (Array.isArray(content)) {
    for (const block of content) {
      if (block.type === 'tool_use') {
        toolCalls.push(`${block.name}:${JSON.stringify(block.input || {}).slice(0, 100)}`);
      }
    }
  }

  return toolCalls.join('|');
}

/**
 * Simple string similarity (Jaccard on character bigrams)
 */
function similarity(a, b) {
  if (!a && !b) return 1;
  if (!a || !b) return 0;

  const bigramsA = new Set();
  const bigramsB = new Set();

  for (let i = 0; i < a.length - 1; i++) bigramsA.add(a.slice(i, i + 2));
  for (let i = 0; i < b.length - 1; i++) bigramsB.add(b.slice(i, i + 2));

  let intersection = 0;
  for (const bg of bigramsA) {
    if (bigramsB.has(bg)) intersection++;
  }

  const union = bigramsA.size + bigramsB.size - intersection;
  return union === 0 ? 1 : intersection / union;
}

/**
 * Get last assistant text output from transcript
 */
function getLastAssistantOutput(transcriptPath) {
  try {
    const content = readFile(transcriptPath);
    if (!content) return null;

    const lines = content.split('\n').filter(l => l.trim());
    let lastAssistant = null;

    for (const line of lines) {
      try {
        const entry = JSON.parse(line);
        if (entry.role === 'assistant' || entry.message?.role === 'assistant') {
          lastAssistant = entry;
        }
      } catch {}
    }

    if (!lastAssistant) return null;

    const msgContent = lastAssistant.message?.content || lastAssistant.content || [];
    if (Array.isArray(msgContent)) {
      return msgContent
        .filter(b => b.type === 'text')
        .map(b => b.text)
        .join('\n');
    }

    return typeof msgContent === 'string' ? msgContent : null;
  } catch {
    return null;
  }
}

/**
 * Check code quality issues
 */
function checkQuality() {
  const issues = [];
  const cwd = process.cwd();

  // Check for console.log in modified files
  const diffResult = runCommand('git diff --name-only HEAD');
  if (diffResult.success) {
    const files = diffResult.output.split('\n')
      .map(f => f.trim())
      .filter(f => /\.(ts|tsx|js|jsx)$/.test(f))
      .map(f => path.resolve(cwd, f))
      .filter(f => f.startsWith(cwd + path.sep) && fs.existsSync(f));

    for (const file of files) {
      const content = readFile(file);
      if (content && /console\.log/.test(content)) {
        issues.push(`console.log in ${path.relative(cwd, file)}`);
      }
    }
  }

  // TypeScript error check (if tsconfig.json exists)
  if (fs.existsSync(path.join(cwd, 'tsconfig.json'))) {
    const tscResult = runCommand('npx tsc --noEmit 2>&1 | head -5', { timeout: 30000 });
    if (!tscResult.success) {
      const hasTsErrors = tscResult.output && tscResult.output.includes('error TS');
      if (hasTsErrors) {
        issues.push('TypeScript errors detected');
      }
    }
  }

  return issues;
}

/**
 * Inject gate context messages into ralph state file's prompt section
 * Uses regex to properly identify YAML frontmatter boundaries
 */
function injectGateContext(messages) {
  const ralphState = readFile(RALPH_STATE_PATH);
  if (!ralphState) return;

  // Remove any previous gate context
  const cleanedState = ralphState.replace(/\n<!-- AUTOPILOT_GATE_START -->[\s\S]*?<!-- AUTOPILOT_GATE_END -->\n/g, '');

  // Match frontmatter: starts with ---, ends with first --- on its own line
  const fmMatch = cleanedState.match(/^(---\n[\s\S]*?\n---\n)([\s\S]*)$/);
  if (!fmMatch) return;

  const [, frontmatter, promptContent] = fmMatch;
  const gateBlock = `\n<!-- AUTOPILOT_GATE_START -->\n## Autopilot Gate Report\n${messages.map(m => `- ${m}`).join('\n')}\n<!-- AUTOPILOT_GATE_END -->\n`;

  const newState = `${frontmatter}${gateBlock}${promptContent}`;

  // Atomic write via temp file
  const tmpPath = RALPH_STATE_PATH + '.tmp.' + process.pid;
  fs.writeFileSync(tmpPath, newState, 'utf8');
  fs.renameSync(tmpPath, RALPH_STATE_PATH);
}

/**
 * Strip <promise> tags from ralph state file to prevent premature completion
 * when tests are still failing. Modifies the completion_promise in frontmatter
 * to a temporary value that won't match the assistant's output.
 */
function stripPromiseFromRalphState() {
  const ralphState = readFile(RALPH_STATE_PATH);
  if (!ralphState) return;

  // Temporarily change the completion promise to block matching
  // Ralph's stop-hook compares <promise>TEXT</promise> against completion_promise
  // By appending a suffix, the comparison will fail
  const modified = ralphState.replace(
    /^(completion_promise: ")(.*)(")$/m,
    '$1$2__BLOCKED_BY_GATE$3'
  );

  if (modified !== ralphState) {
    const tmpPath = RALPH_STATE_PATH + '.tmp.' + process.pid;
    fs.writeFileSync(tmpPath, modified, 'utf8');
    fs.renameSync(tmpPath, RALPH_STATE_PATH);

    // Store original promise in autopilot state for restoration next iteration
    const stateRaw = readFile(AUTOPILOT_STATE_PATH);
    if (stateRaw) {
      try {
        const state = JSON.parse(stateRaw);
        state._promise_blocked = true;
        saveState(state);
      } catch {}
    }

    log('[Autopilot Gate] Blocked completion promise in ralph state');
  }
}

function saveState(state) {
  // Atomic write via temp file to prevent race conditions
  const tmpPath = AUTOPILOT_STATE_PATH + '.tmp.' + process.pid;
  fs.writeFileSync(tmpPath, JSON.stringify(state, null, 2), 'utf8');
  fs.renameSync(tmpPath, AUTOPILOT_STATE_PATH);
}

main().catch(err => {
  log(`[Autopilot Gate] Error: ${err.message}`);
  process.exit(0);
});
