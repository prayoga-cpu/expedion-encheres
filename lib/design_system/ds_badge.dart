import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_tokens.dart';

/// Mirrors `expeditoo-ship/src/components/ui/badge.tsx`.
enum DSBadgeVariant {
  /// Solid `primary` with white text.
  primary,

  /// Solid `muted`.
  secondary,

  /// Solid `destructive` with white text.
  destructive,

  /// Transparent with only the foreground colour.
  outline,

  /// `bg-{status}/10`, `border-{status}/20`, `text-{status}` — the treatment
  /// Expeditoo uses for status pills.
  tinted,
}

/// `inline-flex items-center rounded-md border px-2 py-0.5 text-xs font-medium`
///
/// Note the radius: Expeditoo badges are `rounded-md` (8px), not pills. The
/// roadmap permits pills for status chips but the counterpart does not use
/// them, and parity wins.
class DSBadge extends StatelessWidget {
  const DSBadge({
    super.key,
    required this.label,
    this.variant = DSBadgeVariant.tinted,
    this.status = DSStatus.neutral,
    this.icon,
  });

  /// Convenience constructor for the common case: a tinted status pill.
  const DSBadge.status({
    super.key,
    required this.label,
    required this.status,
    this.icon,
  }) : variant = DSBadgeVariant.tinted;

  final String label;
  final DSBadgeVariant variant;
  final DSStatus status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    late final Color background;
    late final Color foreground;
    late final Color border;

    switch (variant) {
      case DSBadgeVariant.primary:
        background = theme.primary;
        foreground = theme.info;
        border = Colors.transparent;
      case DSBadgeVariant.secondary:
        background = theme.secondary;
        foreground = theme.primaryText;
        border = Colors.transparent;
      case DSBadgeVariant.destructive:
        background = theme.error;
        foreground = Colors.white;
        border = Colors.transparent;
      case DSBadgeVariant.outline:
        background = Colors.transparent;
        foreground = theme.primaryText;
        border = theme.alternate;
      case DSBadgeVariant.tinted:
        background = status.background(context);
        foreground = status.foreground(context);
        border = status.border(context);
    }

    return AnimatedContainer(
      duration: DSMotion.duration,
      curve: DSMotion.curve,
      // `px-2 py-0.5`
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(DSShape.control),
        border: Border.all(color: border, width: DSShape.borderWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            // `[&>svg]:size-3 gap-1`
            Icon(icon, size: 12.0, color: foreground),
            const SizedBox(width: 4.0),
          ],
          Text(
            label,
            style: theme.labelSmall.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
