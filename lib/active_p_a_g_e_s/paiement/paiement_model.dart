import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'paiement_widget.dart' show PaiementWidget;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Exact label Airtable stores for an AD valorem (insured) quote. Pulling this
/// out keeps the amount logic in one place and testable.
const kTypeDevisAdValorem = 'Devis avec assurance AD valorem';

/// Picks the Stripe charge amount, in cents, for a quote. AD valorem quotes are
/// billed at [tarifAdvCents], every other quote type at [tarifStdCents].
/// Returns null when the chosen tariff is missing, so the caller refuses to
/// open Checkout rather than charging a made-up figure.
///
/// The tariffs arrive already in cents — that is the unit `expedion_quotes`
/// stores and the unit the API returns (see `ExpedionQuote`, "Money is cents on
/// the wire throughout"). This function used to multiply by 100 on the way out,
/// which was right when the figures came from Airtable in euros and became a
/// 100x overcharge the moment quotes moved to Postgres.
///
/// Kept as a pure top-level function so it can be unit-tested without building
/// the widget tree or hitting Stripe.
int? computePaiementAmountCents({
  required String typeDevisValide,
  int? tarifAdvCents,
  int? tarifStdCents,
}) {
  return typeDevisValide == kTypeDevisAdValorem ? tarifAdvCents : tarifStdCents;
}

/// The APP_PUBLIC_URL dart-define, trailing slash removed, or '' when the
/// build did not set one.
const String _kAppPublicUrl = String.fromEnvironment('APP_PUBLIC_URL');

/// Absolute base URL Stripe should redirect back to after Checkout.
///
/// An explicit APP_PUBLIC_URL wins on every platform, web included — the only
/// build this project produces is `flutter build web`, so a define the web
/// branch ignored would be dead code. With no define, web uses the app's own
/// origin (e.g. `http://localhost:60816`, or whatever host served the
/// deployment) so the user lands back inside the running app, and mobile falls
/// back to the public site, which is opened in the system browser.
// TODO(EXPEDITOO-TESTING): vercel-build.sh passes APP_PUBLIC_URL through but
// leaves it empty by default, so each deployment redirects back to its own
// origin. Owner: set it in the Vercel environment only when Stripe must return
// to a different origin than the one serving the app (e.g. a custom domain in
// front of a preview host), and set it for mobile builds.
String paiementRedirectBaseUrl() {
  final configured = _kAppPublicUrl.trim();
  if (configured.isNotEmpty) {
    return configured.endsWith('/')
        ? configured.substring(0, configured.length - 1)
        : configured;
  }
  return kIsWeb ? Uri.base.origin : 'https://expedionencheres.com';
}

class PaiementModel extends FlutterFlowModel<PaiementWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - API (CreatePaymentIntent)] action in PAYER widget.
  ApiCallResponse? apiResultu6cADV;
  // Stores action output result for [Backend Call - API (CreatePaymentAirtable)] action in PAYER widget.
  ApiCallResponse? apiResultp9gadv;
  // Stores action output result for [Backend Call - API (CreatePaymentIntent)] action in PAYER widget.
  ApiCallResponse? apiResultu6cSTD;
  // Stores action output result for [Backend Call - API (CreatePaymentAirtable)] action in PAYER widget.
  ApiCallResponse? apiResultp9gstd;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
