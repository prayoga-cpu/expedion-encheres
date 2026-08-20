import 'package:flutter/material.dart';

import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'backend/expedion_api/expedion_quote.dart';
import 'backend/expedion_api/quote_repository.dart';

/// The AI price analysis a client can see while their quote is `pending` —
/// the same kind of estimate an admin sees in the reprice dialog, fetched
/// from `POST /api/expedion/quotes/:id/estimate` and cached server-side.
class AiEstimateSheet {
  const AiEstimateSheet._();

  static Future<void> open(
    BuildContext context, {
    required ExpedionQuote quote,
  }) {
    return showDSSheet<void>(
      context: context,
      title: xpdT(context, 'Estimation IA', 'AI estimate'),
      builder: (sheetContext) => _AiEstimateBody(quoteId: quote.id),
    );
  }
}

class _AiEstimateBody extends StatefulWidget {
  const _AiEstimateBody({required this.quoteId});

  final String quoteId;

  @override
  State<_AiEstimateBody> createState() => _AiEstimateBodyState();
}

class _AiEstimateBodyState extends State<_AiEstimateBody> {
  late Future<AiEstimateResult> _future;

  @override
  void initState() {
    super.initState();
    _future = QuoteRepository.estimate(widget.quoteId);
  }

  void _retry() =>
      setState(() => _future = QuoteRepository.estimate(widget.quoteId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AiEstimateResult>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final result = snapshot.data!;
        if (!result.succeeded || result.estimate == null) {
          return _ErrorState(result: result, onRetry: _retry);
        }
        return _EstimateContent(estimate: result.estimate!);
      },
    );
  }
}

class _EstimateContent extends StatelessWidget {
  const _EstimateContent({required this.estimate});

  final AiPriceEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final palette = XpdPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Disclaimer first — this must never read as a committed price.
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: palette.amberTint(0.12),
              borderRadius: BorderRadius.circular(DSShape.small),
              border: Border.all(color: palette.amberTint(0.30)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16.0, color: palette.amber),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    estimate.isEngineFallback
                        ? xpdT(
                            context,
                            'Estimation par notre moteur de calcul (analyse IA indisponible pour le moment). Le prix final sera confirmé par notre équipe.',
                            'Estimated by our pricing engine (AI analysis unavailable right now). The final price will be confirmed by our team.',
                          )
                        : xpdT(
                            context,
                            'Estimation indicative générée automatiquement. Le prix final sera confirmé par notre équipe.',
                            'Indicative, automatically generated estimate. The final price will be confirmed by our team.',
                          ),
                    style: theme.labelSmall.copyWith(color: palette.amberSub),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          Text(
            formatCents(estimate.standardCents),
            style: theme.headlineSmall
                .copyWith(color: theme.primary, fontWeight: FontWeight.w700),
          ),
          Text(
            xpdT(context, 'Tarif standard estimé', 'Estimated standard price'),
            style: theme.labelSmall,
          ),
          const SizedBox(height: 8.0),
          Text(
            formatCents(estimate.insuredCents),
            style: theme.titleSmall.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            xpdT(context, 'Avec assurance ad valorem', 'With ad valorem insurance'),
            style: theme.labelSmall,
          ),

          if (estimate.reasoning.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            const DSCardDivider(),
            const SizedBox(height: 16.0),
            Text(
              estimate.reasoning,
              style: theme.labelMedium.copyWith(color: theme.secondaryText),
            ),
          ],

          if (estimate.estimations.isNotEmpty) ...[
            const SizedBox(height: 12.0),
            Text(
              xpdT(
                context,
                "Éléments estimés faute d'être renseignés :",
                'Estimated because not provided:',
              ),
              style: theme.labelMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4.0),
            for (final line in estimate.estimations)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '•  $line',
                  style: theme.labelSmall.copyWith(color: theme.secondaryText),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.result, required this.onRetry});

  final AiEstimateResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final message = result.alreadyPriced
        ? xpdT(context, 'Votre devis a déjà été chiffré.', 'Your quote has already been priced.')
        : result.message ??
            xpdT(context, 'Estimation indisponible pour le moment.', 'Estimate unavailable right now.');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: theme.secondaryText, size: 28.0),
          const SizedBox(height: 12.0),
          Text(message, textAlign: TextAlign.center, style: theme.labelMedium),
          if (!result.alreadyPriced) ...[
            const SizedBox(height: 16.0),
            DSButton(
              label: xpdT(context, 'Réessayer', 'Try again'),
              variant: DSButtonVariant.outline,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
