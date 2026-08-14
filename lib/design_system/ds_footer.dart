import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_tokens.dart';

/// One link inside a footer column.
class DSFooterLink {
  const DSFooterLink({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

/// A titled column of links.
class DSFooterColumn {
  const DSFooterColumn({required this.title, required this.links});

  final String title;
  final List<DSFooterLink> links;
}

/// A contact entry or social handle in the bottom bar.
class DSFooterContact {
  const DSFooterContact({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

/// The site footer, matching the Expeditoo landing page.
///
/// Columns of links across the top, then a hairline rule, then a bottom bar
/// carrying contact details on the left and social icons on the right, and
/// finally the centred copyright line.
///
/// Columns reflow to two-up and then one-up as the viewport narrows, rather
/// than being duplicated per breakpoint.
class DSFooter extends StatelessWidget {
  const DSFooter({
    super.key,
    required this.columns,
    this.contacts = const [],
    this.socials = const [],
    this.copyright,
    this.brand,
    this.tagline,
  });

  final List<DSFooterColumn> columns;
  final List<DSFooterContact> contacts;
  final List<DSFooterContact> socials;
  final String? copyright;

  /// Optional wordmark block shown ahead of the columns on wide screens.
  final String? brand;
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final columnCount = width >= 900.0
        ? columns.length
        : (width >= 560.0 ? 2 : 1);

    return Container(
      width: double.infinity,
      color: theme.secondaryBackground,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (brand != null) ...[
                Text(
                  brand!,
                  style: theme.titleLarge.copyWith(
                    color: theme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                if (tagline != null) ...[
                  const SizedBox(height: 6.0),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420.0),
                    child: Text(tagline!, style: theme.labelSmall),
                  ),
                ],
                const SizedBox(height: 32.0),
              ],
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 24.0;
                  final tileWidth = (constraints.maxWidth -
                          gap * (columnCount - 1)) /
                      columnCount;
                  return Wrap(
                    spacing: gap,
                    runSpacing: 32.0,
                    children: [
                      for (final column in columns)
                        SizedBox(
                          width: tileWidth,
                          child: _column(theme, column),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40.0),
              Container(height: 1.0, color: theme.alternate),
              const SizedBox(height: 20.0),
              _bottomBar(context, theme, width),
              if (copyright != null) ...[
                const SizedBox(height: 20.0),
                Center(
                  child: Text(
                    copyright!,
                    textAlign: TextAlign.center,
                    style: theme.labelSmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _column(FlutterFlowTheme theme, DSFooterColumn column) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            column.title,
            style: theme.labelMedium.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14.0),
          for (final link in column.links)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _FooterLinkText(link: link),
            ),
        ],
      );

  Widget _bottomBar(
    BuildContext context,
    FlutterFlowTheme theme,
    double width,
  ) {
    final contactRow = Wrap(
      spacing: 20.0,
      runSpacing: 8.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final c in contacts)
          InkWell(
            onTap: c.onTap,
            borderRadius: BorderRadius.circular(DSShape.small),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c.icon, size: 14.0, color: theme.secondaryText),
                const SizedBox(width: 6.0),
                Text(c.label, style: theme.labelSmall),
              ],
            ),
          ),
      ],
    );

    final socialRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in socials)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Tooltip(
              message: s.label,
              child: InkWell(
                onTap: s.onTap,
                borderRadius: BorderRadius.circular(DSShape.small),
                child: Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DSShape.small),
                    border: Border.all(
                      color: theme.alternate,
                      width: DSShape.borderWidth,
                    ),
                  ),
                  child: Icon(
                    s.icon,
                    size: 15.0,
                    color: theme.secondaryText,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    // Side by side while there is room; stacked once there is not.
    if (width < 640.0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          contactRow,
          const SizedBox(height: 16.0),
          socialRow,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: contactRow),
        socialRow,
      ],
    );
  }
}

class _FooterLinkText extends StatefulWidget {
  const _FooterLinkText({required this.link});

  final DSFooterLink link;

  @override
  State<_FooterLinkText> createState() => _FooterLinkTextState();
}

class _FooterLinkTextState extends State<_FooterLinkText> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return MouseRegion(
      cursor: widget.link.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.link.onTap,
        child: AnimatedDefaultTextStyle(
          duration: DSMotion.duration,
          curve: DSMotion.curve,
          style: theme.labelSmall.copyWith(
            color: _hovered ? theme.primary : theme.secondaryText,
            fontSize: 13.0,
          ),
          child: Text(widget.link.label),
        ),
      ),
    );
  }
}
