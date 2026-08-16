import '/app_shell.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'choix_devis_illustrations.dart';
import 'choix_devis_model.dart';
export 'choix_devis_model.dart';

/// The fork in the road: which of the two quote forms a client should use.
///
/// Both routes end the same way — we read the lot details and send back a
/// price — so the page has to answer one question only: *do you have the
/// auction house's slip as a PDF?* The previous version did not answer it. Both
/// options carried the same closing sentence ("our team will analyse your needs
/// and send you a customised quote"), both buttons said "Open", and neither
/// said what the client would actually be asked to do. A client with a PDF had
/// no reason to prefer the route that reads it for them.
///
/// So the cards now lead with the input rather than the outcome, name the
/// effort ("about a minute" against "about five"), and carry an illustration of
/// the two inputs side by side. The PDF route is marked as the quicker one
/// because it genuinely is: the extractor fills the form in.
class ChoixDevisWidget extends StatefulWidget {
  const ChoixDevisWidget({super.key});

  static String routeName = 'CHOIX-DEVIS';
  static String routePath = '/choixDevis';

  @override
  State<ChoixDevisWidget> createState() => _ChoixDevisWidgetState();
}

class _ChoixDevisWidgetState extends State<ChoixDevisWidget> {
  late ChoixDevisModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChoixDevisModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final theme = FlutterFlowTheme.of(context);

    return XpdPage(
      current: XpdDestination.requestQuote,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Side by side once there is room for two readable columns; the
            // comparison is the point, and stacking hides it.
            final sideBySide = constraints.maxWidth >= 880.0;
            final cards = [
              _RouteCard(
                kind: DevisRouteKind.pdfSlip,
                flag: xpdT(context, 'Le plus rapide', 'Fastest'),
                title: xpdT(
                  context,
                  'J’ai le bordereau en PDF',
                  'I have the slip as a PDF',
                ),
                summary: xpdT(
                  context,
                  'Déposez le PDF de la maison de ventes. Nous en extrayons '
                  'les lots, les dimensions et l’adresse de retrait.',
                  'Drop in the auction house’s PDF. We pull out the lots, the '
                  'dimensions and the collection address for you.',
                ),
                points: [
                  xpdT(context, 'Rien à recopier', 'Nothing to retype'),
                  xpdT(context, 'Environ 1 minute', 'About 1 minute'),
                  xpdT(context, 'Prix le plus fiable', 'Most accurate price'),
                ],
                cta: xpdT(context, 'Déposer mon bordereau', 'Upload my slip'),
                onPressed: () => context
                    .pushNamed(FormulaireDeDevisParBordereauWidget.routeName),
              ),
              _RouteCard(
                kind: DevisRouteKind.manualDetails,
                title: xpdT(
                  context,
                  'Je n’ai pas de PDF',
                  'I don’t have a PDF',
                ),
                summary: xpdT(
                  context,
                  'Photo, scan, bordereau papier ou vente encore à venir : '
                  'renseignez vous-même les lots et l’enlèvement.',
                  'A photo, a scan, a paper slip, or a sale still to come: '
                  'enter the lots and the collection details yourself.',
                ),
                points: [
                  xpdT(context, 'Aucun fichier requis', 'No file needed'),
                  xpdT(context, 'Environ 5 minutes', 'About 5 minutes'),
                  xpdT(
                    context,
                    'Vous gardez la main sur chaque champ',
                    'You control every field',
                  ),
                ],
                cta: xpdT(context, 'Remplir le formulaire', 'Fill in the form'),
                onPressed: () => context.pushNamed(
                  FormulaireDemandeDeDevisRetraitAuxEncheresWidget.routeName,
                ),
              ),
            ];

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 40.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          FFLocalizations.of(context).getText(
                            '71ds2bl2' /* Choisissez votre type de devis */,
                          ),
                          textAlign: TextAlign.center,
                          style: theme.displaySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          xpdT(
                            context,
                            'Une seule question : avez-vous le bordereau de la '
                            'maison de ventes en PDF ?',
                            'Just one question: do you have the auction '
                            'house’s slip as a PDF?',
                          ),
                          textAlign: TextAlign.center,
                          style: theme.bodyMedium
                              .copyWith(color: theme.secondaryText),
                        ),
                        const SizedBox(height: 28.0),
                        if (sideBySide)
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 20.0),
                                Expanded(child: cards[1]),
                              ],
                            ),
                          )
                        else ...[
                          cards[0],
                          const SizedBox(height: 16.0),
                          cards[1],
                        ],
                        const SizedBox(height: 24.0),
                        Text(
                          xpdT(
                            context,
                            'Dans les deux cas, le devis est gratuit et sans '
                            'engagement.',
                            'Either way, the quote is free and comes with no '
                            'obligation.',
                          ),
                          textAlign: TextAlign.center,
                          style: theme.labelSmall
                              .copyWith(color: theme.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One of the two routes: illustration, what it asks of you, and the way in.
class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.kind,
    required this.title,
    required this.summary,
    required this.points,
    required this.cta,
    required this.onPressed,
    this.flag,
  });

  final DevisRouteKind kind;
  final String title;
  final String summary;
  final List<String> points;
  final String cta;
  final VoidCallback onPressed;

  /// Optional badge, e.g. "Fastest". Only the PDF route carries one — two
  /// badges would rank nothing.
  final String? flag;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final recommended = flag != null;

    return DSCard(
      onTap: onPressed,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DSShape.card),
          // The quicker route gets a tinted border rather than a different
          // colour scheme: enough to draw the eye first, not enough to make
          // the other one look broken.
          border: recommended
              ? Border.all(color: theme.primary, width: DSShape.borderWidth)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              decoration: BoxDecoration(
                color: theme.primaryBackground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DSShape.card),
                ),
              ),
              child: DevisRouteIllustration(kind: kind),
            ),
            Padding(
              padding: const EdgeInsets.all(DSSize.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.titleMedium
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8.0),
                        DSBadge(label: flag!, status: DSStatus.info),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    summary,
                    style:
                        theme.bodySmall.copyWith(color: theme.secondaryText),
                  ),
                  const SizedBox(height: 16.0),
                  for (final point in points)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            size: 16.0,
                            color: theme.primary,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(point, style: theme.labelMedium),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12.0),
                  DSButton(
                    label: cta,
                    expand: true,
                    icon: kind == DevisRouteKind.pdfSlip
                        ? Icons.upload_file_rounded
                        : Icons.edit_note_rounded,
                    variant: recommended
                        ? DSButtonVariant.primary
                        : DSButtonVariant.outline,
                    onPressed: onPressed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
