// Unit tests for the value conversions that sit between what a visitor types
// and what reaches the database.
//
// These are worth pinning because both directions are silent when wrong: a
// mis-parsed hammer price becomes a wrong insured value on a real quote, and a
// mis-formatted total becomes a wrong figure on the payments page. Neither
// throws, so only a test catches them.

import 'package:flutter_test/flutter_test.dart';

import 'package:expedion_encheres/backend/expedion_api/expedion_quote.dart';
import 'package:expedion_encheres/backend/quote_draft.dart';

void main() {
  group('formatCents', () {
    test('renders euros and centimes in French convention', () {
      expect(formatCents(0), '0,00${kNoBreakSpace}€');
      expect(formatCents(5), '0,05${kNoBreakSpace}€');
      expect(formatCents(50), '0,50${kNoBreakSpace}€');
      expect(formatCents(12345), '123,45${kNoBreakSpace}€');
    });

    test('groups thousands', () {
      expect(
        formatCents(100000),
        '1${kNarrowNoBreakSpace}000,00${kNoBreakSpace}€',
      );
      expect(
        formatCents(123456789),
        '1${kNarrowNoBreakSpace}234${kNarrowNoBreakSpace}567,89'
        '${kNoBreakSpace}€',
      );
    });

    test('distinguishes unknown from zero', () {
      expect(formatCents(null), '—');
      expect(formatCents(0), isNot('—'));
    });

    test('keeps the sign on a refund', () {
      expect(formatCents(-2500), '-25,00${kNoBreakSpace}€');
    });
  });

  group('QuoteDraft.deliveryParts', () {
    test('splits postcode from city in either order', () {
      expect(
        const QuoteDraft(delivery: '33000 Bordeaux').deliveryParts,
        (postcode: '33000', city: 'Bordeaux'),
      );
      expect(
        const QuoteDraft(delivery: 'Bordeaux 33000').deliveryParts,
        (postcode: '33000', city: 'Bordeaux'),
      );
    });

    test('tolerates a comma between the two', () {
      expect(
        const QuoteDraft(delivery: 'Bordeaux, 33000').deliveryParts,
        (postcode: '33000', city: 'Bordeaux'),
      );
    });

    test('returns empty halves rather than guessing', () {
      expect(
        const QuoteDraft(delivery: 'Bordeaux').deliveryParts,
        (postcode: '', city: 'Bordeaux'),
      );
      expect(
        const QuoteDraft(delivery: '').deliveryParts,
        (postcode: '', city: ''),
      );
    });
  });

  group('QuoteDraft staging', () {
    setUp(QuoteDraft.clear);

    test('an empty draft is never staged', () {
      QuoteDraft.stage(const QuoteDraft());
      expect(QuoteDraft.consume(), isNull);
    });

    test('consume reads once and clears', () {
      QuoteDraft.stage(const QuoteDraft(pickup: 'Drouot'));
      expect(QuoteDraft.consume()?.pickup, 'Drouot');
      expect(QuoteDraft.consume(), isNull);
    });

    test('peek leaves the draft in place', () {
      QuoteDraft.stage(const QuoteDraft(pickup: 'Drouot'));
      expect(QuoteDraft.peek()?.pickup, 'Drouot');
      expect(QuoteDraft.peek()?.pickup, 'Drouot');
      expect(QuoteDraft.consume()?.pickup, 'Drouot');
    });

    test('clear drops it, so signing out cannot leak it to the next visitor',
        () {
      QuoteDraft.stage(const QuoteDraft(email: 'someone@example.fr'));
      QuoteDraft.clear();
      expect(QuoteDraft.peek(), isNull);
    });
  });

  group('ExpedionQuote', () {
    test('reference falls back through quote number, bordereau, then id', () {
      expect(
        const ExpedionQuote({'quoteNumber': 'Q-2026-001', 'id': 'abcdef123456'})
            .reference,
        'Q-2026-001',
      );
      expect(
        const ExpedionQuote({'bordereauNumber': 'B-77', 'id': 'abcdef123456'})
            .reference,
        'B-77',
      );
      expect(
        const ExpedionQuote({'id': 'abcdef123456'}).reference,
        'abcdef12',
      );
    });

    test('isPaid covers every status downstream of payment', () {
      for (final status in [
        'paid',
        'assigned',
        'escalated',
        'in_transit',
        'delivered'
      ]) {
        expect(
          ExpedionQuote({'status': status}).isPaid,
          isTrue,
          reason: '$status should read as paid',
        );
      }
      for (final status in [
        'pending',
        'awaiting_confirmation',
        'quoted',
        'accepted'
      ]) {
        expect(
          ExpedionQuote({'status': status}).isPaid,
          isFalse,
          reason: '$status should not read as paid',
        );
      }
    });

    test('paymentStatus alone is enough to count as paid', () {
      expect(
        const ExpedionQuote({'status': 'accepted', 'paymentStatus': 'paid'})
            .isPaid,
        isTrue,
      );
    });

    test('effectivePrice prefers what the client accepted', () {
      expect(
        const ExpedionQuote({
          'acceptedPriceCents': 15000,
          'quoteStandardCents': 12000,
        }).effectivePriceCents,
        15000,
      );
      expect(
        const ExpedionQuote({'quoteStandardCents': 12000}).effectivePriceCents,
        12000,
      );
    });

    test('hasDriver and isEscalated read the assignment columns', () {
      expect(const ExpedionQuote({}).hasDriver, isFalse);
      expect(const ExpedionQuote({'assignedCarrierId': 'car_1'}).hasDriver,
          isTrue);
      expect(const ExpedionQuote({'listingId': 'lst_1'}).isEscalated, isTrue);
      expect(const ExpedionQuote({'status': 'escalated'}).isEscalated, isTrue);
      expect(const ExpedionQuote({}).isEscalated, isFalse);
    });

    test('numeric fields survive arriving as strings', () {
      // Postgres numerics can serialise as strings through some drivers.
      const quote = ExpedionQuote({
        'quoteStandardCents': '12000',
        'weightKg': '18.5',
      });
      expect(quote.quoteStandardCents, 12000);
      expect(quote.weightKg, 18.5);
    });
  });
}
