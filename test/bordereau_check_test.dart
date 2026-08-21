// Unit tests for the gate that decides whether an uploaded document is a
// bordereau.
//
// Worth pinning in both directions. Too strict and a real slip from a real
// auction house is refused with no way past it, which loses the quote outright;
// too loose and a payslip files a devis nobody can price. The rule is also the
// text of the "what counts as a valid slip" dialog, so a change here that is
// not a change there leaves the client reading instructions that no longer
// match what the button does.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:expedion_encheres/backend/bordereau_check.dart';

/// A slip with every required field on it. Individual tests blank out the one
/// they are about.
Map<String, dynamic> _slip({
  Object? bordereauNumber = '2024-0187',
  Object? auctionHouseName = 'Yssoire Enchères',
  Object? pickupAddress = '12 rue des Ventes',
  Object? pickupPostalCode = '63500',
  Object? pickupCity = 'Issoire',
  Object? lotDescription = 'Commode Louis XV, H. 90 x L. 120 x P. 55 cm',
  Object? declaredValueEur = 4200.50,
  Object? confidence = 0.92,
  Map<String, dynamic> extra = const {},
}) =>
    {
      'bordereauNumber': bordereauNumber,
      'auctionHouseName': auctionHouseName,
      'pickupAddress': pickupAddress,
      'pickupPostalCode': pickupPostalCode,
      'pickupCity': pickupCity,
      'lotDescription': lotDescription,
      'declaredValueEur': declaredValueEur,
      'confidence': confidence,
      ...extra,
    };

void main() {
  group('evaluate', () {
    test('accepts a slip carrying every required field', () {
      final check = BordereauCheck.evaluate(_slip());
      expect(check.status, BordereauCheckStatus.valid);
      expect(check.missing, isEmpty);
      expect(check.blocksSubmit, isFalse);
    });

    test('names the missing field rather than just refusing', () {
      final check = BordereauCheck.evaluate(_slip(declaredValueEur: null));
      expect(check.status, BordereauCheckStatus.invalid);
      expect(check.missing.map((f) => f.key), ['declaredValueEur']);
      expect(check.blocksSubmit, isTrue);
    });

    test('treats an empty string as a field the model did not find', () {
      // GPT-4.1 is told to answer null, and mostly does; Gemini answers "".
      final check = BordereauCheck.evaluate(_slip(bordereauNumber: '   '));
      expect(check.missing.map((f) => f.key), ['bordereauNumber']);
    });

    test('accepts a collection address given only as a town', () {
      // Plenty of slips print the house's name and town but no street. That is
      // a formatting quirk, not a document we cannot route from.
      final check = BordereauCheck.evaluate(_slip(pickupAddress: null));
      expect(check.status, BordereauCheckStatus.valid);
    });

    test('refuses when nothing at all locates the collection', () {
      final check = BordereauCheck.evaluate(_slip(
        pickupAddress: null,
        pickupPostalCode: null,
        pickupCity: null,
      ));
      expect(check.missing.map((f) => f.key), ['pickupAddress']);
    });

    test('does not require dimensions or weight', () {
      // French slips rarely print them and the confirm-details screen collects
      // them; requiring them here would refuse most real bordereaux.
      final check = BordereauCheck.evaluate(_slip());
      expect(check.extraction.containsKey('weightKg'), isFalse);
      expect(check.status, BordereauCheckStatus.valid);
    });

    test('refuses a filled-looking read the model has no confidence in', () {
      final check = BordereauCheck.evaluate(_slip(confidence: 0.2));
      expect(check.status, BordereauCheckStatus.invalid);
      // Nothing the client could add would fix it, so it reads as "wrong
      // document" rather than as one more missing field.
      expect(check.looksUnrelated, isTrue);
    });

    test('reads a slip with no confidence figure on its fields alone', () {
      final check = BordereauCheck.evaluate(_slip(confidence: null));
      expect(check.status, BordereauCheckStatus.valid);
      expect(check.confidence, isNull);
    });

    test('an all-null extraction is the wrong-file case', () {
      final check = BordereauCheck.evaluate(_slip(
        bordereauNumber: null,
        auctionHouseName: null,
        pickupAddress: null,
        pickupPostalCode: null,
        pickupCity: null,
        lotDescription: null,
        declaredValueEur: null,
        confidence: 0.9,
      ));
      expect(check.looksUnrelated, isTrue);
      expect(check.missing.length, kBordereauRequiredFields.length);
    });
  });

  group('quotePatch', () {
    test('maps the extraction onto the quote columns', () {
      final patch = BordereauCheck.evaluate(_slip(extra: {
        'saleDate': '2024-03-14',
        'buyerName': 'Marie Dupont-Leroy',
        'buyerEmail': 'marie@example.fr',
        'lengthCm': 120,
        'weightKg': 45.5,
      })).quotePatch;

      expect(patch['bordereauNumber'], '2024-0187');
      expect(patch['auctionHouseName'], 'Yssoire Enchères');
      expect(patch['pickupCity'], 'Issoire');
      expect(patch['description'], startsWith('Commode Louis XV'));
      expect(patch['saleDate'], '2024-03-14');
      expect(patch['firstName'], 'Marie');
      expect(patch['lastName'], 'Dupont-Leroy');
      expect(patch['email'], 'marie@example.fr');
      expect(patch['lengthCm'], 120);
      expect(patch['weightKg'], 45.5);
    });

    test('converts the total to cents without losing the centimes', () {
      final patch = BordereauCheck.evaluate(_slip()).quotePatch;
      expect(patch['declaredValueCents'], 420050);
    });

    test('drops an email the server would reject', () {
      // `createExpedionQuoteSchema` requires a well-formed address, and a zod
      // failure loses the whole devis — not just the field.
      final patch = BordereauCheck.evaluate(
        _slip(extra: {'buyerEmail': 'contact@'}),
      ).quotePatch;
      expect(patch.containsKey('email'), isFalse);
    });

    test('drops a sale date the server could not parse', () {
      final patch = BordereauCheck.evaluate(
        _slip(extra: {'saleDate': 'mars 2024'}),
      ).quotePatch;
      expect(patch.containsKey('saleDate'), isFalse);
    });

    test('sends nothing for a document that was refused', () {
      final patch = BordereauCheck.evaluate(_slip(confidence: 0.1)).quotePatch;
      expect(patch, isEmpty);
    });
  });

  group('bordereauMimeType', () {
    Uint8List bytes(List<int> head) =>
        Uint8List.fromList([...head, ...List.filled(32, 0)]);

    test('sniffs the real type ahead of the extension', () {
      // A phone that saved a JPEG as "bordereau.pdf" would otherwise be sent
      // to the model as a PDF and rejected there.
      expect(
        bordereauMimeType(bytes([0xFF, 0xD8, 0xFF]), 'bordereau.pdf'),
        'image/jpeg',
      );
      expect(
        bordereauMimeType(bytes([0x25, 0x50, 0x44, 0x46]), 'scan.jpg'),
        'application/pdf',
      );
      expect(
        bordereauMimeType(bytes([0x89, 0x50, 0x4E, 0x47]), 'scan'),
        'image/png',
      );
    });

    test('recognises webp by its RIFF container', () {
      final webp = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // RIFF
        0x00, 0x00, 0x00, 0x00, // size
        0x57, 0x45, 0x42, 0x50, // WEBP
      ]);
      expect(bordereauMimeType(webp, 'slip.webp'), 'image/webp');
    });

    test('falls back to the extension when nothing is recognisable', () {
      expect(bordereauMimeType(bytes([0x00]), 'slip.PDF'), 'application/pdf');
      expect(bordereauMimeType(bytes([0x00]), 'slip.jpeg'), 'image/jpeg');
    });

    test('refuses what the vision models cannot read', () {
      expect(bordereauMimeType(bytes([0x00]), 'slip.heic'), isNull);
      expect(bordereauMimeType(bytes([0x00]), 'slip.docx'), isNull);
      expect(bordereauMimeType(bytes([0x00]), 'slip'), isNull);
    });

    test('every offered extension resolves to an accepted mime type', () {
      for (final extension in kBordereauExtensions) {
        final resolved = bordereauMimeType(bytes([0x00]), 'slip.$extension');
        expect(resolved, isNotNull, reason: '.$extension resolves to nothing');
        expect(kBordereauMimeTypes, contains(resolved));
      }
    });
  });

  group('run', () {
    test('refuses an empty file before touching the network', () async {
      final check = await BordereauCheck.run(
        bytes: Uint8List(0),
        filename: 'slip.pdf',
      );
      expect(check.status, BordereauCheckStatus.invalid);
      expect(check.reasonEn, contains('empty'));
    });

    test('refuses a format no model can read', () async {
      final check = await BordereauCheck.run(
        bytes: Uint8List.fromList(List.filled(16, 0)),
        filename: 'slip.heic',
      );
      expect(check.status, BordereauCheckStatus.invalid);
      expect(check.reasonEn, contains('Unsupported'));
    });

    test('refuses a file too large for the extraction endpoint', () async {
      // Vercel rejects a request body over 4.5 MB and base64 costs a third on
      // top, so this has to be caught here or it surfaces as a network error.
      final check = await BordereauCheck.run(
        bytes: Uint8List.fromList(
          [0x25, 0x50, 0x44, 0x46, ...List.filled(kBordereauMaxBytes, 0)],
        ),
        filename: 'slip.pdf',
      );
      expect(check.status, BordereauCheckStatus.invalid);
      expect(check.reasonEn, contains('too large'));
    });
  });

  group('the standard the dialog prints', () {
    test('is the same list the button is gated on', () {
      // `showBordereauGuideDialog` renders `kBordereauRequiredFields`, so this
      // only guards against the set being emptied or quietly widened.
      expect(
        kBordereauRequiredFields.map((f) => f.key),
        containsAll(<String>[
          'bordereauNumber',
          'auctionHouseName',
          'pickupAddress',
          'lotDescription',
          'declaredValueEur',
        ]),
      );
      expect(kBordereauRequiredFields, hasLength(5));
    });

    test('gives every field copy in both languages', () {
      for (final field in kBordereauFields) {
        expect(field.labelFr, isNotEmpty);
        expect(field.labelEn, isNotEmpty);
      }
    });
  });
}
