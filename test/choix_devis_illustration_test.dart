// The quote-type illustrations are drawn, not shipped as assets, so nothing
// but a render would catch a bad Path or a division by zero in the scaling.
//
// They are also the only artwork in the app that has to work in both themes,
// which is exactly the kind of thing that gets broken by a token rename.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expedion_encheres/active_p_a_g_e_s/choix_devis/choix_devis_illustrations.dart';
import 'package:expedion_encheres/flutter_flow/flutter_flow_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, Brightness brightness, double height) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DevisRouteIllustration(
                  kind: DevisRouteKind.pdfSlip,
                  height: height,
                ),
                DevisRouteIllustration(
                  kind: DevisRouteKind.manualDetails,
                  height: height,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // FlutterFlowTheme reads the saved theme mode out of SharedPreferences,
    // which has no platform implementation under `flutter test`.
    SharedPreferences.setMockInitialValues({});
    await FlutterFlowTheme.initialize();
  });

  testWidgets('both illustrations paint in light and dark', (tester) async {
    for (final brightness in Brightness.values) {
      await _pump(tester, brightness, 132.0);
      await tester.pumpAndSettle();

      expect(find.byType(DevisRouteIllustration), findsNWidgets(2));
      expect(tester.takeException(), isNull,
          reason: 'painting must not throw in ${brightness.name}');
    }
  });

  testWidgets('they survive being squeezed', (tester) async {
    // The card gives them whatever height it has left, and the painter scales
    // off that height — a very small box used to be the obvious way to divide
    // the layout by something near zero.
    for (final height in <double>[8.0, 40.0, 300.0]) {
      await _pump(tester, Brightness.light, height);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'height $height threw');
    }
  });
}
