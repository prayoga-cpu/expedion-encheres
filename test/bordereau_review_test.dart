// Renders the four states of the bordereau gate.
//
// The verdict itself is unit-tested in `bordereau_check_test.dart`; what
// matters here is that the client is never left facing a disabled button with
// nothing to read. Each state has to say something, and the two that block —
// no file, and a refused file — have to offer the way out: the standard,
// written down.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expedion_encheres/active_p_a_g_e_s/formulaire_de_devis_par_bordereau/bordereau_review.dart';
import 'package:expedion_encheres/backend/bordereau_check.dart';
import 'package:expedion_encheres/backend/expedion_api/expedion_quote.dart';
import 'package:expedion_encheres/flutter_flow/flutter_flow_theme.dart';
import 'package:expedion_encheres/flutter_flow/internationalization.dart';

Future<void> _pump(WidgetTester tester, Widget child, {String locale = 'fr'}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

BordereauCheck _validCheck() => BordereauCheck.evaluate({
      'bordereauNumber': '2024-0187',
      'auctionHouseName': 'Yssoire Enchères',
      'pickupAddress': '12 rue des Ventes',
      'pickupCity': 'Issoire',
      'lotDescription': 'Commode Louis XV',
      'declaredValueEur': 4200.50,
      'confidence': 0.92,
    });

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await FlutterFlowTheme.initialize();
  });

  testWidgets('with no file attached it says the slip is required',
      (tester) async {
    await _pump(tester, const BordereauMissingHint(uploadFailed: false));
    expect(find.textContaining('obligatoire'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pick that never reached storage says so, not "required"',
      (tester) async {
    await _pump(tester, const BordereauMissingHint(uploadFailed: true));
    expect(find.textContaining("L'envoi du fichier a échoué"), findsOneWidget);
  });

  testWidgets('an idle check renders nothing at all', (tester) async {
    await _pump(
      tester,
      const BordereauReviewPanel(
        check: BordereauCheck.idle(),
        onRetry: null,
      ),
    );
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('a read in flight shows progress', (tester) async {
    await _pump(
      tester,
      const BordereauReviewPanel(
        check: BordereauCheck.checking(),
        onRetry: null,
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Lecture du bordereau'), findsOneWidget);
  });

  testWidgets('a valid slip previews the fields it read', (tester) async {
    await _pump(
      tester,
      BordereauReviewPanel(check: _validCheck(), onRetry: () {}),
    );

    expect(find.text('Bordereau reconnu'), findsOneWidget);
    expect(find.text('2024-0187'), findsOneWidget);
    expect(find.text('Yssoire Enchères'), findsOneWidget);
    expect(find.text('Issoire'), findsOneWidget);
    // Written by the app's own formatter, so the total reads exactly as it
    // will on the devis and the payments page.
    expect(find.text(formatCents(420050)), findsOneWidget);
  });

  testWidgets('the preview names what still has to be filled in',
      (tester) async {
    await _pump(
      tester,
      BordereauReviewPanel(check: _validCheck(), onRetry: () {}),
    );
    // Dimensions and weight are not on this slip and are not required, so they
    // must read as the next step rather than as a fault.
    expect(find.textContaining('À compléter'), findsOneWidget);
    expect(find.textContaining('poids'), findsOneWidget);
  });

  testWidgets('a refused slip names the missing field', (tester) async {
    final check = BordereauCheck.evaluate({
      'bordereauNumber': '2024-0187',
      'auctionHouseName': 'Yssoire Enchères',
      'pickupCity': 'Issoire',
      'lotDescription': 'Commode Louis XV',
      'declaredValueEur': null,
      'confidence': 0.9,
    });

    await _pump(tester, BordereauReviewPanel(check: check, onRetry: () {}));
    expect(find.text('Document non valide'), findsOneWidget);
    expect(find.textContaining('montant total ttc'), findsOneWidget);
  });

  testWidgets('a document with nothing on it reads as the wrong file',
      (tester) async {
    final check = BordereauCheck.evaluate({'confidence': 0.9});
    await _pump(tester, BordereauReviewPanel(check: check, onRetry: () {}));
    expect(
      find.textContaining("ne ressemble pas à un bordereau"),
      findsOneWidget,
    );
  });

  testWidgets('a file refused before the network keeps its own reason',
      (tester) async {
    const check = BordereauCheck.rejected(
      reasonFr: 'Format non accepté.',
      reasonEn: 'Unsupported format.',
    );
    await _pump(tester, const BordereauReviewPanel(check: check, onRetry: null));
    expect(find.text('Format non accepté.'), findsOneWidget);
    // Nothing to re-read, so no retry is offered.
    expect(find.textContaining('Réessayer'), findsNothing);
  });

  testWidgets('the refusal opens the standard', (tester) async {
    final check = BordereauCheck.evaluate({'confidence': 0.9});
    await _pump(tester, BordereauReviewPanel(check: check, onRetry: () {}));

    await tester.tap(find.textContaining("Qu'est-ce qu'un bordereau valide"));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Le bordereau attendu'), findsOneWidget);
    // Every requirement the button is gated on is printed, so the dialog and
    // the gate cannot disagree.
    for (final field in kBordereauRequiredFields) {
      expect(find.text(field.labelFr), findsOneWidget,
          reason: '${field.key} is gated on but not documented');
    }
  });

  testWidgets('retry re-runs the read on the file already attached',
      (tester) async {
    var retries = 0;
    final check = BordereauCheck.evaluate({'confidence': 0.9});
    await _pump(
      tester,
      BordereauReviewPanel(check: check, onRetry: () => retries++),
    );

    await tester.tap(find.textContaining('Réessayer'));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('a check we could not run does not block, and says why',
      (tester) async {
    // One unset OPENAI_API_KEY must not take the whole quote funnel down.
    final check = await BordereauCheck.run(
      bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0, 0, 0, 0]),
      filename: 'slip.pdf',
    );
    expect(check.status, BordereauCheckStatus.unavailable,
        reason: 'no API credentials under `flutter test`');
    expect(check.blocksSubmit, isFalse);

    await _pump(tester, BordereauReviewPanel(check: check, onRetry: () {}));
    expect(find.text('Vérification automatique indisponible'), findsOneWidget);
    expect(find.textContaining('Vous pouvez envoyer votre demande'),
        findsOneWidget);
  });

  testWidgets('every state reads in English under the English toggle',
      (tester) async {
    await _pump(
      tester,
      BordereauReviewPanel(check: _validCheck(), onRetry: () {}),
      locale: 'en',
    );
    expect(find.text('Slip recognised'), findsOneWidget);
    expect(find.textContaining('To complete at the next step'), findsOneWidget);

    await _pump(
      tester,
      const BordereauMissingHint(uploadFailed: false),
      locale: 'en',
    );
    expect(find.textContaining('required before the request'), findsOneWidget);
  });
}
