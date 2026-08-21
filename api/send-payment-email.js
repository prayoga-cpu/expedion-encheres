// POST /api/send-payment-email — create a Checkout session and e-mail the
// link via Resend. Same flow as "Payer". See api/_payment_core.js.
const { sendPaymentEmail, vercelHandler } = require('./_payment_core');

module.exports = vercelHandler(sendPaymentEmail);
