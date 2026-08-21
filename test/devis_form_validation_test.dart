// The rules the devis form gates its Submit button on, and the two pieces of
// machinery underneath it.
//
// Every rule here exists to stop a quote reaching Expeditoo in a state
// `escalationBlockers` would refuse — a quote missing a postcode or a weight
// does not fail loudly, it sits in the operator queue until somebody
// telephones the client. That is the failure these tests are protecting
// against, which is why "optional" fields are still held to a rule when they
// are filled: a wrong phone number is worse than a blank one.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

import 'package:expedion_encheres/backend/geocoding/nominatim_geocoder.dart';
import 'package:expedion_encheres/backend/quote_form_rules.dart';
import 'package:expedion_encheres/design_system/ds_location_picker.dart';
import 'package:expedion_encheres/design_system/ds_text_field.dart';
import 'package:expedion_encheres/flutter_flow/flutter_flow_theme.dart';
import 'package:expedion_encheres/flutter_flow/internationalization.dart';

// ---------------------------------------------------------------------------
// Geocoder doubles
// ---------------------------------------------------------------------------
// DSAddressValue takes its two lookups as functions so these tests can drive
// the state machine to the exact interleaving that used to break it, instead
// of waiting on a live Nominatim and hoping.

GeocodeSuggestion _hit({
  String address = '9 rue Drouot',
  String city = 'Paris',
  String postalCode = '75009',
  double lat = 48.8721,
  double lng = 2.3390,
}) =>
    GeocodeSuggestion(
      label: [address, postalCode, city].where((s) => s.isNotEmpty).join(', '),
      address: address,
      city: city,
      postalCode: postalCode,
      lat: lat,
      lng: lng,
    );

DSForwardGeocode _forwardReturning(GeocodeSuggestion? hit) => ({
      required String address,
      required String postalCode,
      required String city,
    }) async =>
        hit;

/// Never answers. For the tests that need a lookup to still be in flight.
DSForwardGeocode _forwardHanging() => ({
      required String address,
      required String postalCode,
      required String city,
    }) =>
        Completer<GeocodeSuggestion?>().future;

void main() {
  group('required fields', () {
    test('the auction house needs a name, not a keystroke', () {
      expect(QuoteFormRules.isAuctionHouse('Drouot'), isTrue);
      expect(QuoteFormRules.isAuctionHouse('D'), isFalse);
      expect(QuoteFormRules.isAuctionHouse('   '), isFalse);
      expect(QuoteFormRules.isAuctionHouse(''), isFalse);
    });

    test('the description has to survive `buildTitle`', () {
      expect(QuoteFormRules.isDescription('Commode Louis XV'), isTrue);
      // Below five characters the listing title degrades to
      // "Retrait enchères <town>", which tells a carrier nothing.
      expect(QuoteFormRules.isDescription('lot'), isFalse);
      expect(QuoteFormRules.isDescription(''), isFalse);
    });

    test('weight is positive, bounded, and comma-friendly', () {
      expect(QuoteFormRules.isWeight('42'), isTrue);
      expect(QuoteFormRules.isWeight('12,5'), isTrue);
      expect(QuoteFormRules.isWeight('12.5'), isTrue);
      expect(QuoteFormRules.isWeight('0'), isFalse);
      expect(QuoteFormRules.isWeight('-3'), isFalse);
      expect(QuoteFormRules.isWeight(''), isFalse);
      expect(QuoteFormRules.isWeight('abc'), isFalse);
      // "1200" typed into a field that wanted "12,00" is the case the cap is
      // really there for.
      expect(QuoteFormRules.isWeight('9000'), isFalse);
    });

    test('declared value sizes the cover, so zero is as unusable as blank', () {
      expect(QuoteFormRules.isDeclaredValue('4200'), isTrue);
      expect(QuoteFormRules.isDeclaredValue('4 200,50 €'), isTrue);
      expect(QuoteFormRules.isDeclaredValue('0'), isFalse);
      expect(QuoteFormRules.isDeclaredValue(''), isFalse);
      expect(QuoteFormRules.isDeclaredValue('9 000 000'), isFalse);
    });

    test('euro text lands on the cents the API expects', () {
      expect(QuoteFormRules.euroToCents('1 250,50'), 125050);
      expect(QuoteFormRules.euroToCents('1250.5'), 125050);
      expect(QuoteFormRules.euroToCents('4 200 €'), 420000);
      expect(QuoteFormRules.euroToCents('4200'), 420000);
      // Null rather than zero: "unknown value" and "worth nothing" are
      // different answers.
      expect(QuoteFormRules.euroToCents(''), isNull);
      expect(QuoteFormRules.euroToCents('n/a'), isNull);
    });

    test('a grouped thousand is not read as a decimal', () {
      // Regression: "4.200" parsed as four-point-two insured a €4,200 lot for
      // €4.20 — silently, because 4.20 is a perfectly valid amount.
      expect(QuoteFormRules.euroToCents('4.200'), 420000);
      expect(QuoteFormRules.euroToCents('1.234.567'), 123456700);
      expect(QuoteFormRules.euroToCents('4.200,50'), 420050);
      expect(QuoteFormRules.euroToCents('4,200.50'), 420050);
      // A comma with three digits behind it is still a decimal: French writes
      // four-and-a-fifth as "4,2", and "4,200" is that with trailing zeros.
      expect(QuoteFormRules.euroToCents('4,200'), 420);
      // And the cap still catches the extra zero it is there for.
      expect(QuoteFormRules.isDeclaredValue('4.200'), isTrue);
      expect(QuoteFormRules.isDeclaredValue('9.000.000'), isFalse);
    });
  });

  group('optional fields are still held to their rule', () {
    test('dimensions are all three or none', () {
      expect(QuoteFormRules.areDimensions('', '', ''), isTrue);
      expect(QuoteFormRules.areDimensions('120', '60', '90'), isTrue);
      // Two out of three reach `buildDescription` as nothing at all.
      expect(QuoteFormRules.areDimensions('120', '60', ''), isFalse);
      expect(QuoteFormRules.areDimensions('120', '', ''), isFalse);
      expect(QuoteFormRules.areDimensions('120', '60', '0'), isFalse);
      expect(QuoteFormRules.areDimensions('120', '60', '2000'), isFalse);
    });

    test('a blank phone passes and a wrong one does not', () {
      expect(QuoteFormRules.isPhone(''), isTrue);
      expect(QuoteFormRules.isPhone('06 12 34 56 78'), isTrue);
      expect(QuoteFormRules.isPhone('+33 6 12 34 56 78'), isTrue);
      expect(QuoteFormRules.isPhone('0033612345678'), isTrue);
      expect(QuoteFormRules.isPhone('01.23.45.67.89'), isTrue);
      expect(QuoteFormRules.isPhone('0612345'), isFalse);
      expect(QuoteFormRules.isPhone('00 12 34 56 78'), isFalse);
      expect(QuoteFormRules.isPhone('+44 20 7946 0000'), isFalse);
    });

    test('a recipient is either absent or a name', () {
      expect(QuoteFormRules.isRecipient(''), isTrue);
      expect(QuoteFormRules.isRecipient('Mme Roux'), isTrue);
      expect(QuoteFormRules.isRecipient('R'), isFalse);
    });
  });

  group('address block', () {
    test('the postcode rule matches the server\'s', () {
      expect(DSAddressValue.isPostalCode('75009'), isTrue);
      expect(DSAddressValue.isPostalCode('75 009'), isTrue);
      // "75001 Cedex" and a four-digit typo both fail `normalisePostalCode`
      // server-side; catching them here saves a blocked quote.
      expect(DSAddressValue.isPostalCode('7500'), isFalse);
      expect(DSAddressValue.isPostalCode('75001 Cedex 09'), isFalse);
      expect(DSAddressValue.isPostalCode(''), isFalse);
    });

    test('an empty address is missing all four pieces', () {
      final value = DSAddressValue();
      addTearDown(value.dispose);

      expect(value.isEmpty, isTrue);
      expect(value.status, DSAddressStatus.empty);
      expect(
        value.gaps,
        {
          DSAddressGap.address,
          DSAddressGap.postalCode,
          DSAddressGap.city,
          DSAddressGap.position,
        },
      );
    });

    test('a restored draft comes back located, with no lookup', () {
      final value = DSAddressValue();
      addTearDown(value.dispose);

      value.restore(
        address: '9 rue Drouot',
        postalCode: '75009',
        city: 'Paris',
        lat: 48.8721,
        lng: 2.3390,
      );

      expect(value.status, DSAddressStatus.confirmed);
      expect(value.isLocated, isTrue);
      expect(value.gaps, isEmpty);
      expect(value.point!.latitude, closeTo(48.8721, 0.0001));
    });

    test('editing the address drops the point it belonged to', () {
      final value = DSAddressValue(forwardGeocode: _forwardHanging());
      addTearDown(value.dispose);

      value.restore(
        address: '9 rue Drouot',
        postalCode: '75009',
        city: 'Paris',
        lat: 48.8721,
        lng: 2.3390,
      );
      expect(value.isLocated, isTrue);

      // The visitor corrects the street. The old coordinates describe the old
      // street, so keeping them would be worse than having none.
      value.address.text = '15 rue Drouot';

      expect(value.point, isNull);
      expect(value.isLocated, isFalse);
      expect(value.gaps, {DSAddressGap.position});
    });

    test('a half-typed address is incomplete, not "not found"', () {
      final value = DSAddressValue();
      addTearDown(value.dispose);

      value.address.text = '9 rue Drouot';
      expect(value.status, DSAddressStatus.incomplete);
      expect(value.gaps, contains(DSAddressGap.postalCode));
    });

    test('"use it anyway" unblocks an address Nominatim does not know',
        () async {
      final value = DSAddressValue(forwardGeocode: _forwardReturning(null));
      addTearDown(value.dispose);

      value.restore(address: 'Le Mas Neuf', postalCode: '13200', city: 'Arles');

      // Regression: a draft saved before its address resolved comes back with
      // three full lines and no point. That used to land in `checking` with no
      // lookup scheduled — a spinner that never resolved, Submit disabled for
      // ever, and the "use it anyway" escape not even rendered, because it
      // only appears under `notFound`.
      expect(value.status, DSAddressStatus.checking);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(value.status, DSAddressStatus.notFound);
      expect(value.isLocated, isFalse);

      value.acceptUnverified();
      expect(value.status, DSAddressStatus.accepted);
      expect(value.isLocated, isTrue);
      expect(value.gaps, isEmpty);
    });

    test('a restored draft that still resolves comes back confirmed', () async {
      final value = DSAddressValue(forwardGeocode: _forwardReturning(_hit()));
      addTearDown(value.dispose);

      value.restore(
          address: '9 rue Drouot', postalCode: '75009', city: 'Paris');
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      expect(value.status, DSAddressStatus.confirmed);
      expect(value.point, isNotNull);
      expect(value.gaps, isEmpty);
    });

    test('an edit retires the lookup that was already in flight', () async {
      final reverse = Completer<GeocodeSuggestion?>();
      final value = DSAddressValue(
        forwardGeocode: _forwardHanging(),
        reverseGeocode: (lat, lng) => reverse.future,
      );
      addTearDown(value.dispose);

      value.address.text = '9 rue Drouot';
      unawaited(value.pin(const LatLng(48.8721, 2.3390)));
      expect(value.status, DSAddressStatus.checking);
      expect(value.point, isNotNull);

      // The visitor corrects the street while the pin is still being looked up.
      value.address.text = '15 rue Drouot';
      expect(value.point, isNull);

      // Regression: this answer belongs to the text as it was two edits ago.
      // It used to be accepted anyway — overwriting the line being typed and
      // setting `confirmed` on top of a null point, which reported
      // "Position confirmée — —" and enabled Submit for an address whose
      // position had just been thrown away.
      reverse.complete(_hit(address: '9 rue Drouot'));
      await Future<void>.delayed(Duration.zero);

      expect(value.address.text, '15 rue Drouot');
      expect(value.status, isNot(DSAddressStatus.confirmed));
      expect(value.point, isNull);
      expect(value.gaps, contains(DSAddressGap.position));
    });

    test('focusing a field the pin filled does not throw the pin away',
        () async {
      final value = DSAddressValue(
        forwardGeocode: _forwardHanging(),
        reverseGeocode: (lat, lng) async => _hit(
          address: 'Chemin des Vignes',
          city: 'Fontainebleau',
          postalCode: '',
          lat: lat,
          lng: lng,
        ),
      );
      addTearDown(value.dispose);

      await value.pin(const LatLng(48.4045, 2.7016));
      expect(value.status, DSAddressStatus.confirmed);
      expect(value.gaps, {DSAddressGap.postalCode});

      // Regression: a TextEditingController notifies on selection changes too,
      // and `controller.text = ` leaves the selection invalid, so EditableText
      // repairs it the moment the field is focused. That notification used to
      // read as an edit — the visitor tapped the postcode box to fill in the
      // one thing still missing, and the pin they had just dropped vanished
      // before they typed a character, with nothing scheduled to recover it.
      value.postalCode.selection = const TextSelection.collapsed(offset: 0);
      value.address.selection = TextSelection.collapsed(
        offset: value.address.text.length,
      );

      expect(value.point, isNotNull);
      expect(value.status, DSAddressStatus.confirmed);
      expect(value.gaps, {DSAddressGap.postalCode});

      // A real edit still counts.
      value.postalCode.text = '77300';
      expect(value.point, isNull);
      expect(value.gaps, contains(DSAddressGap.position));
    });

    test('a suggestion brings its own town, and no stale postcode', () {
      final value = DSAddressValue(forwardGeocode: _forwardHanging());
      addTearDown(value.dispose);

      value.restore(
        address: '9 rue Drouot',
        postalCode: '75009',
        city: 'Paris',
        lat: 48.8721,
        lng: 2.3390,
      );

      // A hamlet: Nominatim knows the village, but carries no postcode.
      value.applySuggestion(_hit(
        address: 'Le Mas Neuf',
        city: 'Le Bouscat',
        postalCode: '',
        lat: 44.86,
        lng: -0.6,
      ));

      // Regression: '75009' used to survive next to 'Le Bouscat' and the
      // address still reported `confirmed`, so Submit enabled and the quote
      // reached the carrier with a postcode from another department —
      // `normalisePostalCode` accepts any five digits, so nothing downstream
      // catches it either.
      expect(value.city.text, 'Le Bouscat');
      expect(value.postalCode.text, isEmpty);
      expect(value.gaps, contains(DSAddressGap.postalCode));
    });

    test('a pin takes the town it landed in, and leaves the street typed',
        () async {
      // A point on a rural road: Nominatim knows the commune but has no road
      // and no postcode for it.
      final value = DSAddressValue(
        forwardGeocode: _forwardHanging(),
        reverseGeocode: (lat, lng) async => _hit(
          address: '',
          city: 'Fontainebleau',
          postalCode: '',
          lat: lat,
          lng: lng,
        ),
      );
      addTearDown(value.dispose);

      value.restore(
        address: '9 rue Drouot',
        postalCode: '75009',
        city: 'Paris',
        lat: 48.8721,
        lng: 2.3390,
      );
      await value.pin(const LatLng(48.4045, 2.7016));

      // The street is a suggestion — an empty one leaves the typing alone.
      expect(value.address.text, '9 rue Drouot');
      // The town is not a suggestion. Regression: the old postcode used to
      // survive next to the new town, and the form submitted "75009
      // Fontainebleau" as a real collection address.
      expect(value.city.text, 'Fontainebleau');
      expect(value.postalCode.text, isEmpty);
      expect(value.gaps, contains(DSAddressGap.postalCode));
    });
  });

  group('geocoder parsing', () {
    // The pin writes `address` straight into the visitor's street field, so
    // what the parser calls a street matters.
    final parkJson = <String, dynamic>{
      'lat': '48.8799',
      'lon': '2.3092',
      'display_name': 'Parc Monceau, 8e Arrondissement, Paris, '
          'Île-de-France, 75008, France',
      'address': <String, dynamic>{
        'city': 'Paris',
        'postcode': '75008',
        'country_code': 'fr',
      },
    };

    test('a reverse hit with no road reports no street at all', () {
      final hit = NominatimGeocoder.parseHit(parkJson, streetFallback: false);

      // Regression: this used to return the whole comma-separated place name
      // as the street, which overwrote the typed address with
      // "Parc Monceau, 8e Arrondissement, Paris, …" and submitted it as
      // `pickupAddress` — precisely the address the server then fails to
      // geocode, which is the blocker this map exists to prevent.
      expect(hit, isNotNull);
      expect(hit!.address, isEmpty);
      expect(hit.city, 'Paris');
      expect(hit.postalCode, '75008');
    });

    test('a forward hit still falls back to the display name', () {
      // The dropdown has nothing else to show for a place with no street.
      final hit = NominatimGeocoder.parseHit(parkJson);
      expect(hit!.address, startsWith('Parc Monceau'));
    });

    test('a hit with a road reports the road either way', () {
      final json = <String, dynamic>{
        'lat': '48.8721',
        'lon': '2.3390',
        'display_name': '9, Rue Drouot, Paris, 75009, France',
        'address': <String, dynamic>{
          'house_number': '9',
          'road': 'Rue Drouot',
          'city': 'Paris',
          'postcode': '75009',
          'country_code': 'fr',
        },
      };
      expect(NominatimGeocoder.parseHit(json)!.address, '9 Rue Drouot');
      expect(
        NominatimGeocoder.parseHit(json, streetFallback: false)!.address,
        '9 Rue Drouot',
      );
    });

    test('anything outside France is refused', () {
      expect(
        NominatimGeocoder.parseHit(<String, dynamic>{
          'lat': '51.5',
          'lon': '-0.12',
          'display_name': 'Covent Garden, London, England',
          'address': <String, dynamic>{'city': 'London', 'country_code': 'gb'},
        }),
        isNull,
      );
    });
  });

  group('the map', mapTests);

  group('a failing field says why', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await FlutterFlowTheme.initialize();
    });

    Future<void> pump(WidgetTester tester, Widget child) {
      return tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            FFLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fr'), Locale('en')],
          home: Scaffold(body: child),
        ),
      );
    }

    // Regression: the message used to be rendered at `fontSize: 0`, so a
    // failing field showed a red border and no reason at all.
    testWidgets('the validator message is visible under the field',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        Form(
          child: DSTextField(
            controller: controller,
            label: 'Code postal',
            validator: (value) => DSAddressValue.isPostalCode(value ?? '')
                ? null
                : 'Code postal à 5 chiffres',
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '750');
      await tester.pump();

      expect(find.text('Code postal à 5 chiffres'), findsOneWidget);
    });

    testWidgets('a field filled programmatically clears its own message',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        Form(
          child: DSTextField(
            controller: controller,
            validator: (value) => DSAddressValue.isPostalCode(value ?? '')
                ? null
                : 'Code postal à 5 chiffres',
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '750');
      await tester.pump();
      expect(find.text('Code postal à 5 chiffres'), findsOneWidget);

      // What picking an address suggestion does: the postcode arrives without
      // anybody typing it.
      controller.text = '75009';
      await tester.pump();
      await tester.pump();

      expect(find.text('Code postal à 5 chiffres'), findsNothing);
    });

    testWidgets('an untouched field stays quiet until the form is validated',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        Form(
          key: formKey,
          child: DSTextField(
            controller: controller,
            validator: (value) =>
                (value ?? '').isEmpty ? 'Champ obligatoire' : null,
          ),
        ),
      );

      expect(find.text('Champ obligatoire'), findsNothing);

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Champ obligatoire'), findsOneWidget);
    });
  });
}

// ============================================================================
// The map
// ============================================================================
// Not a rendering test — tiles need a network these tests do not have. What is
// pinned here is the wiring: the widget builds and lays out inside a form, a
// point puts a pin on the map, and a tap on the map reports one back. Those
// three are what the address block depends on and what a flutter_map upgrade
// would break silently.

void mapTests() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await FlutterFlowTheme.initialize();
  });

  Future<void> pumpMap(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          FFLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        home:
            Scaffold(body: SizedBox(width: 600.0, height: 400.0, child: child)),
      ),
    );
    await tester.pump();
  }

  testWidgets('with no point it prompts for one and shows no pin',
      (tester) async {
    LatLng? reported;
    await pumpMap(
      tester,
      DSLocationMap(point: null, onPinned: (point) => reported = point),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Touchez la carte'), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsNothing);
    expect(reported, isNull);
  });

  testWidgets('a point puts the pin on the map', (tester) async {
    await pumpMap(
      tester,
      DSLocationMap(
        point: const LatLng(48.8721, 2.3390),
        onPinned: (_) {},
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.location_on), findsOneWidget);
    // The prompt gives way once there is something to correct.
    expect(find.textContaining('Touchez la carte'), findsNothing);
  });

  testWidgets('tapping the map reports a point inside France', (tester) async {
    LatLng? reported;
    await pumpMap(
      tester,
      DSLocationMap(point: null, onPinned: (point) => reported = point),
    );

    await tester.tapAt(tester.getCenter(find.byType(DSLocationMap)));
    // flutter_map holds a tap for `doubleTapDelay` to see whether a second one
    // is coming, so the tap does not land until that clock has run.
    await tester.pump(const Duration(milliseconds: 400));

    expect(reported, isNotNull);
    // The camera opens on France and the map is bounded to it, so the centre
    // of the widget cannot land anywhere else.
    expect(reported!.latitude, inInclusiveRange(41.0, 52.0));
    expect(reported!.longitude, inInclusiveRange(-6.0, 10.0));
  });

  testWidgets('tapping the pin itself does not walk it up the street',
      (tester) async {
    LatLng? reported;
    await pumpMap(
      tester,
      DSLocationMap(
        point: const LatLng(46.6, 2.35),
        onPinned: (point) => reported = point,
      ),
    );

    // Regression: the marker is drawn *above* its point, so a tap on the pin
    // that fell through to the map read as a tap one icon-height north and
    // re-dropped the pin there.
    await tester.tap(find.byIcon(Icons.location_on));
    await tester.pump(const Duration(milliseconds: 400));

    expect(reported, isNull);
  });

  testWidgets('the address block puts three fields and a map in one column',
      (tester) async {
    final value = DSAddressValue();
    addTearDown(value.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          FFLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        home: Scaffold(
          body: SingleChildScrollView(
            child: Form(
              child: DSAddressPicker(
                value: value,
                addressLabel: 'Adresse de retrait *',
                postalCodeLabel: 'Code postal *',
                cityLabel: 'Ville *',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Adresse de retrait *'), findsOneWidget);
    expect(find.text('Code postal *'), findsOneWidget);
    expect(find.text('Ville *'), findsOneWidget);
    expect(find.byType(DSLocationMap), findsOneWidget);
    // The status line opens by saying which two ways in there are.
    expect(find.textContaining('placez le point'), findsOneWidget);
  });
}
