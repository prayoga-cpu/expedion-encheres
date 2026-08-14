import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_tokens.dart';

/// Mirrors `expeditoo-ship/src/components/ui/input.tsx`, with the fill the
/// Expedion roadmap pins: `#F4F9FF` (`accent1`), 8px radius, 1px `alternate`
/// border, and a `primary` focus ring.
///
/// The focus ring is Tailwind's `focus-visible:ring-[3px]` rendered as a 3px
/// `primary/50` halo plus a `primary` border, which is how the web build reads.
class DSTextField extends StatefulWidget {
  const DSTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,

    /// Render the value in Geist Mono — bordereau numbers, prices, codes.
    this.mono = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final bool mono;

  @override
  State<DSTextField> createState() => _DSTextFieldState();
}

class _DSTextFieldState extends State<DSTextField> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant DSTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (_ownsFocusNode) _focusNode.dispose();
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final ringColor = hasError ? theme.error : theme.primary;

    final textStyle = (widget.mono ? theme.monoMedium : theme.bodyMedium)
        .copyWith(color: theme.primaryText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          // `label.tsx` — text-sm font-medium
          Text(
            widget.label!,
            style: theme.labelMedium.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6.0),
        ],
        AnimatedContainer(
          duration: DSMotion.duration,
          curve: DSMotion.curve,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DSShape.control),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: ringColor.withValues(alpha: 0.50),
                      blurRadius: 0.0,
                      spreadRadius: 3.0,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            obscureText: widget.obscureText,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            autofillHints: widget.autofillHints,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            validator: widget.validator,
            style: textStyle,
            cursorColor: theme.primary,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: widget.enabled ? theme.accent1 : theme.secondary,
              hintText: widget.hintText,
              hintStyle: theme.labelMedium,
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Icon(
                      widget.prefixIcon,
                      size: 18.0,
                      color: theme.secondaryText,
                    ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40.0,
                minHeight: 40.0,
              ),
              suffixIcon: widget.suffixIcon,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: (widget.maxLines ?? 1) > 1 ? 12.0 : 13.0,
              ),
              enabledBorder: _border(hasError ? theme.error : theme.alternate),
              focusedBorder: _border(ringColor),
              errorBorder: _border(theme.error),
              focusedErrorBorder: _border(theme.error),
              disabledBorder: _border(theme.alternate),
              // The message renders below, outside the ring.
              errorStyle: const TextStyle(height: 0.0, fontSize: 0.0),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6.0),
          Text(
            widget.errorText!,
            style: theme.labelSmall.copyWith(color: theme.error),
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: 6.0),
          Text(widget.helperText!, style: theme.labelSmall),
        ],
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSShape.control),
        borderSide: BorderSide(color: color, width: DSShape.borderWidth),
      );
}
