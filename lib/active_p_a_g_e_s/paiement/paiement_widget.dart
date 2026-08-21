import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/expedion_api/expedion_quote.dart' show formatCents;
import '/design_system/ds_l10n.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'paiement_model.dart';
export 'paiement_model.dart';

/// Create a component with quote info and a payment boutton that will allow
/// a client to pay
class PaiementWidget extends StatefulWidget {
  const PaiementWidget({
    super.key,
    this.tarifADV,
    this.quoteID,
    required this.tarifSTD,
    required this.quoteNum,
  });

  final int? tarifADV;
  final String? quoteID;
  final int? tarifSTD;
  final String? quoteNum;

  static String routeName = 'Paiement';
  static String routePath = '/paiement';

  @override
  State<PaiementWidget> createState() => _PaiementWidgetState();
}

class _PaiementWidgetState extends State<PaiementWidget> {
  late PaiementModel _model;

  /// After the payment link is e-mailed, the page swaps its two action buttons
  /// for an in-place confirmation + "waiting for payment" status + resend,
  /// rather than popping to a blank route (this is now a full page, not a
  /// dialog, so there may be nothing to pop to).
  bool _emailSent = false;
  String _sentToEmail = '';
  bool _resending = false;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  /// The quote-kind label in the reader's language. `TypeDeDevisValide` holds a
  /// French sentinel used for logic ('Devis avec assurance AD valorem' /
  /// '...Standard'); showing it raw leaked French under the EN toggle.
  String _localizedKind(BuildContext context) {
    final kind = FFAppState().TypeDeDevisValide;
    final insured = kind == 'Devis avec assurance AD valorem';
    return xpdT(
      context,
      insured ? 'Devis avec assurance Ad Valorem' : 'Devis avec assurance Standard',
      insured ? 'Quote with Ad Valorem insurance' : 'Quote with Standard insurance',
    );
  }

  /// Creates a Checkout session server-side and e-mails the link, in the
  /// reader's language. On success the page switches to its "sent" state
  /// (confirmation + waiting-for-payment status + resend) instead of leaving
  /// the user on a dead-end. Shared by the button and the resend link.
  Future<void> _sendEmailLink(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final isEnglish = xpdIsEnglish(context);
    final email = currentUserEmail;
    final quoteId = widget.quoteID ?? '';

    if (email.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(xpdT(
            context,
            'Aucune adresse e-mail associée à votre compte.',
            'No e-mail address associated with your account.')),
      ));
      return;
    }
    if (quoteId.isEmpty || currentUserUid.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(xpdT(
            context,
            'Session ou devis introuvable. Reconnectez-vous puis réessayez.',
            'Session or quote not found. Please sign in again and retry.')),
      ));
      return;
    }
    final amount = computePaiementAmountCents(
      typeDevisValide: FFAppState().TypeDeDevisValide,
      tarifAdvCents: widget.tarifADV,
      tarifStdCents: widget.tarifSTD,
    );
    if (amount == null || amount <= 0) {
      messenger.showSnackBar(SnackBar(
        content: Text(xpdT(
            context,
            'Tarif indisponible pour ce devis. Contactez-nous avant de payer.',
            'No rate available for this quote. Please contact us before paying.')),
      ));
      return;
    }

    if (mounted) safeSetState(() => _resending = true);
    final baseUrl = paiementRedirectBaseUrl();
    // Paying the emailed link redirects to /success and updates the quote,
    // exactly like "Payer".
    final result = await SendPaymentLinkEmailCall.call(
      email: email,
      amount: amount,
      currency: 'EUR',
      // The line item the payer reads on Stripe's own checkout page and in
      // the receipt, so it follows their language like everything else.
      productName: xpdT(context, 'Retrait/Expédition de biens',
          'Goods pickup / shipping'),
      successUrl:
          '$baseUrl/success?session_id={CHECKOUT_SESSION_ID}&recordId=${Uri.encodeQueryComponent(quoteId)}',
      cancelUrl: '$baseUrl/cancel',
      userID: currentUserUid,
      orderID: quoteId,
      recordID: quoteId,
      quoteNum: widget.quoteNum,
      // Detect the user's language so the e-mail matches the FR/EN toggle.
      lang: isEnglish ? 'en' : 'fr',
    );
    if (!result.succeeded && kDebugMode) {
      debugPrint(
          'email-link failed: status=${result.statusCode} body=${result.jsonBody}');
    }
    if (!mounted) return;
    if (result.succeeded) {
      safeSetState(() {
        _emailSent = true;
        _sentToEmail = email;
        _resending = false;
      });
    } else {
      safeSetState(() => _resending = false);
      messenger.showSnackBar(SnackBar(
        content: Text(xpdT(context, 'Échec de l\'envoi de l\'e-mail. Réessayez.',
            'Failed to send the e-mail. Please try again.')),
      ));
    }
  }

  /// The page's "link sent" state: a confirmation, a waiting-for-payment
  /// status line, and a resend action — replaces the two action buttons once
  /// the e-mail has gone out.
  Widget _sentConfirmation(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: theme.success.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mark_email_read_rounded,
                      color: theme.success, size: 22.0),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      xpdT(context, 'Lien de paiement envoyé',
                          'Payment link sent'),
                      style: theme.titleSmall.override(
                        font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700),
                        letterSpacing: 0.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Text(
                xpdT(
                  context,
                  'Nous avons envoyé le lien de paiement à $_sentToEmail. Ouvrez-le pour régler ce devis en toute sécurité.',
                  'We sent the payment link to $_sentToEmail. Open it to pay this quote securely.',
                ),
                style: theme.bodySmall.override(
                  font: GoogleFonts.plusJakartaSans(),
                  color: theme.secondaryText,
                  letterSpacing: 0.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 12.0,
              height: 12.0,
              child: CircularProgressIndicator(
                  strokeWidth: 2.0, color: theme.primary),
            ),
            const SizedBox(width: 8.0),
            Text(
              xpdT(context, 'En attente du paiement…', 'Waiting for payment…'),
              style: theme.bodySmall.override(
                font: GoogleFonts.plusJakartaSans(),
                color: theme.secondaryText,
                letterSpacing: 0.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        FFButtonWidget(
          onPressed: _resending ? null : () => _sendEmailLink(context),
          text: _resending
              ? xpdT(context, 'Envoi…', 'Sending…')
              : xpdT(context, 'Renvoyer le lien', 'Resend the link'),
          options: FFButtonOptions(
            width: double.infinity,
            height: 44.0,
            padding: const EdgeInsets.all(8.0),
            color: theme.secondaryBackground,
            textStyle: theme.titleSmall.override(
              font: GoogleFonts.plusJakartaSans(),
              color: theme.primary,
              letterSpacing: 0.0,
            ),
            elevation: 0.0,
            borderSide: BorderSide(color: theme.primary, width: 1.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PaiementModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    // Dynamic 30-day validity date
    final expiry = DateTime.now().add(const Duration(days: 30));
    final expiryFormatted =
        '${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}';

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            boxShadow: const [
              BoxShadow(
                blurRadius: 4.0,
                color: Color(0x33000000),
                offset: Offset(0.0, 2.0),
                spreadRadius: 0.0,
              )
            ],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding:
                const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Quote Title ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizedKind(context),
                      style:
                          FlutterFlowTheme.of(context).headlineSmall.override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                                fontSize: 20.0,
                                letterSpacing: 0.0,
                              ),
                    ),
                    if (widget.quoteNum != null && widget.quoteNum!.isNotEmpty)
                      Text(
                        xpdT(context, 'Devis #${widget.quoteNum}',
                            'Quote #${widget.quoteNum}'),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                            ),
                      ),
                  ].divide(const SizedBox(height: 8.0)),
                ),

                // ── Divider + Amount ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 1.0,
                      decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).alternate),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          FFLocalizations.of(context).getText(
                            'pseoz70f' /* Total Amount */,
                          ),
                          style:
                              FlutterFlowTheme.of(context).titleMedium.override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                  ),
                        ),
                        Text(
                          formatCents(FFAppState().SelectedPrice),
                          style:
                              FlutterFlowTheme.of(context).titleMedium.override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).primary,
                                    letterSpacing: 0.0,
                                  ),
                        ),
                      ],
                    ),
                  ].divide(const SizedBox(height: 12.0)),
                ),

                // ── Validity + actions (or the "link sent" state) ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      xpdT(context, 'Valable jusqu\'au : $expiryFormatted',
                          'Valid until: $expiryFormatted'),
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                          ),
                    ),
                    if (_emailSent) _sentConfirmation(context),
                    if (!_emailSent) FFButtonWidget(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        // Read the locale before any `await` below so later
                        // messages don't touch `context` across an async gap.
                        final isEnglish = xpdIsEnglish(context);

                        // Without an authenticated user and a quote id, the
                        // Stripe metadata would be empty and the webhook could
                        // never match the payment back to a quote — bail early
                        // with clear feedback instead of creating an orphan
                        // payment.
                        final quoteId = widget.quoteID ?? '';
                        if (currentUserUid.isEmpty || quoteId.isEmpty) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(xpdT(
                                  context,
                                  'Session ou devis introuvable. Reconnectez-vous puis réessayez.',
                                  'Session or quote not found. Please sign in again and retry.')),
                            ),
                          );
                          return;
                        }

                        final amount = computePaiementAmountCents(
                          typeDevisValide: FFAppState().TypeDeDevisValide,
                          tarifAdvCents: widget.tarifADV,
                          tarifStdCents: widget.tarifSTD,
                        );
                        if (amount == null || amount <= 0) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(xpdT(
                                  context,
                                  'Tarif indisponible pour ce devis. Contactez-nous avant de payer.',
                                  'No rate available for this quote. Please contact us before paying.')),
                            ),
                          );
                          return;
                        }
                        final baseUrl = paiementRedirectBaseUrl();

                        final result = await CreatePaymentIntentCall.call(
                          unitAmount: amount,
                          currency: 'EUR',
                          userID: currentUserUid,
                          cancelUrl: '$baseUrl/cancel',
                          // recordId rides along so the in-app /success page can
                          // mark the quote paid in Airtable client-side (no
                          // webhook/deploy required).
                          successUrl:
                              '$baseUrl/success?session_id={CHECKOUT_SESSION_ID}&recordId=${Uri.encodeQueryComponent(quoteId)}',
                          // The line item the payer reads on Stripe's own
                          // checkout page, so it follows their language.
                          productName: xpdT(
                              context,
                              'Retrait/Expédition de biens',
                              'Goods pickup / shipping'),
                          quantity: 1,
                          recordID: quoteId,
                          orderID: quoteId,
                        );

                        if (result.succeeded) {
                          final url = CreatePaymentIntentCall.sessionURL(
                              result.jsonBody);
                          // The pending-payment record used to be a second
                          // write, to Airtable — dead since quotes moved to
                          // Postgres. There is nothing to double-write here:
                          // the session itself, and later /confirm-payment,
                          // are the record.

                          if (url != null) {
                            // Open Checkout in the same tab on web so Stripe
                            // can redirect the user back to <appOrigin>/success
                            // (or /cancel) inside the running app.
                            final opened = kIsWeb
                                ? await launchUrl(Uri.parse(url),
                                    webOnlyWindowName: '_self')
                                : await launchUrl(Uri.parse(url),
                                    mode: LaunchMode.externalApplication);
                            if (opened) {
                              return;
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(isEnglish
                                    ? 'Unable to open the payment link. Please check your connection.'
                                    : 'Impossible d\'ouvrir le lien de paiement. Vérifiez votre connexion.'),
                              ),
                            );
                            return;
                          }
                        } else if (kDebugMode) {
                          debugPrint(
                              'CreatePaymentIntent failed: status=${result.statusCode} error=${result.exceptionMessage} body=${result.jsonBody}');
                        }

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(isEnglish
                                ? 'The payment could not be started. Please try again.'
                                : 'Le paiement n\'a pas pu être initié. Réessayez.'),
                          ),
                        );
                        if (context.mounted) {
                          context.pushNamed(MesDevisWidget.routeName);
                        }
                        safeSetState(() {});
                      },
                      text: FFLocalizations.of(context).getText(
                        '46x3yoxv' /* Payer */,
                      ),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 48.0,
                        padding: const EdgeInsets.all(8.0),
                        iconPadding:
                            const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context).info,
                                  letterSpacing: 0.0,
                                ),
                        elevation: 0.0,
                        borderSide: const BorderSide(
                            color: Colors.transparent, width: 1.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    // ── Alternative: receive the Stripe link by e-mail ──
                    if (!_emailSent) FFButtonWidget(
                      onPressed: () => _sendEmailLink(context),
                      text: xpdT(context, 'Recevoir le lien par e-mail',
                          'Receive the link by e-mail'),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 44.0,
                        padding: const EdgeInsets.all(8.0),
                        iconPadding:
                            const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  font: GoogleFonts.plusJakartaSans(),
                                  color: FlutterFlowTheme.of(context).primary,
                                  letterSpacing: 0.0,
                                ),
                        elevation: 0.0,
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).primary,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ].divide(const SizedBox(height: 8.0)),
                ),
              ].divide(const SizedBox(height: 16.0)),
            ),
          ),
        ),
      ),
    );
  }
}
