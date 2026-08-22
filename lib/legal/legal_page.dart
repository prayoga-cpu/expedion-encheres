import 'package:flutter/material.dart';

import '/app_shell.dart';
import '/design_system/ds_l10n.dart';
import '/design_system/ds_palette.dart';
import '/design_system/ds_site.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/site_footer.dart';

/// One `<h2>` and the prose under it.
class LegalSection {
  const LegalSection({
    required this.heading,
    this.paragraphs = const <String>[],
    this.bullets = const <String>[],
    this.rows = const <LegalRow>[],
  });

  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;

  /// Label/value pairs, for the identity and retention tables. A null value
  /// renders as an explicit gap rather than being dropped — see [LegalRow].
  final List<LegalRow> rows;
}

/// A labelled fact. [value] is nullable so a page can show that a mandatory
/// detail is still missing instead of silently leaving the row out, which
/// reads as "this does not apply to us".
class LegalRow {
  const LegalRow(this.label, this.value);

  final String label;
  final String? value;
}

/// The four legal documents identified for cross-linking.
enum LegalDoc { cgv, mentions, confidentialite, cookies }

/// The shared shape of a legal document page.
///
/// Every one is the same thing: a title, the date it was last reviewed, a
/// stack of numbered sections, links to its three siblings, and the site
/// footer — which is also how a reader arrived, so it has to be here or the
/// page is a dead end.
class LegalPageScaffold extends StatelessWidget {
  const LegalPageScaffold({
    super.key,
    required this.doc,
    required this.eyebrow,
    required this.title,
    required this.lead,
    required this.updated,
    required this.sections,
    this.notice,
  });

  final LegalDoc doc;
  final String eyebrow;
  final String title;
  final String lead;

  /// ISO date the document was last reviewed, from [LegalEntity].
  final String updated;
  final List<LegalSection> sections;

  /// An amber panel above the body — used when a document is knowingly
  /// incomplete, so the reader is told rather than misled.
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    String t(String fr, String en) => xpdT(context, fr, en);

    return XpdPage(
      current: XpdDestination.none,
      onBack: () => context.safePop(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            XpdSection(
              top: 56.0,
              maxWidth: XpdLayout.narrowWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  XpdSectionIntro(
                    eyebrow: eyebrow,
                    heading: title,
                    lead: lead,
                    maxWidth: XpdLayout.narrowWidth,
                  ),
                  const SizedBox(height: 18.0),
                  Text(
                    t(
                      'Dernière mise à jour : ${_formatDate(context, updated)}',
                      'Last updated: ${_formatDate(context, updated)}',
                    ),
                    style: TextStyle(
                      fontFamily: 'Geist Mono',
                      fontSize: 11.5,
                      letterSpacing: 11.5 * 0.1,
                      color: palette.faint,
                    ),
                  ),
                  if (notice != null) ...[
                    const SizedBox(height: 28.0),
                    _NoticePanel(message: notice!),
                  ],
                ],
              ),
            ),
            XpdSection(
              top: 44.0,
              bottom: 8.0,
              maxWidth: XpdLayout.narrowWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < sections.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == sections.length - 1 ? 0.0 : 34.0,
                      ),
                      child: _SectionBlock(
                        number: i + 1,
                        section: sections[i],
                      ),
                    ),
                ],
              ),
            ),
            XpdSection(
              top: 52.0,
              maxWidth: XpdLayout.narrowWidth,
              child: _RelatedDocuments(current: doc),
            ),
            XpdSiteFooter(currentRouteName: _routeNameFor(doc)),
          ],
        ),
      ),
    );
  }

  /// `2026-08-22` reads as `22 août 2026` in French and `22 August 2026` in
  /// English.
  ///
  /// Spelled out here rather than through `DateFormat('d MMMM y', 'fr')`,
  /// which needs `initializeDateFormatting` to have run — it happens to have,
  /// via `GlobalMaterialLocalizations`, but a legal page that throws in a
  /// widget test because nobody loaded French month names is not a trade worth
  /// making for twelve words. Falls back to the raw value if a date in
  /// [LegalEntity] is ever mistyped.
  /// The route each document is served at, so the footer below it can tell
  /// which of its four Legal links is the page already open.
  static String _routeNameFor(LegalDoc doc) => switch (doc) {
        LegalDoc.cgv => CgvWidget.routeName,
        LegalDoc.mentions => MentionsLegalesWidget.routeName,
        LegalDoc.confidentialite => ConfidentialiteWidget.routeName,
        LegalDoc.cookies => CookiesWidget.routeName,
      };

  static String _formatDate(BuildContext context, String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    const fr = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    const en = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final month = (xpdIsEnglish(context) ? en : fr)[parsed.month - 1];
    return '${parsed.day} $month ${parsed.year}';
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.number, required this.section});

  final int number;
  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);

    final body = TextStyle(
      fontFamily: 'Geist',
      fontSize: 15.5,
      height: 1.7,
      color: palette.muted,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number. ${section.heading}',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 19.0,
            fontWeight: FontWeight.w600,
            height: 1.35,
            letterSpacing: -0.3,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 12.0),
        for (final paragraph in section.paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(paragraph, style: body),
          ),
        for (final bullet in section.bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 9.0, right: 12.0),
                  child: Container(
                    width: 5.0,
                    height: 5.0,
                    decoration: BoxDecoration(
                      color: palette.dim,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(child: Text(bullet, style: body)),
              ],
            ),
          ),
        if (section.rows.isNotEmpty) ...[
          const SizedBox(height: 4.0),
          XpdPanel(
            padding: const EdgeInsets.symmetric(
              horizontal: 22.0,
              vertical: 6.0,
            ),
            child: Column(
              children: [
                for (final row in section.rows)
                  _RowLine(row: row, last: row == section.rows.last),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RowLine extends StatelessWidget {
  const _RowLine({required this.row, required this.last});

  final LegalRow row;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    final missing = row.value == null || row.value!.isEmpty;
    final stack = MediaQuery.sizeOf(context).width < XpdLayout.tablet;

    final label = Text(
      row.label,
      style: TextStyle(
        fontFamily: 'Geist',
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        height: 1.6,
        color: palette.text,
      ),
    );

    final value = Text(
      missing
          ? xpdT(context, 'À compléter', 'To be completed')
          : row.value!,
      style: TextStyle(
        fontFamily: 'Geist',
        fontSize: 14.0,
        height: 1.6,
        fontStyle: missing ? FontStyle.italic : FontStyle.normal,
        color: missing ? palette.amberText : palette.muted,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.line)),
            ),
      child: stack
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label, const SizedBox(height: 2.0), value],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 230.0, child: label),
                const SizedBox(width: 20.0),
                Expanded(child: value),
              ],
            ),
    );
  }
}

class _NoticePanel extends StatelessWidget {
  const _NoticePanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return XpdPanel(
      // The tinted-panel pair the landing page uses, not `palette.amber`
      // itself — that is the brand hue, and filling a panel with it puts
      // amber text on an amber block.
      background: palette.amberTint(0.12),
      borderColor: palette.amberTint(0.30),
      padding: const EdgeInsets.all(20.0),
      radius: 14.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 19.0,
            color: palette.amberText,
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14.0,
                height: 1.6,
                color: palette.amberSub,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The other three documents, as links.
///
/// A reader who lands on the CGV from a search result has no footer above them
/// and nothing but the browser's back button otherwise; the four documents are
/// read together often enough that each should offer the rest.
class _RelatedDocuments extends StatelessWidget {
  const _RelatedDocuments({required this.current});

  final LegalDoc current;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    String t(String fr, String en) => xpdT(context, fr, en);

    final all = <LegalDoc, ({String label, String route})>{
      LegalDoc.cgv: (
        label: t('Conditions générales de vente', 'Terms & Conditions'),
        route: CgvWidget.routeName,
      ),
      LegalDoc.mentions: (
        label: t('Mentions légales', 'Legal notice'),
        route: MentionsLegalesWidget.routeName,
      ),
      LegalDoc.confidentialite: (
        label: t('Politique de confidentialité', 'Privacy policy'),
        route: ConfidentialiteWidget.routeName,
      ),
      LegalDoc.cookies: (
        label: t('Cookies', 'Cookies'),
        route: CookiesWidget.routeName,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.line)),
      ),
      padding: const EdgeInsets.only(top: 26.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          XpdEyebrow(t('AUTRES DOCUMENTS', 'OTHER DOCUMENTS')),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 26.0,
            runSpacing: 12.0,
            children: [
              for (final entry in all.entries)
                if (entry.key != current)
                  XpdLink(
                    label: entry.value.label,
                    // `pushNamed` rather than `go` so the browser's back
                    // button still returns to whatever page linked here.
                    onTap: () => context.pushNamed(entry.value.route),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
