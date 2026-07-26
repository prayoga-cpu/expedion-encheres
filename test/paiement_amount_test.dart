// Unit tests for the pure payment-amount logic used by PaiementWidget.
//
// These intentionally avoid building the widget tree or hitting Stripe — the
// amount calculation was extracted into `computePaiementAmountCents` so the
// STD vs AD valorem pricing can be verified in isolation.

import 'package:flutter_test/flutter_test.dart';
import 'package:expedion_encheres/active_p_a_g_e_s/paiement/paiement_model.dart';

void main() {
  group('computePaiementAmountCents', () {
    test('standard quote is billed at tarifStd, converted to cents', () {
      final cents = computePaiementAmountCents(
        typeDevisValide: 'Devis Standard',
        tarifAdv: 999,
        tarifStd: 50,
      );
      expect(cents, 5000);
    });

    test('AD valorem quote is billed at tarifAdv, converted to cents', () {
      final cents = computePaiementAmountCents(
        typeDevisValide: kTypeDevisAdValorem,
        tarifAdv: 120,
        tarifStd: 50,
      );
      expect(cents, 12000);
    });

    test('null tariffs fall back to 0', () {
      expect(
        computePaiementAmountCents(typeDevisValide: 'Devis Standard'),
        0,
      );
      expect(
        computePaiementAmountCents(typeDevisValide: kTypeDevisAdValorem),
        0,
      );
    });

    test('an unknown quote type is treated as standard pricing', () {
      final cents = computePaiementAmountCents(
        typeDevisValide: 'Type inconnu',
        tarifAdv: 120,
        tarifStd: 50,
      );
      expect(cents, 5000);
    });
  });
}
