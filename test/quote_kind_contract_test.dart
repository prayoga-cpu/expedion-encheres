// The client and server must agree on how a quote's accepted kind is spelled,
// and on the unit its prices are in. Both disagreed at once, silently:
//
//   * `QuoteRepository.accept` sent 'insured', which the server's Zod enum
//     rejects, so accepting the ad valorem price failed every time; and
//   * the validation page multiplied the cents it was handed by 100 before
//     sending them to Stripe, a leftover from when prices came from Airtable
//     in euros.
//
// Neither showed up in a test, because nothing pinned the vocabulary or the
// unit. These do.

import 'package:flutter_test/flutter_test.dart';
import 'package:expedion_encheres/backend/expedion_api/expedion_quote.dart';

void main() {
  group('quote kind vocabulary', () {
    // These two strings are the `expedion_quote_kind` Postgres enum, defined in
    // expeditoo-ship/src/db/schema/expedion.ts. Changing either without
    // changing the server is what this test exists to stop.
    test('matches the server enum exactly', () {
      expect(kQuoteKindStandard, 'standard');
      expect(kQuoteKindInsured, 'with_ad_valorem_insurance');
    });

    test('isInsuredKind reads the wire value, not a French label', () {
      expect(
        ExpedionQuote({'acceptedKind': kQuoteKindInsured}).isInsuredKind,
        isTrue,
      );
      expect(
        ExpedionQuote({'acceptedKind': kQuoteKindStandard}).isInsuredKind,
        isFalse,
      );
      // The label the UI used to compare against must not be mistaken for it.
      expect(
        ExpedionQuote({'acceptedKind': 'ADV'}).isInsuredKind,
        isFalse,
      );
      expect(ExpedionQuote({}).isInsuredKind, isFalse);
    });
  });

  group('prices are cents', () {
    test('the model exposes the raw cents it was given', () {
      final quote = ExpedionQuote({
        'quoteStandardCents': 12345,
        'quoteInsuredCents': 14500,
      });
      expect(quote.quoteStandardCents, 12345);
      expect(quote.quoteInsuredCents, 14500);
    });

    test('formatCents renders cents as euros, not the other way round', () {
      // 12345 cents is 123,45 EUR. If a caller ever passes euros here the
      // output is off by a factor of 100 and obvious on sight.
      expect(formatCents(12345), contains('123'));
      expect(formatCents(12345), contains('45'));
      expect(formatCents(null), '—');
    });
  });
}
