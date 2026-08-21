/// What a devis form will and will not accept, as plain functions.
///
/// These live outside the widget because they are not a presentation detail:
/// each one exists to stop a quote reaching Expeditoo in a state
/// `escalationBlockers`
/// (`expeditoo-ship/src/server/services/expedion-escalation.service.ts`) would
/// refuse — the failure mode being a quote that sits in the operator queue
/// until somebody telephones the client for the answer that was one field
/// away.
///
/// The form reads them twice over: once in each field's validator, to say what
/// is wrong under the field, and once to decide whether Submit is enabled at
/// all. One definition each is what keeps those two answers from disagreeing.
class QuoteFormRules {
  const QuoteFormRules._();

  // ========================================
  // Bounds
  // ========================================

  /// A lot heavier than this is a crane job, not a van job — and far more
  /// often it is "1200" typed into a field that wanted "12,00".
  static const double maxWeightKg = 5000.0;

  /// No single dimension of a lot that fits in a van exceeds 10 m.
  static const double maxDimensionCm = 1000.0;

  /// 5 M€ of ad valorem cover is an underwriting conversation, not a form
  /// submission.
  static const int maxDeclaredValueCents = 500000000;

  /// `buildTitle` uses the description as the listing's title from this length
  /// up, and falls back to "Retrait enchères <town>" below it.
  static const int minDescriptionChars = 5;

  static const int minAuctionHouseChars = 2;
  static const int minRecipientChars = 2;
  static const int maxCommentChars = 1000;
  static const int maxSlipNumberChars = 30;

  // ========================================
  // Parsing
  // ========================================

  /// Euro text to cents, for every way a French client writes a price.
  ///
  /// "1 250,50", "1250.5", "4 200 €" and "4.200" are all real answers to a
  /// declared-value field, and the last one is the trap: a naive parse reads
  /// the dot as a decimal point and insures a €4,200 lot for €4.20. The rule
  /// is the one a reader applies — the *later* separator is the decimal, a
  /// repeated separator is grouping, and a lone dot with exactly three digits
  /// behind it is grouping too (French writes four thousand as "4 200" or
  /// "4.200", and four-and-a-fifth as "4,2").
  ///
  /// Null when there is no number at all — distinct from zero, which is a
  /// stated value of nothing.
  static int? euroToCents(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d.,]'), '');
    if (!cleaned.contains(RegExp(r'\d'))) return null;

    final lastComma = cleaned.lastIndexOf(',');
    final lastDot = cleaned.lastIndexOf('.');

    int decimalAt;
    if (lastComma >= 0 && lastDot >= 0) {
      // Both present: whichever comes last is the decimal mark.
      decimalAt = lastComma > lastDot ? lastComma : lastDot;
    } else if (lastComma >= 0 || lastDot >= 0) {
      final separator = lastComma >= 0 ? ',' : '.';
      final position = lastComma >= 0 ? lastComma : lastDot;
      final occurrences = separator.allMatches(cleaned).length;
      final digitsAfter = cleaned.length - position - 1;
      // Three digits behind a lone separator is grouping whichever separator
      // it is. "4,200" is ambiguous — French reads it as four-and-a-fifth,
      // English as four thousand two hundred — and this field sizes the ad
      // valorem cover, so the tie goes to the reading that cannot
      // under-insure. Nobody declares a €4.20 lot at auction.
      final grouping = occurrences > 1 || digitsAfter == 3;
      decimalAt = grouping ? -1 : position;
    } else {
      decimalAt = -1;
    }

    final separators = RegExp(r'[.,]');
    final wholeText = (decimalAt < 0 ? cleaned : cleaned.substring(0, decimalAt))
        .replaceAll(separators, '');
    final fractionText = decimalAt < 0
        ? ''
        : cleaned.substring(decimalAt + 1).replaceAll(separators, '');

    final whole = int.tryParse(wholeText.isEmpty ? '0' : wholeText);
    if (whole == null) return null;
    // Past this, `whole * 100` would wrap on 64 bits and a twenty-digit entry
    // would come back as a few centimes — under the cap, and insured for
    // nothing. Anything this large is out of range whatever the exact value.
    if (whole > maxDeclaredValueCents) return maxDeclaredValueCents + 1;
    // Anything past the centime is not money the insurer will price.
    final cents = int.tryParse(fractionText.padRight(2, '0').substring(0, 2));
    return cents == null ? null : whole * 100 + cents;
  }

  /// French keyboards produce "12,5"; the numeric keypad produces "12.5".
  static double? number(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  // ========================================
  // Required
  // ========================================

  static bool isAuctionHouse(String raw) =>
      raw.trim().length >= minAuctionHouseChars;

  static bool isDescription(String raw) =>
      raw.trim().length >= minDescriptionChars;

  /// Blocker: `weight`. The upper bound is a typo guard, not a service limit.
  static bool isWeight(String raw) {
    final parsed = number(raw);
    return parsed != null && parsed > 0 && parsed <= maxWeightKg;
  }

  /// Sizes the ad valorem cover, so zero is as unusable as blank.
  static bool isDeclaredValue(String raw) {
    final cents = euroToCents(raw);
    return cents != null && cents > 0 && cents <= maxDeclaredValueCents;
  }

  // ========================================
  // Optional, but not optional to get right
  // ========================================

  /// All three or none. `buildDescription` prints dimensions only as a
  /// complete set, so two out of three reach the carrier as nothing at all.
  static bool areDimensions(String length, String width, String height) {
    final entries = [length, width, height];
    final filled = entries.where((raw) => raw.trim().isNotEmpty);
    if (filled.isEmpty) return true;
    if (filled.length < 3) return false;
    return filled.every(isDimension);
  }

  static bool isDimension(String raw) {
    final parsed = number(raw);
    return parsed != null && parsed > 0 && parsed <= maxDimensionCm;
  }

  static bool isRecipient(String raw) =>
      raw.trim().isEmpty || raw.trim().length >= minRecipientChars;

  /// `06 12 34 56 78`, `+33 6 12 34 56 78` and `0033612345678` are the three
  /// ways a French client writes the number a driver will actually ring.
  /// Empty passes — the field is optional; wrong does not.
  static bool isPhone(String raw) {
    if (raw.trim().isEmpty) return true;
    var digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');

    // International prefix, then the trunk zero that "+33 (0)6 12 34 56 78"
    // writes out and the international form drops. Printed that way on half
    // the letterheads in France, so refusing it would block Submit on an
    // optional field for a number that is perfectly good.
    for (final prefix in ['+33', '0033']) {
      if (digits.startsWith(prefix)) {
        var rest = digits.substring(prefix.length);
        if (rest.startsWith('0')) rest = rest.substring(1);
        digits = '0$rest';
        break;
      }
    }
    return RegExp(r'^0[1-9]\d{8}$').hasMatch(digits);
  }
}
