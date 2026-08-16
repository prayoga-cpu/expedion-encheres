/// A row of `expedion_quotes`, as the Expeditoo API returns it.
///
/// This replaces the untyped Airtable record maps the screens used to pass
/// around. Only the fields the Flutter app actually renders are lifted into
/// properties; the rest stay reachable through [raw] so a new server column
/// does not need a client release to be readable.
///
/// Money is cents on the wire throughout, matching the database. Nothing here
/// formats it — that is the UI's job, and doing it once at the edge is how the
/// old code ended up with prices that disagreed between screens.
library;

/// The two values `expedion_quote_kind` allows, spelled exactly as the server
/// enum spells them.
///
/// They live here because both the repository (which sends one) and the
/// validation page (which receives one) need the same spelling, and the two
/// previously disagreed: the client sent `insured`, which the Zod enum rejects,
/// so accepting an insured quote failed every time.
const String kQuoteKindStandard = 'standard';
const String kQuoteKindInsured = 'with_ad_valorem_insurance';

class ExpedionQuote {
  const ExpedionQuote(this.raw);

  final Map<String, dynamic> raw;

  String get id => _string('id');

  /// Human-facing reference. Falls back to the bordereau number, then to a
  /// short form of the id, so a card always has something to show.
  String get reference {
    final quoteNumber = _string('quoteNumber');
    if (quoteNumber.isNotEmpty) return quoteNumber;
    final bordereau = bordereauNumber;
    if (bordereau.isNotEmpty) return bordereau;
    final identifier = id;
    return identifier.length > 8 ? identifier.substring(0, 8) : identifier;
  }

  String get bordereauNumber => _string('bordereauNumber');
  bool get bordereauPaid => raw['bordereauPaid'] == true;
  String get bordereauDocUrl => _string('bordereauDocUrl');

  String get firstName => _string('firstName');
  String get lastName => _string('lastName');
  String get email => _string('email');
  String get phone => _string('phone');

  String get auctionHouseName => _string('auctionHouseName');
  String get pickupCity => _string('pickupCity');
  String get pickupPostalCode => _string('pickupPostalCode');
  String get deliveryCity => _string('deliveryCity');
  String get deliveryPostalCode => _string('deliveryPostalCode');

  String get description => _string('description');
  double? get lengthCm => _double('lengthCm');
  double? get widthCm => _double('widthCm');
  double? get heightCm => _double('heightCm');
  double? get weightKg => _double('weightKg');

  /// `pending`, `awaiting_confirmation`, `quoted`, `accepted`, `paid`,
  /// `assigned`, `escalated`, `in_transit`, `delivered`, `cancelled`.
  String get status => _string('status');

  /// `unpaid`, `pending`, `paid`, `refunded`.
  String get paymentStatus => _string('paymentStatus');

  int? get quoteStandardCents => _int('quoteStandardCents');
  int? get quoteInsuredCents => _int('quoteInsuredCents');
  int? get acceptedPriceCents => _int('acceptedPriceCents');

  /// [kQuoteKindStandard] or [kQuoteKindInsured], or `''` when the client has
  /// not accepted a price yet.
  String get acceptedKind => _string('acceptedKind');

  /// Whether the accepted price is the ad valorem one.
  bool get isInsuredKind => acceptedKind == kQuoteKindInsured;
  bool get quoteAvailable => raw['quoteAvailable'] == true;

  int? get declaredValueCents => _int('declaredValueCents');

  String get assignedCarrierId => _string('assignedCarrierId');
  bool get hasDriver => assignedCarrierId.isNotEmpty;

  /// Set once the job has been posted to Expeditoo's marketplace.
  String get listingId => _string('listingId');
  bool get isEscalated => listingId.isNotEmpty || status == 'escalated';

  DateTime? get requestedAt => _date('requestedAt');
  DateTime? get createdAt => _date('createdAt');
  DateTime? get storageFreeUntil => _date('storageFreeUntil');
  int? get storageDailyFeeCents => _int('storageDailyFeeCents');

  /// True once the client has accepted a price, whatever happens after.
  bool get isAccepted => const {
        'accepted',
        'paid',
        'assigned',
        'escalated',
        'in_transit',
        'delivered',
      }.contains(status);

  bool get isPaid =>
      paymentStatus == 'paid' ||
      const {
        'paid',
        'assigned',
        'escalated',
        'in_transit',
        'delivered',
      }.contains(status);

  /// The figure to bill or display: what the client accepted, else the
  /// standard price once one is published.
  int? get effectivePriceCents => acceptedPriceCents ?? quoteStandardCents;

  String _string(String key) {
    final value = raw[key];
    return value == null ? '' : value.toString();
  }

  int? _int(String key) {
    final value = raw[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _double(String key) {
    final value = raw[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  DateTime? _date(String key) {
    final value = raw[key];
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}

/// Thousands separator: U+202F narrow no-break space, per French typography.
///
/// Written as an escape rather than the literal character because the two
/// spaces below are indistinguishable on screen from a plain `U+0020`, and a
/// test comparing against the wrong one fails with output that looks identical
/// to what it expected.
const String kNarrowNoBreakSpace = '\u202F';

/// The gap before the currency sign: U+00A0, so the amount can never wrap away
/// from its `€`.
const String kNoBreakSpace = '\u00A0';

/// Formats a cents figure as euros, e.g. `12345` → `123,45 €`.
String formatCents(int? cents) {
  if (cents == null) return '—';
  final negative = cents < 0;
  final absolute = cents.abs();
  final euros = absolute ~/ 100;
  final remainder = absolute % 100;

  // Thousands separated by a narrow no-break space, as French typography does.
  final digits = euros.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(kNarrowNoBreakSpace);
    }
    buffer.write(digits[i]);
  }

  final sign = negative ? '-' : '';
  return '$sign$buffer,${remainder.toString().padLeft(2, '0')}$kNoBreakSpace€';
}
