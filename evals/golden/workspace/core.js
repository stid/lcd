'use strict';
// Golden-fixture core: minimal record store + stats (the "completed feature").

const records = [];

function addRecord(text) {
  const rec = { text: String(text), updatedAt: records.length + 1 };
  records.push(rec);
  return rec;
}

function listRecords() {
  return records.slice();
}

function stats() {
  const count = records.length;
  const lastUpdated = count ? records[count - 1].updatedAt : null;
  let checksum = 0;
  for (const r of records) {
    for (const ch of r.text) checksum = (checksum * 31 + ch.charCodeAt(0)) >>> 0;
  }
  return { count, lastUpdated, checksum };
}

module.exports = { addRecord, listRecords, stats };
