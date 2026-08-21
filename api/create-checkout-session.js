// POST /api/create-checkout-session — Stripe Checkout for a quote, priced
// server-side from the quote's acceptedPriceCents. See api/_payment_core.js.
const { createCheckoutSession, vercelHandler } = require('./_payment_core');

module.exports = vercelHandler(createCheckoutSession);
