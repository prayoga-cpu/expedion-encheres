import '/design_system/ds_l10n.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Landing page Stripe redirects to when a Checkout session is cancelled
/// (`cancel_url = <appOrigin>/cancel`). No payment was taken.
class PaiementCancelWidget extends StatelessWidget {
  const PaiementCancelWidget({super.key});

  static String routeName = 'PAIEMENT_CANCEL';
  static String routePath = '/cancel';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480.0),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel_rounded, color: theme.error, size: 72.0),
                  const SizedBox(height: 24.0),
                  Text(
                    xpdT(context, 'Paiement annulé', 'Payment cancelled'),
                    textAlign: TextAlign.center,
                    style: theme.headlineSmall.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: theme.primaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    xpdT(
                      context,
                      'Votre paiement n\'a pas été finalisé. '
                          'Aucun montant n\'a été débité. Vous pouvez réessayer à tout moment.',
                      'Your payment was not completed. '
                          'No amount was charged. You can try again at any time.',
                    ),
                    textAlign: TextAlign.center,
                    style: theme.bodyMedium.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: theme.secondaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  FFButtonWidget(
                    onPressed: () => context.goNamed(MesDevisWidget.routeName),
                    text: xpdT(context, 'Retour à mes devis', 'Back to my quotes'),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 48.0,
                      color: theme.primary,
                      textStyle: theme.titleSmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: theme.info,
                        letterSpacing: 0.0,
                      ),
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
