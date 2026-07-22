'use strict';
// Golden-fixture HTTP server: exposes the shared core's stats operation at /stats.

const http = require('http');
const core = require('./core.js');

function createServer() {
  return http.createServer((req, res) => {
    if (req.method === 'GET' && req.url === '/stats') {
      res.writeHead(200, { 'content-type': 'application/json' });
      res.end(JSON.stringify(core.stats()));
    } else {
      res.writeHead(404);
      res.end();
    }
  });
}

if (require.main === module) {
  createServer().listen(3000);
}

module.exports = { createServer };
