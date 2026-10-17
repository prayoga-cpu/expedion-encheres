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
  Map<String, dynamic> _photos = const {'pickup': [], 'delivery': []};
  bool _loading = true;
  String? _errorCode;

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
      ExpedionApi.listShipmentPhotos(widget.quoteId),
    ]);
    if (!mounted) return;

    final quoteResult = results[0];
    final eventsResult = results[1];
    final photosResult = results[2];

    setState(() {
      _loading = false;
      if (!quoteResult.success) {
        _errorCode = quoteResult.code;
        return;
      }
      _errorCode = null;
      _quote = quoteResult.map;
      _events = eventsResult.success ? eventsResult.list : const [];
      // A photo listing that fails is a missing section, never a failed
      // screen: the tracking itself is what the client came for.
      _photos = photosResult.success
          ? photosResult.map
          : const {'pickup': [], 'delivery': []};
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

    if (_errorCode != null) {
      return DSEmptyState(
        icon: Icons.error_outline_rounded,
        title: xpdT(context, 'Suivi indisponible', 'Tracking unavailable'),
        description: xpdApiErrorMessage(
          context,
          _errorCode,
          fallbackFr: 'Suivi temporairement indisponible.',
          fallbackEn: 'Tracking temporarily unavailable.',
        ),
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
          if (_askedMilestone != null) ...[
            _confirmationCard(theme, _askedMilestone!),
            const SizedBox(height: DSSize.sectionGap),
          ],
          if (escalated) ...[
            _escalationNotice(theme),
            const SizedBox(height: DSSize.sectionGap),
          ],
          _PhotoSection(
            title: xpdT(context, 'Photos au retrait', 'Photos at pickup'),
            photos: _photos['pickup'] as List<dynamic>? ?? const [],
            emptyLabel: xpdT(
              context,
              "Aucune photo au retrait pour l'instant.",
              'No pickup photos yet.',
            ),
          ),
          const SizedBox(height: DSSize.sectionGap),
          _PhotoSection(
            title: xpdT(context, 'Photos à la livraison', 'Photos at delivery'),
            photos: _photos['delivery'] as List<dynamic>? ?? const [],
            emptyLabel: xpdT(
              context,
              "Aucune photo à la livraison pour l'instant.",
              'No delivery photos yet.',
            ),
          ),
          const SizedBox(height: DSSize.sectionGap),
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

  /// Which milestone the client is being asked to attest, if any.
  ///
  /// Driven by the quote's own stage rather than a separate call: `picked_up`
  /// means the transporter says they collected, `delivered` that they
  /// delivered. Any earlier stage has nothing the client has witnessed, and
  /// asking would put a question on screen nobody can answer.
  String? get _askedMilestone {
    switch ((_quote?['status'] ?? '').toString()) {
      case 'picked_up':
        return 'PICKED_UP';
      case 'delivered':
        return 'DELIVERED';
      default:
        return null;
    }
  }

  /// Whether the client has already answered, read off the shared feed.
  ///
  /// The confirmation is mirrored onto this timeline when it is recorded, from
  /// whichever channel it arrived on — so a client who tapped the link in
  /// their SMS does not get asked again here.
  bool _isConfirmed(String milestone) => _events.any((event) {
        final row = event as Map<String, dynamic>;
        final metadata = row['metadata'];
        // Keyed on the milestone alone, not on `actor`: an operator who
        // answered for a client who could not writes `actor: 'admin'`, and
        // the question is settled either way. Asking again would offer a
        // button the server can only answer with "already confirmed".
        return metadata is Map &&
            metadata['confirmedMilestone'] == milestone;
      });

  /// Whether the recorded answer came from an operator rather than the client.
  bool _confirmedByOperator(String milestone) => _events.any((event) {
        final metadata = (event as Map<String, dynamic>)['metadata'];
        return metadata is Map &&
            metadata['confirmedMilestone'] == milestone &&
            metadata['confirmedBy'] == 'operator';
      });

  Future<void> _confirm(String milestone) async {
    final result =
        await ExpedionApi.confirmMilestone(widget.quoteId, milestone);
    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            xpdApiErrorMessage(
              context,
              result.code,
              fallbackFr: "La confirmation n'a pas pu être enregistrée.",
              fallbackEn: 'The confirmation could not be saved.',
            ),
          ),
        ),
      );
      return;
    }

    // Reload rather than patching local state: the confirmation comes back on
    // the shared feed, which is what `_isConfirmed` reads.
    await _load();
  }

  /// Asks the client to confirm what the transporter has recorded — or tells
  /// them it is already done.
  ///
  /// Confirming commits nothing. It cannot move the transport, release a
  /// payment or close the quote, and the copy says so, because a client who
  /// thinks a button might charge them will not press it.
  Widget _confirmationCard(FlutterFlowTheme theme, String milestone) {
    final confirmed = _isConfirmed(milestone);
    final isPickup = milestone == 'PICKED_UP';
    final status = confirmed ? DSStatus.success : DSStatus.info;

    return Container(
      padding: const EdgeInsets.all(DSSize.cardPadding),
      decoration: BoxDecoration(
        color: status.background(context),
        borderRadius: BorderRadius.circular(DSShape.card),
        border: Border.all(
          color: status.border(context),
          width: DSShape.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                confirmed
                    ? Icons.verified_rounded
                    : Icons.help_outline_rounded,
                size: 20.0,
                color: theme.primary,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      confirmed
                          ? xpdT(context, 'Merci, c’est confirmé',
                              'Thank you, that’s confirmed')
                          : isPickup
                              ? xpdT(context, 'Confirmez le retrait',
                                  'Confirm the pickup')
                              : xpdT(context, 'Confirmez la réception',
                                  'Confirm delivery'),
                      style: theme.labelMedium.copyWith(
                        color: theme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      confirmed
                          ? (_confirmedByOperator(milestone)
                              ? xpdT(
                                  context,
                                  'Un opérateur a confirmé cette étape pour '
                                  'votre compte.',
                                  'An operator confirmed this step on your '
                                  'behalf.',
                                )
                              : xpdT(
                                  context,
                                  'Votre confirmation a bien été enregistrée.',
                                  'Your confirmation has been saved.',
                                ))
                          : isPickup
                              ? xpdT(
                                  context,
                                  'Le transporteur nous indique avoir effectué '
                                  'le retrait. Confirmez-le pour que les deux '
                                  'parties soient d’accord sur ce qui s’est '
                                  'passé.',
                                  'The transporter has recorded collecting '
                                  'your goods. Confirm it so both parties '
                                  'agree on what happened.',
                                )
                              : xpdT(
                                  context,
                                  'Le transporteur nous indique avoir livré '
                                  'votre lot. Confirmez la bonne réception '
                                  'pour clôturer le transport.',
                                  'The transporter has recorded delivering '
                                  'your goods. Confirm receipt to close the '
                                  'shipment.',
                                ),
                      style: theme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!confirmed) ...[
            const SizedBox(height: 12.0),
            DSButton(
              label: isPickup
                  ? xpdT(context, 'Oui, le retrait a bien eu lieu',
                      'Yes, the pickup happened')
                  : xpdT(context, 'Oui, j’ai bien reçu mon lot',
                      'Yes, I received my goods'),
              icon: Icons.check_circle_outline_rounded,
              expand: true,
              onPressed: () => _confirm(milestone),
            ),
            const SizedBox(height: 8.0),
            Text(
              xpdT(
                context,
                'Confirmer n’engage aucun paiement et ne modifie pas votre '
                'transport.',
                'Confirming commits no payment and does not change your '
                'shipment.',
              ),
              style: theme.labelSmall,
            ),
          ],
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
/// One stage's photos, as the client reads them.
///
/// Rendered even when empty, deliberately: someone looking for pickup photos
/// on a job that has not been collected should learn that from the screen
/// rather than wonder whether the section failed to load.
///
/// Every thumbnail carries its time and place as text underneath as well as
/// burned into the pixels. The burn-in is what survives a screenshot forwarded
/// to an insurer; the text is what stays readable if the server that stamped
/// it had no fonts (expeditoo-ship docs/specs/shipment_photos_spec.md §5.4).
class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.title,
    required this.photos,
    required this.emptyLabel,
  });

  final String title;
  final List<dynamic> photos;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: theme.titleMedium),
        const SizedBox(height: 12.0),
        if (photos.isEmpty)
          Text(
            emptyLabel,
            style: theme.bodySmall.copyWith(color: theme.secondaryText),
          )
        else
          DSCard(
            padding: const EdgeInsets.all(DSSize.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final photo in photos)
                  _PhotoTile(photo: photo as Map<String, dynamic>),
              ],
            ),
          ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo});

  final Map<String, dynamic> photo;

  /// The server's clock, not the device's — the one number in this record that
  /// the person holding the camera does not control.
  String get _when {
    final recorded = DateTime.tryParse('${photo['recordedAt']}')?.toLocal();
    if (recorded == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(recorded.day)}/${two(recorded.month)}/${recorded.year} '
        '${two(recorded.hour)}:${two(recorded.minute)}';
  }

  String get _coordinates {
    final lat = (photo['capturedLat'] as num?)?.toStringAsFixed(5);
    final lng = (photo['capturedLng'] as num?)?.toStringAsFixed(5);
    if (lat == null || lng == null) return '';
    final accuracy = (photo['capturedAccuracyM'] as num?)?.round();
    return accuracy == null ? '$lat, $lng' : '$lat, $lng · ±$accuracy m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final address = (photo['capturedAddress'] as String?)?.trim();
    final url = ExpedionApi.photoUrl('${photo['url']}');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DSShape.control),
            child: Image.network(
              url,
              // The object has no public URL: this path authorises the reader
              // and only then redirects, so an anonymous request gets a 401.
              headers: ExpedionApi.photoHeaders,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, _, __) => Container(
                height: 120.0,
                alignment: Alignment.center,
                color: theme.alternate,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: theme.secondaryText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6.0),
          if (_when.isNotEmpty)
            Text(
              _when,
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            ),
          if (address != null && address.isNotEmpty)
            Text(
              address,
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            ),
          if (_coordinates.isNotEmpty)
            Text(
              _coordinates,
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            ),
        ],
      ),
    );
  }
}

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
