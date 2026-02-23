#!/usr/bin/env node
/**
 * Autopilot Setup Script
 * Creates autopilot-state.local.json safely without shell injection risks.
 * Called from /autopilot command with environment variables.
 *
 * Environment variables:
 *   AUTOPILOT_MODE     - tdd|focused|freestyle|review (default: tdd)
 *   AUTOPILOT_PROMPT   - Task description
 *   AUTOPILOT_MAX_ITER - Max iterations (default: 30)
 *   AUTOPILOT_PROMISE  - Completion promise (default: COMPLETE)
 */

const fs = require('fs');
const path = require('path');
const { detectProject } = require('./lib/project-detector');

const VALID_MODES = new Set(['tdd', 'focused', 'freestyle', 'review']);

const mode = VALID_MODES.has(process.env.AUTOPILOT_MODE)
  ? process.env.AUTOPILOT_MODE
  : 'tdd';

const prompt = process.env.AUTOPILOT_PROMPT || '';
if (!prompt) {
  console.error('Error: AUTOPILOT_PROMPT is required');
  process.exit(1);
}

const maxIter = parseInt(process.env.AUTOPILOT_MAX_ITER, 10) || 30;
const promise = process.env.AUTOPILOT_PROMISE || 'COMPLETE';

const project = detectProject();

const enableTdd = mode === 'tdd' || mode === 'focused';
const enableQuality = mode !== 'freestyle';

const state = {
  active: true,
  mode,
  iteration: 0,
  gates: {
    tdd: enableTdd,
    quality: enableQuality
  },
  stuck_count: 0,
  gate_failure_count: 0,
  circuit_breaker_threshold: 5,
  started_at: new Date().toISOString(),
  project,
  original_prompt: prompt
};

const stateDir = path.join(process.cwd(), '.claude');
if (!fs.existsSync(stateDir)) {
  fs.mkdirSync(stateDir, { recursive: true });
}

const statePath = path.join(stateDir, 'autopilot-state.local.json');
fs.writeFileSync(statePath, JSON.stringify(state, null, 2), 'utf8');

console.log(JSON.stringify({
  status: 'created',
  mode,
  project_type: project.type,
  test_command: project.testCommand,
  build_command: project.buildCommand,
  max_iterations: maxIter,
  completion_promise: promise,
  gates: { tdd: enableTdd, quality: enableQuality }
}, null, 2));
