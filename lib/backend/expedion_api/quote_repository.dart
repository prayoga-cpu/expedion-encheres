import '/backend/quote_draft.dart';
import 'expedion_api.dart';
import 'expedion_quote.dart';

/// The app's single source of quotes.
///
/// Everything the screens need — listing, searching, the counters, creating a
/// devis, accepting one — goes through here and out to Expeditoo's PostgreSQL
/// database. The Airtable `CONTACTS` table this replaces is no longer read or
/// written by any of these paths.
///
/// The repository deliberately returns [QuoteListResult] rather than throwing:
/// these screens all have an empty state and an error state to render, and an
/// exception crossing a `FutureBuilder` boundary produces neither.
class QuoteRepository {
  const QuoteRepository._();

  /// Page size for the quote lists. The server caps `limit` at 100.
  static const int pageSize = 50;

  // ========================================
  // Reading
  // ========================================

  /// The signed-in client's quotes, newest first (the server orders them).
  ///
  /// [status] filters server-side; [bordereauNumber] is the search box.
  static Future<QuoteListResult> list({
    String? status,
    String? bordereauNumber,
    int page = 1,
    int limit = pageSize,
  }) async {
    final result = await ExpedionApi.listQuotes(
      status: status,
      bordereauNumber: bordereauNumber,
      page: page,
      limit: limit,
    );

    if (!result.success) {
      return QuoteListResult._failure(result.code, result.message);
    }

    return QuoteListResult._success(
      [
        for (final row in result.list)
          if (row is Map) ExpedionQuote(row.cast<String, dynamic>()),
      ],
      total: (result.meta?['total'] as num?)?.toInt(),
    );
  }

  static Future<ExpedionQuote?> byId(String id) async {
    final result = await ExpedionApi.getQuote(id);
    return result.success && result.map.isNotEmpty
        ? ExpedionQuote(result.map)
        : null;
  }

  /// The three figures the "Mes devis" header shows.
  ///
  /// Derived from one full page rather than three filtered round trips: the
  /// counts must agree with each other and with the list under them, and three
  /// separate queries can disagree if a quote changes state between them.
  static Future<QuoteCounts> counts() async {
    final result = await list(limit: pageSize);
    if (!result.succeeded) return const QuoteCounts.empty();

    var validated = 0;
    var paid = 0;
    for (final quote in result.quotes) {
      if (quote.isAccepted) validated++;
      if (quote.isPaid) paid++;
    }
    return QuoteCounts(
      total: result.total ?? result.quotes.length,
      validated: validated,
      paid: paid,
    );
  }

  static Future<List<QuoteEvent>> events(String id) async {
    final result = await ExpedionApi.listEvents(id);
    if (!result.success) return const [];
    return [
      for (final row in result.list)
        if (row is Map) QuoteEvent(row.cast<String, dynamic>()),
    ];
  }

  /// The AI price estimate for a still-pending quote.
  static Future<AiEstimateResult> estimate(String id) async {
    final result = await ExpedionApi.estimateQuote(id);
    if (!result.success) {
      return AiEstimateResult._failure(result.code, result.message);
    }
    return AiEstimateResult._success(AiPriceEstimate(result.map));
  }

  // ========================================
  // Writing
  // ========================================

  /// Files a devis and returns it, or a failure the caller can show.
  ///
  /// The server prices it asynchronously and records a `pending` event, so the
  /// quote returned here will usually have no price yet — that is expected, not
  /// an error, and the UI should say "devis en cours de calcul" rather than
  /// waiting.
  static Future<QuoteWriteResult> create(Map<String, dynamic> payload) async {
    final result = await ExpedionApi.createQuote(_pruned(payload));
    if (!result.success) {
      return QuoteWriteResult._failure(result.code, result.message);
    }
    return QuoteWriteResult._success(ExpedionQuote(result.map));
  }

  /// Files a devis from what the landing page collected.
  ///
  /// The draft is deliberately thin — a visitor who has not signed in gave us
  /// a pickup house and a delivery city, not dimensions — so this fills what it
  /// can and leaves the rest for the confirm-details screen.
  static Future<QuoteWriteResult> createFromDraft(QuoteDraft draft) {
    final delivery = draft.deliveryParts;
    return create({
      'auctionHouseName': draft.pickup,
      'deliveryCity': delivery.city,
      'deliveryPostalCode': delivery.postcode,
      'email': draft.email,
      'phone': draft.phone,
      'declaredValueCents': _euroTextToCents(draft.hammerPrice),
      'description': draft.lotType,
      'comment': _draftComment(draft),
    });
  }

  static Future<QuoteWriteResult> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final result = await ExpedionApi.updateQuote(id, _pruned(payload));
    if (!result.success) {
      return QuoteWriteResult._failure(result.code, result.message);
    }
    return QuoteWriteResult._success(ExpedionQuote(result.map));
  }

  /// Accepts a published price. [insured] picks the ad valorem variant.
  static Future<QuoteWriteResult> accept(
    String id, {
    required bool insured,
  }) async {
    final result = await ExpedionApi.acceptQuote(
      id,
      insured ? kQuoteKindInsured : kQuoteKindStandard,
    );
    if (!result.success) {
      return QuoteWriteResult._failure(result.code, result.message);
    }
    return QuoteWriteResult._success(ExpedionQuote(result.map));
  }

  // ========================================
  // Helpers
  // ========================================

  /// Drops empty values before sending.
  ///
  /// The server's zod schema treats `""` as a supplied-but-blank string and
  /// writes it, which would overwrite a good value with an empty one on PATCH.
  /// Omitting the key leaves the column alone.
  static Map<String, dynamic> _pruned(Map<String, dynamic> payload) => {
        for (final entry in payload.entries)
          if (entry.value != null &&
              !(entry.value is String &&
                  (entry.value as String).trim().isEmpty))
            entry.key: entry.value is String
                ? (entry.value as String).trim()
                : entry.value,
      };

  /// "4 200 €" / "4.200,50" → cents. Returns null when there is no number,
  /// rather than 0, so "unknown value" and "worth nothing" stay distinct.
  static int? _euroTextToCents(String text) {
    if (text.trim().isEmpty) return null;
    // Strip everything that is not a digit or a separator, then normalise the
    // decimal mark: French writes "4 200,50", so a comma is the decimal.
    var cleaned = text.replaceAll(RegExp(r'[^\d.,]'), '');
    if (cleaned.isEmpty) return null;

    final lastComma = cleaned.lastIndexOf(',');
    final lastDot = cleaned.lastIndexOf('.');
    final decimalAt = lastComma > lastDot ? lastComma : lastDot;

    // A separator only marks decimals if exactly two digits follow it;
    // otherwise it is a thousands separator ("4.200" is four thousand).
    if (decimalAt >= 0 && cleaned.length - decimalAt - 1 == 2) {
      final whole =
          cleaned.substring(0, decimalAt).replaceAll(RegExp(r'[.,]'), '');
      final fraction = cleaned.substring(decimalAt + 1);
      final value = int.tryParse('$whole$fraction');
      return value;
    }
    cleaned = cleaned.replaceAll(RegExp(r'[.,]'), '');
    final whole = int.tryParse(cleaned);
    return whole == null ? null : whole * 100;
  }

  /// Carries the draft's free-text answers into the quote's comment so nothing
  /// the visitor typed is silently dropped.
  static String _draftComment(QuoteDraft draft) {
    final parts = <String>[
      if (draft.lotCount.isNotEmpty) 'Nombre de lots : ${draft.lotCount}',
      if (draft.lotType.isNotEmpty) 'Type de lot : ${draft.lotType}',
      if (draft.deadline.isNotEmpty)
        "Date limite d'enlèvement : ${draft.deadline}",
      if (draft.delivery.isNotEmpty) 'Livraison : ${draft.delivery}',
    ];
    return parts.join('\n');
  }
}

/// One row of a quote's status feed.
class QuoteEvent {
  const QuoteEvent(this.raw);

  final Map<String, dynamic> raw;

  String get status => raw['status']?.toString() ?? '';
  String get message => raw['message']?.toString() ?? '';

  /// `client`, `admin`, `system` or `carrier`.
  String get actor => raw['actor']?.toString() ?? '';

  DateTime? get createdAt {
    final value = raw['createdAt'];
    return value is String ? DateTime.tryParse(value)?.toLocal() : null;
  }
}

class QuoteCounts {
  const QuoteCounts({
    required this.total,
    required this.validated,
    required this.paid,
  });

  const QuoteCounts.empty()
      : total = 0,
        validated = 0,
        paid = 0;

  final int total;
  final int validated;
  final int paid;
}

class QuoteListResult {
  const QuoteListResult._success(this.quotes, {this.total})
      : succeeded = true,
        code = null,
        message = null;

  const QuoteListResult._failure(this.code, this.message)
      : succeeded = false,
        quotes = const [],
        total = null;

  final bool succeeded;
  final List<ExpedionQuote> quotes;

  /// Total matching rows on the server, which may exceed [quotes].length.
  final int? total;
  final String? code;
  final String? message;

  bool get isEmpty => succeeded && quotes.isEmpty;

  /// True when the failure is "you are not signed in" rather than a fault —
  /// the UI should offer a login, not an error.
  bool get needsSignIn => code == 'UNAUTHENTICATED' || code == 'UNAUTHORIZED';
}

class AiEstimateResult {
  const AiEstimateResult._success(this.estimate)
      : succeeded = true,
        code = null,
        message = null;

  const AiEstimateResult._failure(this.code, this.message)
      : succeeded = false,
        estimate = null;

  final bool succeeded;
  final AiPriceEstimate? estimate;
  final String? code;
  final String? message;

  bool get needsSignIn => code == 'UNAUTHENTICATED' || code == 'UNAUTHORIZED';

  /// The server refused because the quote already has a real price — stale,
  /// not an error worth alarming over.
  bool get alreadyPriced => code == 'QUOTE_ALREADY_PRICED';
}

class QuoteWriteResult {
  const QuoteWriteResult._success(this.quote)
      : succeeded = true,
        code = null,
        message = null;

  const QuoteWriteResult._failure(this.code, this.message)
      : succeeded = false,
        quote = null;

  final bool succeeded;
  final ExpedionQuote? quote;
  final String? code;
  final String? message;

  bool get needsSignIn => code == 'UNAUTHENTICATED' || code == 'UNAUTHORIZED';
}
