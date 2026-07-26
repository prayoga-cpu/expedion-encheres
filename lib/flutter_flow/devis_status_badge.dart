import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// A visual stepper that shows the full lifecycle of a Devis (Quote).
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

  // Determine which step index (0-4) is currently active.
  int get _activeStep {
    if (statutLivraison.isNotEmpty &&
        statutLivraison.toLowerCase() != 'en attente') return 4;
    if (statutRetrait.isNotEmpty &&
        statutRetrait.toLowerCase() != 'en attente') return 3;
    if (statutPaiement.toLowerCase() == 'paiement reçu') return 2;
    if (statutDevis.toLowerCase() == 'devis validé') return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepData(
        icon: Icons.hourglass_top_rounded,
        label: 'En attente',
        sublabel: 'Devis reçu',
        activeColor: const Color(0xFFFFA000),
      ),
      _StepData(
        icon: Icons.check_circle_outline_rounded,
        label: 'Validé',
        sublabel: 'Devis validé',
        activeColor: const Color(0xFF1976D2),
      ),
      _StepData(
        icon: Icons.payment_rounded,
        label: 'Payé',
        sublabel: 'Paiement reçu',
        activeColor: const Color(0xFF388E3C),
      ),
      _StepData(
        icon: Icons.inventory_2_outlined,
        label: 'Retrait',
        sublabel: 'Retrait effectué',
        activeColor: const Color(0xFF7B1FA2),
      ),
      _StepData(
        icon: Icons.local_shipping_outlined,
        label: 'Livraison',
        sublabel: 'Livré',
        activeColor: const Color(0xFF00796B),
      ),
    ];

    final active = _activeStep;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length * 2 - 1, (i) {
          // Even indices = steps, odd = connectors
          if (i.isOdd) {
            final stepIdx = i ~/ 2;
            final passed = stepIdx < active;
            return Expanded(
              child: Container(
                height: 2.0,
                decoration: BoxDecoration(
                  gradient: passed
                      ? LinearGradient(
                          colors: [
                            steps[stepIdx].activeColor,
                            steps[stepIdx + 1].activeColor,
                          ],
                        )
                      : null,
                  color: passed
                      ? null
                      : FlutterFlowTheme.of(context).alternate,
                ),
              ),
            );
          }

          final stepIdx = i ~/ 2;
          final step = steps[stepIdx];
          final isDone = stepIdx < active;
          final isCurrent = stepIdx == active;
          final isUpcoming = stepIdx > active;

          final iconColor = isDone || isCurrent
              ? step.activeColor
              : FlutterFlowTheme.of(context).secondaryText;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 36.0 : 30.0,
                height: isCurrent ? 36.0 : 30.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? step.activeColor.withOpacity(0.15)
                      : isCurrent
                          ? step.activeColor.withOpacity(0.12)
                          : FlutterFlowTheme.of(context)
                              .primaryBackground,
                  border: Border.all(
                    color: isDone || isCurrent
                        ? step.activeColor
                        : FlutterFlowTheme.of(context).alternate,
                    width: isCurrent ? 2.0 : 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isDone ? Icons.check_rounded : step.icon,
                    size: isCurrent ? 18.0 : 15.0,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                step.label,
                style: GoogleFonts.inter(
                  fontSize: 9.0,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isUpcoming
                      ? FlutterFlowTheme.of(context).secondaryText
                      : step.activeColor,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StepData {
  const _StepData({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.activeColor,
  });
  final IconData icon;
  final String label;
  final String sublabel;
  final Color activeColor;
}
