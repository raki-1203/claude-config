#!/usr/bin/env node
/**
 * PreCompact Hook - Save state before context compaction
 *
 * Cross-platform (Windows, macOS, Linux)
 *
 * Runs before Claude compacts context, giving you a chance to
 * preserve important state that might get lost in summarization.
 */

const fs = require('fs');
const path = require('path');
const {
  getSessionsDir,
  getDateTimeString,
  getTimeString,
  findFiles,
  ensureDir,
  appendFile,
  readFile,
  writeFile,
  log
} = require('../lib/utils');

async function main() {
  const sessionsDir = getSessionsDir();
  const compactionLog = path.join(sessionsDir, 'compaction-log.txt');

  ensureDir(sessionsDir);

  // Log compaction event with timestamp
  const timestamp = getDateTimeString();
  appendFile(compactionLog, `[${timestamp}] Context compaction triggered\n`);

  // If there's an active session file, note the compaction
  const sessions = findFiles(sessionsDir, '*.tmp');

  if (sessions.length > 0) {
    const activeSession = sessions[0].path;
    const timeStr = getTimeString();
    appendFile(activeSession, `\n---\n**[Compaction occurred at ${timeStr}]** - Context was summarized\n`);
  }

  // Autopilot state preservation
  const autopilotStatePath = path.join(process.cwd(), '.claude', 'autopilot-state.local.json');
  if (fs.existsSync(autopilotStatePath)) {
    try {
      const stateRaw = readFile(autopilotStatePath);
      const state = JSON.parse(stateRaw);
      if (state.active) {
        // Save autopilot context to session file for post-compaction recovery
        const autopilotContext = [
          `\n---\n**[Autopilot State at Compaction - ${timestamp}]**`,
          `- Mode: ${state.mode || 'tdd'}`,
          `- Iteration: ${state.iteration || 0}`,
          `- Gate failures: ${state.gate_failure_count || 0}`,
          `- Stuck count: ${state.stuck_count || 0}`,
          `- Last gate: ${state.last_gate_result || 'unknown'}`,
          `- Original prompt: ${(state.original_prompt || '').slice(0, 200)}`,
          ''
        ].join('\n');

        if (sessions.length > 0) {
          appendFile(sessions[0].path, autopilotContext);
        }
        log('[PreCompact] Autopilot state preserved before compaction');
      }
    } catch (err) {
      log(`[PreCompact] WARNING: Failed to parse autopilot state: ${err.message}. State not preserved.`);
    }
  }

  log('[PreCompact] State saved before compaction');
  process.exit(0);
}

main().catch(err => {
  console.error('[PreCompact] Error:', err.message);
  process.exit(0);
});
