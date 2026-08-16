import '/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/backend/expedion_api/expedion_quote.dart';
import '/backend/expedion_api/quote_repository.dart';
import '/backend/quote_draft.dart';
import '/design_system/ds_app_shell.dart';
import '/design_system/ds_button.dart';
import '/design_system/ds_palette.dart';
import '/design_system/ds_quote_card.dart';
import '/design_system/ds_site.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'mes_devis_model.dart';
export 'mes_devis_model.dart';

/// "Mes devis" — the client's quotes.
///
/// Rebuilt on [QuoteRepository], so every figure on this page comes from the
/// Expeditoo database. The previous version made four separate Airtable
/// requests — one for the list, one each for the "validés" and "payés"
/// counters, one for the search — which could and did disagree with each other.
/// Now one request feeds the list and the counters, so they cannot.
class MesDevisWidget extends StatefulWidget {
  const MesDevisWidget({super.key});

  // Route names are the app's navigation identity: the payment-result pages
  // reach this screen with `context.goNamed('MES-DEVIS')`, so this string is
  // load-bearing and must not be tidied.
  static String routeName = 'MES-DEVIS';
  static String routePath = '/mesDevis';

  @override
  State<MesDevisWidget> createState() => _MesDevisWidgetState();
}

class _MesDevisWidgetState extends State<MesDevisWidget> {
  late MesDevisModel _model;

  /// The current load. Held rather than re-created in `build` so a rebuild
  /// (theme flip, language switch, keystroke) does not re-fetch.
  late Future<QuoteListResult> _quotes;

  String _search = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MesDevisModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _quotes = QuoteRepository.list();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  bool get _isEnglish =>
      FFLocalizations.of(context).languageCode.startsWith('en');

  String _t(String fr, String en) => _isEnglish ? en : fr;

  void _reload() {
    setState(() {
      _quotes = QuoteRepository.list(
        bordereauNumber: _search.isEmpty ? null : _search,
      );
    });
  }

  void _runSearch() {
    _search = _model.textController.text.trim();
    _reload();
  }

  /// Starts a new devis.
  ///
  /// The old button only made the 28px "+" glyph tappable, so pressing the card
  /// around it did nothing — which is what "nothing happens" was. The whole
  /// tile is the target now, and the draft is cleared first so a stale one from
  /// the landing page cannot prefill an unrelated request.
  void _newQuote() {
    QuoteDraft.clear();
    context.pushNamed(FormulaireDeDevisParBordereauWidget.routeName);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final palette = XpdPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = XpdLayout.gutterFor(width);

    return XpdPage(
      current: XpdDestination.quotes,
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _quotes;
        },
        child: FutureBuilder<QuoteListResult>(
          future: _quotes,
          builder: (context, snapshot) {
            final result = snapshot.data;
            final loading = snapshot.connectionState == ConnectionState.waiting;

            return ListView(
              padding: const EdgeInsets.only(bottom: 40.0),
              children: [
                XpdPageHeader(
                  title: _t('Mes devis', 'My quotes'),
                  subtitle: _t(
                    'Aperçu de vos demandes',
                    'Preview of your quotes',
                  ),
                  action: XpdButton(
                    label: _t('Nouveau bordereau', 'New slip'),
                    // The banner behind it is solid brand blue.
                    variant: XpdButtonVariant.inverse,
                    fontSize: 14.5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18.0,
                      vertical: 11.0,
                    ),
                    onPressed: _newQuote,
                  ),
                ),
                const SizedBox(height: 20.0),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: _counters(result, loading),
                ),
                const SizedBox(height: 20.0),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: _searchBar(palette),
                ),
                const SizedBox(height: 24.0),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (result == null || !result.succeeded)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: _failure(palette, result),
                  )
                else if (result.quotes.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: _empty(palette),
                  )
                else
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: _list(result),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Total / validés / payés, all read off the same fetch as the list below.
  Widget _counters(QuoteListResult? result, bool loading) {
    final palette = XpdPalette.of(context);
    final quotes = result?.quotes ?? const <ExpedionQuote>[];
    final validated = quotes.where((q) => q.isAccepted).length;
    final paid = quotes.where((q) => q.isPaid).length;
    final total = result?.total ?? quotes.length;

    return Row(
      children: [
        Expanded(
          child: XpdStatTile(
            value: '$total',
            label: _t('Total', 'Total'),
            valueColor: XpdPalette.blue,
            loading: loading,
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: XpdStatTile(
            value: '$validated',
            label: _t('Validés', 'Validated'),
            valueColor: palette.green,
            loading: loading,
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: XpdStatTile(
            value: '$paid',
            label: _t('Payés', 'Paid'),
            valueColor: palette.green,
            loading: loading,
          ),
        ),
      ],
    );
  }

  Widget _searchBar(XpdPalette palette) => Container(
        decoration: BoxDecoration(
          color: palette.chip,
          border: Border.all(color: palette.line),
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 20.0, color: palette.muted),
            const SizedBox(width: 12.0),
            Expanded(
              child: TextField(
                controller: _model.textController,
                focusNode: _model.textFieldFocusNode,
                onSubmitted: (_) => _runSearch(),
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15.0,
                  color: palette.text,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  // The app's InputDecorationTheme fills every field with
                  // `accent1`, which painted a second, paler rectangle inside
                  // this bar's `chip` background. The container owns the fill.
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                  hintText: _t(
                    'Rechercher par numéro de bordereau…',
                    'Search by slip number…',
                  ),
                  hintStyle: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15.0,
                    color: palette.faint,
                  ),
                ),
              ),
            ),
            if (_search.isNotEmpty)
              IconButton(
                tooltip: _t('Effacer', 'Clear'),
                icon:
                    Icon(Icons.close_rounded, size: 18.0, color: palette.muted),
                onPressed: () {
                  _model.textController?.clear();
                  _search = '';
                  _reload();
                },
              ),
            XpdLink(
              label: _t('Rechercher', 'Search'),
              fontSize: 14.5,
              onTap: _runSearch,
            ),
          ],
        ),
      );

  Widget _list(QuoteListResult result) => Column(
        children: [
          for (final quote in result.quotes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: DSQuoteCard(
                devis: DevisSummary.fromExpedionApi(quote.raw),
                onTap: () => _openQuote(quote),
                action: _actionFor(quote),
              ),
            ),
        ],
      );

  /// Opens the validation screen, which is also where payment happens.
  ///
  /// Its route still takes the two tariffs alongside the id — a leftover of the
  /// Airtable shape, where the screen had no way to fetch them itself. They are
  /// passed in cents from the quote so the page shows the same figures as the
  /// card the client just pressed.
  void _openValidation(ExpedionQuote quote, {required bool alreadyAccepted}) {
    context.pushNamed(
      PageValidationDevisWidget.routeName,
      queryParameters: {
        'quoteID': serializeParam(quote.id, ParamType.String),
        if (quote.quoteStandardCents != null)
          'tarifAssSTD':
              serializeParam(quote.quoteStandardCents, ParamType.int),
        if (quote.quoteInsuredCents != null)
          'tarifAssADV': serializeParam(quote.quoteInsuredCents, ParamType.int),
        if (quote.acceptedKind.isNotEmpty)
          'typeDevisChoisi':
              serializeParam(quote.acceptedKind, ParamType.String),
        'devisValideOuPas':
            serializeParam(alreadyAccepted ? 'valide' : '', ParamType.String),
      }.withoutNulls,
    );
  }

  /// What the client can do next with this quote.
  Widget? _actionFor(ExpedionQuote quote) {
    // A price is published and not yet accepted — the one action that matters.
    if (quote.quoteAvailable && !quote.isAccepted) {
      return DSButton(
        label: _t('Valider le devis', 'Accept quote'),
        icon: Icons.check_rounded,
        expand: true,
        onPressed: () => _openValidation(quote, alreadyAccepted: false),
      );
    }
    if (quote.isAccepted && !quote.isPaid) {
      return DSButton(
        label: _t('Payer', 'Pay'),
        icon: Icons.credit_card_rounded,
        expand: true,
        onPressed: () => _openValidation(quote, alreadyAccepted: true),
      );
    }
    if (quote.isPaid) {
      return DSButton(
        label: _t('Suivre la livraison', 'Track delivery'),
        variant: DSButtonVariant.outline,
        icon: Icons.local_shipping_outlined,
        expand: true,
        onPressed: () => context.pushNamed(
          SuiviDeLivraisonWidget.routeName,
          queryParameters: {
            'quoteId': serializeParam(quote.id, ParamType.String),
          }.withoutNulls,
        ),
      );
    }
    // Still pending: priced by an admin or by auto-pricing, nothing to press.
    return null;
  }

  /// Tapping the card itself goes wherever the quote currently *is*.
  ///
  /// `DetailsDevisWidget` is deliberately not a target: its route still takes
  /// twenty-five flat Airtable fields rather than an id, so reaching it from
  /// here would mean reconstructing a record shape this page no longer holds.
  void _openQuote(ExpedionQuote quote) {
    final quoteId = {
      'quoteId': serializeParam(quote.id, ParamType.String),
    }.withoutNulls;

    if (quote.status == 'awaiting_confirmation') {
      context.pushNamed(
        ConfirmerLesDetailsWidget.routeName,
        queryParameters: quoteId,
      );
      return;
    }
    if (quote.isPaid) {
      context.pushNamed(
        SuiviDeLivraisonWidget.routeName,
        queryParameters: quoteId,
      );
      return;
    }
    if (quote.quoteAvailable) {
      _openValidation(quote, alreadyAccepted: quote.isAccepted);
    }
  }

  Widget _empty(XpdPalette palette) => XpdPanel(
        padding: const EdgeInsets.symmetric(vertical: 56.0, horizontal: 28.0),
        child: Column(
          children: [
            Container(
              width: 64.0,
              height: 64.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.chip,
                border: Border.all(color: palette.line),
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: palette.muted,
                size: 28.0,
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              _search.isEmpty
                  ? _t('Aucun devis disponible', 'No quotes yet')
                  : _t('Aucun résultat', 'No results'),
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 19.0,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              _search.isEmpty
                  ? _t(
                      "Vous n'avez pas encore demandé de devis. Faites votre première demande pour commencer.",
                      'You have not requested a quote yet. Make your first request to get started.',
                    )
                  : _t(
                      'Aucun devis ne correspond à « $_search ».',
                      'No quote matches “$_search”.',
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15.0,
                height: 1.55,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 24.0),
            XpdButton(
              label: _t('Demander un devis', 'Request a quote'),
              onPressed: _newQuote,
            ),
          ],
        ),
      );

  /// Distinguishes "sign in" from "something broke": the first needs a login,
  /// the second needs a retry, and offering the wrong one wastes the client's
  /// time.
  Widget _failure(XpdPalette palette, QuoteListResult? result) {
    final needsSignIn = result?.needsSignIn ?? false;
    return XpdPanel(
      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 28.0),
      child: Column(
        children: [
          Icon(
            needsSignIn ? Icons.lock_outline_rounded : Icons.cloud_off_rounded,
            color: palette.muted,
            size: 32.0,
          ),
          const SizedBox(height: 18.0),
          Text(
            needsSignIn
                ? _t('Connectez-vous', 'Sign in')
                : _t('Chargement impossible', 'Could not load'),
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 19.0,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            result?.message ??
                _t(
                  'Vos devis sont temporairement indisponibles.',
                  'Your quotes are temporarily unavailable.',
                ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 15.0,
              height: 1.55,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 24.0),
          XpdButton(
            label: needsSignIn
                ? _t('Se connecter', 'Sign in')
                : _t('Réessayer', 'Try again'),
            onPressed: needsSignIn
                ? () => context.pushNamed(SeConnecterWidget.routeName)
                : _reload,
          ),
        ],
      ),
    );
  }
}
