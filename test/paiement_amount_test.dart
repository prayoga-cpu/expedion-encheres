// Unit tests for the pure payment-amount logic used by PaiementWidget.
//
// These intentionally avoid building the widget tree or hitting Stripe — the
// amount calculation was extracted into `computePaiementAmountCents` so the
// STD vs AD valorem pricing can be verified in isolation.
//
// The tariffs are CENTS, which is what `expedion_quotes` stores and what the
// API returns. They were euros while quotes lived in Airtable, and the helper
// multiplied by 100 on the way out; these tests pinned that older contract, so
// they moved with it.

import 'package:flutter_test/flutter_test.dart';
import 'package:expedion_encheres/active_p_a_g_e_s/paiement/paiement_model.dart';

void main() {
  group('computePaiementAmountCents', () {
    test('standard quote is billed at the standard tariff, unscaled', () {
      final cents = computePaiementAmountCents(
        typeDevisValide: 'Devis Standard',
        tarifAdvCents: 99900,
        tarifStdCents: 5000,
      );
      expect(cents, 5000);
    });

    test('AD valorem quote is billed at the insured tariff, unscaled', () {
      final cents = computePaiementAmountCents(
        typeDevisValide: kTypeDevisAdValorem,
        tarifAdvCents: 12000,
        tarifStdCents: 5000,
      );
      expect(cents, 12000);
    });

    test('a missing tariff yields null so the caller can refuse to charge', () {
      expect(
        computePaiementAmountCents(typeDevisValide: 'Devis Standard'),
        isNull,
      );
      expect(
        computePaiementAmountCents(typeDevisValide: kTypeDevisAdValorem),
        isNull,
      );
    });

    test('an unrecognised type falls back to the standard tariff', () {
      expect(
        computePaiementAmountCents(
          typeDevisValide: 'with_ad_valorem_insurance',
          tarifAdvCents: 12000,
          tarifStdCents: 5000,
        ),
        5000,
        reason:
            'the wire vocabulary is normalised to the French labels before it '
            'reaches here; anything else must not be treated as insured',
      );
    });
  });
}
