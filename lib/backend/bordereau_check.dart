import 'dart:convert';
import 'dart:typed_data';

import '/backend/expedion_api/expedion_api.dart';

/// Reads an uploaded bordereau before the devis is filed, and decides whether
/// it is one at all.
///
/// The upload form used to accept any PDF and send it: a payslip, a blank page
/// or a photo of a cat all filed a quote that nobody could price, and the
/// client only found out days later when the devis came back empty. The check
/// runs the same GPT-4.1 Vision extraction the server does
/// (`POST /api/expedion/extract`, `expedion-extraction.service.ts`) at pick
/// time, so "this is not a bordereau" is said while the file picker is still
/// in living memory.
///
/// Two things come out of it and both matter:
///
///  * a **verdict** — [BordereauCheckStatus] — that gates the submit button;
///  * the **fields themselves**, already mapped onto the quote columns
///    ([BordereauCheck.quotePatch]), so a slip that passes also prefills the
///    devis instead of arriving as a bare document URL.
///
/// Extraction is never the last word on accuracy — the client still confirms
/// every field on *Confirmer les détails* — so this is a floor, not a
/// judgement: it rejects documents that are missing the things a devis cannot
/// be produced without, and lets everything else through to be corrected.

// ========================================
// The standard
// ========================================

/// How a value should be rendered in the preview.
enum BordereauValueKind { text, euros, centimetres, kilograms, date }

/// One line of the extraction preview — and, when [isRequired], one of the
/// conditions a document has to satisfy before the devis can be sent.
class BordereauField {
  const BordereauField(
    this.key,
    this.labelFr,
    this.labelEn, {
    this.isRequired = false,
    this.alternateKeys = const <String>[],
    this.kind = BordereauValueKind.text,
  });

  /// Key in the extraction JSON (`bordereauExtractionSchema` on the server).
  final String key;
  final String labelFr;
  final String labelEn;

  /// Blocks the submit button when neither [key] nor any of [alternateKeys]
  /// came back.
  final bool isRequired;

  /// Keys that satisfy this requirement in [key]'s place.
  ///
  /// Only the collection address uses them: a slip that names the town but
  /// prints the auction house's street nowhere is still a slip we can route
  /// from, and rejecting it would turn a formatting quirk into a dead end.
  final List<String> alternateKeys;

  final BordereauValueKind kind;
}

class BordereauSection {
  const BordereauSection(this.titleFr, this.titleEn, this.fields);

  final String titleFr;
  final String titleEn;
  final List<BordereauField> fields;
}

/// What we read off a bordereau, grouped the way the preview shows it.
///
/// The required five are the ones a devis genuinely cannot be produced
/// without: who sold it, under which slip, where it is collected, what it is,
/// and what it is worth. Dimensions and weight are *not* required here even
/// though pricing wants them — French slips rarely print them, and the
/// confirm-details screen exists to collect them. Requiring them would reject
/// most real bordereaux.
const kBordereauSections = <BordereauSection>[
  BordereauSection('La vente', 'The sale', [
    BordereauField('bordereauNumber', 'Numéro de bordereau', 'Slip number',
        isRequired: true),
    BordereauField('auctionHouseName', 'Maison de ventes', 'Auction house',
        isRequired: true),
    BordereauField('saleDate', 'Date de la vente', 'Sale date',
        kind: BordereauValueKind.date),
  ]),
  BordereauSection('Le retrait', 'Collection', [
    BordereauField('pickupAddress', 'Adresse de retrait', 'Collection address',
        isRequired: true,
        alternateKeys: ['pickupPostalCode', 'pickupCity']),
    BordereauField('pickupPostalCode', 'Code postal', 'Postal code'),
    BordereauField('pickupCity', 'Ville', 'Town'),
  ]),
  BordereauSection('Le lot', 'The lot', [
    BordereauField('lotDescription', 'Désignation du lot', 'Lot description',
        isRequired: true),
    BordereauField('declaredValueEur', 'Montant total TTC', 'Total incl. VAT',
        isRequired: true, kind: BordereauValueKind.euros),
    BordereauField('lengthCm', 'Longueur', 'Length',
        kind: BordereauValueKind.centimetres),
    BordereauField('widthCm', 'Largeur', 'Width',
        kind: BordereauValueKind.centimetres),
    BordereauField('heightCm', 'Hauteur', 'Height',
        kind: BordereauValueKind.centimetres),
    BordereauField('weightKg', 'Poids', 'Weight',
        kind: BordereauValueKind.kilograms),
  ]),
  BordereauSection("L'acheteur", 'The buyer', [
    BordereauField('buyerName', 'Nom', 'Name'),
    BordereauField('buyerAddress', 'Adresse', 'Address'),
    BordereauField('buyerPostalCode', 'Code postal', 'Postal code'),
    BordereauField('buyerCity', 'Ville', 'Town'),
    BordereauField('buyerPhone', 'Téléphone', 'Phone'),
    BordereauField('buyerEmail', 'E-mail', 'Email'),
  ]),
];

/// Every field, in preview order.
List<BordereauField> get kBordereauFields =>
    [for (final section in kBordereauSections) ...section.fields];

/// The subset the submit button is gated on.
List<BordereauField> get kBordereauRequiredFields =>
    [for (final field in kBordereauFields) if (field.isRequired) field];

/// What the file picker offers and what the vision models can actually read.
///
/// HEIC is deliberately absent: an iPhone photo in its native format is
/// rejected by OpenAI outright, so accepting it here would only move the
/// failure to a slower, less explicable place.
const kBordereauMimeTypes = <String>{
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/webp',
};

/// Extensions handed to the file picker, matching [kBordereauMimeTypes].
const kBordereauExtensions = <String>['pdf', 'jpg', 'jpeg', 'png', 'webp'];

/// Ceiling on the raw file, before base64.
///
/// The extraction endpoint is a Vercel serverless function, and those refuse a
/// request body over 4.5 MB. Base64 costs a third on top, so 3 MB of PDF is
/// the largest thing that can reach the model — anything above it would fail
/// as an opaque network error rather than as "your scan is too big".
const int kBordereauMaxBytes = 3 * 1024 * 1024;

/// Below this, treat the read as a miss even when the fields look filled.
///
/// The model reports its own confidence and is asked never to guess, so a low
/// figure alongside plausible-looking values means it inferred them from
/// something that was not a bordereau.
const double kBordereauMinConfidence = 0.35;

// ========================================
// The verdict
// ========================================

enum BordereauCheckStatus {
  /// No document attached yet.
  idle,

  /// The extraction is in flight.
  checking,

  /// A bordereau we can work from: every required field came back.
  valid,

  /// Read, and it is not a bordereau — or not a complete one.
  invalid,

  /// Could not be read at all: the service is down, the network failed, or
  /// nobody is signed in. Deliberately **not** a rejection — see
  /// [BordereauCheck.blocksSubmit].
  unavailable,
}

/// The outcome of checking one document.
class BordereauCheck {
  const BordereauCheck._({
    required this.status,
    this.extraction = const <String, dynamic>{},
    this.missing = const <BordereauField>[],
    this.confidence,
    this.errorCode,
    this.reasonFr,
    this.reasonEn,
  });

  const BordereauCheck.idle() : this._(status: BordereauCheckStatus.idle);

  const BordereauCheck.checking()
      : this._(status: BordereauCheckStatus.checking);

  /// Turned away before the network was touched — wrong file type, too large,
  /// empty. [reasonFr]/[reasonEn] say which.
  const BordereauCheck.rejected({
    required String reasonFr,
    required String reasonEn,
  }) : this._(
          status: BordereauCheckStatus.invalid,
          reasonFr: reasonFr,
          reasonEn: reasonEn,
        );

  final BordereauCheckStatus status;

  /// The raw extraction JSON, keyed as `bordereauExtractionSchema`.
  final Map<String, dynamic> extraction;

  /// Required fields the model could not find. Empty when [status] is not
  /// [BordereauCheckStatus.invalid], and also empty for a client-side
  /// rejection, which has a [reasonFr] instead.
  final List<BordereauField> missing;

  final double? confidence;

  /// The API failure that made this [BordereauCheckStatus.unavailable];
  /// `xpdApiErrorMessage` turns it into copy.
  final String? errorCode;

  final String? reasonFr;
  final String? reasonEn;

  bool get isChecking => status == BordereauCheckStatus.checking;
  bool get isValid => status == BordereauCheckStatus.valid;
  bool get isInvalid => status == BordereauCheckStatus.invalid;
  bool get isUnavailable => status == BordereauCheckStatus.unavailable;

  /// Whether the submit button should stay disabled.
  ///
  /// Only a document we read and rejected blocks. A check we could not run —
  /// no `OPENAI_API_KEY` on the server, a flaky connection, a signed-out
  /// visitor — must not, because that would take the entire quote funnel down
  /// with one unset environment variable. Those uploads go through with a
  /// visible "we could not verify this" notice and are checked by hand.
  bool get blocksSubmit => isChecking || isInvalid;

  /// True when the model read the document but found none of what a bordereau
  /// carries — the "you have uploaded the wrong file" case, as opposed to
  /// "your bordereau is missing its total".
  bool get looksUnrelated =>
      isInvalid &&
      reasonFr == null &&
      missing.length == kBordereauRequiredFields.length;

  /// Whether [field] came back with a usable value.
  bool has(BordereauField field) =>
      _valueOf(extraction, field.key) != null ||
      field.alternateKeys.any((k) => _valueOf(extraction, k) != null);

  /// The extracted value for [field], or null when the model did not find it.
  Object? valueOf(BordereauField field) => _valueOf(extraction, field.key);

  /// The extraction mapped onto `createExpedionQuoteSchema`'s columns, so a
  /// slip that passes the check also fills the devis.
  ///
  /// Mirrors `expedionExtractionService.toQuotePatch` on the server, minus the
  /// keys that schema does not accept from a client. Empty and unparseable
  /// values are dropped rather than sent as blanks: `QuoteRepository.create`
  /// prunes empty strings, but a malformed email would fail the whole zod
  /// parse and lose the quote, so it is filtered here.
  Map<String, dynamic> get quotePatch {
    if (!isValid && !isUnavailable) return const <String, dynamic>{};

    final patch = <String, dynamic>{};
    void put(String key, Object? value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      patch[key] = value;
    }

    String? text(String key) => _valueOf(extraction, key)?.toString().trim();
    num? number(String key) {
      final value = _valueOf(extraction, key);
      return value is num ? value : num.tryParse(value?.toString() ?? '');
    }

    put('bordereauNumber', text('bordereauNumber'));
    put('saleDate', _isoDate(text('saleDate')));
    put('auctionHouseName', text('auctionHouseName'));
    put('pickupAddress', text('pickupAddress'));
    put('pickupPostalCode', text('pickupPostalCode'));
    put('pickupCity', text('pickupCity'));

    final buyer = (text('buyerName') ?? '').split(RegExp(r'\s+'));
    if (buyer.isNotEmpty && buyer.first.isNotEmpty) {
      put('firstName', buyer.first);
      put('lastName', buyer.skip(1).join(' '));
    }
    put('clientAddress', text('buyerAddress'));
    put('clientPostalCode', text('buyerPostalCode'));
    put('clientCity', text('buyerCity'));
    put('phone', text('buyerPhone'));

    // The server's zod schema requires a well-formed address here; a model
    // that read "contact@" off a footer would otherwise 400 the whole create.
    final email = text('buyerEmail');
    if (email != null && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      put('email', email);
    }

    put('description', text('lotDescription'));
    put('lengthCm', number('lengthCm'));
    put('widthCm', number('widthCm'));
    put('heightCm', number('heightCm'));
    put('weightKg', number('weightKg'));

    final value = number('declaredValueEur');
    if (value != null && value >= 0) {
      put('declaredValueCents', (value * 100).round());
    }

    return patch;
  }

  // ========================================
  // Running the check
  // ========================================

  /// Reads [bytes] and decides whether they are a bordereau.
  ///
  /// [filename] is only a hint — the type is sniffed from the leading bytes
  /// first, because a `.pdf` that is really a JPEG (or the other way round)
  /// would otherwise be sent under a mime type the model rejects.
  static Future<BordereauCheck> run({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (bytes.isEmpty) {
      return const BordereauCheck.rejected(
        reasonFr: 'Le fichier est vide.',
        reasonEn: 'That file is empty.',
      );
    }

    final mimeType = bordereauMimeType(bytes, filename);
    if (mimeType == null) {
      return const BordereauCheck.rejected(
        reasonFr: 'Format non accepté. Envoyez un PDF ou une photo '
            '(JPG, PNG, WEBP).',
        reasonEn: 'Unsupported format. Upload a PDF or a photo '
            '(JPG, PNG, WEBP).',
      );
    }

    if (bytes.length > kBordereauMaxBytes) {
      const megabytes = kBordereauMaxBytes ~/ (1024 * 1024);
      return const BordereauCheck.rejected(
        reasonFr: 'Fichier trop lourd (maximum $megabytes Mo). '
            'Compressez-le ou photographiez le bordereau.',
        reasonEn: 'File too large (maximum $megabytes MB). '
            'Compress it or photograph the slip instead.',
      );
    }

    final result = await ExpedionApi.extractBordereau(
      data: base64Encode(bytes),
      mimeType: mimeType,
      filename: filename.isEmpty ? null : filename,
    );

    if (!result.success) {
      return BordereauCheck._(
        status: BordereauCheckStatus.unavailable,
        errorCode: result.code,
      );
    }

    final extraction = result.map['extraction'];
    if (extraction is! Map) {
      // A 200 without an extraction is the server failing in a shape we have
      // no reading of; treat it as "could not check", not "not a bordereau".
      return const BordereauCheck._(
        status: BordereauCheckStatus.unavailable,
        errorCode: 'EXTRACTION_UNAVAILABLE',
      );
    }

    return evaluate(extraction.cast<String, dynamic>());
  }

  /// The verdict for an already-fetched [extraction]. Split out from [run] so
  /// the rule is testable without a network.
  static BordereauCheck evaluate(Map<String, dynamic> extraction) {
    final raw = extraction['confidence'];
    final confidence = raw is num ? raw.toDouble() : null;

    final missing = <BordereauField>[];
    for (final field in kBordereauRequiredFields) {
      final found = _valueOf(extraction, field.key) != null ||
          field.alternateKeys.any((k) => _valueOf(extraction, k) != null);
      if (!found) missing.add(field);
    }

    // A confidence miss is reported as "nothing recognised" rather than as a
    // sixth requirement, because there is no field the client could add to
    // fix it — the document itself is wrong.
    final belowFloor =
        confidence != null && confidence < kBordereauMinConfidence;

    return BordereauCheck._(
      status: missing.isEmpty && !belowFloor
          ? BordereauCheckStatus.valid
          : BordereauCheckStatus.invalid,
      extraction: extraction,
      missing: belowFloor ? kBordereauRequiredFields : missing,
      confidence: confidence,
    );
  }
}

// ========================================
// Helpers
// ========================================

/// The document's real type, sniffed from its magic bytes and falling back to
/// the extension. Null when it is not something the models can read.
String? bordereauMimeType(Uint8List bytes, String filename) {
  bool startsWith(List<int> signature, {int offset = 0}) {
    if (bytes.length < offset + signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[offset + i] != signature[i]) return false;
    }
    return true;
  }

  if (startsWith([0x25, 0x50, 0x44, 0x46])) return 'application/pdf'; // %PDF
  if (startsWith([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (startsWith([0x89, 0x50, 0x4E, 0x47])) return 'image/png';
  if (startsWith([0x52, 0x49, 0x46, 0x46]) && // RIFF ... WEBP
      startsWith([0x57, 0x45, 0x42, 0x50], offset: 8)) {
    return 'image/webp';
  }

  switch (filename.toLowerCase().split('.').last) {
    case 'pdf':
      return 'application/pdf';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    default:
      return null;
  }
}

/// Treats null, empty strings and whitespace as "not found", so a model that
/// answers `""` instead of `null` does not read as a filled field.
Object? _valueOf(Map<String, dynamic> extraction, String key) {
  final value = extraction[key];
  if (value == null) return null;
  if (value is String) return value.trim().isEmpty ? null : value.trim();
  return value;
}

/// Keeps only a date the server's `looseDate` will parse.
String? _isoDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value) == null ? null : value;
}
