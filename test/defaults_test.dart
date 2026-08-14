// The app's two "what happens on a fresh install" decisions.
//
// Both are one-line defaults that nothing else fails loudly about: a theme that
// silently stops following the OS, or a language that silently starts following
// it, would both look like ordinary behaviour to anyone who did not already
// know which was intended. So they are pinned here.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expedion_encheres/flutter_flow/flutter_flow_theme.dart';
import 'package:expedion_encheres/flutter_flow/internationalization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('theme follows the device until told otherwise', () {
    test('a fresh install is ThemeMode.system', () async {
      SharedPreferences.setMockInitialValues({});
      await FlutterFlowTheme.initialize();

      expect(FlutterFlowTheme.themeMode, ThemeMode.system);
    });

    test('an explicit choice is honoured', () async {
      SharedPreferences.setMockInitialValues({'__theme_mode__': true});
      await FlutterFlowTheme.initialize();
      expect(FlutterFlowTheme.themeMode, ThemeMode.dark);

      SharedPreferences.setMockInitialValues({'__theme_mode__': false});
      await FlutterFlowTheme.initialize();
      expect(FlutterFlowTheme.themeMode, ThemeMode.light);
    });

    test('choosing System clears the stored preference rather than storing one',
        () async {
      SharedPreferences.setMockInitialValues({'__theme_mode__': true});
      await FlutterFlowTheme.initialize();
      expect(FlutterFlowTheme.themeMode, ThemeMode.dark);

      FlutterFlowTheme.saveThemeMode(ThemeMode.system);
      // Re-reading proves it went back to "no opinion", not to a stored light.
      expect(FlutterFlowTheme.themeMode, ThemeMode.system);
    });

    test('a round trip through every mode lands where it started', () async {
      SharedPreferences.setMockInitialValues({});
      await FlutterFlowTheme.initialize();

      for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.system]) {
        FlutterFlowTheme.saveThemeMode(mode);
        expect(FlutterFlowTheme.themeMode, mode,
            reason: '$mode should persist');
      }
    });
  });

  group('language is French by default, whatever the device says', () {
    test('the default locale is French', () {
      expect(kDefaultLocale, const Locale('fr'));
    });

    test('a fresh install has stored nothing, so the default applies',
        () async {
      SharedPreferences.setMockInitialValues({});
      await FFLocalizations.initialize();

      expect(FFLocalizations.getStoredLocale(), isNull);
      // This is the expression `main.dart` uses to seed `_locale`. It must not
      // be null: a null `locale` hands resolution to MaterialApp, which would
      // match the device and open an English phone in English.
      expect(FFLocalizations.getStoredLocale() ?? kDefaultLocale,
          const Locale('fr'));
    });

    test('an explicit switch is remembered across a restart', () async {
      SharedPreferences.setMockInitialValues({});
      await FFLocalizations.initialize();

      await FFLocalizations.storeLocale('en');
      expect(FFLocalizations.getStoredLocale(), const Locale('en'));

      await FFLocalizations.storeLocale('fr');
      expect(FFLocalizations.getStoredLocale(), const Locale('fr'));
    });

    test('French is also the fallback for an untranslated device locale', () {
      // MaterialApp resolves an unsupported locale to supportedLocales.first,
      // so the default and the fallback have to be the same entry.
      expect(FFLocalizations.languages().first, kDefaultLocale.languageCode);
    });
  });
}
