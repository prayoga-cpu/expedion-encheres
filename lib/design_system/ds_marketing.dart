import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_card.dart';
import 'ds_tokens.dart';

/// The small tinted eyebrow pill Expeditoo sits above every section heading —
/// "Processus Simple", "Catégories", "Fonctionnalités", "Témoignages".
///
/// One of the two places a fully-rounded shape is correct (the other being the
/// segmented control); everything structural stays on the 8/12/16 scale.
class DSSectionBadge extends StatelessWidget {
  const DSSectionBadge({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DSShape.pill),
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.16),
          width: DSShape.borderWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13.0, color: theme.primary),
            const SizedBox(width: 6.0),
          ],
          Text(
            label,
            style: theme.labelSmall.copyWith(
              color: theme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge → heading → subheading, centred. The header block that opens every
/// section of the Expeditoo landing page.
class DSSectionHeader extends StatelessWidget {
  const DSSectionHeader({
    super.key,
    required this.title,
    this.badge,
    this.badgeIcon,
    this.subtitle,
    this.align = TextAlign.center,
  });

  final String title;
  final String? badge;
  final IconData? badgeIcon;
  final String? subtitle;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final cross = align == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (badge != null) ...[
          DSSectionBadge(label: badge!, icon: badgeIcon),
          const SizedBox(height: 16.0),
        ],
        Text(
          title,
          textAlign: align,
          style: theme.headlineMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8.0),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560.0),
            child: Text(subtitle!, textAlign: align, style: theme.labelMedium),
          ),
        ],
      ],
    );
  }
}

/// Icon-in-a-tinted-square, then a large figure, then a muted caption —
/// the "50 000+ / Livraisons effectuées" tiles.
class DSStatCard extends StatelessWidget {
  const DSStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return DSCard(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DSShape.control),
            ),
            child: Icon(icon, size: 20.0, color: theme.primary),
          ),
          const SizedBox(height: 16.0),
          // Figures are data — Geist Mono, matching `--font-mono`.
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.monoLarge.copyWith(
              fontSize: 26.0,
              fontWeight: FontWeight.w500,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(label, textAlign: TextAlign.center, style: theme.labelSmall),
        ],
      ),
    );
  }
}

/// "Économique / Écologique / Sécurisé / Communauté" — icon square, title,
/// muted body, left-aligned inside a bordered card.
class DSFeatureCard extends StatelessWidget {
  const DSFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return DSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36.0,
            height: 36.0,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DSShape.small),
            ),
            child: Icon(icon, size: 18.0, color: theme.primary),
          ),
          const SizedBox(height: 14.0),
          Text(
            title,
            style: theme.titleSmall.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4.0),
          Text(description, style: theme.labelSmall),
        ],
      ),
    );
  }
}

/// One step in the "Comment ça marche ?" row: a circled icon over a title and
/// a muted line, with connector rules drawn by [DSStepRow].
class DSProcessStep {
  const DSProcessStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class DSStepRow extends StatelessWidget {
  const DSStepRow({super.key, required this.steps});

  final List<DSProcessStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Below roughly two columns the horizontal rail stops being legible,
        // so the row becomes a stack.
        final horizontal = constraints.maxWidth > 640.0;
        if (!horizontal) {
          return Column(
            children: [
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == steps.length - 1 ? 0.0 : 20.0,
                  ),
                  child: _step(theme, steps[i]),
                ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length * 2 - 1; i++)
              if (i.isOdd)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 27.0),
                    child: Container(height: 1.0, color: theme.alternate),
                  ),
                )
              else
                Expanded(flex: 3, child: _step(theme, steps[i ~/ 2])),
          ],
        );
      },
    );
  }

  Widget _step(FlutterFlowTheme theme, DSProcessStep step) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54.0,
            height: 54.0,
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.alternate,
                width: DSShape.borderWidth,
              ),
            ),
            child: Icon(step.icon, size: 22.0, color: theme.primary),
          ),
          const SizedBox(height: 12.0),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: theme.labelMedium.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: theme.labelSmall,
          ),
        ],
      );
}

/// The blue full-bleed call-to-action panel that closes the landing page.
class DSCtaBlock extends StatelessWidget {
  const DSCtaBlock({
    super.key,
    required this.title,
    this.badge,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? badge;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      decoration: BoxDecoration(
        color: theme.primary,
        borderRadius: BorderRadius.circular(DSShape.sheet),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DSShape.pill),
              ),
              child: Text(
                badge!,
                style: theme.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12.0),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520.0),
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 24.0),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Five-star row used on the testimonial cards and the hero rating line.
class DSStarRating extends StatelessWidget {
  const DSStarRating({
    super.key,
    required this.rating,
    this.size = 14.0,
    this.max = 5,
  });

  final double rating;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Padding(
            padding: EdgeInsets.only(right: i == max - 1 ? 0.0 : 2.0),
            child: Icon(
              i < rating.floor()
                  ? Icons.star_rounded
                  : (i < rating
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
              size: size,
              color: theme.primary,
            ),
          ),
      ],
    );
  }
}

/// A quote card from the "Aimé par des Milliers" band: star row, the quote
/// itself, a small tinted tag, then the attribution with an avatar initial.
class DSTestimonialCard extends StatelessWidget {
  const DSTestimonialCard({
    super.key,
    required this.quote,
    required this.name,
    required this.role,
    this.rating = 5,
    this.tag,
  });

  final String quote;
  final String name;
  final String role;
  final double rating;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return DSCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 22.0,
            color: theme.primary.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 8.0),
          DSStarRating(rating: rating),
          const SizedBox(height: 12.0),
          Text(
            quote,
            style: theme.labelMedium.copyWith(
              color: theme.primaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16.0),
          if (tag != null) ...[
            DSSectionBadge(label: tag!),
            const SizedBox(height: 12.0),
          ],
          Row(
            children: [
              Container(
                width: 30.0,
                height: 30.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: theme.labelSmall.copyWith(
                    color: theme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: theme.labelMedium.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      role,
                      style: theme.labelSmall.copyWith(fontSize: 11.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Image tile with a bottom gradient scrim and white label — the "Meubles /
/// Pièces Auto / Électronique" category grid.
class DSCategoryCard extends StatelessWidget {
  const DSCategoryCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.subtitle,
    this.onTap,
    this.height = 150.0,
  });

  final String title;
  final String imageUrl;
  final String? subtitle;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final radius = BorderRadius.circular(DSShape.card);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      ColoredBox(color: theme.secondary),
                ),
                // Scrim, so white type stays legible over any photograph.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB3000000)],
                      stops: [0.45, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 12.0,
                  right: 12.0,
                  bottom: 10.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11.0,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
