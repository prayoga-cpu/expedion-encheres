// The contact details had already diverged across three files — the landing
// page, the old FlutterFlow contact page, and a form placeholder holding the
// textbook dummy number. Centralising them only helps if the derived `tel:`
// form is right, which is the part nobody checks by eye.

import 'package:flutter_test/flutter_test.dart';
import 'package:expedion_encheres/support_contact.dart';

void main() {
  group('SupportContact', () {
    test('dials in international form, which is what tel: needs', () {
      // 01 84 80 12 40 is a French national number: drop the trunk 0, prefix
      // +33. Getting this wrong fails silently — the dialler just opens with a
      // number that cannot connect.
      expect(SupportContact.phoneDialable, '+33184801240');
    });

    test('the dialable form carries no spaces', () {
      expect(SupportContact.phoneDialable, isNot(contains(' ')));
    });

    test('display form stays human-readable', () {
      expect(SupportContact.phone, '01 84 80 12 40');
    });

    test('email is on the company domain, not a placeholder', () {
      expect(SupportContact.email, endsWith('@expedion-encheres.com'));
      expect(SupportContact.email, isNot(contains('example')));
    });
  });
}
