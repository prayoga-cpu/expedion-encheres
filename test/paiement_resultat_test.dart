// Widget + routing tests for the post-Checkout landing pages that Stripe
// redirects back into (`/success` and `/cancel`).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expedion_encheres/active_p_a_g_e_s/paiement_resultat/paiement_success_widget.dart';
import 'package:expedion_encheres/active_p_a_g_e_s/paiement_resultat/paiement_cancel_widget.dart';

void main() {
  setUpAll(() {
    // Keep tests offline: don't let google_fonts try to fetch fonts.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('success page shows confirmation and the session reference',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PaiementSuccessWidget(sessionId: 'cs_test_123'),
    ));

    expect(find.text('Paiement réussi'), findsOneWidget);
    expect(find.text('Référence : cs_test_123'), findsOneWidget);
    expect(find.text('Retour à mes devis'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('success page hides the reference when no session id is given',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PaiementSuccessWidget(),
    ));

    expect(find.text('Paiement réussi'), findsOneWidget);
    expect(find.textContaining('Référence :'), findsNothing);
  });

  testWidgets('with no recordId, the page does NOT attempt to mark paid',
      (tester) async {
    var called = false;
    await tester.pumpWidget(MaterialApp(
      home: PaiementSuccessWidget(
        sessionId: 'cs_test_1',
        markQuotePaid: (_) async {
          called = true;
          return true;
        },
      ),
    ));
    await tester.pump();

    expect(called, isFalse);
    expect(find.textContaining('Mise à jour'), findsNothing);
  });

  testWidgets('with a recordId, the page marks the quote paid and confirms',
      (tester) async {
    final completer = Completer<bool>();
    String? markedId;
    await tester.pumpWidget(MaterialApp(
      home: PaiementSuccessWidget(
        recordId: 'recABC123',
        markQuotePaid: (id) {
          markedId = id;
          return completer.future;
        },
      ),
    ));

    // While the call is in flight, the "updating" state is shown.
    await tester.pump();
    expect(find.textContaining('Mise à jour du statut'), findsOneWidget);

    // Resolve the mark-paid call → confirmation state.
    completer.complete(true);
    await tester.pumpAndSettle();
    expect(markedId, 'recABC123');
    expect(find.text('Votre devis est confirmé comme payé.'), findsOneWidget);
  });

  testWidgets('an unconfirmed payment says so rather than claiming success',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PaiementSuccessWidget(
        recordId: 'recABC123',
        markQuotePaid: (_) async => false,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Paiement réussi'), findsOneWidget);
    // The page used to assert "Paiement reçu" here, which it does not know:
    // confirmation failing is exactly the case where the payment may not have
    // gone through. Since the unverified client-side fallback was removed, the
    // only honest thing to report is that it is unconfirmed.
    expect(find.textContaining('pas encore pu confirmer'), findsOneWidget);
    expect(find.textContaining('Paiement reçu.'), findsNothing);
  });

  testWidgets('cancel page shows the cancellation message', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PaiementCancelWidget(),
    ));

    expect(find.text('Paiement annulé'), findsOneWidget);
    expect(find.text('Retour à mes devis'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
  });

  testWidgets(
      '/success route parses session_id and the back button navigates to MES-DEVIS',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/success?session_id=cs_abc',
      routes: [
        GoRoute(
          path: '/success',
          builder: (context, state) => PaiementSuccessWidget(
            sessionId: state.uri.queryParameters['session_id'],
          ),
        ),
        GoRoute(
          path: '/cancel',
          builder: (context, state) => const PaiementCancelWidget(),
        ),
        // The result pages navigate via context.goNamed(MesDevisWidget.routeName),
        // whose value is the literal 'MES-DEVIS'.
        GoRoute(
          name: 'MES-DEVIS',
          path: '/mesDevis',
          builder: (context, state) =>
              const Scaffold(body: Text('mes devis stub')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Paiement réussi'), findsOneWidget);
    expect(find.text('Référence : cs_abc'), findsOneWidget);

    await tester.tap(find.text('Retour à mes devis'));
    await tester.pumpAndSettle();

    expect(find.text('mes devis stub'), findsOneWidget);
  });
}
