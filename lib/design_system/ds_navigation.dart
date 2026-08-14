import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_tokens.dart';

/// Sidebar / menu row, matching the Expeditoo app shell.
///
/// Active rows are a solid `primary` block with white text and an 8px radius;
/// inactive rows are plain `foreground` on transparent and only tint on hover.
/// The icon always leads, 12px from the label.
class DSNavItem extends StatefulWidget {
  const DSNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? trailing;

  @override
  State<DSNavItem> createState() => _DSNavItemState();
}

class _DSNavItemState extends State<DSNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final foreground =
        widget.selected ? theme.info : theme.primaryText;

    final background = widget.selected
        ? theme.primary
        : (_hovered ? theme.accent1 : Colors.transparent);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(DSShape.control),
          child: AnimatedContainer(
            duration: DSMotion.duration,
            curve: DSMotion.curve,
            height: 48.0,
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(DSShape.control),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 20.0, color: foreground),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyMedium.copyWith(
                      color: foreground,
                      fontWeight:
                          widget.selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 15.0,
                    ),
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The small count bubble on the notification bell.
class DSNotificationBadge extends StatelessWidget {
  const DSNotificationBadge({
    super.key,
    required this.count,
    required this.icon,
    this.onTap,
  });

  final int count;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon, color: theme.primaryText),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 4.0,
            top: 4.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              constraints: const BoxConstraints(minWidth: 18.0),
              height: 18.0,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(DSShape.pill),
                border: Border.all(
                  color: theme.secondaryBackground,
                  width: 2.0,
                ),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: theme.labelSmall.copyWith(
                  color: theme.info,
                  fontSize: 10.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Search row from the Expeditoo home screen: a filled rounded field with a
/// leading magnifier and an inline submit label, plus a detached square filter
/// button beside it.
class DSSearchBar extends StatelessWidget {
  const DSSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Rechercher…',
    this.submitLabel = 'Rechercher',
    this.onSubmitted,
    this.onChanged,
    this.onFilterTap,
    this.focusNode,
  });

  final TextEditingController controller;
  final String hintText;
  final String submitLabel;
  final ValueChanged<String>? onSubmitted;

  /// Fires on every keystroke. Callers that want as-you-type results debounce
  /// here; the submit button stays available either way.
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52.0,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: theme.accent1,
              borderRadius: BorderRadius.circular(DSShape.card),
              border: Border.all(
                color: theme.alternate,
                width: DSShape.borderWidth,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20.0,
                  color: theme.secondaryText,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    textInputAction: TextInputAction.search,
                    style: theme.bodyMedium,
                    cursorColor: theme.primary,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      hintText: hintText,
                      hintStyle: theme.labelMedium,
                    ),
                  ),
                ),
                if (onSubmitted != null)
                  TextButton(
                    onPressed: () => onSubmitted!(controller.text),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      submitLabel,
                      style: theme.labelMedium.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: 12.0),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFilterTap,
              borderRadius: BorderRadius.circular(DSShape.card),
              child: Container(
                width: 52.0,
                height: 52.0,
                decoration: BoxDecoration(
                  color: theme.secondaryBackground,
                  borderRadius: BorderRadius.circular(DSShape.card),
                  border: Border.all(
                    color: theme.alternate,
                    width: DSShape.borderWidth,
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 20.0,
                  color: theme.primaryText,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The pill tab switcher used for "J'expédie / Je transporte / Enchères".
class DSSegmentedControl extends StatelessWidget {
  const DSSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<DSSegment> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: theme.accent1,
        borderRadius: BorderRadius.circular(DSShape.pill),
        border: Border.all(color: theme.alternate, width: DSShape.borderWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < segments.length; i++)
            _segment(context, theme, i),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, FlutterFlowTheme theme, int index) {
    final segment = segments[index];
    final selected = index == selectedIndex;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(index),
        borderRadius: BorderRadius.circular(DSShape.pill),
        child: AnimatedContainer(
          duration: DSMotion.duration,
          curve: DSMotion.curve,
          padding: const EdgeInsets.symmetric(
            horizontal: 18.0,
            vertical: 10.0,
          ),
          decoration: BoxDecoration(
            color: selected ? theme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(DSShape.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (segment.icon != null) ...[
                Icon(
                  segment.icon,
                  size: 16.0,
                  color: selected ? theme.info : theme.secondaryText,
                ),
                const SizedBox(width: 6.0),
              ],
              Text(
                segment.label,
                style: theme.labelMedium.copyWith(
                  color: selected ? theme.info : theme.secondaryText,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DSSegment {
  const DSSegment({required this.label, this.icon});

  final String label;
  final IconData? icon;
}
