import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Shared shape and motion constants for the Expedion ↔ Expeditoo design
/// system, resolved from [FlutterFlowTheme]'s design tokens.
///
/// The token scale itself lives in `FFRadius` / `FFSpacing` / `FFMotion`. This
/// file records the *component-level* decisions so that every widget in
/// `lib/design_system` reaches for the same number rather than re-deriving it.
class DSShape {
  const DSShape._();

  /// Buttons, inputs, badges — Tailwind `rounded-md`, i.e. `--radius` (8px).
  static const double control = 8.0;

  /// Small controls — `rounded-sm`, `calc(--radius - 2px)` (6px).
  static const double small = 6.0;

  /// Cards.
  ///
  /// NOTE: the Expedion roadmap's token table says 12px, but the counterpart
  /// this is graded against — `expeditoo-ship/src/components/ui/card.tsx` and
  /// `features/app/home/ui/ListingCard.tsx` — both render Tailwind
  /// `rounded-xl`, which resolves to `calc(--radius + 8px)` = 16px. The Phase C
  /// exit criterion is the side-by-side card test, so we match the shipped
  /// component. Flip this single constant to 12.0 if Expeditoo moves to
  /// `rounded-lg` instead.
  static const double card = 16.0;

  /// Bottom sheets — 16px on the top corners only.
  static const double sheet = 16.0;

  /// Every border in the system is 1px of `alternate`.
  static const double borderWidth = 1.0;

  /// Fully rounded. Reserved for the sheet drag handle and progress tracks —
  /// the roadmap's "no pills" rule applies to buttons, inputs and cards.
  static const double pill = 9999.0;
}

class DSSize {
  const DSSize._();

  /// Primary control height. The roadmap pins 44px for Expedion: Expeditoo's
  /// web default is `h-9` (36px), which is below the 44px touch target both
  /// iOS and Android ask for on a real device.
  static const double controlHeight = 44.0;

  /// Parity with Expeditoo's `h-9` default, for dense/desktop rows.
  static const double controlHeightSm = 36.0;
  static const double controlHeightLg = 48.0;

  /// `p-4` on ListingCard.
  static const double cardPadding = 16.0;

  /// Gap between page sections.
  static const double sectionGap = 24.0;
}

class DSMotion {
  const DSMotion._();

  /// Expeditoo transitions colour, border, fill and stroke over 200ms.
  static const Duration duration = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeInOut;
}

/// Status semantics shared by both apps' pills.
enum DSStatus { neutral, info, success, warning, danger }

extension DSStatusColors on DSStatus {
  /// The solid hue — used for text and the icon.
  Color foreground(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    switch (this) {
      case DSStatus.neutral:
        return theme.secondaryText;
      case DSStatus.info:
        return theme.primary;
      case DSStatus.success:
        return theme.success;
      case DSStatus.warning:
        return theme.warning;
      case DSStatus.danger:
        return theme.error;
    }
  }

  /// Tailwind `bg-{token}/10`.
  Color background(BuildContext context) => this == DSStatus.neutral
      ? FlutterFlowTheme.of(context).secondary.withValues(alpha: 0.35)
      : foreground(context).withValues(alpha: 0.10);

  /// Tailwind `border-{token}/20`.
  Color border(BuildContext context) => this == DSStatus.neutral
      ? FlutterFlowTheme.of(context).alternate
      : foreground(context).withValues(alpha: 0.20);
}
