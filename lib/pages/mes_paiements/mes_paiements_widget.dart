import '/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/backend/expedion_api/expedion_quote.dart';
import '/backend/expedion_api/quote_repository.dart';
import '/design_system/ds_app_shell.dart';
import '/design_system/ds_l10n.dart';
import '/design_system/ds_palette.dart';
import '/design_system/ds_site.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'mes_paiements_model.dart';
export 'mes_paiements_model.dart';

/// "Mes paiements".
///
/// The previous version of this page fetched nothing: the headline figure,
/// the transaction count and the "+15.2%" trend were literal strings baked in
/// by the page builder, and "Recent Payments" had no list under it at all. So
/// it showed $2,847.50 to every client, including one with no quotes.
///
/// Every figure here is now derived from the client's own paid quotes.
class MesPaiementsWidget extends StatefulWidget {
  const MesPaiementsWidget({super.key});

  static String routeName = 'MesPaiements';
  static String routePath = '/mesPaiements';

  @override
  State<MesPaiementsWidget> createState() => _MesPaiementsWidgetState();
}

class _MesPaiementsWidgetState extends State<MesPaiementsWidget> {
  late MesPaiementsModel _model;
  late Future<QuoteListResult> _quotes;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MesPaiementsModel());
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

  void _reload() => setState(() => _quotes = QuoteRepository.list());

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final palette = XpdPalette.of(context);
    final gutter = XpdLayout.gutterFor(MediaQuery.sizeOf(context).width);

    return XpdPage(
      current: XpdDestination.payments,
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _quotes;
        },
        child: FutureBuilder<QuoteListResult>(
          future: _quotes,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final result = snapshot.data;
            final paid = <ExpedionQuote>[
              for (final quote in result?.quotes ?? const <ExpedionQuote>[])
                if (quote.isPaid) quote,
            ]..sort((a, b) {
                final left = a.requestedAt ?? a.createdAt;
                final right = b.requestedAt ?? b.createdAt;
                if (left == null || right == null) return 0;
                return right.compareTo(left);
              });

            final totalCents = paid.fold<int>(
              0,
              (sum, quote) => sum + (quote.effectivePriceCents ?? 0),
            );

            return ListView(
              padding: const EdgeInsets.only(bottom: 40.0),
              children: [
                XpdPageHeader(
                  title: _t('Mes paiements', 'My payments'),
                  subtitle: _t(
                    'Vos règlements et vos factures',
                    'Your payments and invoices',
                  ),
                ),
                const SizedBox(height: 20.0),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: _summary(palette, totalCents, paid.length, loading),
                ),
                const SizedBox(height: 28.0),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: Text(
                    _t('Paiements récents', 'Recent payments'),
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: palette.text,
                    ),
                  ),
                ),
                const SizedBox(height: 14.0),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (result == null || !result.succeeded)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: _message(
                      palette,
                      icon: (result?.needsSignIn ?? false)
                          ? Icons.lock_outline_rounded
                          : Icons.cloud_off_rounded,
                      title: (result?.needsSignIn ?? false)
                          ? _t('Connectez-vous', 'Sign in')
                          : _t('Chargement impossible', 'Could not load'),
                      // `result.message` is whatever language the failure
                      // happened to speak — hardcoded French from the data
                      // layer, or the server's own words — and it is non-null
                      // on every failure, so it always won over the translated
                      // fallback below. Localize the code instead.
                      body: xpdApiErrorMessage(
                        context,
                        result?.code,
                        fallbackFr:
                            'Vos paiements sont temporairement indisponibles.',
                        fallbackEn:
                            'Your payments are temporarily unavailable.',
                      ),
                    ),
                  )
                else if (paid.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: _message(
                      palette,
                      icon: Icons.receipt_long_outlined,
                      title: _t('Aucun paiement', 'No payments yet'),
                      body: _t(
                        "Vos règlements apparaîtront ici dès qu'un devis sera payé.",
                        'Your payments will appear here once a quote is paid.',
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: Column(
                      children: [
                        for (final quote in paid)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _paymentRow(palette, quote),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The headline card.
  ///
  /// Deliberately "Total payé", not "this month": `expedion_quotes` records no
  /// paid-at timestamp, only `requestedAt`, so a monthly figure could only be
  /// bucketed by when the quote was *asked for*, which is not when it was paid.
  /// An all-time total is a number this data can actually support. Add a
  /// `paid_at` column and this becomes a monthly total honestly.
  Widget _summary(
    XpdPalette palette,
    int totalCents,
    int count,
    bool loading,
  ) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 26.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF3D7BFF), XpdPalette.blue],
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t('Total payé', 'Total paid'),
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15.0,
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
            const SizedBox(height: 6.0),
            if (loading)
              const SizedBox(
                height: 34.0,
                width: 34.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Text(
                formatCents(totalCents),
                style: const TextStyle(
                  fontFamily: 'Geist Mono',
                  fontSize: 34.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            const SizedBox(height: 8.0),
            Text(
              count == 1
                  ? _t('1 transaction', '1 transaction')
                  : _t('$count transactions', '$count transactions'),
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14.0,
                color: Colors.white.withValues(alpha: 0.80),
              ),
            ),
          ],
        ),
      );

  Widget _paymentRow(XpdPalette palette, ExpedionQuote quote) {
    final date = quote.requestedAt ?? quote.createdAt;
    final subtitle = [
      if (quote.auctionHouseName.isNotEmpty) quote.auctionHouseName,
      if (quote.deliveryCity.isNotEmpty) quote.deliveryCity,
      if (date != null) dateTimeFormat('d MMM y', date),
    ].join(' · ');

    return XpdPanel(
      radius: 16.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      child: Row(
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: palette.greenBg,
              borderRadius: BorderRadius.circular(11.0),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 20.0,
              color: palette.green,
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quote.reference,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: palette.text,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3.0),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13.5,
                      color: palette.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          Text(
            formatCents(quote.effectivePriceCents),
            style: TextStyle(
              fontFamily: 'Geist Mono',
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(
    XpdPalette palette, {
    required IconData icon,
    required String title,
    required String body,
  }) =>
      XpdPanel(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 28.0),
        child: Column(
          children: [
            Icon(icon, color: palette.muted, size: 30.0),
            const SizedBox(height: 18.0),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 19.0,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15.0,
                height: 1.55,
                color: palette.muted,
              ),
            ),
          ],
        ),
      );
}
