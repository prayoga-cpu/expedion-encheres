// The devis form's Save-draft button writes here.
//
// Three things have to hold, because each one is a way to lose or leak an
// afternoon's work: a draft comes back exactly as it went in, it belongs to
// the account that wrote it, and it does not come back for ever.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expedion_encheres/backend/quote_form_draft.dart';

/// `shared_preferences` namespaces every key it stores.
String _storedKey(String uid) => 'flutter.expedion.quoteFormDraft.$uid';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('a saved draft comes back with every value intact', () async {
    final values = {
      'auctionHouse': 'Drouot',
      'pickupPostalCode': '75009',
      'pickupLat': 48.8721,
      'pickupLng': 2.3390,
      'bordereauPaid': true,
      'photoUrls': ['https://example.test/a.jpg', 'https://example.test/b.jpg'],
    };

    expect(await QuoteFormDraft.save('user-1', values), isTrue);

    final restored = await QuoteFormDraft.load('user-1');
    expect(restored, isNotNull);
    expect(restored!.text('auctionHouse'), 'Drouot');
    expect(restored.text('pickupPostalCode'), '75009');
    expect(restored.number('pickupLat'), closeTo(48.8721, 0.0001));
    expect(restored.flag('bordereauPaid'), isTrue);
    expect(restored.strings('photoUrls'), hasLength(2));
  });

  test('a draft belongs to the account that wrote it', () async {
    await QuoteFormDraft.save('user-1', {'auctionHouse': 'Drouot'});

    // The next person to use this browser signs in as themselves and sees
    // nothing of the first one's half-written address.
    expect(await QuoteFormDraft.load('user-2'), isNull);
    expect(await QuoteFormDraft.load(''), isNull);

    // And the first one still has theirs.
    expect(
        (await QuoteFormDraft.load('user-1'))?.text('auctionHouse'), 'Drouot');
  });

  test('a signed-out draft lands in the shared anon slot', () async {
    await QuoteFormDraft.save('', {'auctionHouse': 'Drouot'});
    expect((await QuoteFormDraft.load(''))?.text('auctionHouse'), 'Drouot');
  });

  test('a draft older than the retention window is dropped, not returned',
      () async {
    final stale = DateTime.now().subtract(QuoteFormDraft.keepFor * 2);
    SharedPreferences.setMockInitialValues({
      _storedKey('user-1'): jsonEncode({
        'savedAt': stale.toIso8601String(),
        'values': {'auctionHouse': 'Drouot'},
      }),
    });

    expect(await QuoteFormDraft.load('user-1'), isNull);

    // Dropped on the way past, so it cannot resurface.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_storedKey('user-1')), isNull);
  });

  test('a draft written by an older form does not throw on read', () async {
    SharedPreferences.setMockInitialValues({
      _storedKey('user-1'): jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'values': {
          'auctionHouse': 42, // was a String in this version
          'photoUrls': 'not-a-list',
          'pickupLat': '48.87', // numbers used to be stored as text
        },
      }),
    });

    final restored = await QuoteFormDraft.load('user-1');
    expect(restored, isNotNull);
    expect(restored!.text('auctionHouse'), '');
    expect(restored.strings('photoUrls'), isEmpty);
    expect(restored.number('pickupLat'), closeTo(48.87, 0.0001));
    expect(restored.text('never-written'), '');
    expect(restored.flag('never-written'), isFalse);
    expect(restored.number('never-written'), isNull);
  });

  test('unreadable JSON is cleared rather than returned', () async {
    SharedPreferences.setMockInitialValues({_storedKey('user-1'): '{oops'});
    expect(await QuoteFormDraft.load('user-1'), isNull);
  });

  test('submitting clears the draft', () async {
    await QuoteFormDraft.save('user-1', {'auctionHouse': 'Drouot'});
    await QuoteFormDraft.clear('user-1');
    expect(await QuoteFormDraft.load('user-1'), isNull);
  });
}
