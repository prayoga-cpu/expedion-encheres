/**
 * Payment core — the logic shared by the deployed Vercel functions in this
 * directory and the local dev server (`tools/local_payment_server.js`).
 * Extracted so the two can never drift: both are thin transports over these
 * three handlers.
 *
 * Zero dependencies (Node built-ins only). Env:
 *   STRIPE_SECRET_KEY        required — Checkout sessions
 *   EXPEDION_API_BASE_URL    the expeditoo-ship deployment holding the quotes
 *                            (default http://localhost:3000 for local dev)
 *   EXPEDION_ADMIN_API_KEY   required — server-to-server quote lookup and
 *                            mark-paid; never reaches any client bundle
 *   RESEND_API_KEY           optional — payment-link e-mail delivery
 *   RESEND_FROM              optional — sender address for that e-mail
 */
const https = require('https');
const http = require('http');
const { URLSearchParams } = require('url');

// Env values go into HTTP headers (Authorization, Bearer keys) and URLs, where
// a stray trailing newline or space — easy to introduce when piping a secret
// into `vercel env add` — is an illegal header character that throws
// ERR_INVALID_CHAR at request time. Trim every one at the boundary so the rest
// of the file can treat them as clean.
const env = (name, fallback = '') => (process.env[name] || fallback).trim();

const STRIPE_SECRET_KEY = env('STRIPE_SECRET_KEY');

// This server has to ask Expedion what a quote is actually worth rather than
// trust whatever `unitAmount` the client sends — a client-supplied amount is
// exactly the "edit the URL, change what you pay" hole the Stripe call on the
// validation page used to have.
const EXPEDION_API_BASE_URL = env('EXPEDION_API_BASE_URL', 'http://localhost:3000');
const EXPEDION_ADMIN_API_KEY = env('EXPEDION_ADMIN_API_KEY');

// Resend (https://resend.com) sends the payment-link e-mail. Without a key the
// link is still returned but not delivered. `onboarding@resend.dev` can send to
// your own account address without domain verification (great for testing).
const RESEND_API_KEY = env('RESEND_API_KEY');
const RESEND_FROM = env('RESEND_FROM', 'Expedion Enchères <onboarding@resend.dev>');

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
  const r = await expedion(
    `/api/expedion/quotes/${encodeURIComponent(recordID)}`,
  );
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

// ---------------------------------------------------------------------------
// The three endpoint handlers. Each takes the parsed JSON body and returns
// { status, payload } where payload is an object or a raw JSON string (the
// Stripe pass-through). Transports decide how to read the body and write the
// response.
// ---------------------------------------------------------------------------

async function createCheckoutSession(b) {
  if (!b.recordID) return { status: 400, payload: { error: 'recordID required' } };
  const price = await authoritativePriceCents(b.recordID);
  if (price.error) return { status: 409, payload: { error: price.error } };
  const r = await createSession(b, price.cents);
  console.log(
    `[create-session] record=${b.recordID} client-sent=${b.unitAmount} charged=${price.cents} -> ${r.status}`,
  );
  return { status: r.status, payload: r.body }; // pass Stripe's {id,url,...} through
}

async function sendPaymentEmail(b) {
  if (!b.recordID || !b.customerEmail) {
    return {
      status: 400,
      payload: { error: 'recordID and customerEmail required' },
    };
  }
  const price = await authoritativePriceCents(b.recordID);
  if (price.error) return { status: 409, payload: { error: price.error } };

  // 1) Create a Checkout session — the emailed link is the SAME flow as
  // "Payer", so paying it redirects to /success and updates the quote.
  const r = await createSession(b, price.cents);
  const session = JSON.parse(r.body);
  if (!session.url) {
    console.error('[send-email] session failed', r.status, r.body);
    return { status: r.status, payload: r.body };
  }

  // 2) Deliver the link via Resend (Stripe can't e-mail in test mode).
  if (!RESEND_API_KEY) {
    console.log(
      `[send-email] to=${b.customerEmail} session=ok emailed=false (no RESEND_API_KEY)`,
    );
    return {
      status: 200,
      payload: {
        url: session.url,
        emailed: false,
        reason: 'RESEND_API_KEY not configured on the server',
      },
    };
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
  console.log(
    `[send-email] to=${b.customerEmail} record=${b.recordID} charged=${price.cents} resend=${mail.status} emailed=${emailed}`,
  );
  return {
    status: emailed ? 200 : 502,
    payload: {
      url: session.url,
      emailed,
      mailStatus: mail.status,
      detail: emailed ? undefined : mail.body,
    },
  };
}

async function confirmPayment(b) {
  if (!b.sessionId) return { status: 400, payload: { error: 'sessionId required' } };
  const s = await stripeGet(
    `/v1/checkout/sessions/${encodeURIComponent(b.sessionId)}`,
  );
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
  console.log(
    `[confirm] session=${b.sessionId} payment_status=${session && session.payment_status} record=${b.recordId} updated=${updated}`,
  );
  return {
    status: 200,
    payload: { paid, updated, paymentStatus: session && session.payment_status },
  };
}

/**
 * Adapter for a Vercel Node function: CORS, OPTIONS, POST-only, JSON body in,
 * JSON out. `handler` is one of the three above.
 */
function vercelHandler(handler) {
  return async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'content-type, authorization');
    if (req.method === 'OPTIONS') {
      res.statusCode = 204;
      return res.end();
    }
    if (req.method !== 'POST') {
      res.statusCode = 405;
      return res.end(JSON.stringify({ error: 'POST only' }));
    }
    let body = req.body;
    if (typeof body === 'string') {
      try {
        body = JSON.parse(body || '{}');
      } catch {
        body = {};
      }
    }
    try {
      const { status, payload } = await handler(body || {});
      res.statusCode = status;
      res.setHeader('Content-Type', 'application/json');
      res.end(typeof payload === 'string' ? payload : JSON.stringify(payload));
    } catch (e) {
      console.error('[payment-fn] error', e);
      res.statusCode = 500;
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify({ error: String(e) }));
    }
  };
}

module.exports = {
  createCheckoutSession,
  sendPaymentEmail,
  confirmPayment,
  vercelHandler,
};
