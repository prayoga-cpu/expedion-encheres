const admin = require("firebase-admin/app");
admin.initializeApp();

const createPaymentLink = require("./create_payment_link.js");
exports.createPaymentLink = createPaymentLink.createPaymentLink;
