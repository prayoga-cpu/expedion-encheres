#!/usr/bin/env node
/**
 * Local payment server — zero dependencies (Node built-ins only).
 *
 * Holds the Stripe SECRET key (which can't live in the Flutter client) and:
 *   POST /create-checkout-session  -> create a Checkout session, return {id,url,...}
 *   POST /send-payment-email       -> same, then e-mail the link via Resend
 *   POST /confirm-payment          -> verify a session is PAID, then report it
 *                                     to Expedion so the quote is marked paid
 *   GET  /health                   -> {ok:true}
 *
 * This makes the in-app payment flow work WITHOUT deploying / fixing the broken
 * Firebase Cloud Function.
 *
 * Run:  node tools/local_payment_server.js
 * Env: PORT, STRIPE_SECRET_KEY, EXPEDION_API_BASE_URL, EXPEDION_ADMIN_API_KEY,
 *      RESEND_API_KEY, RESEND_FROM.
 *
 * PRODUCTION: host this same logic anywhere and point _kPaymentServerBaseUrl
 * (lib/backend/api_requests/api_calls.dart) at it.
 */
const http = require('http');
const https = require('https');
const { URLSearchParams } = require('url');

const PORT = process.env.PORT || 4242;
const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY;

// Where Expedion's own quotes live. This server has to ask Expedion what a
// quote is actually worth rather than trust whatever `unitAmount` the client
// sends — a client-supplied amount is exactly the "edit the URL, change what
// you pay" hole the Stripe call on the validation page used to have.
const EXPEDION_API_BASE_URL =
  process.env.EXPEDION_API_BASE_URL || 'http://localhost:3000';
const EXPEDION_ADMIN_API_KEY = process.env.EXPEDION_ADMIN_API_KEY;

// Resend (https://resend.com) sends the payment-link e-mail. Without a key the
// link is still returned but not delivered. `onboarding@resend.dev` can send to
// your own account address without domain verification (great for testing).
const RESEND_API_KEY = process.env.RESEND_API_KEY || '';
const RESEND_FROM =
  process.env.RESEND_FROM || 'Expedion Enchères <onboarding@resend.dev>';

function request(opts, payload) {
  return new Promise((resolve, reject) => {
    const req = https.request(opts, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => resolve({ status: res.statusCode, body: data }));
    });
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

function stripeForm(path, formObj) {
  const body = new URLSearchParams(formObj).toString();
  return request(
    {
      host: 'api.stripe.com',
      path,
      method: 'POST',
      headers: {
        Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(body),
      },
    },
    body,
  );
}

function stripeGet(path) {
  return request({
    host: 'api.stripe.com',
    path,
    method: 'GET',
    headers: { Authorization: `Bearer ${STRIPE_SECRET_KEY}` },
  });
}

/**
 * The one place this server reaches into Expedion. `x-expedion-uid` is
 * required by the bridge even for admin-key calls; it is attribution, not an
 * identity check, so a fixed label is enough.
 */
function expedion(pathAndQuery, { method = 'GET', body } = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(pathAndQuery, EXPEDION_API_BASE_URL);
    const payload = body ? JSON.stringify(body) : undefined;
    const client = url.protocol === 'https:' ? https : http;
    const req = client.request(
      {
        hostname: url.hostname,
        port: url.port || (url.protocol === 'https:' ? 443 : 80),
        path: url.pathname + url.search,
        method,
        headers: {
          Authorization: `Bearer ${EXPEDION_ADMIN_API_KEY}`,
          'x-expedion-uid': 'payment-server',
          'Content-Type': 'application/json',
          ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
        },
      },
      (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end', () => resolve({ status: res.statusCode, body: data }));
      },
    );
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

/**
 * The authoritative price for a quote, in cents. Only `acceptedPriceCents` is
 * trusted — it is what `POST /accept` locks in server-side, so by the time a
 * client can reach the payment step this is always set. A quote with no
 * accepted price has not gone through accept and must not be charged.
 */
async function authoritativePriceCents(recordID) {
  const r = await expedion(`/api/expedion/quotes/${encodeURIComponent(recordID)}`);
  if (r.status !== 200) return { error: `quote lookup failed (${r.status})` };
  let parsed;
  try {
    parsed = JSON.parse(r.body);
  } catch {
    return { error: 'quote lookup returned invalid JSON' };
  }
  const cents = parsed && parsed.data && parsed.data.acceptedPriceCents;
  if (typeof cents !== 'number' || cents <= 0) {
    return { error: 'quote has no accepted price yet' };
  }
  return { cents };
}

async function createSession(b, unitAmount) {
  const form = {
    mode: 'payment',
    'payment_method_types[0]': 'card',
    'line_items[0][price_data][currency]': b.currency || 'eur',
    'line_items[0][price_data][product_data][name]':
      b.productName || 'Retrait/Expédition de biens',
    'line_items[0][price_data][unit_amount]': unitAmount,
    'line_items[0][quantity]': b.quantity || 1,
    success_url: b.successUrl,
    cancel_url: b.cancelUrl,
    'metadata[orderID]': b.orderID || '',
    'metadata[recordID]': b.recordID || '',
    'metadata[userID]': b.userID || '',
    'payment_intent_data[metadata][recordID]': b.recordID || '',
    'payment_intent_data[metadata][devisId]': b.recordID || '',
    'payment_intent_data[metadata][userID]': b.userID || '',
  };
  if (b.customerEmail) form.customer_email = b.customerEmail;
  return stripeForm('/v1/checkout/sessions', form);
}

function resendSend(to, subject, html) {
  const body = JSON.stringify({ from: RESEND_FROM, to: [to], subject, html });
  return request(
    {
      host: 'api.resend.com',
      path: '/emails',
      method: 'POST',
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      },
    },
    body,
  );
}

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
  if (req.method === 'GET' && req.url === '/health') return send(res, 200, { ok: true });

  if (req.method === 'POST' && req.url === '/create-checkout-session') {
    const b = await readBody(req);
    if (!b.recordID) return send(res, 400, { error: 'recordID required' });
    try {
      const price = await authoritativePriceCents(b.recordID);
      if (price.error) return send(res, 409, { error: price.error });
      const r = await createSession(b, price.cents);
      console.log(
        `[create-session] record=${b.recordID} client-sent=${b.unitAmount} charged=${price.cents} -> ${r.status}`,
      );
      return send(res, r.status, r.body); // pass Stripe's {id,url,...} through
    } catch (e) {
      console.error('[create-session] error', e);
      return send(res, 500, { error: String(e) });
    }
  }

  if (req.method === 'POST' && req.url === '/send-payment-email') {
    const b = await readBody(req);
    if (!b.recordID || !b.customerEmail)
      return send(res, 400, { error: 'recordID and customerEmail required' });
    try {
      const price = await authoritativePriceCents(b.recordID);
      if (price.error) return send(res, 409, { error: price.error });

      // 1) Create a Checkout session — the emailed link is the SAME flow as
      // "Payer", so paying it redirects to /success and updates the quote.
      const r = await createSession(b, price.cents);
      const session = JSON.parse(r.body);
      if (!session.url) {
        console.error('[send-email] session failed', r.status, r.body);
        return send(res, r.status, r.body);
      }

      // 2) Deliver the link via Resend (Stripe can't e-mail in test mode).
      if (!RESEND_API_KEY) {
        console.log(`[send-email] to=${b.customerEmail} session=ok emailed=false (no RESEND_API_KEY)`);
        return send(res, 200, {
          url: session.url,
          emailed: false,
          reason: 'RESEND_API_KEY not configured on the server',
        });
      }
      const euros = (price.cents / 100).toFixed(2);
      const label = b.quoteNum ? ` n°${b.quoteNum}` : '';
      const html =
        `<p>Bonjour,</p>` +
        `<p>Voici votre lien de paiement sécurisé pour le devis${label} d'un montant de <b>${euros} €</b>.</p>` +
        `<p><a href="${session.url}" style="display:inline-block;padding:10px 20px;background:#007BFF;color:#fff;text-decoration:none;border-radius:5px;">Payer en ligne via Stripe</a></p>` +
        `<p>Merci de votre confiance,<br/>Expedion Enchères</p>`;
      const mail = await resendSend(
        b.customerEmail,
        `Votre lien de paiement${label} - Expedion Enchères`,
        html,
      );
      const emailed = mail.status >= 200 && mail.status < 300;
      console.log(`[send-email] to=${b.customerEmail} record=${b.recordID} charged=${price.cents} resend=${mail.status} emailed=${emailed}`);
      return send(res, emailed ? 200 : 502, {
        url: session.url,
        emailed,
        mailStatus: mail.status,
        detail: emailed ? undefined : mail.body,
      });
    } catch (e) {
      console.error('[send-email] error', e);
      return send(res, 500, { error: String(e) });
    }
  }

  if (req.method === 'POST' && req.url === '/confirm-payment') {
    const b = await readBody(req);
    if (!b.sessionId) return send(res, 400, { error: 'sessionId required' });
    try {
      const s = await stripeGet(`/v1/checkout/sessions/${encodeURIComponent(b.sessionId)}`);
      const session = JSON.parse(s.body);
      const paid = session && session.payment_status === 'paid';
      let updated = false;
      if (paid && b.recordId) {
        const r = await expedion(
          `/api/expedion/quotes/${encodeURIComponent(b.recordId)}/paid`,
          { method: 'POST', body: { reference: b.sessionId, method: 'stripe' } },
        );
        updated = r.status >= 200 && r.status < 300;
        if (!updated) console.error('[confirm] mark-paid failed', r.status, r.body);
      }
      console.log(`[confirm] session=${b.sessionId} payment_status=${session && session.payment_status} record=${b.recordId} updated=${updated}`);
      return send(res, 200, { paid, updated, paymentStatus: session && session.payment_status });
    } catch (e) {
      console.error('[confirm] error', e);
      return send(res, 500, { error: String(e) });
    }
  }

  return send(res, 404, { error: 'not found' });
});

server.listen(PORT, () => console.log(`local payment server listening on http://localhost:${PORT}`));
