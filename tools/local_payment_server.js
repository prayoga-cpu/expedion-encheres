#!/usr/bin/env node
/**
 * Local payment server — zero dependencies (Node built-ins only).
 *
 * Holds the Stripe SECRET key (which can't live in the Flutter client) and:
 *   POST /create-checkout-session  -> create a Checkout session, return {id,url,...}
 *   POST /confirm-payment          -> verify a session is PAID, then mark the
 *                                     Airtable quote paid (server-side, verified)
 *   GET  /health                   -> {ok:true}
 *
 * This makes the in-app payment flow work WITHOUT deploying / fixing the broken
 * Firebase Cloud Function.
 *
 * Run:  node tools/local_payment_server.js
 * Env overrides: PORT, STRIPE_SECRET_KEY, AIRTABLE_PAT, AIRTABLE_BASE.
 *
 * PRODUCTION: host this same logic anywhere and point _kPaymentServerBaseUrl
 * (lib/backend/api_requests/api_calls.dart) at it.
 */
const http = require('http');
const https = require('https');
const { URLSearchParams } = require('url');

const PORT = process.env.PORT || 4242;
const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY;
const AIRTABLE_PAT = process.env.AIRTABLE_PAT;
const AIRTABLE_BASE = process.env.AIRTABLE_BASE || 'appu3jamyzCJRuOjr';
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

function airtablePatchContact(recordId, fields) {
  const body = JSON.stringify({ records: [{ id: recordId, fields }] });
  return request(
    {
      host: 'api.airtable.com',
      path: `/v0/${AIRTABLE_BASE}/CONTACTS`,
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${AIRTABLE_PAT}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      },
    },
    body,
  );
}

async function createSession(b) {
  const form = {
    mode: 'payment',
    'payment_method_types[0]': 'card',
    'line_items[0][price_data][currency]': b.currency || 'eur',
    'line_items[0][price_data][product_data][name]':
      b.productName || 'Retrait/Expédition de biens',
    'line_items[0][price_data][unit_amount]': b.unitAmount,
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
    if (!b.unitAmount) return send(res, 400, { error: 'unitAmount required' });
    try {
      const r = await createSession(b);
      console.log(`[create-session] amount=${b.unitAmount} record=${b.recordID} -> ${r.status}`);
      return send(res, r.status, r.body); // pass Stripe's {id,url,...} through
    } catch (e) {
      console.error('[create-session] error', e);
      return send(res, 500, { error: String(e) });
    }
  }

  if (req.method === 'POST' && req.url === '/send-payment-email') {
    const b = await readBody(req);
    if (!b.unitAmount || !b.customerEmail)
      return send(res, 400, { error: 'unitAmount and customerEmail required' });
    try {
      // 1) Create a Checkout session — the emailed link is the SAME flow as
      // "Payer", so paying it redirects to /success and updates the quote.
      const r = await createSession(b);
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
      const euros = (Number(b.unitAmount) / 100).toFixed(2);
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
      console.log(`[send-email] to=${b.customerEmail} session=ok resend=${mail.status} emailed=${emailed}`);
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
        const r = await airtablePatchContact(b.recordId, {
          'STATUT DU PAIEMENT': 'Paiement reçu',
          'VALIDER DEVIS': 'Devis Validé',
        });
        updated = r.status >= 200 && r.status < 300;
        if (!updated) console.error('[confirm] airtable patch failed', r.status, r.body);
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
