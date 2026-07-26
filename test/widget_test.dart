// Smoke test.
//
// The default FlutterFlow smoke test pumped `MyApp()`, which requires Firebase
// to be initialized and therefore fails under `flutter test`. It is replaced
// here with a lightweight render check of a page that has no backend
// dependencies. See paiement_amount_test.dart and paiement_resultat_test.dart
// for the payment-flow coverage.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expedion_encheres/active_p_a_g_e_s/paiement_resultat/paiement_success_widget.dart';

void main() {
  testWidgets('Payment success page renders', (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(const MaterialApp(home: PaiementSuccessWidget()));

    expect(find.text('Paiement réussi'), findsOneWidget);
  });
}
