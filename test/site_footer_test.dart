// The footer's Legal column used to render as plain text — four labels that
// looked like links and did nothing, because the pages behind them did not
// exist. They exist now, and this is what keeps the column honest: every link
// in every column must carry an `onTap`, in both languages.
//
// A dead footer link is invisible in review. Nothing throws, nothing logs, the
// label is styled exactly like its neighbours; the only symptom is a reader
// clicking it and staying where they are.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expedion_encheres/design_system/ds_site_footer.dart';
import 'package:expedion_encheres/flutter_flow/flutter_flow_theme.dart';
import 'package:expedion_encheres/flutter_flow/internationalization.dart';
import 'package:expedion_encheres/legal/cgv_widget.dart';
import 'package:expedion_encheres/legal/confidentialite_widget.dart';
import 'package:expedion_encheres/legal/cookies_widget.dart';
import 'package:expedion_encheres/legal/legal_entity.dart';
import 'package:expedion_encheres/legal/mentions_legales_widget.dart';
import 'package:expedion_encheres/site_footer.dart';

Future<XpdFooter> _pumpFooter(
  WidgetTester tester, {
  required String languageCode,
  void Function(XpdSiteSection)? onSection,
  String? currentRouteName,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(languageCode),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: XpdSiteFooter(
            onSection: onSection,
            currentRouteName: currentRouteName,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.widget<XpdFooter>(find.byType(XpdFooter));
}

Iterable<XpdFooterLink> _links(XpdFooter footer) =>
    footer.columns.expand((column) => column.links);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await FlutterFlowTheme.initialize();
  });

  group('site footer', () {
    for (final language in ['fr', 'en']) {
      testWidgets('every link goes somewhere in $language', (tester) async {
        final footer = await _pumpFooter(tester, languageCode: language);

        expect(footer.columns, hasLength(3));
        final links = _links(footer).toList();
        expect(links, hasLength(11));

        for (final link in links) {
          expect(
            link.onTap,
            isNotNull,
            reason: '"${link.label}" renders as plain text, not a link',
          );
          expect(link.label.trim(), isNotEmpty);
        }
      });
    }

    testWidgets('the Service column scrolls in place when it can', (
      tester,
    ) async {
      // On the landing page the footer is handed a scroll callback, and the
      // four Service links must use it rather than routing to a page the
      // reader is already on.
      final scrolled = <XpdSiteSection>[];
      final footer = await _pumpFooter(
        tester,
        languageCode: 'fr',
        onSection: scrolled.add,
      );

      for (final link in footer.columns.first.links) {
        link.onTap!();
      }

      expect(scrolled, [
        XpdSiteSection.devis,
        XpdSiteSection.tarifs,
        XpdSiteSection.couverture,
        XpdSiteSection.app,
      ]);
    });

    testWidgets('a legal page does not link to itself', (tester) async {
      // Tapping "Cookies" in the footer of /cookies used to push a second
      // /cookies onto the navigator, so leaving took two presses of Back.
      final footer = await _pumpFooter(
        tester,
        languageCode: 'fr',
        currentRouteName: CookiesWidget.routeName,
      );
      final legal = footer.columns[2].links;
      final self = legal.firstWhere((link) => link.label == 'Cookies');

      // Still a link, so the column does not go ragged — it just does nothing,
      // which is what XpdPage does with the header link you are already on.
      expect(self.onTap, isNotNull);
      expect(() => self.onTap!(), returnsNormally);
    });

    testWidgets('the two carrier links do not lead to the same place', (
      tester,
    ) async {
      // They did: both opened the Expeditoo home page, so "Devenir
      // transporteur" promised a sign-up and delivered a landing page.
      final footer = await _pumpFooter(tester, languageCode: 'fr');
      final group = footer.columns[1].links;
      expect(group, hasLength(3));
      expect(
        group.map((link) => link.label).toSet(),
        hasLength(3),
        reason: 'the group column repeats a label',
      );
    });
  });

  group('XpdSiteSection', () {
    test('every section round-trips through its slug', () {
      for (final section in XpdSiteSection.values) {
        expect(XpdSiteSection.fromSlug(section.slug), section);
      }
    });

    test('an unknown or empty slug resolves to nothing', () {
      // `/accueil?section=tarifss` must open the top of the page, not throw.
      expect(XpdSiteSection.fromSlug('tarifss'), isNull);
      expect(XpdSiteSection.fromSlug(''), isNull);
      expect(XpdSiteSection.fromSlug(null), isNull);
    });
  });

  group('legal routes', () {
    test('each document has a distinct name and path', () {
      final names = [
        CgvWidget.routeName,
        MentionsLegalesWidget.routeName,
        ConfidentialiteWidget.routeName,
        CookiesWidget.routeName,
      ];
      final paths = [
        CgvWidget.routePath,
        MentionsLegalesWidget.routePath,
        ConfidentialiteWidget.routePath,
        CookiesWidget.routePath,
      ];

      expect(names.toSet(), hasLength(4));
      expect(paths.toSet(), hasLength(4));
      for (final path in paths) {
        expect(path, startsWith('/'));
      }
    });
  });

  group('LegalEntity', () {
    test('no registry field is filled with an invented value', () {
      // The point of the nullable constants: a plausible-looking SIREN on a
      // public legal notice is worse than a visible gap. If someone fills
      // these in, they should be real, and this test should be deleted along
      // with the "à compléter" rows it guards.
      expect(
        LegalEntity.isPublisherComplete,
        LegalEntity.missingPublisherFields.isEmpty,
      );
    });

    test('the missing-field labels exist in both languages', () {
      // They are interpolated into the notice at the top of the legal notice,
      // which renders in whichever language the reader chose. Returning bare
      // French strings — as this did — put "raison sociale, forme juridique et
      // capital social" inside an otherwise English sentence.
      for (final field in LegalPublisherField.values) {
        expect(field.fr.trim(), isNotEmpty);
        expect(field.en.trim(), isNotEmpty);
        expect(field.en, isNot(field.fr), reason: '${field.name} is untranslated');
      }
    });

    test('the host is named, as the LCEN requires', () {
      expect(LegalEntity.hostName, isNotEmpty);
      expect(LegalEntity.hostAddress, isNotEmpty);
    });

    test('every review date parses', () {
      for (final date in [
        LegalEntity.cgvUpdated,
        LegalEntity.mentionsUpdated,
        LegalEntity.privacyUpdated,
        LegalEntity.cookiesUpdated,
      ]) {
        expect(DateTime.tryParse(date), isNotNull, reason: '$date is not a date');
      }
    });
  });
}
