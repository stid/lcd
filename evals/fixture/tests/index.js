// Aggregator entry so `node --test tests/` works even where the runner does not
// scan positional directory arguments. New test files: add a require line here.
'use strict';

require('./core.test.js');
require('./cli.test.js');
require('./server.test.js');
