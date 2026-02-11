#!/usr/bin/env node
/**
 * MCP proxy for Xcode's mcpbridge.
 *
 * Xcode's MCP tools declare outputSchema but sometimes do not return
 * structuredContent (e.g. BuildProject). Cursor then errors with:
 * "Tool X has an output schema but did not return structured content".
 *
 * This proxy forwards all JSON-RPC between Cursor and mcpbridge, and
 * strips outputSchema from tool definitions in tools/list responses.
 * The client then accepts plain content[] and no longer requires
 * structuredContent.
 */

const { spawn } = require('child_process');
const readline = require('readline');

const MCPBRIDGE = 'xcrun';
const MCPBRIDGE_ARGS = ['mcpbridge'];

const bridge = spawn(MCPBRIDGE, MCPBRIDGE_ARGS, {
  stdio: ['pipe', 'pipe', 'inherit'],
  env: process.env,
});

const pendingMethods = new Map(); // id -> method name

// From Cursor -> to mcpbridge
const rlStdin = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });
rlStdin.on('line', (line) => {
  if (!line.trim()) return;
  try {
    const msg = JSON.parse(line);
    if (msg.id !== undefined && msg.method) pendingMethods.set(msg.id, msg.method);
  } catch (_) {}
  bridge.stdin.write(line + '\n');
});

// From mcpbridge -> to Cursor
const rlBridge = readline.createInterface({ input: bridge.stdout, crlfDelay: Infinity });
rlBridge.on('line', (line) => {
  if (!line.trim()) return;
  try {
    const msg = JSON.parse(line);
    if (msg.result && msg.id !== undefined) {
      const method = pendingMethods.get(msg.id);
      pendingMethods.delete(msg.id);
      // Strip outputSchema so Cursor accepts content[] when server omits structuredContent
      if (Array.isArray(msg.result?.tools)) {
        msg.result = {
          ...msg.result,
          tools: msg.result.tools.map((t) => {
            const { outputSchema, ...rest } = t;
            return rest;
          }),
        };
      }
    }
    process.stdout.write(JSON.stringify(msg) + '\n');
  } catch (_) {
    process.stdout.write(line + '\n');
  }
});

bridge.on('error', (err) => {
  console.error('xcode-mcp-proxy: mcpbridge spawn error', err);
  process.exit(1);
});
bridge.on('exit', (code) => {
  process.exit(code ?? 0);
});
process.on('SIGINT', () => bridge.kill('SIGINT'));
process.on('SIGTERM', () => bridge.kill('SIGTERM'));
