#!/usr/bin/env node
// cli.js — CLI surface over core.js. Keep all behavior in core; this file only
// parses argv and formats output.
'use strict';

const core = require('./core');

const USAGE = 'usage: node cli.js <add <text> | list | version>';

function main(argv) {
  const [command, ...rest] = argv;

  switch (command) {
    case 'add': {
      const text = rest.join(' ');
      try {
        const record = core.addRecord(text);
        console.log(`added ${record.id}: ${record.text}`);
        return 0;
      } catch (err) {
        console.error(`error: ${err.message}`);
        return 1;
      }
    }
    case 'list': {
      for (const record of core.listRecords()) {
        console.log(`${record.id}: ${record.text}`);
      }
      return 0;
    }
    case 'version': {
      console.log(core.VERSION);
      return 0;
    }
    default: {
      console.error(USAGE);
      return 1;
    }
  }
}

if (require.main === module) {
  process.exitCode = main(process.argv.slice(2));
}

module.exports = { main, USAGE };
