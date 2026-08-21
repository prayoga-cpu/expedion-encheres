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
///
/// Validation renders *below* the ring rather than inside the input's own
/// decoration, so the halo stays wrapped around the box and does not stretch
/// to enclose the message. That is why the input is a [TextField] inside a
/// [FormField] rather than a [TextFormField]: the form field owns the error
/// state and this widget decides where to draw it.
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
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,

    /// Render the value in Geist Mono — bordereau numbers, prices, codes.
    this.mono = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;

  /// A failure the [validator] cannot see — a server refusal, a cross-field
  /// rule the owning form checks itself. Takes precedence over the validator's
  /// own message.
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;

  /// Hard cap on what can be typed. Enforced by the field itself rather than
  /// by a validator, so an over-long paste is trimmed instead of refused.
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  /// Defaults to [AutovalidateMode.onUserInteraction]: a field says what is
  /// wrong with it as soon as the visitor has typed in *that* field, and stays
  /// quiet until then. `Form.validate()` still forces every field to speak.
  final AutovalidateMode autovalidateMode;
  final bool mono;

  @override
  State<DSTextField> createState() => _DSTextFieldState();
}

class _DSTextFieldState extends State<DSTextField> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _focused = false;

  /// The live form field, so a programmatic edit — an address suggestion
  /// filling the city, a restored draft — can re-run validation the same way
  /// typing does. Without this a "required" message could outlive the value
  /// that fixed it.
  FormFieldState<String>? _field;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller?.addListener(_syncFieldValue);
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
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_syncFieldValue);
      widget.controller?.addListener(_syncFieldValue);
    }
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  /// Post-frame because a controller listener can fire mid-build (a parent
  /// rebuilding with new text), and [FormFieldState.didChange] calls setState.
  void _syncFieldValue() {
    final text = widget.controller?.text ?? '';
    if (_field == null || _field!.value == text) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final field = _field;
      final current = widget.controller?.text ?? '';
      if (field == null || field.value == current) return;
      field.didChange(current);
    });
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_syncFieldValue);
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller?.text ?? '',
      enabled: widget.enabled,
      autovalidateMode: widget.autovalidateMode,
      // Validate what the controller holds, not the form field's own copy:
      // the two only agree while the visitor is the one typing.
      validator: widget.validator == null
          ? null
          : (_) => widget.validator!(widget.controller?.text ?? ''),
      builder: (field) {
        _field = field;
        return _input(context, field);
      },
    );
  }

  Widget _input(BuildContext context, FormFieldState<String> field) {
    final theme = FlutterFlowTheme.of(context);

    final errorText = (widget.errorText?.isNotEmpty ?? false)
        ? widget.errorText
        : field.errorText;
    final hasError = errorText != null && errorText.isNotEmpty;
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
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            obscureText: widget.obscureText,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            autofillHints: widget.autofillHints,
            onChanged: (value) {
              field.didChange(value);
              widget.onChanged?.call(value);
            },
            onSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            style: textStyle,
            cursorColor: theme.primary,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: widget.enabled ? theme.accent1 : theme.secondary,
              hintText: widget.hintText,
              hintStyle: theme.labelMedium,
              // The counter would sit inside the ring; the caller shows the
              // remaining length in `helperText` when it wants one.
              counterText: '',
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
              disabledBorder: _border(theme.alternate),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14.0,
                color: theme.error,
              ),
              const SizedBox(width: 4.0),
              Expanded(
                child: Text(
                  errorText,
                  style: theme.labelSmall.copyWith(color: theme.error),
                ),
              ),
            ],
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
