import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
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

  /// Test seam: confirms the payment and returns whether the quote was
  /// recorded as paid. Defaults to [_confirmPayment], which verifies the Stripe
  /// session server-side.
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

  /// Whether the confirm call never reached the server at all.
  ///
  /// `ApiCallResponse.succeeded` is merely `200 <= statusCode < 300`, so a
  /// server that answers 402/403/404 ("this session was never paid") is a
  /// *definitive rejection*, not an outage, and must be trusted. Only a
  /// transport failure counts as unreachable: `ApiManager.makeApiCall` catches
  /// those and builds `ApiCallResponse(null, {}, -1, exception: e)`, so a
  /// status below any real HTTP code means no answer was received.
  static bool _isUnreachable(ApiCallResponse result) => result.statusCode < 100;

  /// Verifies the payment server-side — the session really is paid — and lets
  /// the server record it.
  ///
  /// There is deliberately no client-side fallback. There used to be one, gated
  /// behind `ALLOW_UNVERIFIED_MARKPAID`, which fired whenever the payment server
  /// was unreachable and PATCHed the quote straight to paid with no check at
  /// all: visiting `/success?recordId=<any id>` was enough to settle someone
  /// else's quote. It defaulted to on, and `vercel-build.sh` forwarded that
  /// default to production.
  ///
  /// It was also, by then, incapable of working: it wrote to the Airtable
  /// CONTACTS base using an id that has been a Postgres key since quotes moved
  /// off Airtable, so every call could only 404. Removing it costs nothing and
  /// closes the hole. An unconfirmed payment now stays unconfirmed until the
  /// payment server reconciles it, which is the honest outcome.
  Future<bool> _confirmPayment(String recordId) async {
    final result = await ConfirmPaymentCall.call(
      sessionId: widget.sessionId ?? '',
      recordId: recordId,
    );
    if (result.succeeded) {
      return ConfirmPaymentCall.updated(result.jsonBody);
    }
    if (kDebugMode) {
      debugPrint(
        'confirm-payment ${_isUnreachable(result) ? "unreachable" : "refused"}: '
        'status=${result.statusCode}',
      );
    }
    return false;
  }

  String? get _statusMessage {
    switch (_status) {
      case _UpdateStatus.updating:
        return 'Mise à jour du statut de votre devis…';
      case _UpdateStatus.done:
        return 'Votre devis est confirmé comme payé.';
      case _UpdateStatus.error:
        return 'Nous n\'avons pas encore pu confirmer ce paiement. '
            'Si votre carte a été débitée, le statut se mettra à jour '
            'automatiquement — sinon, contactez-nous.';
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
