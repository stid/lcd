'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { spawnSync } = require('node:child_process');
const path = require('node:path');

const CLI = path.join(__dirname, '..', 'cli.js');

function runCli(...args) {
  return spawnSync(process.execPath, [CLI, ...args], { encoding: 'utf8' });
}

test('cli add reports the stored record', () => {
  const res = runCli('add', 'hello', 'world');
  assert.strictEqual(res.status, 0);
  assert.strictEqual(res.stdout.trim(), 'added 1: hello world');
});

test('cli list prints nothing on a fresh store', () => {
  const res = runCli('list');
  assert.strictEqual(res.status, 0);
  assert.strictEqual(res.stdout.trim(), '');
});

test('cli version prints the core version', () => {
  const res = runCli('version');
  assert.strictEqual(res.status, 0);
  assert.match(res.stdout.trim(), /^\d+\.\d+\.\d+$/);
});

test('cli add without text exits non-zero with an error', () => {
  const res = runCli('add');
  assert.notStrictEqual(res.status, 0);
  assert.match(res.stderr, /error:/);
});

test('cli unknown command exits non-zero with usage', () => {
  const res = runCli('bogus');
  assert.notStrictEqual(res.status, 0);
  assert.match(res.stderr, /usage:/);
});
