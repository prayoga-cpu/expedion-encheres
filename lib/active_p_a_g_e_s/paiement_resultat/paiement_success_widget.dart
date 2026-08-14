import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Landing page Stripe redirects to after a successful Checkout
/// (`success_url = <appOrigin>/success?session_id={CHECKOUT_SESSION_ID}&recordId=<id>`).
///
/// When a [recordId] is present, the page marks the quote paid in Airtable
/// directly (client-side, no webhook/Cloud Function deploy needed) and shows
/// the progress of that update. The payment itself already succeeded on
/// Stripe's side regardless of whether this update succeeds.
class PaiementSuccessWidget extends StatefulWidget {
  const PaiementSuccessWidget({
    super.key,
    this.sessionId,
    this.recordId,
    this.markQuotePaid,
  });

  /// Stripe Checkout Session id, forwarded by Stripe as `?session_id=...`.
  final String? sessionId;

  /// Airtable record id of the paid quote, forwarded as `?recordId=...`.
  final String? recordId;

  /// Test seam: marks the quote paid and returns whether it succeeded.
  /// Defaults to a real Airtable PATCH via [MarkQuotePaidCall].
  final Future<bool> Function(String recordId)? markQuotePaid;

  static String routeName = 'PAIEMENT_SUCCESS';
  static String routePath = '/success';

  @override
  State<PaiementSuccessWidget> createState() => _PaiementSuccessWidgetState();
}

enum _UpdateStatus { none, updating, done, error }

class _PaiementSuccessWidgetState extends State<PaiementSuccessWidget> {
  _UpdateStatus _status = _UpdateStatus.none;

  @override
  void initState() {
    super.initState();
    final recordId = widget.recordId ?? '';
    if (recordId.isEmpty) return;

    _status = _UpdateStatus.updating;
    final markPaid = widget.markQuotePaid ?? _confirmPayment;
    markPaid(recordId).then((ok) {
      if (!mounted) return;
      setState(() => _status = ok ? _UpdateStatus.done : _UpdateStatus.error);
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _status = _UpdateStatus.error);
    });
  }

  // TODO(EXPEDITOO-TESTING): *** SECURITY — SPOOFABLE MARK-PAID FALLBACK ***
  // When the verify server is unreachable, this page PATCHes Airtable directly
  // and marks the quote paid with ZERO verification: anyone who visits
  // /success?recordId=<id> can mark an unpaid quote as paid. The flag below
  // defaults to true ONLY so testing works without a deployed payment server.
  // Before any real payment flows the owner MUST: (1) deploy the payment
  // server and set PAYMENT_SERVER_URL, (2) flip this default to false (or
  // build with --dart-define=ALLOW_UNVERIFIED_MARKPAID=false), and then
  // (3) delete the fallback branch and this flag entirely.
  static const bool _kAllowUnverifiedMarkPaid = bool.fromEnvironment(
    'ALLOW_UNVERIFIED_MARKPAID',
    defaultValue: true,
  );

  /// Verifies the payment server-side (the session is actually paid) and lets
  /// the server mark the quote paid in Airtable. Falls back to a direct
  /// client-side Airtable update if the server is unreachable — see the loud
  /// TODO above; the fallback is gated and must be removed for production.
  Future<bool> _confirmPayment(String recordId) async {
    final result = await ConfirmPaymentCall.call(
      sessionId: widget.sessionId ?? '',
      recordId: recordId,
    );
    if (result.succeeded) {
      return ConfirmPaymentCall.updated(result.jsonBody);
    }
    if (!_kAllowUnverifiedMarkPaid) {
      // No verified confirmation available; leave the quote untouched. The
      // Stripe payment itself still succeeded — reconcile via webhook/server.
      return false;
    }
    // Server unreachable → best-effort direct update (UNVERIFIED, see TODO).
    final fallback = await MarkQuotePaidCall.call(quoteID: recordId);
    return fallback.succeeded;
  }

  String? get _statusMessage {
    switch (_status) {
      case _UpdateStatus.updating:
        return 'Mise à jour du statut de votre devis…';
      case _UpdateStatus.done:
        return 'Votre devis est confirmé comme payé.';
      case _UpdateStatus.error:
        return 'Paiement reçu. La mise à jour du statut peut prendre quelques instants.';
      case _UpdateStatus.none:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final statusMessage = _statusMessage;
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480.0),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: theme.success, size: 72.0),
                  const SizedBox(height: 24.0),
                  Text(
                    'Paiement réussi',
                    textAlign: TextAlign.center,
                    style: theme.headlineSmall.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: theme.primaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Merci ! Votre paiement a bien été pris en compte.',
                    textAlign: TextAlign.center,
                    style: theme.bodyMedium.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: theme.secondaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
                  if (statusMessage != null) ...[
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_status == _UpdateStatus.updating) ...[
                          SizedBox(
                            width: 14.0,
                            height: 14.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(theme.primary),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                        ],
                        Flexible(
                          child: Text(
                            statusMessage,
                            textAlign: TextAlign.center,
                            style: theme.labelMedium.override(
                              font: GoogleFonts.plusJakartaSans(),
                              color: theme.secondaryText,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.sessionId != null &&
                      widget.sessionId!.isNotEmpty) ...[
                    const SizedBox(height: 12.0),
                    Text(
                      'Référence : ${widget.sessionId}',
                      textAlign: TextAlign.center,
                      style: theme.labelSmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: theme.secondaryText,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32.0),
                  FFButtonWidget(
                    onPressed: () => context.goNamed(MesDevisWidget.routeName),
                    text: 'Retour à mes devis',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 48.0,
                      color: theme.primary,
                      textStyle: theme.titleSmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: theme.info,
                        letterSpacing: 0.0,
                      ),
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
