const functions = require("firebase-functions");
const admin = require("firebase-admin");
// To avoid deployment errors, do not call admin.initializeApp() in your code
const Stripe = require("stripe");

exports.createPaymentLink = async (req, res) => {
  // CORS headers
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "authorization, content-type");
  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  const stripeSecretKey =
    functions.config().stripe && functions.config().stripe.secret_key
      ? functions.config().stripe.secret_key
      : process.env.STRIPE_SECRET_KEY;

  if (!stripeSecretKey) {
    return res.status(500).send({ error: "Stripe secret key not configured." });
  }

  const stripe = new Stripe(stripeSecretKey);

  const { amount, description, userID, orderID, devisId, customerEmail } =
    req.body;

  if (!amount || !userID) {
    return res.status(400).send({ error: "Missing required fields: amount and userID." });
  }

  try {
    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      payment_method_types: ["card"],
      line_items: [
        {
          price_data: {
            currency: "eur",
            product_data: {
              name: description || "Retrait/Expédition de biens - Expedion Encheres",
            },
            unit_amount: amount, // Amount in cents (e.g., 5000 = €50.00)
          },
          quantity: 1,
        },
      ],
      success_url: "https://expedionencheres.com/success?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: "https://expedionencheres.com/cancel",
      customer_email: customerEmail || undefined,
      metadata: {
        userID: userID || "unknown",
        orderID: orderID || "unknown",
        devisId: devisId || "unknown",
      },
      payment_intent_data: {
        metadata: {
          userID: userID || "unknown",
          devisId: devisId || "unknown",
        },
      },
    });

    return res.status(200).send({
      url: session.url,
      sessionId: session.id,
    });
  } catch (error) {
    console.error("Stripe error:", error.message);
    return res.status(500).send({
      error: error.message,
    });
  }
};
