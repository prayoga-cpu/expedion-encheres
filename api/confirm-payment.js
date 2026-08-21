// POST /api/confirm-payment — verify a Checkout session is PAID with Stripe,
// then report it to Expedion so the quote is marked paid (which also stamps
// the escalation timer). See api/_payment_core.js.
const { confirmPayment, vercelHandler } = require('./_payment_core');

module.exports = vercelHandler(confirmPayment);
