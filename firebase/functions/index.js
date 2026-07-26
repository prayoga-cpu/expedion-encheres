const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const stripeModule = require("stripe");

// Credentials (set via `firebase functions:config:set stripe.prod_secret_key=... stripe.test_secret_key=...`
// or the STRIPE_PROD_SECRET_KEY / STRIPE_TEST_SECRET_KEY env vars)
const kStripeProdSecretKey =
  (functions.config().stripe && functions.config().stripe.prod_secret_key) ||
  process.env.STRIPE_PROD_SECRET_KEY;
const kStripeTestSecretKey =
  (functions.config().stripe && functions.config().stripe.test_secret_key) ||
  process.env.STRIPE_TEST_SECRET_KEY;

const secretKey = (isProd) =>
  isProd ? kStripeProdSecretKey : kStripeTestSecretKey;

/**
 *
 */
exports.initStripePayment = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      return "Unauthenticated calls are not allowed.";
    }
    return await initPayment(data, true);
  });

/**
 *
 */
exports.initStripeTestPayment = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      return "Unauthenticated calls are not allowed.";
    }
    return await initPayment(data, false);
  });

async function initPayment(data, isProd) {
  try {
    const stripe = new stripeModule.Stripe(secretKey(isProd), {
      apiVersion: "2020-08-27",
    });

    const customers = await stripe.customers.list({
      email: data.email,
      limit: 1,
    });
    var customer = customers.data[0];
    if (!customer) {
      customer = await stripe.customers.create({
        email: data.email,
        ...(data.name && { name: data.name }),
      });
    }

    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customer.id },
      { apiVersion: "2020-08-27" },
    );
    const paymentIntent = await stripe.paymentIntents.create({
      amount: data.amount,
      currency: data.currency,
      customer: customer.id,
      ...(data.description && { description: data.description }),
      ...(data.metadata && { metadata: data.metadata }),
    });

    return {
      paymentId: paymentIntent.id,
      paymentIntent: paymentIntent.client_secret,
      ephemeralKey: ephemeralKey.secret,
      customer: customer.id,
      success: true,
    };
  } catch (error) {
    console.log(`Error: ${error}`);
    return { success: false, error: userFacingMessage(error) };
  }
}

/**
 * Sanitize the error message for the user.
 */
function userFacingMessage(error) {
  return error.type
    ? error.message
    : "An error occurred, developers have been alerted";
}
const apiManager = require("./api_manager");
const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { pipeline } = require("node:stream/promises");
const axios = require("axios").default;

async function sendMailViaMailtrap(to, subject, html) {
  const token = "9bca923f498bc13037557f114187e871";
  try {
    await axios.post(
      "https://send.api.mailtrap.io/api/send",
      {
        from: {
          email: "info@expedionencheres.com",
          name: "Expedion Encheres"
        },
        to: [{ email: to }],
        subject: subject,
        html: html
      },
      {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json"
        }
      }
    );
    console.log(`Mailtrap email sent successfully to ${to}`);
  } catch (err) {
    console.error(`Failed to send email via Mailtrap to ${to}:`, err.response ? err.response.data : err.message);
  }
}


setGlobalOptions({ region: "us-central1" });

exports.ffPrivateApiCall = functions
  .region("us-central1")
  .runWith({ minInstances: 1, timeoutSeconds: 120 })
  .https.onCall(async (data, context) => {
    try {
      console.log(`Making API call for ${data["callName"]}`);
      var response = await apiManager.makeApiCall(context, data);
      console.log(`Done making API Call! Status: ${response.statusCode}`);
      return response;
    } catch (err) {
      console.error(`Error performing API call: ${err}`);
      return {
        statusCode: 400,
        error: `${err}`,
      };
    }
  });

async function verifyAuthHeader(request) {
  const authorization = request.header("authorization");
  if (!authorization) {
    return null;
  }
  const idToken = authorization.includes("Bearer ")
    ? authorization.split("Bearer ")[1]
    : null;
  if (!idToken) {
    return null;
  }
  try {
    const authResult = await admin.auth().verifyIdToken(idToken);
    return authResult;
  } catch (err) {
    return null;
  }
}

function setCorsHeaders(req, res) {
  const origin = req.header("origin");
  if (origin) {
    res.set("Access-Control-Allow-Origin", origin);
    res.set("Access-Control-Allow-Credentials", "true");
    res.set("Vary", "Origin");
  } else {
    res.set("Access-Control-Allow-Origin", "*");
  }

  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set(
    "Access-Control-Allow-Headers",
    req.header("access-control-request-headers") ||
      "authorization, content-type",
  );
}

exports.ffPrivateApiCallV2 = onRequest(
  { minInstances: 1, timeoutSeconds: 120 },
  async (req, res) => {
    setCorsHeaders(req, res);
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    try {
      const context = {
        auth: await verifyAuthHeader(req),
      };
      const data = req.body.data;
      console.log(`Making API call for ${data["callName"]}`);
      var endpointResponse = await apiManager.makeApiCall(context, data);
      console.log(
        `Done making API Call! Status: ${endpointResponse.statusCode}`,
      );
      res.set(endpointResponse.headers);
      setCorsHeaders(req, res);
      res.status(endpointResponse.statusCode);
      await pipeline(endpointResponse.body, res);
    } catch (err) {
      console.error(`Error performing API call: ${err}`);
      setCorsHeaders(req, res);
      res.status(400).send(`${err}`);
    }
  },
);
exports.onUserDeleted = functions
  .region("us-central1")
  .auth.user()
  .onDelete(async (user) => {
    let firestore = admin.firestore();
    let userRef = firestore.doc("users/" + user.uid);
    await firestore.collection("users").doc(user.uid).delete();
  });

/**
 * Automate Emails based on Devis Status
 * Requires "Trigger Email" Firebase Extension connected to the 'mail' collection.
 */
exports.onDevisApproved = functions
  .region("us-central1")
  .firestore.document("devis/{devisId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Trigger email when Devis is waiting for payment
    if (before.status !== "Awaiting Payment" && after.status === "Awaiting Payment") {
      const customerEmail = after.customerEmail;
      if (!customerEmail) return null;

      // Generate a Stripe Checkout Session
      const stripe = new stripeModule.Stripe(secretKey(true), {
        apiVersion: "2020-08-27",
      });

      // Assuming after.price is in standard currency unit (e.g. Euros).
      // Stripe requires amount in smallest currency unit (cents), so multiply by 100.
      const amountInCents = Math.round((after.price || 0) * 100);

      let checkoutUrl = "expedionencheres://payment?devisId=" + context.params.devisId; // Fallback to deep link

      try {
        const session = await stripe.checkout.sessions.create({
          payment_method_types: ['card'],
          line_items: [{
            price_data: {
              currency: 'eur',
              product_data: {
                name: 'Quote Payment - Expedion Encheres',
              },
              unit_amount: amountInCents,
            },
            quantity: 1,
          }],
          mode: 'payment',
          // Users will be redirected here after payment
          success_url: 'https://expedionencheres.com/success',
          cancel_url: 'https://expedionencheres.com/cancel',
          customer_email: customerEmail,
          payment_intent_data: {
            metadata: {
              devisId: context.params.devisId,
            }
          }
        });
        checkoutUrl = session.url;
      } catch (err) {
        console.error("Failed to create Stripe Checkout session:", err);
      }

      await admin.firestore().collection("mail").add({
        to: customerEmail,
        message: {
          subject: "Your Quote is Approved - Expedion Encheres",
          html: `<p>Hello,</p>
                 <p>Your quote has been approved for the amount of <b>€${after.price}</b>.</p>
                 <p><a href="${checkoutUrl}" style="display:inline-block;padding:10px 20px;background-color:#007BFF;color:#fff;text-decoration:none;border-radius:5px;">Click here to pay securely via Stripe</a></p>
                 <p>Thank you!</p>`
        }
      });

      await sendMailViaMailtrap(
        customerEmail,
        "Your Quote is Approved - Expedion Encheres",
        `<p>Hello,</p>
         <p>Your quote has been approved for the amount of <b>€${after.price}</b>.</p>
         <p><a href="${checkoutUrl}" style="display:inline-block;padding:10px 20px;background-color:#007BFF;color:#fff;text-decoration:none;border-radius:5px;">Click here to pay securely via Stripe</a></p>
         <p>Thank you!</p>`
      );
    }

    // Trigger email when Devis is successfully paid
    if (before.status !== "Paid" && after.status === "Paid") {
      const customerEmail = after.customerEmail;
      if (!customerEmail) return null;

      await admin.firestore().collection("mail").add({
        to: customerEmail,
        message: {
          subject: "Payment Receipt - Expedion Encheres",
          html: `<p>Hello,</p>
                 <p>We have successfully received your payment of <b>${after.price}</b> for your quote.</p>
                 <p>Thank you for choosing Expedion Encheres!</p>`
        }
      });

      await sendMailViaMailtrap(
        customerEmail,
        "Payment Receipt - Expedion Encheres",
        `<p>Hello,</p>
         <p>We have successfully received your payment of <b>${after.price}</b> for your quote.</p>
         <p>Thank you for choosing Expedion Encheres!</p>`
      );
    }
    return null;
  });

/**
 * Stripe Webhook Handler
 * Updates the Firestore document status to 'Paid' when a payment succeeds.
 */
exports.stripeWebhook = functions
  .region("us-central1")
  .https.onRequest(async (req, res) => {
    const sig = req.headers["stripe-signature"];
    // The webhook signing secret is a `whsec_...` value from the Stripe
    // dashboard — NOT an API secret key. Set it with:
    //   firebase functions:config:set stripe.webhook_secret=whsec_xxx
    // (or the STRIPE_WEBHOOK_SECRET env var). We fail closed when it is
    // missing rather than falling back to a value that can never verify a
    // signature.
    const endpointSecret =
      (functions.config().stripe && functions.config().stripe.webhook_secret) ||
      process.env.STRIPE_WEBHOOK_SECRET ||
      "";
    if (!endpointSecret) {
      console.error(
        "stripeWebhook: missing stripe.webhook_secret config; rejecting event.",
      );
      return res.status(500).send("Webhook signing secret not configured.");
    }

    let event;
    try {
      event = stripeModule.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
    } catch (err) {
      console.error(`Webhook Error: ${err.message}`);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    // Handle the successful payment intent
    if (event.type === 'payment_intent.succeeded') {
      const paymentIntent = event.data.object;
      const devisId = paymentIntent.metadata ? (paymentIntent.metadata.devisId || paymentIntent.metadata.recordID) : null;
      
      if (devisId) {
        // 1. Update Firestore status
        try {
          await admin.firestore().collection("devis").doc(devisId).update({
            status: "Paid"
          });
          console.log(`Firestore document ${devisId} updated to Paid.`);
        } catch (err) {
          console.log(`Firestore document update skipped/failed: ${err.message}`);
        }

        // 2. Update Airtable status
        try {
          const airtableBase =
            (functions.config().airtable && functions.config().airtable.base) ||
            process.env.AIRTABLE_BASE ||
            "appu3jamyzCJRuOjr";
          const airtablePat =
            (functions.config().airtable && functions.config().airtable.pat) ||
            process.env.AIRTABLE_PAT;
          const airtableUrl = `https://api.airtable.com/v0/${airtableBase}/CONTACTS`;
          await axios.patch(
            airtableUrl,
            {
              records: [
                {
                  id: devisId,
                  fields: {
                    "STATUT DU PAIEMENT": "Paiement reçu",
                    "VALIDER DEVIS": "Devis Validé"
                  }
                }
              ]
            },
            {
              headers: {
                Authorization: `Bearer ${airtablePat}`,
                "Content-Type": "application/json"
              }
            }
          );
          console.log(`Airtable record ${devisId} updated to Paid.`);
        } catch (err) {
          console.error(`Failed to update Airtable record ${devisId}:`, err.response ? err.response.data : err.message);
        }
      }
    }

    res.json({received: true});
  });

/**
 * HTTP endpoint: create a Stripe Checkout session for a quote and e-mail the
 * payment link to the customer. Called from the app's "Recevoir le lien par
 * e-mail" button (SendPaymentLinkEmailCall in api_calls.dart).
 */
exports.sendPaymentLinkEmail = functions
  .region("us-central1")
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    const {
      amount,
      description,
      userID,
      orderID,
      devisId,
      customerEmail,
      quoteNum,
    } = req.body || {};

    if (!amount || !customerEmail) {
      res
        .status(400)
        .send({ error: "Missing required fields: amount and customerEmail." });
      return;
    }

    const stripeSecretKey =
      (functions.config().stripe && functions.config().stripe.secret_key) ||
      kStripeTestSecretKey;
    const stripe = new stripeModule.Stripe(stripeSecretKey, {
      apiVersion: "2020-08-27",
    });

    try {
      const session = await stripe.checkout.sessions.create({
        mode: "payment",
        payment_method_types: ["card"],
        line_items: [
          {
            price_data: {
              currency: "eur",
              product_data: {
                name:
                  description ||
                  "Retrait/Expédition de biens - Expedion Encheres",
              },
              unit_amount: amount, // smallest currency unit (cents)
            },
            quantity: 1,
          },
        ],
        success_url:
          "https://expedionencheres.com/success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "https://expedionencheres.com/cancel",
        customer_email: customerEmail,
        metadata: {
          userID: userID || "unknown",
          orderID: orderID || "unknown",
          devisId: devisId || "unknown",
        },
        // Mirror metadata onto the PaymentIntent so the
        // `payment_intent.succeeded` webhook can mark the quote paid.
        payment_intent_data: {
          metadata: {
            userID: userID || "unknown",
            recordID: devisId || "unknown",
            devisId: devisId || "unknown",
          },
        },
      });

      const amountEuros = (Number(amount) / 100).toFixed(2);
      const quoteLabel = quoteNum ? ` n°${quoteNum}` : "";
      const html = `<p>Bonjour,</p>
        <p>Voici votre lien de paiement sécurisé pour le devis${quoteLabel} d'un montant de <b>${amountEuros} €</b>.</p>
        <p><a href="${session.url}" style="display:inline-block;padding:10px 20px;background-color:#007BFF;color:#fff;text-decoration:none;border-radius:5px;">Payer en ligne via Stripe</a></p>
        <p>Merci de votre confiance,<br/>Expedion Enchères</p>`;

      await sendMailViaMailtrap(
        customerEmail,
        `Votre lien de paiement${quoteLabel} - Expedion Encheres`,
        html,
      );

      res.status(200).send({ url: session.url, sessionId: session.id });
    } catch (error) {
      console.error("sendPaymentLinkEmail error:", error.message);
      res.status(500).send({ error: error.message });
    }
  });
