// core.js — the single shared records module. Both surfaces (cli.js, server.js)
// must go through this module; neither keeps state of its own.
'use strict';

const VERSION = '1.0.0';

const records = [];

/**
 * Add a record. Text must be a non-empty string.
 * Returns the stored record ({ id, text }).
 */
function addRecord(text) {
  if (typeof text !== 'string' || text.trim() === '') {
    throw new Error('record text must be a non-empty string');
  }
  const record = { id: records.length + 1, text: text.trim() };
  records.push(record);
  return record;
}

/** Return a copy of all records, in insertion order. */
function listRecords() {
  return records.map((r) => ({ ...r }));
}

/** Remove all records (used by tests for isolation). */
function clear() {
  records.length = 0;
}

module.exports = { VERSION, addRecord, listRecords, clear };
