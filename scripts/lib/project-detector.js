#!/usr/bin/env node
/**
 * Project type detector for autopilot gate
 * Detects project type and returns appropriate test command
 */

const fs = require('fs');
const path = require('path');
const { readFile, runCommand } = require('./utils');

/**
 * Detect project type from current working directory
 * @param {string} [cwd] - Directory to check (defaults to process.cwd())
 * @returns {{ type: string, testCommand: string|null, buildCommand: string|null }}
 */
function detectProject(cwd) {
  const dir = cwd || process.cwd();

  // Node.js project
  const pkgJsonPath = path.join(dir, 'package.json');
  if (fs.existsSync(pkgJsonPath)) {
    const pkgJson = readFile(pkgJsonPath);
    if (pkgJson) {
      try {
        const pkg = JSON.parse(pkgJson);
        const scripts = pkg.scripts || {};
        let testCommand = null;
        let buildCommand = null;

        // Detect package manager
        const pm = fs.existsSync(path.join(dir, 'bun.lockb')) ? 'bun' :
                   fs.existsSync(path.join(dir, 'pnpm-lock.yaml')) ? 'pnpm' :
                   fs.existsSync(path.join(dir, 'yarn.lock')) ? 'yarn' : 'npm';

        if (scripts.test && scripts.test !== 'echo "Error: no test specified" && exit 1') {
          testCommand = `${pm} test`;
        }
        if (scripts.build) {
          buildCommand = `${pm} run build`;
        }

        return { type: 'node', testCommand, buildCommand };
      } catch {
        return { type: 'node', testCommand: null, buildCommand: null };
      }
    }
  }

  // Python project
  if (fs.existsSync(path.join(dir, 'pyproject.toml')) ||
      fs.existsSync(path.join(dir, 'setup.py')) ||
      fs.existsSync(path.join(dir, 'setup.cfg'))) {
    const hasPytest = fs.existsSync(path.join(dir, 'tests')) ||
                      fs.existsSync(path.join(dir, 'test'));
    return {
      type: 'python',
      testCommand: hasPytest ? 'pytest' : null,
      buildCommand: null
    };
  }

  // Rust project
  if (fs.existsSync(path.join(dir, 'Cargo.toml'))) {
    return {
      type: 'rust',
      testCommand: 'cargo test',
      buildCommand: 'cargo build'
    };
  }

  // Go project
  if (fs.existsSync(path.join(dir, 'go.mod'))) {
    return {
      type: 'go',
      testCommand: 'go test ./...',
      buildCommand: 'go build ./...'
    };
  }

  // Generic / unknown
  return { type: 'generic', testCommand: null, buildCommand: null };
}

module.exports = { detectProject };
