const axios = require("axios").default;
const qs = require("qs");

async function _createPaymentIntentCall(context, ffVariables) {
  if (!context.auth) {
    return _unauthenticatedResponse;
  }
  var unitAmount = ffVariables["unitAmount"];
  var currency = ffVariables["currency"];
  var userID = ffVariables["userID"];
  var cancelUrl = ffVariables["cancelUrl"];
  var successUrl = ffVariables["successUrl"];
  var productName = ffVariables["productName"];
  var quantity = ffVariables["quantity"];
  var orderID = ffVariables["orderID"];
  var recordID = ffVariables["recordID"];

  var url = `https://api.stripe.com/v1/checkout/sessions`;
  const functions = require("firebase-functions");
  const stripeSecretKey =
    (functions.config().stripe && functions.config().stripe.secret_key) ||
    process.env.STRIPE_SECRET_KEY;
  var headers = {
    Authorization: `Bearer ${stripeSecretKey}`,
  };
  var params = {
    cancel_url: cancelUrl,
    success_url: successUrl,
    "line_items[0][price_data][currency]": currency,
    "line_items[0][price_data][product_data][name]": productName,
    "line_items[0][price_data][unit_amount]": unitAmount,
    "line_items[0][quantity]": quantity,
    mode: `payment`,
    "metadata[orderID]": orderID,
    "metadata[recordID]": recordID,
    "metadata[userID]": userID,
    // Also copy the metadata onto the PaymentIntent. Checkout Session metadata
    // does NOT propagate to the underlying PaymentIntent, and the
    // `payment_intent.succeeded` webhook reads it from there to mark the quote
    // paid (`metadata.devisId || metadata.recordID`).
    "payment_intent_data[metadata][orderID]": orderID,
    "payment_intent_data[metadata][recordID]": recordID,
    "payment_intent_data[metadata][userID]": userID,
    "payment_intent_data[metadata][devisId]": recordID,
  };
  var ffApiRequestBody = undefined;

  return makeApiRequest({
    method: "post",
    url,
    headers,
    body: createBody({
      headers,
      params,
      body: ffApiRequestBody,
      bodyType: "X_WWW_FORM_URL_ENCODED",
    }),
    returnBody: true,
    isStreamingApi: false,
  });
}

/// Helper functions to route to the appropriate API Call.

async function makeApiCall(context, data) {
  var callName = data["callName"] || "";
  var variables = data["variables"] || {};

  const callMap = {
    CreatePaymentIntentCall: _createPaymentIntentCall,
  };

  if (!(callName in callMap)) {
    return {
      statusCode: 400,
      error: `API Call "${callName}" not defined as private API.`,
    };
  }

  var apiCall = callMap[callName];
  var response = await apiCall(context, variables);
  return response;
}

async function makeApiRequest({
  method,
  url,
  headers,
  params,
  body,
  returnBody,
  isStreamingApi,
}) {
  return axios
    .request({
      method: method,
      url: url,
      headers: headers,
      params: params,
      responseType: isStreamingApi ? "stream" : "json",
      ...(body && { data: body }),
    })
    .then((response) => {
      return {
        statusCode: response.status,
        headers: response.headers,
        ...(returnBody && { body: response.data }),
        isStreamingApi: isStreamingApi,
      };
    })
    .catch(function (error) {
      return {
        statusCode: error.response.status,
        headers: error.response.headers,
        ...(returnBody && { body: error.response.data }),
        error: error.message,
      };
    });
}

const _unauthenticatedResponse = {
  statusCode: 401,
  headers: {},
  error: "API call requires authentication",
};

function createBody({ headers, params, body, bodyType }) {
  switch (bodyType) {
    case "JSON":
      headers["Content-Type"] = "application/json";
      return body;
    case "TEXT":
      headers["Content-Type"] = "text/plain";
      return body;
    case "X_WWW_FORM_URL_ENCODED":
      headers["Content-Type"] = "application/x-www-form-urlencoded";
      return qs.stringify(params);
  }
}
function escapeStringForJson(val) {
  if (typeof val !== "string") {
    return val;
  }
  return val
    .replace(/[\\]/g, "\\\\")
    .replace(/["]/g, '\\"')
    .replace(/[\n]/g, "\\n")
    .replace(/[\t]/g, "\\t");
}

module.exports = { makeApiCall };
