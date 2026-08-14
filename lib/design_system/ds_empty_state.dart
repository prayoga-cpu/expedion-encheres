import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_tokens.dart';

/// Mirrors `expeditoo-ship/src/components/ui/centered-empty-state.tsx`.
///
/// Icon in a `bg-muted/50` circle with a `ring-1 ring-border/50`, then a
/// `text-lg font-semibold` title, a `text-sm text-muted-foreground`
/// description, and any action 24px below.
class DSEmptyState extends StatelessWidget {
  const DSEmptyState({
    super.key,
    required this.title,
    this.icon,
    this.description,
    this.action,
    this.variant = DSEmptyStateVariant.normal,
  });

  final String title;
  final IconData? icon;
  final String? description;
  final Widget? action;
  final DSEmptyStateVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.secondary.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.alternate.withValues(alpha: 0.5),
                width: DSShape.borderWidth,
              ),
            ),
            child: Icon(
              icon,
              size: 32.0,
              color: theme.secondaryText.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16.0),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        if (description != null) ...[
          const SizedBox(height: 4.0),
          Text(description!, textAlign: TextAlign.center, style: theme.labelMedium),
        ],
        if (action != null) ...[
          const SizedBox(height: DSSize.sectionGap),
          action!,
        ],
      ],
    );

    return Container(
      width: double.infinity,
      constraints: variant == DSEmptyStateVariant.page
          ? const BoxConstraints(minHeight: 400.0)
          : const BoxConstraints(),
      padding: const EdgeInsets.all(32.0),
      alignment: Alignment.center,
      // `max-w-sm`
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 384.0),
        child: content,
      ),
    );
  }
}

enum DSEmptyStateVariant {
  normal,

  /// Fills the page, matching the `page` variant's `min-h-[400px]`.
  page,
}
