// Unit tests for the profile model that replaced the Airtable USERS table.
//
// The endpoint behind it (`/api/expedion/me/profile`) is coded against a
// contract, so these pin the client's half of that contract: what is read,
// what is sent, and what is left out so the server leaves it alone.

import 'package:flutter_test/flutter_test.dart';

import 'package:expedion_encheres/backend/expedion_api/expedion_api.dart';
import 'package:expedion_encheres/backend/expedion_api/expedion_profile.dart';

void main() {
  group('ExpedionProfile.fromJson', () {
    test('reads every field', () {
      final profile = ExpedionProfile.fromJson(const {
        'email': 'a@b.fr',
        'firstName': 'Camille',
        'lastName': 'Martin',
        'phone': '+33612345678',
        'address': {
          'line1': '12 rue X',
          'line2': 'Bât B',
          'zip': '75011',
          'city': 'Paris',
          'country': 'France',
        },
      });
      expect(profile.displayName, 'Martin Camille');
      expect(profile.phone, '+33612345678');
      expect(profile.address!.oneLine, '12 rue X, Bât B, 75011 Paris');
    });

    test('nulls stay null, so the page can say "no address"', () {
      final profile = ExpedionProfile.fromJson(const {
        'email': 'a@b.fr',
        'firstName': null,
        'lastName': null,
        'phone': null,
        'address': null,
      });
      expect(profile.displayName, isNull);
      expect(profile.phone, isNull);
      expect(profile.address, isNull);
    });

    test('a null second line is not printed', () {
      final address = ExpedionAddress.fromJson(const {
        'line1': '12 rue X',
        'line2': null,
        'zip': '75011',
        'city': 'Paris',
        'country': 'France',
      });
      expect(address.oneLine, '12 rue X, 75011 Paris');
    });
  });

  group('ExpedionAddress.fromForm', () {
    test('needs street, postcode and city', () {
      expect(
        ExpedionAddress.fromForm(line1: '12 rue X', zip: '', city: 'Paris'),
        isNull,
      );
      expect(
        ExpedionAddress.fromForm(line1: '', zip: '75011', city: 'Paris'),
        isNull,
      );
    });

    test('defaults a blank country to France and trims', () {
      final address = ExpedionAddress.fromForm(
        line1: ' 12 rue X ',
        zip: '75011',
        city: 'Paris ',
      )!;
      expect(address.country, kDefaultCountry);
      expect(address.toJson(), {
        'line1': '12 rue X',
        'line2': '',
        'zip': '75011',
        'city': 'Paris',
        'country': 'France',
      });
    });

    test('a prefilled country alone is still a blank form', () {
      expect(
        ExpedionAddress.isBlankForm(line1: ' ', zip: '', city: ''),
        isTrue,
      );
      expect(
        ExpedionAddress.isBlankForm(line1: '', zip: '75011', city: ''),
        isFalse,
      );
    });
  });

  group('ExpedionProfileUpdate', () {
    test('sends only what was set', () {
      const update = ExpedionProfileUpdate(phone: '06 12 34 56 78');
      expect(update.toJson(), {'phone': '06 12 34 56 78'});
      expect(const ExpedionProfileUpdate().isEmpty, isTrue);
    });

    test('an empty phone is sent, because it clears the number', () {
      expect(const ExpedionProfileUpdate(phone: '').toJson(), {'phone': ''});
    });

    test('without drops the named fields and keeps the rest', () {
      final update = ExpedionProfileUpdate(
        phone: 'nope',
        address: ExpedionAddress.fromForm(
          line1: '12 rue X',
          zip: '75011',
          city: 'Paris',
        ),
      ).without({'phone'});
      expect(update.phone, isNull);
      expect(update.address, isNotNull);
    });

    test('survives a round trip through storage', () {
      final update = ExpedionProfileUpdate(
        firstName: 'Camille',
        phone: '0612345678',
        address: ExpedionAddress.fromForm(
          line1: '12 rue X',
          zip: '75011',
          city: 'Paris',
        ),
      );
      expect(
        ExpedionProfileUpdate.fromJson(update.toJson()).toJson(),
        update.toJson(),
      );
    });
  });

  group('ProfileResult.fromApi', () {
    test('a validation error names the refused fields', () {
      final result = ProfileResult.fromApi(ExpedionApiResult.failure(
        code: 'VALIDATION_ERROR',
        message: 'Invalid input',
        statusCode: 400,
        details: {
          'phone': 'Numéro invalide',
          'address.zip': ['Requis'],
        },
      ));
      expect(result.succeeded, isFalse);
      expect(result.isValidationError, isTrue);
      expect(result.details, {
        'phone': 'Numéro invalide',
        'address.zip': 'Requis',
      });
      expect(result.invalidFields, {'phone', 'address'});
    });

    test('reads zod-style fieldErrors too', () {
      final result = ProfileResult.fromApi(ExpedionApiResult.failure(
        code: 'VALIDATION_ERROR',
        message: 'Invalid input',
        details: {
          'fieldErrors': {
            'phone': ['Numéro invalide'],
          },
        },
      ));
      expect(result.invalidFields, {'phone'});
    });

    test('a Firebase-era session is told apart from a failure', () {
      final result = ProfileResult.fromApi(ExpedionApiResult.failure(
        code: 'PROFILE_NEEDS_ACCOUNT',
        message: 'No account',
        statusCode: 403,
      ));
      expect(result.needsAccount, isTrue);
      expect(result.isUnauthenticated, isFalse);
    });

    test('a 401 is an expired session', () {
      final result = ProfileResult.fromApi(ExpedionApiResult.failure(
        code: 'UNAUTHORIZED',
        message: 'No session',
        statusCode: 401,
      ));
      expect(result.isUnauthenticated, isTrue);
    });
  });

  group('names and phones', () {
    test('a name part the server would refuse is left out', () {
      expect(namePartOrNull('  '), isNull);
      expect(namePartOrNull('x' * (kNamePartMax + 1)), isNull);
      expect(namePartOrNull(' Camille '), 'Camille');
    });

    test('a French E.164 number is shown the national way', () {
      expect(formatFrenchPhone('+33612345678'), '06 12 34 56 78');
      expect(formatFrenchPhone('+442071234567'), '+442071234567');
    });
  });
}
