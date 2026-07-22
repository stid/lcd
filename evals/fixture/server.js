// server.js — HTTP surface over core.js. Same core module as the CLI; the two
// surfaces must stay behavior-identical. Only listens when run directly so
// tests can create/start/stop a server themselves.
'use strict';

const http = require('node:http');
const core = require('./core');

function createServer() {
  return http.createServer((req, res) => {
    const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

    const sendJson = (status, body) => {
      res.writeHead(status, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(body));
    };

    if (req.method === 'GET' && url.pathname === '/records') {
      sendJson(200, { records: core.listRecords() });
      return;
    }

    if (req.method === 'POST' && url.pathname === '/records') {
      let raw = '';
      req.on('data', (chunk) => { raw += chunk; });
      req.on('end', () => {
        try {
          const body = JSON.parse(raw || '{}');
          const record = core.addRecord(body.text);
          sendJson(201, { record });
        } catch (err) {
          sendJson(400, { error: err.message });
        }
      });
      return;
    }

    if (req.method === 'GET' && url.pathname === '/version') {
      sendJson(200, { version: core.VERSION });
      return;
    }

    sendJson(404, { error: 'not found' });
  });
}

if (require.main === module) {
  const port = Number(process.env.PORT) || 3000;
  createServer().listen(port, () => {
    console.log(`records server listening on port ${port}`);
  });
}

module.exports = { createServer };
