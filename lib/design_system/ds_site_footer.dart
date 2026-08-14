import 'package:flutter/material.dart';

import 'ds_logo.dart';
import 'ds_palette.dart';

/// One labelled column of footer links.
class XpdFooterColumn {
  const XpdFooterColumn({required this.title, required this.links});
  final String title;
  final List<XpdFooterLink> links;
}

class XpdFooterLink {
  const XpdFooterLink({required this.label, this.onTap});
  final String label;

  /// A null [onTap] renders plain text rather than a dead link — the legal
  /// pages do not exist yet and the design should not promise them.
  final VoidCallback? onTap;
}

/// The site footer: a brand column, three link columns, and a rule above the
/// copyright line with the two group swatches on the right.
class XpdFooter extends StatelessWidget {
  const XpdFooter({
    super.key,
    required this.tagline,
    required this.domain,
    required this.columns,
    required this.copyright,
    required this.groupNote,
  });

  final String tagline;
  final String domain;
  final List<XpdFooterColumn> columns;
  final String copyright;
  final String groupNote;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = XpdLayout.gutterFor(width);
    final stack = width < XpdLayout.desktop;

    final brandColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const XpdLogo(markSize: 28.0),
        const SizedBox(height: 16.0),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280.0),
          child: Text(
            tagline,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14.0,
              height: 1.6,
              color: palette.muted,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          domain,
          style: TextStyle(
            fontFamily: 'Geist Mono',
            fontSize: 11.0,
            letterSpacing: 11.0 * 0.14,
            color: palette.faint,
          ),
        ),
      ],
    );

    Widget linkColumn(XpdFooterColumn column) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              column.title,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 12.0),
            for (final link in column.links)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _FooterLink(link: link),
              ),
          ],
        );

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: stack ? 64.0 : XpdLayout.sectionGap),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.line)),
      ),
      padding: EdgeInsets.fromLTRB(gutter, 56.0, gutter, 40.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: XpdLayout.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stack)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    brandColumn,
                    const SizedBox(height: 32.0),
                    Wrap(
                      spacing: 48.0,
                      runSpacing: 32.0,
                      children: [for (final c in columns) linkColumn(c)],
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // `grid-template-columns:1.4fr 1fr 1fr 1fr`
                    Expanded(flex: 14, child: brandColumn),
                    const SizedBox(width: 32.0),
                    for (final column in columns) ...[
                      Expanded(flex: 10, child: linkColumn(column)),
                      if (column != columns.last) const SizedBox(width: 32.0),
                    ],
                  ],
                ),
              const SizedBox(height: 44.0),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: palette.line)),
                ),
                padding: const EdgeInsets.only(top: 28.0),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 24.0,
                  runSpacing: 16.0,
                  children: [
                    Text(
                      copyright,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13.0,
                        color: palette.faint,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            groupNote,
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 13.0,
                              color: palette.faint,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        const _Swatch(color: XpdPalette.brandAmber),
                        const SizedBox(width: 10.0),
                        const _Swatch(color: XpdPalette.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 16.0,
        height: 16.0,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5.0),
        ),
      );
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({required this.link});
  final XpdFooterLink link;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    final interactive = widget.link.onTap != null;
    final text = Text(
      widget.link.label,
      style: TextStyle(
        fontFamily: 'Geist',
        fontSize: 14.0,
        color: _hovered && interactive ? palette.blueLink : palette.muted,
      ),
    );

    if (!interactive) return text;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.link.onTap, child: text),
    );
  }
}
