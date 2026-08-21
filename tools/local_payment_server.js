#!/usr/bin/env node
/**
 * Local payment server — the dev transport over api/_payment_core.js.
 *
 * The SAME handlers are deployed to production as Vercel functions
 * (api/create-checkout-session.js and siblings), so this file exists only to
 * run them on localhost:4242 for `flutter run` against a local backend:
 *   POST /api/create-checkout-session  -> create a Checkout session, {id,url,...}
 *   POST /api/send-payment-email       -> same, then e-mail the link via Resend
 *   POST /api/confirm-payment          -> verify a session is PAID, then report
 *                                         it to Expedion (marks the quote paid)
 *   GET  /api/health                   -> {ok:true}
 * The un-prefixed paths (/create-checkout-session, ...) still work for
 * anything old that calls them.
 *
 * Run:  node tools/local_payment_server.js
 * Env: PORT, STRIPE_SECRET_KEY, EXPEDION_API_BASE_URL, EXPEDION_ADMIN_API_KEY,
 *      RESEND_API_KEY, RESEND_FROM — see api/_payment_core.js.
 */
const http = require('http');
const {
  createCheckoutSession,
  sendPaymentEmail,
  confirmPayment,
} = require('../api/_payment_core');

const PORT = process.env.PORT || 4242;

const ROUTES = {
  '/create-checkout-session': createCheckoutSession,
  '/send-payment-email': sendPaymentEmail,
  '/confirm-payment': confirmPayment,
};

function readBody(req) {
  return new Promise((resolve) => {
    let raw = '';
    req.on('data', (c) => (raw += c));
    req.on('end', () => {
      try {
        resolve(JSON.parse(raw || '{}'));
      } catch (_) {
        resolve({});
      }
    });
  });
}

function send(res, status, obj) {
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': 'content-type, authorization',
  });
  res.end(typeof obj === 'string' ? obj : JSON.stringify(obj));
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') return send(res, 204, '');
  // The deployed functions live under /api/*; accept both spellings here so
  // the client can use one path everywhere.
  const path = req.url.replace(/^\/api(?=\/)/, '').split('?')[0];
  if (req.method === 'GET' && path === '/health') return send(res, 200, { ok: true });

  const handler = ROUTES[path];
  if (req.method === 'POST' && handler) {
    try {
      const { status, payload } = await handler(await readBody(req));
      return send(res, status, payload);
    } catch (e) {
      console.error(`[${path}] error`, e);
      return send(res, 500, { error: String(e) });
    }
  }

  return send(res, 404, { error: 'not found' });
});

server.listen(PORT, () =>
  console.log(`local payment server listening on http://localhost:${PORT}`),
);
