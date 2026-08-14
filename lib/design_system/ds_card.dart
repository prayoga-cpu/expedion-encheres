import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_tokens.dart';

/// Mirrors `expeditoo-ship/src/components/ui/card.tsx` as consumed by
/// `features/app/home/ui/ListingCard.tsx`:
/// `bg-card border rounded-xl overflow-hidden hover:shadow-lg`, `p-4` inside.
class DSCard extends StatefulWidget {
  const DSCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(DSSize.cardPadding),
    this.margin,
    this.clip = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// `overflow-hidden` — set false when a child needs to paint outside.
  final bool clip;

  @override
  State<DSCard> createState() => _DSCardState();
}

class _DSCardState extends State<DSCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final radius = BorderRadius.circular(DSShape.card);

    final card = AnimatedContainer(
      duration: DSMotion.duration,
      curve: DSMotion.curve,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: radius,
        border: Border.all(
          color: theme.alternate,
          width: DSShape.borderWidth,
        ),
        boxShadow: [
          _hovered && widget.onTap != null
              ? theme.designToken.shadow.lg
              : theme.designToken.shadow.sm,
        ],
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );

    final content =
        widget.clip ? ClipRRect(borderRadius: radius, child: card) : card;

    if (widget.onTap == null) return content;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          child: content,
        ),
      ),
    );
  }
}

/// `border-t border-border/50` divider used inside cards, e.g. above the price
/// row on `ListingCard`.
class DSCardDivider extends StatelessWidget {
  const DSCardDivider({super.key, this.height = 1.0});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        color: FlutterFlowTheme.of(context).alternate.withValues(alpha: 0.5),
      );
}
