import 'package:flutter/material.dart';
import 'ds_l10n.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'ds_badge.dart';
import 'ds_card.dart';
import 'ds_tokens.dart';

/// Where a devis sits in its lifecycle.
///
/// Derived from the Airtable columns the quote list already reads, so the same
/// derivation serves the list, the tracking screen and the storage countdown
/// without each re-inventing the rules.
enum DevisStage {
  /// Submitted, no price yet.
  enAttente,

  /// Priced by an admin, waiting on the client.
  devisDisponible,

  /// Client accepted, not yet paid.
  valide,

  /// Paid, waiting on collection.
  paye,

  /// Collected from the auction house.
  retraitFait,

  /// Delivered.
  livre,

  /// No driver took it; pushed to the Expeditoo marketplace.
  escalade,
}

extension DevisStageDisplay on DevisStage {
  /// The badge caption, in the reader's language.
  ///
  /// Takes a context rather than being a plain getter because the status badge
  /// is the most visible thing on the card: it was the one part of "Mes devis"
  /// still reading "Livré" once the header had switched to English.
  String labelFor(BuildContext context) {
    switch (this) {
      case DevisStage.enAttente:
        return xpdT(context, 'En attente', 'Pending');
      case DevisStage.devisDisponible:
        return xpdT(context, 'Devis disponible', 'Quote ready');
      case DevisStage.valide:
        return xpdT(context, 'Validé', 'Accepted');
      case DevisStage.paye:
        return xpdT(context, 'Payé', 'Paid');
      case DevisStage.retraitFait:
        return xpdT(context, 'Retrait fait', 'Collected');
      case DevisStage.livre:
        return xpdT(context, 'Livré', 'Delivered');
      case DevisStage.escalade:
        return xpdT(context, 'Mise en concurrence', 'Out to tender');
    }
  }

  DSStatus get status {
    switch (this) {
      case DevisStage.enAttente:
        return DSStatus.neutral;
      case DevisStage.devisDisponible:
        return DSStatus.warning;
      case DevisStage.valide:
        return DSStatus.info;
      case DevisStage.paye:
        return DSStatus.info;
      case DevisStage.retraitFait:
        return DSStatus.info;
      case DevisStage.livre:
        return DSStatus.success;
      case DevisStage.escalade:
        return DSStatus.warning;
    }
  }

  IconData get icon {
    switch (this) {
      case DevisStage.enAttente:
        return Icons.hourglass_top_rounded;
      case DevisStage.devisDisponible:
        return Icons.request_quote_outlined;
      case DevisStage.valide:
        return Icons.check_circle_outline_rounded;
      case DevisStage.paye:
        return Icons.payments_outlined;
      case DevisStage.retraitFait:
        return Icons.inventory_2_outlined;
      case DevisStage.livre:
        return Icons.local_shipping_outlined;
      case DevisStage.escalade:
        return Icons.gavel_rounded;
    }
  }
}

/// Reads an Airtable quote record into the fields the card and the tracking
/// screen need.
class DevisSummary {
  const DevisSummary({
    required this.stage,
    this.numeroDevis,
    this.numeroBordereau,
    this.villeRetrait,
    this.villeLivraison,
    this.maisonDeVentes,
    this.description,
    this.tarif,
    this.dateDeVente,
    this.dateDemande,
    this.escalated = false,
  });

  final DevisStage stage;
  final String? numeroDevis;
  final String? numeroBordereau;
  final String? villeRetrait;
  final String? villeLivraison;
  final String? maisonDeVentes;
  final String? description;
  final String? tarif;
  final String? dateDeVente;
  final String? dateDemande;
  final bool escalated;

  /// Maps a Postgres `expedion_quote_status` onto a display stage.
  ///
  /// The API's enum is finer-grained than the card needs — `awaiting_confirmation`
  /// and `assigned` both read as "in progress" to a client — so the mapping is
  /// deliberately lossy.
  static DevisStage stageFromApiStatus(String status) {
    switch (status) {
      case 'awaiting_confirmation':
      case 'pending':
        return DevisStage.enAttente;
      case 'quoted':
        return DevisStage.devisDisponible;
      case 'accepted':
        return DevisStage.valide;
      case 'paid':
      case 'assigned':
        return DevisStage.paye;
      case 'escalated':
        return DevisStage.escalade;
      case 'picked_up':
        return DevisStage.retraitFait;
      case 'delivered':
        return DevisStage.livre;
      default:
        return DevisStage.enAttente;
    }
  }

  /// Builds a summary from the Next.js quotes API (Phase A onward).
  factory DevisSummary.fromExpedionApi(Map<String, dynamic> quote) {
    String? str(String key) {
      final value = quote[key];
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    String? euros(String key) {
      final value = quote[key];
      if (value is! num) return null;
      return (value / 100).toStringAsFixed(2).replaceAll('.', ',');
    }

    String? day(String key) {
      final parsed = DateTime.tryParse(quote[key]?.toString() ?? '');
      if (parsed == null) return null;
      final local = parsed.toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${two(local.day)}/${two(local.month)}/${local.year}';
    }

    return DevisSummary(
      stage: stageFromApiStatus(str('status') ?? ''),
      numeroDevis: str('quoteNumber'),
      numeroBordereau: str('bordereauNumber'),
      villeRetrait: str('pickupCity'),
      villeLivraison: str('deliveryCity'),
      maisonDeVentes: str('auctionHouseName'),
      description: str('description'),
      // The accepted price once chosen, otherwise the standard quote.
      tarif: euros('acceptedPriceCents') ?? euros('quoteStandardCents'),
      dateDeVente: day('saleDate'),
      dateDemande: day('requestedAt'),
      escalated: quote['listingId'] != null,
    );
  }

  /// Builds a summary from a raw Airtable record (`{"fields": {...}}`).
  factory DevisSummary.fromAirtable(dynamic record) {
    String? field(String name) {
      final value = getJsonField(record, r'''$.fields["''' + name + r'''"]''');
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty || text == 'null' ? null : text;
    }

    bool truthy(String name) {
      final value = field(name);
      if (value == null) return false;
      final lower = value.toLowerCase();
      return lower != 'false' && lower != '0' && lower != 'non';
    }

    final escalated = truthy('Escalade Expeditoo');

    DevisStage resolveStage() {
      if (truthy('livraison fait')) return DevisStage.livre;
      if (truthy('Retrait fait')) return DevisStage.retraitFait;
      if (truthy('PAIEMENT RECU') ||
          (field('STATUT DU PAIEMENT')?.toLowerCase().contains('reçu') ??
              false)) {
        return DevisStage.paye;
      }
      if (truthy('VALIDER DEVIS')) return DevisStage.valide;
      if (escalated) return DevisStage.escalade;
      if (truthy('Devis disponible')) return DevisStage.devisDisponible;
      return DevisStage.enAttente;
    }

    return DevisSummary(
      stage: resolveStage(),
      numeroDevis: field('Numéro Devis'),
      numeroBordereau: field('N°Bordereau'),
      villeRetrait: field('Ville de retrait'),
      villeLivraison: field('Ville de livraison'),
      maisonDeVentes: field('Nom de la maison de ventes'),
      description: field("DESCRIPTION de l'objet"),
      tarif: field('Tarif Devis correspondant'),
      dateDeVente: field('Date de vente'),
      dateDemande: field('Date demande devis'),
      escalated: escalated,
    );
  }
}

/// The Expedion counterpart to `expeditoo-ship/src/features/app/home/ui/
/// ListingCard.tsx`.
///
/// Same card chrome (`bg-card border rounded-xl`, `p-4`, hover lift), same
/// header row with a status badge pinned right, the same muted metadata rows
/// with a `primary` leading icon, the same `border-t` divider above a
/// `text-2xl font-bold text-primary` price, and the same full-width CTA.
class DSQuoteCard extends StatelessWidget {
  const DSQuoteCard({
    super.key,
    required this.devis,
    this.onTap,
    this.action,
  });

  final DevisSummary devis;
  final VoidCallback? onTap;

  /// Primary call to action, e.g. "Voir le devis" or "Payer".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    // Falls back twice: to the auction house, then to a generic caption. Only
    // the caption is ours to translate — the other two are the client's data.
    final title = devis.description?.isNotEmpty == true
        ? devis.description!
        : (devis.maisonDeVentes ??
            xpdT(context, 'Demande de devis', 'Quote request'));

    return DSCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: title + status badge, `flex items-start justify-between`
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8.0),
              DSBadge.status(
                label: devis.stage.labelFor(context),
                status: devis.stage.status,
                icon: devis.stage.icon,
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Metadata rows — `space-y-1.5`, `text-sm text-muted-foreground`
          if (devis.numeroBordereau != null)
            _MetaRow(
              icon: Icons.receipt_long_outlined,
              // Bordereau numbers are codes: Geist Mono, per the type spec.
              child: Text(
                devis.numeroBordereau!,
                style: theme.monoSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (devis.villeRetrait != null || devis.villeLivraison != null)
            _MetaRow(
              icon: Icons.place_outlined,
              child: Text(
                [devis.villeRetrait, devis.villeLivraison]
                    .whereType<String>()
                    .join('  →  '),
                style: theme.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (devis.dateDeVente != null)
            _MetaRow(
              icon: Icons.event_outlined,
              child: Text(
                'Vente du ${devis.dateDeVente}',
                style: theme.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const SizedBox(height: 12.0),
          const DSCardDivider(),
          const SizedBox(height: 12.0),

          // Price row — `text-2xl font-bold text-primary`
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      devis.tarif != null ? '${devis.tarif} €' : '—',
                      style: theme.headlineSmall.copyWith(
                        color: theme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      devis.numeroDevis != null
                          ? '${xpdT(context, 'Devis', 'Quote')} ${devis.numeroDevis}'
                          : xpdT(context, 'Tarif à confirmer', 'Price to be confirmed'),
                      style: theme.labelSmall,
                    ),
                  ],
                ),
              ),
              if (devis.dateDemande != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14.0,
                          color: theme.secondaryText,
                        ),
                        const SizedBox(width: 4.0),
                        Text(devis.dateDemande!, style: theme.labelSmall),
                      ],
                    ),
                  ],
                ),
            ],
          ),

          if (action != null) ...[
            const SizedBox(height: 12.0),
            SizedBox(width: double.infinity, child: action),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 14.0, color: theme.primary),
          const SizedBox(width: 8.0),
          Expanded(child: child),
        ],
      ),
    );
  }
}
