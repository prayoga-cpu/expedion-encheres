import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/expedion_api/expedion_quote.dart' show formatCents;
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

  @override
  State<PaiementWidget> createState() => _PaiementWidgetState();
}

class _PaiementWidgetState extends State<PaiementWidget> {
  late PaiementModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
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
                      FFAppState().TypeDeDevisValide,
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
                        'Devis #${widget.quoteNum}',
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

                // ── Validity + Pay Button ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Valable jusqu\'au : $expiryFormatted',
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
                    FFButtonWidget(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);

                        // Without an authenticated user and a quote id, the
                        // Stripe metadata would be empty and the webhook could
                        // never match the payment back to a quote — bail early
                        // with clear feedback instead of creating an orphan
                        // payment.
                        final quoteId = widget.quoteID ?? '';
                        if (currentUserUid.isEmpty || quoteId.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Session ou devis introuvable. Reconnectez-vous puis réessayez.'),
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
                            const SnackBar(
                              content: Text(
                                  'Tarif indisponible pour ce devis. Contactez-nous avant de payer.'),
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
                          productName: 'Retrait/Expédition de biens',
                          quantity: 1,
                          recordID: quoteId,
                          orderID: quoteId,
                        );

                        if (result.succeeded) {
                          final url = CreatePaymentIntentCall.sessionURL(
                              result.jsonBody);
                          await CreatePaymentAirtableCall.call(
                            currency: 'EUR',
                            description: 'Paiement Devis Expedion Encheres',
                            amountstripe: amount,
                            orderId: quoteId,
                            status: 'Paiement en attente',
                            userId: currentUserUid,
                            paymentUrl: url,
                          );

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
                              const SnackBar(
                                content: Text(
                                    'Impossible d\'ouvrir le lien de paiement. Vérifiez votre connexion.'),
                              ),
                            );
                            return;
                          }
                        } else if (kDebugMode) {
                          debugPrint(
                              'CreatePaymentIntent failed: status=${result.statusCode} error=${result.exceptionMessage} body=${result.jsonBody}');
                        }

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Le paiement n\'a pas pu être initié. Réessayez.'),
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
                    FFButtonWidget(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        final email = currentUserEmail;
                        final quoteId = widget.quoteID ?? '';

                        if (email.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Aucune adresse e-mail associée à votre compte.'),
                            ),
                          );
                          return;
                        }
                        if (quoteId.isEmpty || currentUserUid.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Session ou devis introuvable. Reconnectez-vous puis réessayez.'),
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
                            const SnackBar(
                              content: Text(
                                  'Tarif indisponible pour ce devis. Contactez-nous avant de payer.'),
                            ),
                          );
                          return;
                        }
                        final baseUrl = paiementRedirectBaseUrl();

                        // The payment server creates a Checkout session and
                        // e-mails the link. Paying it redirects to /success and
                        // updates the quote, exactly like "Payer".
                        final result = await SendPaymentLinkEmailCall.call(
                          email: email,
                          amount: amount,
                          currency: 'EUR',
                          productName: 'Retrait/Expédition de biens',
                          successUrl:
                              '$baseUrl/success?session_id={CHECKOUT_SESSION_ID}&recordId=${Uri.encodeQueryComponent(quoteId)}',
                          cancelUrl: '$baseUrl/cancel',
                          userID: currentUserUid,
                          orderID: quoteId,
                          recordID: quoteId,
                          quoteNum: widget.quoteNum,
                        );
                        if (!result.succeeded && kDebugMode) {
                          debugPrint(
                              'email-link failed: status=${result.statusCode} body=${result.jsonBody}');
                        }

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(result.succeeded
                                ? 'Facture de paiement envoyée à $email'
                                : 'Échec de l\'envoi de l\'e-mail. Réessayez.'),
                          ),
                        );
                        if (result.succeeded) {
                          navigator.pop();
                        }
                      },
                      text: 'Recevoir le lien par e-mail',
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
