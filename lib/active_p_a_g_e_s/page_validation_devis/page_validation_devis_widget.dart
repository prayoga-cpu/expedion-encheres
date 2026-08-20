import '/app_shell.dart';
import '/active_p_a_g_e_s/paiement/paiement_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/expedion_api/expedion_quote.dart'
    show formatCents, kQuoteKindInsured;
import '/backend/expedion_api/quote_repository.dart';
import '/design_system/ds_l10n.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'page_validation_devis_model.dart';
export 'page_validation_devis_model.dart';

/// Create a page that allows a User to chose between two prices : Devis avec
/// asrance Advalorem and  Devis aveec assurrence standard .at the bottom add
/// to buttons: confirmer devis, Payer
class PageValidationDevisWidget extends StatefulWidget {
  const PageValidationDevisWidget({
    super.key,
    required this.tarifAssADV,
    required this.tarifAssSTD,
    required this.typeDevisChoisi,
    this.quoteID,
    required this.devisValideOuPas,
  });

  final int? tarifAssADV;
  final int? tarifAssSTD;
  final String? typeDevisChoisi;
  final String? quoteID;
  final String? devisValideOuPas;

  static String routeName = 'Page_Validation_Devis';
  static String routePath = '/pageValidationDevis';

  @override
  State<PageValidationDevisWidget> createState() =>
      _PageValidationDevisWidgetState();
}

class _PageValidationDevisWidgetState extends State<PageValidationDevisWidget> {
  late PageValidationDevisModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PageValidationDevisModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      FFAppState().DevisValideOuPas = '';
      FFAppState().TypeDeDevisValide = '';
      safeSetState(() {});
      FFAppState().DevisValideOuPas = 'Devis Validé';
      FFAppState().TypeDeDevisValide = _selectedKindFromRoute();
      safeSetState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  /// Translates the accepted kind the API returns into the vocabulary this
  /// page's buttons compare against.
  ///
  /// `typeDevisChoisi` carries `acceptedKind` straight off the wire, which is
  /// `standard` / `with_ad_valorem_insurance`. The two buttons below test for
  /// 'ADV' and the French label, so an accepted insured quote matched neither
  /// and fell through to the standard branch — billing the wrong tariff and
  /// relabelling the quote as standard on confirm.
  String _selectedKindFromRoute() {
    final kind = widget.typeDevisChoisi;
    if (kind == null || kind.isEmpty || kind == 'null') return '';
    return kind == kQuoteKindInsured ? 'ADV' : 'STD';
  }

  /// Whether the tariff for the currently selected kind was actually published.
  bool get _hasPriceForSelectedKind {
    final cents =
        FFAppState().TypeDeDevisValide == 'Devis avec assurance AD valorem'
            ? widget.tarifAssADV
            : widget.tarifAssSTD;
    return cents != null && cents > 0;
  }

  void _showMissingTariff() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          xpdT(
            context,
            'Tarif indisponible pour ce devis. Contactez-nous avant de payer.',
            'Tariff unavailable for this quote. Contact us before paying.',
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: XpdPage(
        current: XpdDestination.none,
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: 900.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 20.0, 0.0, 0.0),
                          child: Text(
                            FFLocalizations.of(context).getText(
                              'dbgkl39t' /* Choisissez votre assurance */,
                            ),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .headlineMedium
                                .override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .fontStyle,
                                  ),
                                  fontSize: 28.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .fontStyle,
                                ),
                          ),
                        ),
                        Text(
                          FFLocalizations.of(context).getText(
                            'jiu8q7xp' /* Sélectionnez le type d'assuran... */,
                          ),
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    FFAppState().TypeDeDevisValide = '';
                                    safeSetState(() {});
                                    FFAppState().TypeDeDevisValide = 'ADV';
                                    safeSetState(() {});
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(16.0),
                                      border: Border.all(
                                        color: FFAppState().TypeDeDevisValide ==
                                                'ADV'
                                            ? FlutterFlowTheme.of(context)
                                                .primary
                                            : FlutterFlowTheme.of(context)
                                                .alternate,
                                        width: 2.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'ip6ahqx8' /* Devis avec assurance */,
                                                      ),
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .titleLarge
                                                          .override(
                                                            font: GoogleFonts
                                                                .plusJakartaSans(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleLarge
                                                                      .fontStyle,
                                                            ),
                                                            fontSize: 20.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLarge
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  4.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Text(
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                          'hzstbv4q' /* Advalorem */,
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .plusJakartaSans(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary,
                                                                  fontSize:
                                                                      18.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleMedium
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 24.0,
                                                height: 24.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 2.0,
                                                  ),
                                                ),
                                                child: Visibility(
                                                  visible: FFAppState()
                                                          .TypeDeDevisValide ==
                                                      'ADV',
                                                  child: Icon(
                                                    Icons.check_circle,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    size: 24.0,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            FFLocalizations.of(context).getText(
                                              'rwfkh9cj' /* Couverture complète avec prote... */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 16.0, 0.0, 16.0),
                                            child: Divider(
                                              thickness: 1.0,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'uw33xcm9' /* Prix: */,
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                              ),
                                              Text(
                                                formatCents(widget.tarifAssADV),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary,
                                                          fontSize: 24.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontStyle,
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    FFAppState().TypeDeDevisValide = '';
                                    safeSetState(() {});
                                    FFAppState().TypeDeDevisValide = 'STD';
                                    safeSetState(() {});
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(16.0),
                                      border: Border.all(
                                        color: FFAppState().TypeDeDevisValide ==
                                                'STD'
                                            ? FlutterFlowTheme.of(context)
                                                .primary
                                            : FlutterFlowTheme.of(context)
                                                .alternate,
                                        width: 2.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        '0xqyb9wk' /* Devis avec assurance */,
                                                      ),
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .titleLarge
                                                          .override(
                                                            font: GoogleFonts
                                                                .plusJakartaSans(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleLarge
                                                                      .fontStyle,
                                                            ),
                                                            fontSize: 20.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLarge
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  4.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Text(
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                          '99pols2d' /* Standard */,
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .plusJakartaSans(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  fontSize:
                                                                      18.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleMedium
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 24.0,
                                                height: 24.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 2.0,
                                                  ),
                                                ),
                                                child: Visibility(
                                                  visible: FFAppState()
                                                          .TypeDeDevisValide ==
                                                      'STD',
                                                  child: Icon(
                                                    Icons.check_circle,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    size: 24.0,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            FFLocalizations.of(context).getText(
                                              'bd7vyssm' /* Protection de base avec couver... */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 16.0, 0.0, 16.0),
                                            child: Divider(
                                              thickness: 1.0,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'mut8vfyk' /* Prix: */,
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                              ),
                                              Text(
                                                formatCents(widget.tarifAssSTD),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          fontSize: 24.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontStyle,
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ].divide(SizedBox(height: 20.0)),
                            ),
                            Stack(
                              children: [
                                FFButtonWidget(
                                  onPressed: () async {
                                    // Refuse rather than invent a figure: the
                                    // tariffs used to fall back to 50, which
                                    // silently charged a made-up price when
                                    // the server had not published one.
                                    if (!_hasPriceForSelectedKind) {
                                      _showMissingTariff();
                                      return;
                                    }
                                    if (FFAppState().TypeDeDevisValide ==
                                        'Devis avec assurance AD valorem') {
                                      _model.apiResultz01ADV =
                                          await CreatePaymentIntentCall.call(
                                        unitAmount: widget.tarifAssADV!,
                                        currency: 'EUR',
                                        userID: currentUserUid,
                                        // TODO(EXPEDITOO-TESTING): redirect
                                        // URLs now derive from the app
                                        // origin / APP_PUBLIC_URL define
                                        // (was placeholder testurl.net.fr).
                                        // Owner: set APP_PUBLIC_URL at build
                                        // time (see vercel-build.sh).
                                        cancelUrl:
                                            '${paiementRedirectBaseUrl()}/cancel',
                                        successUrl:
                                            '${paiementRedirectBaseUrl()}/success?session_id={CHECKOUT_SESSION_ID}&recordId=${Uri.encodeQueryComponent(widget.quoteID ?? '')}',
                                        productName: xpdT(
                                          context,
                                          'Retrait/Expedition de biens',
                                          'Pickup/Shipping of goods',
                                        ),
                                        quantity: 1,
                                        recordID: widget.quoteID ?? '',
                                      );

                                      if ((_model.apiResultz01ADV?.succeeded ??
                                          true)) {
                                        // The pending-payment record used to be
                                        // a second write, to Airtable — dead
                                        // since quotes moved to Postgres.
                                        await launchURL(
                                            CreatePaymentIntentCall.sessionURL(
                                          (_model.apiResultz01ADV?.jsonBody ??
                                              ''),
                                        )!);
                                      }
                                    } else {
                                      _model.apiResultz01STD =
                                          await CreatePaymentIntentCall.call(
                                        unitAmount: widget.tarifAssSTD!,
                                        currency: 'eur',
                                        userID: currentUserUid,
                                        // TODO(EXPEDITOO-TESTING): redirect
                                        // URLs now derive from the app
                                        // origin / APP_PUBLIC_URL define
                                        // (was placeholder testurl.net.fr).
                                        // Owner: set APP_PUBLIC_URL at build
                                        // time (see vercel-build.sh).
                                        cancelUrl:
                                            '${paiementRedirectBaseUrl()}/cancel',
                                        successUrl:
                                            '${paiementRedirectBaseUrl()}/success?session_id={CHECKOUT_SESSION_ID}&recordId=${Uri.encodeQueryComponent(widget.quoteID ?? '')}',
                                        productName: xpdT(
                                          context,
                                          'Retrait/Expedition de biens',
                                          'Pickup/Shipping of goods',
                                        ),
                                        quantity: 1,
                                        recordID: widget.quoteID ?? '',
                                      );

                                      if ((_model.apiResultz01STD?.succeeded ??
                                          true)) {
                                        // Same: no second write, see the ADV
                                        // branch above.

                                        await launchURL(
                                            CreatePaymentIntentCall.sessionURL(
                                          (_model.apiResultz01STD?.jsonBody ??
                                              ''),
                                        )!);
                                      }
                                    }

                                    safeSetState(() {});
                                  },
                                  text: FFLocalizations.of(context).getText(
                                    '1mitwq8y' /* Payer */,
                                  ),
                                  options: FFButtonOptions(
                                    width: double.infinity,
                                    height: 52.0,
                                    padding: EdgeInsets.all(8.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          fontSize: 16.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderSide: BorderSide(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                Builder(
                                  builder: (context) => FFButtonWidget(
                                    onPressed: () async {
                                      final insured =
                                          FFAppState().TypeDeDevisValide ==
                                              'ADV';
                                      // Cents, straight from the quote. A
                                      // missing tariff stops the flow here
                                      // rather than opening a payment sheet
                                      // for an amount nobody published.
                                      final cents = insured
                                          ? widget.tarifAssADV
                                          : widget.tarifAssSTD;
                                      if (cents == null || cents <= 0) {
                                        _showMissingTariff();
                                        return;
                                      }
                                      FFAppState().TypeDeDevisValide = '';
                                      safeSetState(() {});
                                      FFAppState().TypeDeDevisValide = insured
                                          ? 'Devis avec assurance AD valorem'
                                          : 'Devis avec assurance Standard';
                                      FFAppState().SelectedPrice = cents;
                                      safeSetState(() {});

                                      // Fixes the accepted price and kind
                                      // server-side (`acceptedPriceCents`),
                                      // which is what the payment server will
                                      // trust once "Payer" is pressed — the
                                      // client's own `cents` value above is
                                      // display-only from this point on.
                                      final accept =
                                          await QuoteRepository.accept(
                                        widget.quoteID ?? '',
                                        insured: insured,
                                      );
                                      if (!accept.succeeded) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              xpdApiErrorMessage(
                                                context,
                                                accept.code,
                                                fallbackFr:
                                                    'Impossible de confirmer ce devis. Réessayez.',
                                                fallbackEn:
                                                    'Could not confirm this quote. Try again.',
                                              ),
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      FFAppState().DevisValideOuPas =
                                          'Devis Validé';
                                      safeSetState(() {});
                                      if (!context.mounted) return;
                                      await showDialog(
                                        context: context,
                                        builder: (dialogContext) {
                                          return Dialog(
                                            elevation: 0,
                                            insetPadding: EdgeInsets.zero,
                                            backgroundColor: Colors.transparent,
                                            alignment: AlignmentDirectional(
                                                    0.0, 0.0)
                                                .resolve(
                                                    Directionality.of(context)),
                                            child: GestureDetector(
                                              onTap: () {
                                                FocusScope.of(dialogContext)
                                                    .unfocus();
                                                FocusManager
                                                    .instance.primaryFocus
                                                    ?.unfocus();
                                              },
                                              child: Container(
                                                height: 800.0,
                                                width: 400.0,
                                                child: PaiementWidget(
                                                  tarifADV: FFAppState()
                                                      .SelectedPrice,
                                                  quoteID: widget.quoteID ?? '',
                                                  tarifSTD: FFAppState()
                                                      .SelectedPrice,
                                                  quoteNum: FFAppState()
                                                      .SelectedQuoteNum,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );

                                      safeSetState(() {});
                                    },
                                    text: FFLocalizations.of(context).getText(
                                      'exitny41' /* Confirmer devis */,
                                    ),
                                    options: FFButtonOptions(
                                      width: double.infinity,
                                      height: 52.0,
                                      padding: EdgeInsets.all(8.0),
                                      iconPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              0.0, 0.0, 0.0, 0.0),
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      textStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                            color: Colors.white,
                                            fontSize: 16.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                      elevation: 0.0,
                                      borderSide: BorderSide(
                                        color: Colors.transparent,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ].divide(SizedBox(height: 20.0)),
                    ),
                  ),
                ),
                Container(
                  width: 1500.0,
                  height: 1.0,
                  decoration: BoxDecoration(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
