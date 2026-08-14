import 'dart:async';

import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_tokens.dart';

/// Mirrors `expeditoo-ship/src/components/ui/button.tsx`.
enum DSButtonVariant { primary, destructive, outline, secondary, ghost, link }

enum DSButtonSize { sm, md, lg, icon }

/// A button matching Expeditoo's `button.tsx` one to one.
///
/// Filled `#076BE3`, 8px radius, 44px tall, `text-sm font-medium`, 8px gap
/// between icon and label, 200ms colour transition, 50% opacity when disabled.
///
/// [onPressed] may return a `Future`; while it is in flight the label is
/// swapped for a spinner and further taps are ignored, which is what the
/// existing `FFButtonWidget` does and what every call site already expects.
class DSButton extends StatefulWidget {
  const DSButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = DSButtonVariant.primary,
    this.size = DSButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.showLoadingIndicator = true,
  });

  final String label;

  /// `null` disables the button.
  final FutureOr<void> Function()? onPressed;
  final DSButtonVariant variant;
  final DSButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;

  /// Stretch to the parent's width (`w-full`).
  final bool expand;
  final bool showLoadingIndicator;

  @override
  State<DSButton> createState() => _DSButtonState();
}

class _DSButtonState extends State<DSButton> {
  bool _loading = false;

  bool get _enabled => widget.onPressed != null && !_loading;

  double get _height {
    switch (widget.size) {
      case DSButtonSize.sm:
        return DSSize.controlHeightSm;
      case DSButtonSize.md:
        return DSSize.controlHeight;
      case DSButtonSize.lg:
        return DSSize.controlHeightLg;
      case DSButtonSize.icon:
        return DSSize.controlHeight;
    }
  }

  EdgeInsets get _padding {
    if (widget.size == DSButtonSize.icon) return EdgeInsets.zero;
    if (widget.variant == DSButtonVariant.link) {
      return const EdgeInsets.symmetric(horizontal: 4.0);
    }
    return EdgeInsets.symmetric(
      horizontal: widget.size == DSButtonSize.sm ? 12.0 : 16.0,
    );
  }

  Future<void> _handleTap() async {
    if (!_enabled) return;
    if (!widget.showLoadingIndicator) {
      await widget.onPressed!();
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final style = _resolveStyle(theme);

    final labelStyle = theme.labelMedium.copyWith(
      color: style.foreground,
      fontWeight: FontWeight.w500,
      decoration: widget.variant == DSButtonVariant.link
          ? TextDecoration.underline
          : null,
    );

    Widget child;
    if (_loading) {
      child = SizedBox(
        width: 18.0,
        height: 18.0,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(style.foreground),
        ),
      );
    } else {
      final parts = <Widget>[
        if (widget.icon != null)
          Icon(widget.icon, size: 16.0, color: style.foreground),
        if (widget.size != DSButtonSize.icon)
          Flexible(
            child: Text(
              widget.label,
              style: labelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (widget.trailingIcon != null)
          Icon(widget.trailingIcon, size: 16.0, color: style.foreground),
      ];
      child = Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        // `gap-2`
        children: _withGap(parts, 8.0),
      );
    }

    return Opacity(
      opacity: widget.onPressed == null ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _enabled ? _handleTap : null,
          borderRadius: BorderRadius.circular(DSShape.control),
          splashColor: style.foreground.withValues(alpha: 0.10),
          highlightColor: style.foreground.withValues(alpha: 0.05),
          hoverColor: style.hover,
          child: AnimatedContainer(
            duration: DSMotion.duration,
            curve: DSMotion.curve,
            height: _height,
            width: widget.size == DSButtonSize.icon
                ? _height
                : (widget.expand ? double.infinity : null),
            padding: _padding,
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(DSShape.control),
              border: style.border == null
                  ? null
                  : Border.all(
                      color: style.border!,
                      width: DSShape.borderWidth,
                    ),
              boxShadow: style.elevated
                  ? [theme.designToken.shadow.xs]
                  : const <BoxShadow>[],
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  _DSButtonStyle _resolveStyle(FlutterFlowTheme theme) {
    switch (widget.variant) {
      case DSButtonVariant.primary:
        return _DSButtonStyle(
          background: theme.primary,
          foreground: theme.info,
          hover: theme.primary.withValues(alpha: 0.90),
        );
      case DSButtonVariant.destructive:
        return _DSButtonStyle(
          background: theme.error,
          foreground: Colors.white,
          hover: theme.error.withValues(alpha: 0.90),
        );
      case DSButtonVariant.outline:
        return _DSButtonStyle(
          background: theme.secondaryBackground,
          foreground: theme.primaryText,
          border: theme.alternate,
          hover: theme.accent1,
          elevated: true,
        );
      case DSButtonVariant.secondary:
        return _DSButtonStyle(
          background: theme.secondary,
          foreground: theme.primaryText,
          hover: theme.secondary.withValues(alpha: 0.80),
        );
      case DSButtonVariant.ghost:
        return _DSButtonStyle(
          background: Colors.transparent,
          foreground: theme.primaryText,
          hover: theme.accent1,
        );
      case DSButtonVariant.link:
        return _DSButtonStyle(
          background: Colors.transparent,
          foreground: theme.primary,
          hover: Colors.transparent,
        );
    }
  }
}

class _DSButtonStyle {
  const _DSButtonStyle({
    required this.background,
    required this.foreground,
    required this.hover,
    this.border,
    this.elevated = false,
  });

  final Color background;
  final Color foreground;
  final Color hover;
  final Color? border;
  final bool elevated;
}

/// Tailwind `gap-2` between whichever of icon / label / trailing icon exist.
List<Widget> _withGap(List<Widget> children, double gap) => [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(width: gap),
        children[i],
      ],
    ];
