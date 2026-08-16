import 'package:flutter/material.dart';
import 'ds_l10n.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_tokens.dart';

/// **Compte à rebours de gardiennage** — the storage-fee countdown.
///
/// This is the conversion lever, not decoration (ROADMAP.md §1). Auction
/// houses refuse to ship and start charging daily storage after a grace
/// period — Accord Enchères bills €1–20 per day after day ten. Surfacing the
/// remaining days is what turns a browsing buyer into a booked one.
///
/// The tone escalates with urgency rather than shouting from day one: neutral
/// while there is time, warning inside the final stretch, destructive once
/// fees are actually accruing.
class DSStorageCountdown extends StatelessWidget {
  const DSStorageCountdown({
    super.key,
    required this.freeUntil,
    this.dailyFeeCents,
    this.now,
    this.onAction,
    this.actionLabel = 'Organiser le retrait',
  });

  /// Last day before gardiennage starts being charged.
  final DateTime freeUntil;

  /// Daily fee once the grace period lapses, in cents.
  final int? dailyFeeCents;

  /// Injectable clock, so the widget is testable.
  final DateTime? now;

  final VoidCallback? onAction;
  final String actionLabel;

  /// Whole days remaining. Negative once fees have started.
  int get daysRemaining {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final deadline = DateTime(freeUntil.year, freeUntil.month, freeUntil.day);
    return deadline.difference(today).inDays;
  }

  /// Below this, the countdown starts reading as urgent.
  static const int warningThresholdDays = 4;

  DSStatus get _status {
    final days = daysRemaining;
    if (days < 0) return DSStatus.danger;
    if (days <= warningThresholdDays) return DSStatus.warning;
    return DSStatus.info;
  }

  String _headline(BuildContext context) {
    final days = daysRemaining;
    if (days < 0) {
      final overdue = -days;
      return xpdT(
        context,
        'Frais de gardiennage en cours depuis $overdue jour'
            '${overdue > 1 ? 's' : ''}',
        'Storage fees running for $overdue day${overdue > 1 ? 's' : ''}',
      );
    }
    if (days == 0) {
      return xpdT(
        context,
        'Dernier jour sans frais de gardiennage',
        'Last free storage day',
      );
    }
    return xpdT(
      context,
      '$days jour${days > 1 ? 's' : ''} avant les frais de gardiennage',
      '$days day${days > 1 ? 's' : ''} before storage fees start',
    );
  }

  String? _detail(BuildContext context) {
    if (dailyFeeCents == null) return null;
    // Comma decimal separator in French, point in English — the figure is the
    // same money either way, but "12.50" reads as a typo to a French client.
    final english = xpdIsEnglish(context);
    String money(num cents) {
      final text = (cents / 100).toStringAsFixed(2);
      return english ? text : text.replaceAll('.', ',');
    }

    final fee = money(dailyFeeCents!);
    final days = daysRemaining;
    if (days < 0) {
      final accrued = money(dailyFeeCents! * -days);
      return xpdT(
        context,
        '$fee € par jour · $accrued € cumulés à ce jour',
        '€$fee per day · €$accrued accrued so far',
      );
    }
    return xpdT(
      context,
      '$fee € par jour au-delà du ${_formatDate(freeUntil)}',
      '€$fee per day after ${_formatDate(freeUntil)}',
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final status = _status;
    final fg = status.foreground(context);
    final detail = _detail(context);

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
                daysRemaining < 0
                    ? Icons.warning_amber_rounded
                    : Icons.timer_outlined,
                size: 20.0,
                color: fg,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _headline(context),
                      style: theme.titleSmall.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 2.0),
                      // Money and dates read as data: Geist Mono.
                      Text(detail, style: theme.monoSmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (onAction != null) ...[
            const SizedBox(height: 12.0),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  backgroundColor: fg,
                  foregroundColor: theme.info,
                  minimumSize: const Size.fromHeight(DSSize.controlHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DSShape.control),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: theme.labelMedium.copyWith(
                    color: theme.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
