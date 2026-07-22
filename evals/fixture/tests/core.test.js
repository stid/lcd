'use strict';

const test = require('node:test');
const assert = require('node:assert');
const core = require('../core');

test.beforeEach(() => core.clear());

test('addRecord stores and returns the record', () => {
  const record = core.addRecord('first note');
  assert.deepStrictEqual(record, { id: 1, text: 'first note' });
});

test('listRecords returns records in insertion order', () => {
  core.addRecord('one');
  core.addRecord('two');
  assert.deepStrictEqual(core.listRecords(), [
    { id: 1, text: 'one' },
    { id: 2, text: 'two' },
  ]);
});

test('listRecords returns copies, not live state', () => {
  core.addRecord('immutable');
  core.listRecords()[0].text = 'mutated';
  assert.strictEqual(core.listRecords()[0].text, 'immutable');
});

test('addRecord rejects empty text', () => {
  assert.throws(() => core.addRecord(''), /non-empty/);
  assert.throws(() => core.addRecord('   '), /non-empty/);
  assert.throws(() => core.addRecord(42), /non-empty/);
});

test('clear empties the store', () => {
  core.addRecord('gone soon');
  core.clear();
  assert.deepStrictEqual(core.listRecords(), []);
});

test('VERSION is a semver-ish string', () => {
  assert.match(core.VERSION, /^\d+\.\d+\.\d+$/);
});
