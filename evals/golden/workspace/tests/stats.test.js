'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { execFileSync } = require('node:child_process');
const path = require('node:path');

const core = require('../core.js');
const { createServer } = require('../server.js');

test('AC-1 (CLI): stats command reports count, last-updated, checksum', () => {
  const out = execFileSync('node', [path.join(__dirname, '..', 'cli.js'), 'stats']);
  const body = JSON.parse(out.toString());
  assert.deepStrictEqual(Object.keys(body).sort(), ['checksum', 'count', 'lastUpdated']);
});

test('AC-2 (HTTP): /stats reports semantics identical to the CLI', async () => {
  const server = createServer();
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  const res = await fetch(`http://127.0.0.1:${port}/stats`);
  const body = await res.json();
  server.close();
  assert.strictEqual(res.status, 200);
  assert.deepStrictEqual(body, core.stats());
});
