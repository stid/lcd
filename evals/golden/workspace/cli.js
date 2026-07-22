#!/usr/bin/env node
'use strict';
// Golden-fixture CLI: exposes the shared core's stats operation.

const core = require('./core.js');

const cmd = process.argv[2];
if (cmd === 'stats') {
  process.stdout.write(JSON.stringify(core.stats()) + '\n');
} else {
  process.stderr.write('usage: cli.js stats\n');
  process.exit(2);
}
