// The landing page's two quote forms, and the handover they exist to make.
//
// Neither form files a quote. Both park a `QuoteDraft` that the real devis
// form seeds from, which is why the interesting failures here are quiet ones:
// a delivery line with no postcode in it reaches the devis form as a town and
// an empty field, an oversized slip fails in an upload two screens later, and
// a draft that only lives in memory is lost by the very sign-in detour the
// page sends people on.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expedion_encheres/backend/quote_draft.dart';
import 'package:expedion_encheres/backend/quote_form_rules.dart';
import 'package:expedion_encheres/flutter_flow/upload_data.dart';
import 'package:expedion_encheres/design_system/ds_form_feedback.dart';
import 'package:expedion_encheres/design_system/ds_site.dart';

/// What `QuoteDraft` asks for...
const _prefsKey = 'expedion.landingQuoteDraft';

/// ...and the namespaced form `shared_preferences` actually stores it under,
/// which is what `setMockInitialValues` seeds. Reading back through the plugin
/// uses the plain key; seeding the store behind it uses this one.
const _storedKey = 'flutter.$_prefsKey';

Future<void> _pumpThemed(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    QuoteDraft.clear();
  });

  // ==========================================================================
  // What the forms accept
  // ==========================================================================

  group('the pickup line', () {
    test('is required, and has to name something', () {
      expect(QuoteFormRules.isPickupLine(''), isFalse);
      expect(QuoteFormRules.isPickupLine('   '), isFalse);
      expect(QuoteFormRules.isPickupLine('D'), isFalse);
      expect(QuoteFormRules.isPickupLine('Drouot, Paris 9e'), isTrue);
    });
  });

  group('the delivery line', () {
    test('has to carry a postcode, in either order', () {
      expect(QuoteFormRules.isDeliveryLine('33000 Bordeaux'), isTrue);
      expect(QuoteFormRules.isDeliveryLine('Bordeaux 33000'), isTrue);
    });

    // The reason the rule exists: `deliveryParts` splits on the postcode, so a
    // town on its own arrives at the devis form as a blank postcode field —
    // which is one of Expeditoo's escalation blockers, reached without anyone
    // being told.
    test('refuses a town on its own, because the split needs the digits', () {
      expect(QuoteFormRules.isDeliveryLine('Bordeaux'), isFalse);
      expect(QuoteFormRules.isDeliveryLine(''), isFalse);

      const parsed = QuoteDraft(delivery: 'Bordeaux');
      expect(parsed.deliveryParts.postcode, isEmpty);
    });

    test('a line the rule accepts is one the devis form can split', () {
      const draft = QuoteDraft(delivery: '33000 Bordeaux');
      expect(draft.deliveryParts.postcode, '33000');
      expect(draft.deliveryParts.city, 'Bordeaux');
    });
  });

  group('the email', () {
    test('is required, and has to look like an address', () {
      expect(QuoteFormRules.isEmail(''), isFalse);
      expect(QuoteFormRules.isEmail('vous'), isFalse);
      expect(QuoteFormRules.isEmail('vous@exemple'), isFalse);
      expect(QuoteFormRules.isEmail('vous@exemple.fr'), isTrue);
      expect(QuoteFormRules.isEmail('  vous@exemple.fr '), isTrue);
    });
  });

  group('the optional fields', () {
    // Empty is the whole point of optional; wrong is not, because a wrong
    // answer is carried into the devis form as though it had been checked.
    test('pass when blank', () {
      expect(QuoteFormRules.isLotCount(''), isTrue);
      expect(QuoteFormRules.isHammerPrice('  '), isTrue);
      expect(QuoteFormRules.isPickupDeadline(''), isTrue);
      expect(QuoteFormRules.isPhone(''), isTrue);
    });

    test('but are held to their shape when filled', () {
      expect(QuoteFormRules.isLotCount('0'), isFalse);
      expect(QuoteFormRules.isLotCount('deux'), isFalse);
      expect(QuoteFormRules.isLotCount('100'), isFalse);
      expect(QuoteFormRules.isLotCount('2'), isTrue);

      expect(QuoteFormRules.isPickupDeadline('bientôt'), isFalse);
      expect(QuoteFormRules.isPickupDeadline('22 / 08 / 2026'), isTrue);
      expect(QuoteFormRules.isPickupDeadline('22-08-2026'), isTrue);
    });

    // The landing page must not accept a price the devis form would reject:
    // both read it through `euroToCents`, so every spelling that parses here
    // parses there.
    test('the hammer price is read exactly as the devis form reads it', () {
      for (final written in ['4 200 €', '4200', '4 200,50', '4.200']) {
        expect(QuoteFormRules.isHammerPrice(written), isTrue,
            reason: '"$written" is a price a client actually types');
        expect(QuoteFormRules.euroToCents(written), isNotNull);
      }
      expect(QuoteFormRules.isHammerPrice('quatre mille'), isFalse);
    });
  });

  test('the upload cap is the one the caption promises', () {
    expect(QuoteFormRules.maxUploadBytes, 10 * 1024 * 1024);
  });

  // ==========================================================================
  // The handover
  // ==========================================================================

  group('a parked draft', () {
    test('survives the reload the sign-in detour can cause', () async {
      QuoteDraft.stage(const QuoteDraft(
        pickup: 'Drouot, Paris 9e',
        delivery: '33000 Bordeaux',
        email: 'vous@exemple.fr',
      ));
      await QuoteDraft.settled;

      // Whatever the tab did in between, the next run starts from disk.
      QuoteDraft.clear();
      await QuoteDraft.settled;
      SharedPreferences.setMockInitialValues({
        _storedKey: jsonEncode({
          'stagedAt': DateTime.now().toIso8601String(),
          'values': {
            'pickup': 'Drouot, Paris 9e',
            'delivery': '33000 Bordeaux',
            'email': 'vous@exemple.fr',
          },
        }),
      });

      await QuoteDraft.restore();
      final restored = QuoteDraft.peek();
      expect(restored, isNotNull);
      expect(restored!.pickup, 'Drouot, Paris 9e');
      expect(restored.delivery, '33000 Bordeaux');
      expect(restored.email, 'vous@exemple.fr');
    });

    test('is written to disk as it is staged', () async {
      QuoteDraft.stage(const QuoteDraft(pickup: 'Drouot, Paris 9e'));
      await QuoteDraft.settled;

      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString(_prefsKey)!) as Map;
      expect((stored['values'] as Map)['pickup'], 'Drouot, Paris 9e');
    });

    // Signing out clears it; the disk copy has to go with it, or the next
    // person on a shared browser is handed a stranger's address.
    test('leaves nothing behind when it is cleared', () async {
      QuoteDraft.stage(const QuoteDraft(pickup: 'Drouot, Paris 9e'));
      QuoteDraft.clear();
      await QuoteDraft.settled;

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_prefsKey), isNull);
      expect(QuoteDraft.peek(), isNull);
    });

    test('does not come back once it has gone stale', () async {
      SharedPreferences.setMockInitialValues({
        _storedKey: jsonEncode({
          'stagedAt': DateTime.now()
              .subtract(const Duration(hours: 3))
              .toIso8601String(),
          'values': {'pickup': 'Drouot, Paris 9e'},
        }),
      });

      await QuoteDraft.restore();
      expect(QuoteDraft.peek(), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_prefsKey), isNull,
          reason: 'a stale draft is deleted on the way past, not left to rot');
    });

    test('a draft staged this session outranks the one on disk', () async {
      SharedPreferences.setMockInitialValues({
        _storedKey: jsonEncode({
          'stagedAt': DateTime.now().toIso8601String(),
          'values': {'pickup': 'Hôtel des ventes de Lyon'},
        }),
      });

      QuoteDraft.stage(const QuoteDraft(pickup: 'Drouot, Paris 9e'));
      await QuoteDraft.restore();

      expect(QuoteDraft.peek()!.pickup, 'Drouot, Paris 9e');
    });

    test('unreadable storage is simply no draft', () async {
      SharedPreferences.setMockInitialValues({_storedKey: 'not json'});
      await QuoteDraft.restore();
      expect(QuoteDraft.peek(), isNull);
    });
  });

  group('where a draft resumes', () {
    // The fork asks one question — do you have the slip? — and a draft has
    // already answered it. Sending someone back to it after signing in asks
    // them to choose a route they have taken, and the wrong choice opens a
    // form showing none of their answers.
    test('a slip goes to the route that reads it', () {
      final draft = QuoteDraft(
        pickup: 'Drouot, Paris 9e',
        bordereau: SelectedFile(
          storagePath: 'bordereau.pdf',
          bytes: Uint8List.fromList([1, 2, 3]),
          originalFilename: 'bordereau.pdf',
        ),
      );
      expect(draft.resume, QuoteDraftResume.bordereau);
    });

    test('addresses without a slip go to the form that has fields for them',
        () {
      const draft = QuoteDraft(
        pickup: 'Drouot, Paris 9e',
        delivery: '33000 Bordeaux',
      );
      expect(draft.resume, QuoteDraftResume.manual);
    });
  });

  // ==========================================================================
  // Saying so
  // ==========================================================================

  group('the feedback the forms give', () {
    testWidgets('a refusal moves the panel, and a second one moves it again',
        (tester) async {
      var shakes = 0;
      late StateSetter refuse;

      await _pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            refuse = setState;
            return XpdShake(
              trigger: shakes,
              child: const SizedBox(width: 100.0, height: 40.0),
            );
          },
        ),
      );

      Offset at() => tester.getTopLeft(find.byType(SizedBox).first);
      final rest = at();
      // A form that has never been submitted sits still.
      await tester.pump(const Duration(milliseconds: 120));
      expect(at(), rest);

      refuse(() => shakes++);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(at(), isNot(rest), reason: 'the first refusal shakes');

      await tester.pumpAndSettle();
      expect(at(), rest, reason: 'and it comes back to rest');

      // The bug a bool would have: the second refusal in a row must move too.
      refuse(() => shakes++);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(at(), isNot(rest), reason: 'the second refusal shakes as well');

      await tester.pumpAndSettle();
    });

    testWidgets('an upload refusal is written where the file drop was',
        (tester) async {
      await _pumpThemed(
        tester,
        const XpdInlineError(message: 'Ce fichier dépasse 10 Mo.'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ce fichier dépasse 10 Mo.'), findsOneWidget);
    });

    testWidgets('and no space is held open when there is nothing to say',
        (tester) async {
      await _pumpThemed(tester, const XpdInlineError(message: null));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(XpdInlineError)).height, 0.0);
    });

    testWidgets('a success panel says what was kept and what happens next',
        (tester) async {
      await _pumpThemed(
        tester,
        const SizedBox(
          width: 420.0,
          child: XpdFormSuccess(
            title: 'Demande enregistrée.',
            message: 'Nous gardons vos réponses.',
            footnote: 'Rien n\'est envoyé pour le moment.',
            editLabel: 'Corriger ma demande',
          ),
        ),
      );

      // The tick is drawn over several frames; the copy follows it in.
      await tester.pumpAndSettle();
      expect(find.text('Demande enregistrée.'), findsOneWidget);
      expect(find.text('Nous gardons vos réponses.'), findsOneWidget);
      expect(find.text('Rien n\'est envoyé pour le moment.'), findsOneWidget);
      expect(find.byType(XpdAnimatedCheck), findsOneWidget);
    });

    // The forms reach into their fields from the outside to put the cursor in
    // the first one a refused submit complained about. Before `XpdField` took
    // a node, there was nothing to reach.
    testWidgets('a field can be focused from outside the form', (tester) async {
      final node = FocusNode();
      final controller = TextEditingController();
      addTearDown(node.dispose);
      addTearDown(controller.dispose);

      await _pumpThemed(
        tester,
        SizedBox(
          width: 320.0,
          child: XpdField(
            label: 'Enlèvement',
            controller: controller,
            focusNode: node,
          ),
        ),
      );

      expect(node.hasFocus, isFalse);
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);
    });

    // A node the caller owns is the caller's to dispose. Tearing the field
    // down must not take it with them, or the next `requestFocus` throws on a
    // disposed node.
    testWidgets('and the caller keeps ownership of the node it lent',
        (tester) async {
      final node = FocusNode();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpThemed(
        tester,
        SizedBox(
          width: 320.0,
          child: XpdField(
            label: 'Enlèvement',
            controller: controller,
            focusNode: node,
          ),
        ),
      );
      await _pumpThemed(tester, const SizedBox.shrink());

      // Still usable, which it would not be had the field disposed it: a
      // disposed ChangeNotifier throws the moment anything is added to it.
      // (`hasListeners` says the same thing, but it is @protected, so reading
      // it from a test is an analyzer warning.)
      expect(() => node.addListener(() {}), returnsNormally);
      node.dispose();
    });

    testWidgets('the way back is only offered when there is one',
        (tester) async {
      await _pumpThemed(
        tester,
        const SizedBox(
          width: 420.0,
          child: XpdFormSuccess(
            title: 'Demande enregistrée.',
            message: 'Nous gardons vos réponses.',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Corriger ma demande'), findsNothing);
    });
  });

}
