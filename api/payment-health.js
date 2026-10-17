// GET /api/payment-health — which Stripe mode the payment functions run in,
// whether their keys are accepted, and whether the payment e-mail leaves from
// a real sender. Reveals no key. See paymentHealth in api/_payment_core.js.
const { paymentHealth, vercelHandler } = require('./_payment_core');

module.exports = vercelHandler(paymentHealth, 'GET');
