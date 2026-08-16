import '/app_shell.dart';
import 'package:flutter/material.dart';

import '/backend/expedion_api/expedion_api.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// **Suivi de livraison** — the delivery tracking screen.
///
/// Reads the shared status feed that both apps append to, so a job escalated
/// to Expeditoo shows its selected carrier and live status here without the
/// client ever leaving Expedion (ROADMAP.md §8 Phase D).
///
/// The gardiennage countdown sits at the top whenever the auction house has a
/// storage deadline on file, because that is the thing the client actually
/// needs to act on.
class SuiviDeLivraisonWidget extends StatefulWidget {
  const SuiviDeLivraisonWidget({super.key, required this.quoteId});

  static const String routeName = 'SuiviDeLivraison';
  static const String routePath = '/suiviDeLivraison';

  final String quoteId;

  @override
  State<SuiviDeLivraisonWidget> createState() => _SuiviDeLivraisonWidgetState();
}

class _SuiviDeLivraisonWidgetState extends State<SuiviDeLivraisonWidget> {
  Map<String, dynamic>? _quote;
  List<dynamic> _events = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // One round trip each; the feed is small and the quote is the source of
    // truth for the countdown, so both are always fetched together.
    final results = await Future.wait([
      ExpedionApi.getQuote(widget.quoteId),
      ExpedionApi.listEvents(widget.quoteId),
    ]);
    if (!mounted) return;

    final quoteResult = results[0];
    final eventsResult = results[1];

    setState(() {
      _loading = false;
      if (!quoteResult.success) {
        _error = quoteResult.message;
        return;
      }
      _error = null;
      _quote = quoteResult.map;
      _events = eventsResult.success ? eventsResult.list : const [];
    });
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return XpdPage(
      current: XpdDestination.quotes,
      onBack: () => context.safePop(),
      body: SafeArea(child: _body(theme)),
    );
  }

  Widget _body(FlutterFlowTheme theme) {
    if (_loading) {
      return DSPageLoader(
        message: xpdT(context, 'Chargement du suivi…', 'Loading tracking…'),
      );
    }

    if (_error != null) {
      return DSEmptyState(
        icon: Icons.error_outline_rounded,
        title: xpdT(context, 'Suivi indisponible', 'Tracking unavailable'),
        description: _error,
        variant: DSEmptyStateVariant.page,
        action: DSButton(
          label: xpdT(context, 'Réessayer', 'Try again'),
          icon: Icons.refresh_rounded,
          onPressed: () {
            setState(() => _loading = true);
            return _load();
          },
        ),
      );
    }

    final quote = _quote ?? const {};
    final devis = DevisSummary.fromExpedionApi(quote);
    final storageFreeUntil = _parseDate(quote['storageFreeUntil']);
    final escalated = quote['listingId'] != null;

    return RefreshIndicator(
      onRefresh: _load,
      color: theme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
        children: [
          if (storageFreeUntil != null) ...[
            DSStorageCountdown(
              freeUntil: storageFreeUntil,
              dailyFeeCents: (quote['storageDailyFeeCents'] as num?)?.toInt(),
            ),
            const SizedBox(height: DSSize.sectionGap),
          ],
          DSQuoteCard(devis: devis),
          const SizedBox(height: DSSize.sectionGap),
          if (escalated) ...[
            _escalationNotice(theme),
            const SizedBox(height: DSSize.sectionGap),
          ],
          Text(xpdT(context, 'Historique', 'History'),
              style: theme.titleMedium),
          const SizedBox(height: 12.0),
          if (_events.isEmpty)
            DSEmptyState(
              icon: Icons.history_rounded,
              title: xpdT(context, 'Aucun événement', 'No events yet'),
              description: xpdT(
                context,
                'Le suivi apparaîtra ici dès que votre transport avancera.',
                'Tracking will appear here as soon as your shipment moves.',
              ),
            )
          else
            DSCard(
              padding: const EdgeInsets.all(DSSize.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _events.length; i++)
                    _EventRow(
                      event: _events[i] as Map<String, dynamic>,
                      isFirst: i == 0,
                      isLast: i == _events.length - 1,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Escalated jobs are on the Expeditoo marketplace; say so plainly rather
  /// than leaving the client wondering why the status changed.
  Widget _escalationNotice(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(DSSize.cardPadding),
      decoration: BoxDecoration(
        color: DSStatus.info.background(context),
        borderRadius: BorderRadius.circular(DSShape.card),
        border: Border.all(
          color: DSStatus.info.border(context),
          width: DSShape.borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gavel_rounded, size: 20.0, color: theme.primary),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  xpdT(context, 'Mise en concurrence', 'Out to tender'),
                  style: theme.labelMedium.copyWith(
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  xpdT(
                    context,
                    'Votre transport est proposé à notre réseau de '
                    'transporteurs. Vous serez notifié dès qu’un transporteur '
                    'est retenu.',
                    'Your shipment has been offered to our carrier network. '
                    'You will be notified as soon as a carrier takes it on.',
                  ),
                  style: theme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One entry in the shared status feed, drawn as a timeline row.
class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  final Map<String, dynamic> event;
  final bool isFirst;
  final bool isLast;

  /// Who appended the event. The keys are the server's `actor` values; the
  /// two brand names are the same in both languages, so only three translate.
  static String _actorLabel(BuildContext context, String? actor) {
    switch (actor) {
      case 'client':
        return xpdT(context, 'Vous', 'You');
      case 'admin':
        return 'Expedion';
      case 'driver':
        return xpdT(context, 'Transporteur', 'Carrier');
      case 'expeditoo':
        return 'Expeditoo';
      default:
        return xpdT(context, 'Automatique', 'Automatic');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final stage = DevisSummary.stageFromApiStatus(
      event['status']?.toString() ?? '',
    );
    final createdAt = DateTime.tryParse(event['createdAt']?.toString() ?? '');
    final colour = isFirst ? stage.status.foreground(context) : theme.alternate;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail.
          Column(
            children: [
              Container(
                width: 12.0,
                height: 12.0,
                margin: const EdgeInsets.only(top: 4.0),
                decoration: BoxDecoration(
                  color: isFirst
                      ? stage.status.foreground(context)
                      : theme.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colour, width: 2.0),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2.0, color: theme.alternate),
                ),
            ],
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stage.labelFor(context),
                          style: theme.labelMedium.copyWith(
                            color: theme.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          _formatDateTime(createdAt),
                          style: theme.monoSmall,
                        ),
                    ],
                  ),
                  if (event['message'] != null) ...[
                    const SizedBox(height: 2.0),
                    Text(event['message'].toString(), style: theme.labelSmall),
                  ],
                  const SizedBox(height: 2.0),
                  Text(
                    _actorLabel(context, event['actor']?.toString()),
                    style: theme.labelSmall.copyWith(fontSize: 11.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime d) {
    final local = d.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} ${two(local.hour)}:'
        '${two(local.minute)}';
  }
}
