'use strict';

const test = require('node:test');
const assert = require('node:assert');
const core = require('../core');
const { createServer } = require('../server');

let server;
let base;

test.before(async () => {
  server = createServer();
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  base = `http://127.0.0.1:${server.address().port}`;
});

test.after(() => new Promise((resolve) => server.close(resolve)));

test.beforeEach(() => core.clear());

test('GET /records returns the shared core state', async () => {
  core.addRecord('from core');
  const res = await fetch(`${base}/records`);
  assert.strictEqual(res.status, 200);
  assert.deepStrictEqual(await res.json(), {
    records: [{ id: 1, text: 'from core' }],
  });
});

test('POST /records adds through core', async () => {
  const res = await fetch(`${base}/records`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text: 'via http' }),
  });
  assert.strictEqual(res.status, 201);
  assert.deepStrictEqual((await res.json()).record, { id: 1, text: 'via http' });
  assert.deepStrictEqual(core.listRecords(), [{ id: 1, text: 'via http' }]);
});

test('POST /records with bad input is a 400', async () => {
  const res = await fetch(`${base}/records`, { method: 'POST', body: '{}' });
  assert.strictEqual(res.status, 400);
});

test('GET /version returns the core version', async () => {
  const res = await fetch(`${base}/version`);
  assert.strictEqual(res.status, 200);
  assert.deepStrictEqual(await res.json(), { version: core.VERSION });
});

test('unknown route is a 404', async () => {
  const res = await fetch(`${base}/nope`);
  assert.strictEqual(res.status, 404);
});
