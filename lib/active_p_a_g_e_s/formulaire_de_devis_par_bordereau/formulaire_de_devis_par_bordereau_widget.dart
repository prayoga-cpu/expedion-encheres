import '/app_shell.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/bordereau_check.dart';
import '/backend/expedion_api/quote_repository.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/quote_draft.dart';
import '/design_system/ds_l10n.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:async';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'bordereau_review.dart';
import 'formulaire_de_devis_par_bordereau_model.dart';
export 'formulaire_de_devis_par_bordereau_model.dart';

/// create a form for a website page that allows a client to ask for a
/// transport quote.
///
/// the page must be adptable for computer and phone screen. the second column
/// must be in a container that is 800 wide and centered
class FormulaireDeDevisParBordereauWidget extends StatefulWidget {
  const FormulaireDeDevisParBordereauWidget({super.key});

  static String routeName = 'Formulaire-de-devis-par-bordereau';
  static String routePath = '/formulaireDeDevisParBordereau';

  @override
  State<FormulaireDeDevisParBordereauWidget> createState() =>
      _FormulaireDeDevisParBordereauWidgetState();
}

class _FormulaireDeDevisParBordereauWidgetState
    extends State<FormulaireDeDevisParBordereauWidget> {
  late FormulaireDeDevisParBordereauModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// The staged express-card bordereau's upload while it is in flight. Submit
  /// awaits it, so tapping "Envoyer" early cannot silently drop the file.
  Future<void>? _draftBordereauUpload;

  /// True while the quote is being filed, so the button cannot be pressed twice
  /// and file two identical devis.
  bool _submitting = false;

  /// The verdict on the attached bordereau.
  ///
  /// "Envoyer" is gated on it: this form's whole input is one document, and a
  /// document that is not a bordereau produces a devis nobody can price. The
  /// check runs at pick time so the objection lands while the client still has
  /// the right file to hand — see [BordereauCheck].
  BordereauCheck _check = const BordereauCheck.idle();

  /// The attached file, kept so "Réessayer la lecture" does not have to send
  /// the client back through the picker for a document they already chose.
  Uint8List? _slipBytes;
  String _slipFilename = '';

  /// Guards against an out-of-order read: picking a second file while the
  /// first is still in the model must not let the first one's verdict land on
  /// the second one's document.
  int _checkGeneration = 0;

  Future<void> _runBordereauCheck(Uint8List bytes, String filename) async {
    final generation = ++_checkGeneration;
    safeSetState(() {
      _slipBytes = bytes;
      _slipFilename = filename;
      _check = const BordereauCheck.checking();
    });

    final check = await BordereauCheck.run(bytes: bytes, filename: filename);
    if (!mounted || generation != _checkGeneration) return;
    safeSetState(() => _check = check);
  }

  /// Drops the verdict along with the file it belonged to. Bumping the
  /// generation also orphans a read still in flight.
  void _clearBordereauCheck() {
    _checkGeneration++;
    _slipBytes = null;
    _slipFilename = '';
    _check = const BordereauCheck.idle();
  }

  /// The required answers this form asks for beside the bordereau, as the
  /// labels themselves promise: every field printed with an asterisk.
  ///
  /// Only ad valorem qualifies today — "Que souhaitez-vous ?" is asterisked but
  /// carries a preselected answer, and "Montant de la marchandise" is not
  /// asterisked at all. Add to this list rather than to [_canSubmit], so a new
  /// requirement is named to the client instead of just disabling the button.
  List<String> _missingRequiredFields(BuildContext context) => [
        if ((_model.assuranceADVValue ?? '').isEmpty)
          xpdT(context, "l'assurance ad valorem", 'ad valorem insurance'),
      ];

  /// Whether the devis can be filed.
  ///
  /// Everything here was previously unenforced: the asterisks on "Insérez un
  /// bordereau" and on the ad valorem question were decoration, and an empty
  /// form submitted happily. The panel above the button names whichever of
  /// these is unmet, so a disabled button is never unexplained.
  bool get _canSubmit =>
      _model.uploadedFileUrl_uploadDataBordereau.isNotEmpty &&
      !_model.isDataUploading_uploadDataBordereau &&
      !_check.blocksSubmit &&
      (_model.assuranceADVValue ?? '').isNotEmpty &&
      !_submitting;

  /// Files the devis with Expeditoo.
  ///
  /// This used to POST to Airtable and navigate away without looking at the
  /// response, so a rejected quote and a filed one were indistinguishable from
  /// the client's side — the page just moved on and "Mes devis" stayed empty.
  /// Now the outcome decides what happens: success navigates, failure says why
  /// and leaves the form intact so nothing typed is lost.
  Future<void> _submitQuote() async {
    if (_submitting) return;
    safeSetState(() => _submitting = true);

    final photoUrl = _model.uploadedFileUrl_uploadDataPhoto;
    final bordereauUrl = _model.uploadedFileUrl_uploadDataBordereau;

    // The three dropdowns and the comment are all this form collects; the
    // server's extraction step reads the rest off the bordereau itself.
    final comment = [
      _model.commentaireTextController.text.trim(),
      if ((_model.queSouhaitezVousValue ?? '').isNotEmpty)
        'Demande : ${_model.queSouhaitezVousValue}',
      if ((_model.assuranceADVValue ?? '').isNotEmpty)
        'Assurance ad valorem : ${_model.assuranceADVValue}',
    ].where((line) => line.isNotEmpty).join('\n');

    // What the bordereau said, with what the account knows laid over it. The
    // signed-in client's own name, e-mail and phone are authoritative — the
    // slip's "buyer" may be an agent, or simply out of date — but everything
    // the slip alone can give (the auction house, the collection address, the
    // lot and its value) now travels with the devis instead of waiting for
    // someone to open the PDF by hand.
    final payload = <String, dynamic>{..._check.quotePatch};
    void fill(String key, Object? value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      payload[key] = value;
    }

    fill('bordereauDocUrl', bordereauUrl);
    if (photoUrl.isNotEmpty && Uri.tryParse(photoUrl)?.hasScheme == true) {
      fill('photoUrls', [photoUrl]);
    }
    fill('firstName', valueOrDefault(currentUserDocument?.prenom, ''));
    fill('lastName', valueOrDefault(currentUserDocument?.nom, ''));
    fill('email', currentUserEmail);
    fill('phone', currentPhoneNumber);
    fill('valueBracket', _model.trancheValue);
    fill('comment', comment);

    final result = await QuoteRepository.create(payload);

    if (!mounted) return;
    safeSetState(() => _submitting = false);

    if (!result.succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.needsSignIn
                ? FFLocalizations.of(context).getVariableText(
                    frText: 'Connectez-vous pour envoyer votre demande.',
                    enText: 'Sign in to send your request.',
                  )
                : xpdApiErrorMessage(
                    context,
                    result.code,
                    fallbackFr: "L'envoi a échoué. Réessayez.",
                    fallbackEn: 'Could not send the request. Try again.',
                  ),
          ),
        ),
      );
      if (result.needsSignIn) {
        context.pushNamed(SeConnecterWidget.routeName);
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          FFLocalizations.of(context).getVariableText(
            frText: 'Demande envoyée. Votre devis arrive sous 48 h.',
            enText: 'Request sent. Your quote will arrive within 48 h.',
          ),
        ),
      ),
    );
    context.pushNamed(MesDevisWidget.routeName);
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FormulaireDeDevisParBordereauModel());

    // Whatever the landing page's express/quote card collected. This form has
    // no address/lot fields of its own, so everything the card knew is parked
    // in the comment — the one free-text field this quote submits — instead of
    // being silently dropped ([QuoteDraft.consume] clears as it reads).
    final draft = QuoteDraft.consume();
    // The labels below prefill the visible "Commentaire" field, so they must
    // read in the active language just like the rest of the form — this used
    // to be hardcoded French and would still show up under the English toggle.
    String draftLabel(String fr, String en) =>
        FFLocalizations.of(context).getVariableText(frText: fr, enText: en);
    final draftSummary = [
      if ((draft?.pickup ?? '').isNotEmpty)
        '${draftLabel('Retrait', 'Pickup')} : ${draft!.pickup}',
      if ((draft?.delivery ?? '').isNotEmpty)
        '${draftLabel('Livraison', 'Delivery')} : ${draft!.delivery}',
      if ((draft?.lotCount ?? '').isNotEmpty)
        '${draftLabel('Nombre de lots', 'Number of lots')} : ${draft!.lotCount}',
      if ((draft?.lotType ?? '').isNotEmpty)
        '${draftLabel('Type de lots', 'Lot type')} : ${draft!.lotType}',
      if ((draft?.hammerPrice ?? '').isNotEmpty)
        '${draftLabel('Montant adjugé', 'Hammer price')} : ${draft!.hammerPrice}',
      if ((draft?.deadline ?? '').isNotEmpty)
        '${draftLabel('Deadline de retrait', 'Pickup deadline')} : ${draft!.deadline}',
      if ((draft?.email ?? '').isNotEmpty)
        '${draftLabel('E-mail', 'Email')} : ${draft!.email}',
      if ((draft?.phone ?? '').isNotEmpty)
        '${draftLabel('Téléphone', 'Phone')} : ${draft!.phone}',
    ].join('\n');

    _model.commentaireTextController ??=
        TextEditingController(text: draftSummary);
    _model.commentaireFocusNode ??= FocusNode();

    // If the landing page's express card attached a bordereau, carry it in as
    // though the visitor had picked it here: show it locally right away and
    // upload it post-frame so the submit's uploadedFileUrl is populated.
    final draftBordereau = draft?.bordereau;
    if (draftBordereau != null && draftBordereau.bytes.isNotEmpty) {
      final stagedLocalFile = FFUploadedFile(
        name: draftBordereau.storagePath.split('/').last,
        bytes: draftBordereau.bytes,
        originalFilename: draftBordereau.originalFilename,
      );
      _model.uploadedLocalFile_uploadDataBordereau = stagedLocalFile;
      // A slip that arrived from the landing page has to clear the same bar as
      // one picked here — the gate is on the document, not on which screen
      // chose it. Deferred with the upload below because `run` reads
      // `ExpedionApi`'s credentials, and this is still `initState`.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_runBordereauCheck(
          draftBordereau.bytes,
          draftBordereau.originalFilename,
        )),
      );
      // TODO(EXPEDITOO-TESTING): best-effort upload of the express-card
      // bordereau. If Firebase Storage rejects the stored path (e.g. the file
      // was picked while signed out), uploadedFileUrl stays empty and the
      // attachment is still dropped from the Airtable quote unless the
      // visitor re-picks it. Owner: recompute the storage path under the
      // signed-in user's prefix before uploading (expose a public path helper
      // in lib/flutter_flow/upload_data.dart) so this upload can't be
      // rejected by storage rules.
      final uploadDone = Completer<void>();
      _draftBordereauUpload = uploadDone.future;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        safeSetState(() => _model.isDataUploading_uploadDataBordereau = true);
        String? url;
        try {
          url = await uploadData(
              draftBordereau.storagePath, draftBordereau.bytes);
        } catch (_) {
          url = null; // Best effort — the visitor can re-pick the file.
        } finally {
          _model.isDataUploading_uploadDataBordereau = false;
        }
        // Only claim the slot if it is still the staged file: while this was in
        // flight the visitor may have picked their own bordereau (or removed
        // this one), and that choice wins.
        if (url != null &&
            identical(_model.uploadedLocalFile_uploadDataBordereau,
                stagedLocalFile)) {
          _model.uploadedFileUrl_uploadDataBordereau = url;
        }
        safeSetState(() {});
        uploadDone.complete();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    // The form used to sit behind a `FutureBuilder` on Airtable's `GetPrice`
    // table whose response was never read — it only ever gated rendering. With
    // no Airtable PAT configured that future never completed, so the page stayed
    // on its spinner forever and "Nouveau bordereau" appeared to do nothing.
    // Pricing is the server's job now (`expedionService.autoPrice`), so the
    // form renders immediately.
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: XpdPage(
        current: XpdDestination.requestQuote,
        onBack: () => context.safePop(),
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
                  child: Align(
                    alignment: AlignmentDirectional(0.0, -1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              10.0, 30.0, 10.0, 0.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    FFLocalizations.of(context).getText(
                                      'ecqz1jlv' /* Remplissez le formulaire ci-de... */,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontStyle,
                                          ),
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyLarge
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyLarge
                                                  .fontStyle,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 20.0,
                                  color: Color(0x1A000000),
                                  offset: Offset(
                                    0.0,
                                    8.0,
                                  ),
                                )
                              ],
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Form(
                                  key: _model.formKey,
                                  autovalidateMode: AutovalidateMode.disabled,
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        20.0, 0.0, 20.0, 0.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 20.0, 0.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'wqfii7ko' /* Demande devis par bordereau d'... */,
                                            ),
                                            textAlign: TextAlign.center,
                                            style: FlutterFlowTheme.of(context)
                                                .headlineSmall
                                                .override(
                                                  font: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .headlineSmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .headlineSmall
                                                          .fontStyle,
                                                ),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 8.0),
                                                    child: Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'dd7rsein' /* Que souhaitez-vous? * */,
                                                      ),
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .plusJakartaSans(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
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
                                                  ),
                                                  FlutterFlowDropDown<String>(
                                                    controller: _model
                                                            .queSouhaitezVousValueController ??=
                                                        FormFieldController<
                                                            String>(
                                                      _model.queSouhaitezVousValue ??=
                                                          'Retrait enchères - Withdraw your lots in an auction house',
                                                    ),
                                                    options: List<String>.from([
                                                      'Retrait enchères - Withdraw your lots in an auction house'
                                                    ]),
                                                    optionLabels: [
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        '1jleyuie' /* Retrait enchères */,
                                                      )
                                                    ],
                                                    onChanged: (val) async {
                                                      safeSetState(() => _model
                                                              .queSouhaitezVousValue =
                                                          val);
                                                      FFAppState()
                                                              .selectedPlace =
                                                          _model
                                                              .queSouhaitezVousValue!;
                                                      safeSetState(() {});
                                                    },
                                                    width: 300.0,
                                                    textStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .override(
                                                              font: GoogleFonts
                                                                  .plusJakartaSans(
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                              letterSpacing:
                                                                  0.0,
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
                                                    hintText:
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                      'vxy3mciq' /* Selectionez ici */,
                                                    ),
                                                    icon: Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      size: 24.0,
                                                    ),
                                                    fillColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primaryBackground,
                                                    elevation: 2.0,
                                                    borderColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .alternate,
                                                    borderWidth: 0.0,
                                                    borderRadius: 8.0,
                                                    margin:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 0.0),
                                                    hidesUnderline: true,
                                                    isOverButton: false,
                                                    isSearchable: false,
                                                    isMultiSelect: false,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ].divide(SizedBox(width: 16.0)),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 8.0),
                                                    child: Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        '8tzczywk' /* Souhaitez-vous une assurance A... */,
                                                      ),
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .plusJakartaSans(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
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
                                                  ),
                                                  FlutterFlowDropDown<String>(
                                                    controller: _model
                                                            .assuranceADVValueController ??=
                                                        FormFieldController<
                                                            String>(null),
                                                    options: List<String>.from([
                                                      'OUI - YES',
                                                      'NON - NO',
                                                      'Ne se prononce pas - not pronounced'
                                                    ]),
                                                    optionLabels: [
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'r5w5bnke' /* OUI - YES */,
                                                      ),
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'ylvpdhj6' /* NON - NO */,
                                                      ),
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        '5m6o7bzs' /* Ne se prononce pas - not prono... */,
                                                      )
                                                    ],
                                                    onChanged: (val) =>
                                                        safeSetState(() => _model
                                                                .assuranceADVValue =
                                                            val),
                                                    width: 300.0,
                                                    textStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .override(
                                                              font: GoogleFonts
                                                                  .plusJakartaSans(
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                              letterSpacing:
                                                                  0.0,
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
                                                    hintText:
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                      'zopj5xhi' /* Selectionez ici */,
                                                    ),
                                                    icon: Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      size: 24.0,
                                                    ),
                                                    fillColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primaryBackground,
                                                    elevation: 2.0,
                                                    borderColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .alternate,
                                                    borderWidth: 0.0,
                                                    borderRadius: 8.0,
                                                    margin:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 0.0),
                                                    hidesUnderline: true,
                                                    isOverButton: false,
                                                    isSearchable: false,
                                                    isMultiSelect: false,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ].divide(SizedBox(width: 16.0)),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 8.0),
                                                    child: Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'porjfywj' /* Montant de la marchandise à ha... */,
                                                      ),
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .plusJakartaSans(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
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
                                                  ),
                                                  FlutterFlowDropDown<String>(
                                                    controller: _model
                                                            .trancheValueController ??=
                                                        FormFieldController<
                                                            String>(
                                                      _model.trancheValue ??=
                                                          '',
                                                    ),
                                                    options: List<String>.from([
                                                      'Jusqu\'à 150 €',
                                                      'Jusqu\'à 250 €',
                                                      'Jusqu\'à 500 €',
                                                      'Jusqu\'à 1000 €',
                                                      'Jusqu\'à 1500 €',
                                                      'Jusqu\'à 2000 €',
                                                      'Jusqu\'à 2500 €',
                                                      'Jusqu\'à 3000 €',
                                                      'Jusqu\'à 3500 €',
                                                      'Jusqu\'à 4000 €',
                                                      'Jusqu\'à 4500 €',
                                                      'Jusqu\'à 5000 €'
                                                    ]),
                                                    optionLabels: [
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'moea6ki0' /* Jusqu'à 150 € */,
                                                      ),
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'e92q2ix2' /* Jusqu'à 250 € */,
                                                      ),
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'ypsifoji' /* Jusqu'à 500 € */,
                                                      ),
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'q7t2ojvd' /* Jusqu'à 1000 € */,
                                                      ),
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'hgtmku9f' /* Jusqu'à 1500 € */,
                                                      ),
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        '7x3xxnbc' /* Jusqu'à 2000 € */,
                                                      ),
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'i8zp66ie' /* Jusqu'à 2500 € */,
                                                      ),
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'aw2568vr' /* Jusqu'à 3000 € */,
                                                      ),
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'zuj9pxqx' /* Jusqu'à 3500 € */,
                                                      ),
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        '3v7yrtkg' /* Jusqu'à 4000 € */,
                                                      ),
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'kti6lcuu' /* Jusqu'à 4500 € */,
                                                      ),
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'i2tfptij' /* Jusqu'à 5000 € */,
                                                      )
                                                    ],
                                                    onChanged: (val) async {
                                                      safeSetState(() => _model
                                                          .trancheValue = val);
                                                      FFAppState()
                                                              .selectedSize =
                                                          _model.trancheValue!;
                                                      safeSetState(() {});
                                                    },
                                                    width: 300.0,
                                                    textStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .override(
                                                              font: GoogleFonts
                                                                  .plusJakartaSans(
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                              letterSpacing:
                                                                  0.0,
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
                                                    hintText:
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                      '8h917upp' /* Selectionez ici */,
                                                    ),
                                                    icon: Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      size: 24.0,
                                                    ),
                                                    fillColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primaryBackground,
                                                    elevation: 2.0,
                                                    borderColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .alternate,
                                                    borderWidth: 0.0,
                                                    borderRadius: 8.0,
                                                    margin:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 0.0),
                                                    hidesUnderline: true,
                                                    isOverButton: false,
                                                    isSearchable: false,
                                                    isMultiSelect: false,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ].divide(SizedBox(width: 16.0)),
                                        ),
                                        Divider(
                                          height: 1.0,
                                          thickness: 1.0,
                                          color: FlutterFlowTheme.of(context)
                                              .alternate,
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 0.0, 0.0, 8.0),
                                              child: Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'qsdfozzd' /* Commentaire */,
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
                                            ),
                                            TextFormField(
                                              controller: _model
                                                  .commentaireTextController,
                                              focusNode:
                                                  _model.commentaireFocusNode,
                                              autofocus: false,
                                              textInputAction:
                                                  TextInputAction.done,
                                              obscureText: false,
                                              decoration: InputDecoration(
                                                hintText:
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                  's3qdtido' /* Exigences particulières, détai... */,
                                                ),
                                                hintStyle:
                                                    FlutterFlowTheme.of(context)
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
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 1.0,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    width: 1.0,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: Color(0x00000000),
                                                    width: 1.0,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedErrorBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: Color(0x00000000),
                                                    width: 1.0,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                filled: true,
                                                fillColor:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryBackground,
                                                contentPadding:
                                                    EdgeInsetsDirectional
                                                        .fromSTEB(16.0, 16.0,
                                                            16.0, 16.0),
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
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
                                                        fontSize: 16.0,
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
                                              maxLines: 4,
                                              minLines: 3,
                                              keyboardType:
                                                  TextInputType.multiline,
                                              cursorColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              validator: _model
                                                  .commentaireTextControllerValidator
                                                  .asValidator(context),
                                            ),
                                          ],
                                        ),
                                        Divider(
                                          height: 1.0,
                                          thickness: 1.0,
                                          color: FlutterFlowTheme.of(context)
                                              .alternate,
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                final selectedFiles =
                                                    await selectFiles(
                                                  allowedExtensions:
                                                      kBordereauExtensions,
                                                  multiFile: false,
                                                );
                                                if (selectedFiles != null) {
                                                  // Read the slip and store it
                                                  // at the same time: vision
                                                  // over a PDF takes far longer
                                                  // than the upload does, and
                                                  // neither waits on the other.
                                                  unawaited(_runBordereauCheck(
                                                    selectedFiles.first.bytes,
                                                    selectedFiles.first
                                                        .originalFilename,
                                                  ));
                                                  safeSetState(() => _model
                                                          .isDataUploading_uploadDataBordereau =
                                                      true);
                                                  var selectedUploadedFiles =
                                                      <FFUploadedFile>[];

                                                  var downloadUrls = <String>[];
                                                  try {
                                                    selectedUploadedFiles =
                                                        selectedFiles
                                                            .map((m) =>
                                                                FFUploadedFile(
                                                                  name: m
                                                                      .storagePath
                                                                      .split(
                                                                          '/')
                                                                      .last,
                                                                  bytes:
                                                                      m.bytes,
                                                                  originalFilename:
                                                                      m.originalFilename,
                                                                ))
                                                            .toList();

                                                    downloadUrls = (await Future
                                                            .wait(
                                                      selectedFiles.map(
                                                        (f) async =>
                                                            await uploadData(
                                                                f.storagePath,
                                                                f.bytes),
                                                      ),
                                                    ))
                                                        .where((u) => u != null)
                                                        .map((u) => u!)
                                                        .toList();
                                                  } finally {
                                                    _model.isDataUploading_uploadDataBordereau =
                                                        false;
                                                  }
                                                  if (selectedUploadedFiles
                                                              .length ==
                                                          selectedFiles
                                                              .length &&
                                                      downloadUrls.length ==
                                                          selectedFiles
                                                              .length) {
                                                    safeSetState(() {
                                                      _model.uploadedLocalFile_uploadDataBordereau =
                                                          selectedUploadedFiles
                                                              .first;
                                                      _model.uploadedFileUrl_uploadDataBordereau =
                                                          downloadUrls.first;
                                                    });
                                                  } else {
                                                    safeSetState(() {});
                                                    return;
                                                  }
                                                }

                                                FFAppState()
                                                        .uploadedBodereauUrl =
                                                    _model
                                                        .uploadedFileUrl_uploadDataBordereau;
                                                safeSetState(() {});
                                              },
                                              child: Container(
                                                width: 252.26,
                                                height: 73.4,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          18.0),
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      // Not the generated
                                                      // `k52ooucw` string any
                                                      // more: that one promises
                                                      // PDF, and the picker now
                                                      // takes a photo of the
                                                      // slip too.
                                                      xpdT(
                                                        context,
                                                        'Insérez un bordereau (PDF ou photo) *',
                                                        'Add your slip (PDF or photo) *',
                                                      ),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font: GoogleFonts
                                                                    .plusJakartaSans(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                    ),
                                                    Icon(
                                                      Icons.add,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      size: 30.0,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if ((FFAppState()
                                                            .uploadedBodereauUrl !=
                                                        null &&
                                                    FFAppState()
                                                            .uploadedBodereauUrl !=
                                                        '') &&
                                                responsiveVisibility(
                                                  context: context,
                                                  phone: false,
                                                  tablet: false,
                                                ))
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      'taftq4ax' /* Un pdf a été téléchargé. */,
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
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
                                                  InkWell(
                                                    splashColor:
                                                        Colors.transparent,
                                                    focusColor:
                                                        Colors.transparent,
                                                    hoverColor:
                                                        Colors.transparent,
                                                    highlightColor:
                                                        Colors.transparent,
                                                    onTap: () async {
                                                      safeSetState(() {
                                                        _model.isDataUploading_uploadDataBordereau =
                                                            false;
                                                        _model.uploadedLocalFile_uploadDataBordereau =
                                                            FFUploadedFile(
                                                                bytes: Uint8List
                                                                    .fromList(
                                                                        []),
                                                                originalFilename:
                                                                    '');
                                                        _model.uploadedFileUrl_uploadDataBordereau =
                                                            '';
                                                        _clearBordereauCheck();
                                                      });

                                                      FFAppState()
                                                          .uploadedBodereauUrl = '';
                                                      safeSetState(() {});
                                                    },
                                                    child: Icon(
                                                      Icons.close,
                                                      color: Color(0xFFE91A1A),
                                                      size: 20.0,
                                                    ),
                                                  ),
                                                ].divide(SizedBox(width: 10.0)),
                                              ),
                                          ].divide(SizedBox(width: 20.0)),
                                        ),
                                        if ((FFAppState().uploadedBodereauUrl !=
                                                    null &&
                                                FFAppState()
                                                        .uploadedBodereauUrl !=
                                                    '') &&
                                            responsiveVisibility(
                                              context: context,
                                              tabletLandscape: false,
                                              desktop: false,
                                            ))
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'qy1s58ny' /* Un pdf a été téléchargé. */,
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
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
                                              InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: () async {
                                                  safeSetState(() {
                                                    _model.isDataUploading_uploadDataBordereau =
                                                        false;
                                                    _model.uploadedLocalFile_uploadDataBordereau =
                                                        FFUploadedFile(
                                                            bytes: Uint8List
                                                                .fromList([]),
                                                            originalFilename:
                                                                '');
                                                    _model.uploadedFileUrl_uploadDataBordereau =
                                                        '';
                                                    _clearBordereauCheck();
                                                  });

                                                  FFAppState()
                                                      .uploadedBodereauUrl = '';
                                                  safeSetState(() {});
                                                },
                                                child: Icon(
                                                  Icons.close,
                                                  color: Color(0xFFE91A1A),
                                                  size: 20.0,
                                                ),
                                              ),
                                            ].divide(SizedBox(width: 10.0)),
                                          ),
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                final selectedMedia =
                                                    await selectMediaWithSourceBottomSheet(
                                                  context: context,
                                                  maxWidth: 600.00,
                                                  maxHeight: 350.00,
                                                  allowPhoto: true,
                                                );
                                                if (selectedMedia != null &&
                                                    selectedMedia.every((m) =>
                                                        validateFileFormat(
                                                            m.storagePath,
                                                            context))) {
                                                  safeSetState(() => _model
                                                          .isDataUploading_uploadDataPhoto =
                                                      true);
                                                  var selectedUploadedFiles =
                                                      <FFUploadedFile>[];

                                                  var downloadUrls = <String>[];
                                                  try {
                                                    selectedUploadedFiles =
                                                        selectedMedia
                                                            .map((m) =>
                                                                FFUploadedFile(
                                                                  name: m
                                                                      .storagePath
                                                                      .split(
                                                                          '/')
                                                                      .last,
                                                                  bytes:
                                                                      m.bytes,
                                                                  height: m
                                                                      .dimensions
                                                                      ?.height,
                                                                  width: m
                                                                      .dimensions
                                                                      ?.width,
                                                                  blurHash: m
                                                                      .blurHash,
                                                                  originalFilename:
                                                                      m.originalFilename,
                                                                ))
                                                            .toList();

                                                    downloadUrls = (await Future
                                                            .wait(
                                                      selectedMedia.map(
                                                        (m) async =>
                                                            await uploadData(
                                                                m.storagePath,
                                                                m.bytes),
                                                      ),
                                                    ))
                                                        .where((u) => u != null)
                                                        .map((u) => u!)
                                                        .toList();
                                                  } finally {
                                                    _model.isDataUploading_uploadDataPhoto =
                                                        false;
                                                  }
                                                  if (selectedUploadedFiles
                                                              .length ==
                                                          selectedMedia
                                                              .length &&
                                                      downloadUrls.length ==
                                                          selectedMedia
                                                              .length) {
                                                    safeSetState(() {
                                                      _model.uploadedLocalFile_uploadDataPhoto =
                                                          selectedUploadedFiles
                                                              .first;
                                                      _model.uploadedFileUrl_uploadDataPhoto =
                                                          downloadUrls.first;
                                                    });
                                                  } else {
                                                    safeSetState(() {});
                                                    return;
                                                  }
                                                }

                                                FFAppState().uploadedPhotoUrl =
                                                    _model
                                                        .isDataUploading_uploadDataPhoto
                                                        .toString();
                                                safeSetState(() {});
                                              },
                                              child: Container(
                                                width: 252.3,
                                                height: 73.4,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          18.0),
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'khfq0k8k' /* Inserrez une image */,
                                                      ),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font: GoogleFonts
                                                                    .plusJakartaSans(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                    ),
                                                    Icon(
                                                      Icons.add,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      size: 30.0,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if ((FFAppState()
                                                            .uploadedPhotoUrl !=
                                                        null &&
                                                    FFAppState()
                                                            .uploadedPhotoUrl !=
                                                        '') &&
                                                responsiveVisibility(
                                                  context: context,
                                                  phone: false,
                                                  tablet: false,
                                                ))
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      'kxikq5kl' /* Une image a été téléchargée. */,
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
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
                                                  InkWell(
                                                    splashColor:
                                                        Colors.transparent,
                                                    focusColor:
                                                        Colors.transparent,
                                                    hoverColor:
                                                        Colors.transparent,
                                                    highlightColor:
                                                        Colors.transparent,
                                                    onTap: () async {
                                                      safeSetState(() {
                                                        _model.isDataUploading_uploadDataPhoto =
                                                            false;
                                                        _model.uploadedLocalFile_uploadDataPhoto =
                                                            FFUploadedFile(
                                                                bytes: Uint8List
                                                                    .fromList(
                                                                        []),
                                                                originalFilename:
                                                                    '');
                                                        _model.uploadedFileUrl_uploadDataPhoto =
                                                            '';
                                                      });

                                                      FFAppState()
                                                          .uploadedPhotoUrl = '';
                                                      safeSetState(() {});
                                                    },
                                                    child: Icon(
                                                      Icons.close,
                                                      color: Color(0xFFE91A1A),
                                                      size: 20.0,
                                                    ),
                                                  ),
                                                ].divide(SizedBox(width: 10.0)),
                                              ),
                                          ].divide(SizedBox(width: 20.0)),
                                        ),
                                        if ((FFAppState().uploadedPhotoUrl !=
                                                    null &&
                                                FFAppState().uploadedPhotoUrl !=
                                                    '') &&
                                            responsiveVisibility(
                                              context: context,
                                              tabletLandscape: false,
                                              desktop: false,
                                            ))
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'dv5wcqrk' /* Une image a été téléchargé. */,
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
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
                                              InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: () async {
                                                  safeSetState(() {
                                                    _model.isDataUploading_uploadDataPhoto =
                                                        false;
                                                    _model.uploadedLocalFile_uploadDataPhoto =
                                                        FFUploadedFile(
                                                            bytes: Uint8List
                                                                .fromList([]),
                                                            originalFilename:
                                                                '');
                                                    _model.uploadedFileUrl_uploadDataPhoto =
                                                        '';
                                                  });

                                                  FFAppState()
                                                      .uploadedPhotoUrl = '';
                                                  safeSetState(() {});
                                                },
                                                child: Icon(
                                                  Icons.close,
                                                  color: Color(0xFFE91A1A),
                                                  size: 20.0,
                                                ),
                                              ),
                                            ].divide(SizedBox(width: 10.0)),
                                          ),
                                        // The bordereau gate. Until a slip
                                        // is attached this says so; once one
                                        // is, it shows what we read off it or
                                        // why it will not do. "Envoyer" stays
                                        // disabled the whole time it objects.
                                        if (_model.uploadedFileUrl_uploadDataBordereau
                                                .isEmpty &&
                                            !_model
                                                .isDataUploading_uploadDataBordereau)
                                          BordereauMissingHint(
                                            uploadFailed: _model
                                                    .uploadedLocalFile_uploadDataBordereau
                                                    .bytes
                                                    ?.isNotEmpty ??
                                                false,
                                          )
                                        else
                                          BordereauReviewPanel(
                                            check: _check,
                                            onRetry: _slipBytes == null
                                                ? null
                                                : () => unawaited(
                                                      _runBordereauCheck(
                                                        _slipBytes!,
                                                        _slipFilename,
                                                      ),
                                                    ),
                                          ),
                                        if (_missingRequiredFields(context)
                                            .isNotEmpty)
                                          MissingFieldsHint(
                                            labels: _missingRequiredFields(
                                                context),
                                          ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 30.0, 0.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(12.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                            'gfduvzpb' /* Informations sur le devis */,
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodySmall
                                                              .override(
                                                                font: GoogleFonts
                                                                    .plusJakartaSans(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
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
                                                              'f03mu0av' /* Nous étudierons votre demande ... */,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodySmall
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .plusJakartaSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.4,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 50.0),
                                          child: FFButtonWidget(
                                            // Disabled until there is a
                                            // bordereau in storage that the
                                            // check did not reject — see
                                            // [_canSubmit]. The panel above
                                            // says which of those is missing,
                                            // so a dead button is never
                                            // unexplained.
                                            onPressed: !_canSubmit
                                                    ? null
                                                    : () async {
                                                        // The express-card bordereau
                                                        // may still be in flight; wait
                                                        // for it before submitting.
                                                        await _draftBordereauUpload;

                                                        await _submitQuote();
                                                      },
                                            text: FFLocalizations.of(context)
                                                .getText(
                                              '21hyovyr' /* Envoyer */,
                                            ),
                                            options: FFButtonOptions(
                                              width: 300.0,
                                              height: 56.0,
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      32.0, 0.0, 32.0, 0.0),
                                              iconPadding: EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 0.0, 0.0, 0.0),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              // Without these two,
                                              // `FFButtonWidget` paints
                                              // `color` in every state — a
                                              // disabled button that still
                                              // looks like a live CTA, which
                                              // reads as a broken page rather
                                              // than as a form to finish.
                                              disabledColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondary,
                                              disabledTextColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              textStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .override(
                                                        font: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontStyle,
                                                        ),
                                                        color: Colors.white,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleMedium
                                                                .fontStyle,
                                                      ),
                                              elevation: 2.0,
                                              borderSide: BorderSide(
                                                color: Colors.transparent,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                            ),
                                          ),
                                        ),
                                      ].divide(SizedBox(height: 24.0)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1500.0,
                  height: 11.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
