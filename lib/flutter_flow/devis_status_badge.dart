import 'package:flutter/material.dart';

import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// The lifecycle stepper for a devis: reçu → validé → payé → retrait → livré.
///
/// Uses the same treatment as `expeditoo-ship/src/components/Stepper.tsx` —
/// `primary` for every reached step, a `primary/30` halo on the current one,
/// `muted` ahead of it. It previously painted five unrelated Material hues
/// (amber, blue, green, purple, teal), which put five colours on screen that
/// exist in neither app's palette.
///
/// Usage:
///   DevisStatusBadge(
///     statutDevis: 'Devis Validé',
///     statutPaiement: 'Paiement reçu',
///     statutRetrait: 'En cours',
///     statutLivraison: '',
///   )
class DevisStatusBadge extends StatelessWidget {
  const DevisStatusBadge({
    super.key,
    this.statutDevis = '',
    this.statutPaiement = '',
    this.statutRetrait = '',
    this.statutLivraison = '',
  });

  final String statutDevis;
  final String statutPaiement;
  final String statutRetrait;
  final String statutLivraison;

  static const _steps = <_StepData>[
    _StepData(icon: Icons.hourglass_top_rounded, label: 'En attente'),
    _StepData(icon: Icons.check_circle_outline_rounded, label: 'Validé'),
    _StepData(icon: Icons.payments_outlined, label: 'Payé'),
    _StepData(icon: Icons.inventory_2_outlined, label: 'Retrait'),
    _StepData(icon: Icons.local_shipping_outlined, label: 'Livraison'),
  ];

  // Which step index (0–4) is currently active.
  int get _activeStep {
    bool started(String value) =>
        value.isNotEmpty && value.toLowerCase() != 'en attente';

    if (started(statutLivraison)) return 4;
    if (started(statutRetrait)) return 3;
    if (statutPaiement.toLowerCase() == 'paiement reçu') return 2;
    if (statutDevis.toLowerCase() == 'devis validé') return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final active = _activeStep;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(DSShape.card),
        border: Border.all(
          color: theme.alternate,
          width: DSShape.borderWidth,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_steps.length * 2 - 1, (i) {
          // Even indices are steps, odd indices are the connectors between them.
          if (i.isOdd) {
            final leftStep = i ~/ 2;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 17.0),
                child: AnimatedContainer(
                  duration: DSMotion.duration,
                  curve: DSMotion.curve,
                  height: 2.0,
                  color: leftStep < active ? theme.primary : theme.alternate,
                ),
              ),
            );
          }
          return _step(context, theme, i ~/ 2, active);
        }),
      ),
    );
  }

  Widget _step(
    BuildContext context,
    FlutterFlowTheme theme,
    int index,
    int active,
  ) {
    final step = _steps[index];
    final isDone = index < active;
    final isCurrent = index == active;
    final isReached = isDone || isCurrent;

    // Reaching the last step means delivered, so it lands on `success`
    // rather than `primary` — the one place the ramp changes hue.
    final reachedColor =
        index == _steps.length - 1 ? theme.success : theme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: DSMotion.duration,
          curve: DSMotion.curve,
          width: 36.0,
          height: 36.0,
          decoration: BoxDecoration(
            color: isReached ? reachedColor : theme.secondary,
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: reachedColor.withValues(alpha: 0.30),
                      blurRadius: 0.0,
                      spreadRadius: 2.0,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          alignment: Alignment.center,
          child: Icon(
            isDone ? Icons.check_rounded : step.icon,
            size: 18.0,
            color: isReached ? theme.info : theme.secondaryText,
          ),
        ),
        const SizedBox(height: 6.0),
        Text(
          step.label,
          textAlign: TextAlign.center,
          style: theme.labelSmall.copyWith(
            fontSize: 10.0,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
            color: isReached ? theme.primaryText : theme.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _StepData {
  const _StepData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
