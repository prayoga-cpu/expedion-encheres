import 'dart:convert';

import 'package:http/http.dart' as http;

import '/auth/firebase_auth/auth_util.dart';

/// Client for the Expedion quotes API served by Expeditoo's Next.js app.
///
/// This is the Phase A repoint: the same data the Flutter UI reads from
/// Airtable today, served from the PostgreSQL database shared with Expeditoo
/// (ROADMAP.md §5). Only the data layer moves — no screen changes are implied
/// by this file existing.
///
/// Configuration, all supplied at build time:
///
///   --dart-define=EXPEDION_API_BASE_URL=https://app.expeditoo.fr
///   --dart-define=EXPEDION_API_KEY=...
///
/// SECURITY. `EXPEDION_API_KEY` authenticates *the app*, not the signed-in
/// user; the server pairs it with the `x-expedion-uid` header to decide whose
/// quotes to return. A `--dart-define` is compiled into the bundle, so on
/// Flutter **web** this key is readable by anyone who opens devtools. Ship the
/// web target only once either (a) calls are proxied through a server that
/// holds the key, or (b) the Firebase → Better Auth migration lands and the
/// server can verify a real user token. On iOS/Android/macOS the compiled-in
/// key is the same trade-off the Airtable PAT already makes today.
class ExpedionApi {
  ExpedionApi._();

  static const String baseUrl =
      String.fromEnvironment('EXPEDION_API_BASE_URL');
  static const String _apiKey = String.fromEnvironment('EXPEDION_API_KEY');

  /// False until both defines are supplied, so callers can keep using the
  /// Airtable path during the migration instead of failing at runtime.
  static bool get isConfigured => baseUrl.isNotEmpty && _apiKey.isNotEmpty;

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'x-expedion-uid': currentUserUid,
        'Content-Type': 'application/json',
      };

  static Uri _uri(String path, [Map<String, String>? query]) => Uri.parse(
        '$baseUrl$path',
      ).replace(queryParameters: query?..removeWhere((_, v) => v.isEmpty));

  // ========================================
  // Quotes
  // ========================================

  static Future<ExpedionApiResult> listQuotes({
    String? status,
    String? bordereauNumber,
    int page = 1,
    int limit = 20,
  }) =>
      _send(
        () => http.get(
          _uri('/api/expedion/quotes', {
            if (status != null) 'status': status,
            if (bordereauNumber != null) 'bordereauNumber': bordereauNumber,
            'page': '$page',
            'limit': '$limit',
          }),
          headers: _headers,
        ),
      );

  static Future<ExpedionApiResult> getQuote(String id) => _send(
        () => http.get(_uri('/api/expedion/quotes/$id'), headers: _headers),
      );

  static Future<ExpedionApiResult> createQuote(
    Map<String, dynamic> payload,
  ) =>
      _send(
        () => http.post(
          _uri('/api/expedion/quotes'),
          headers: _headers,
          body: jsonEncode(payload),
        ),
      );

  /// Used by the confirm-details screen. Pass `confirmExtraction: true` to sign
  /// the extraction off, which releases the quote for pricing.
  static Future<ExpedionApiResult> updateQuote(
    String id,
    Map<String, dynamic> payload,
  ) =>
      _send(
        () => http.patch(
          _uri('/api/expedion/quotes/$id'),
          headers: _headers,
          body: jsonEncode(payload),
        ),
      );

  static Future<ExpedionApiResult> acceptQuote(String id, String kind) =>
      _send(
        () => http.post(
          _uri('/api/expedion/quotes/$id/accept'),
          headers: _headers,
          body: jsonEncode({'kind': kind}),
        ),
      );

  /// The shared status feed behind the tracking screen.
  static Future<ExpedionApiResult> listEvents(String id) => _send(
        () => http.get(
          _uri('/api/expedion/quotes/$id/events'),
          headers: _headers,
        ),
      );

  // ========================================
  // Extraction
  // ========================================

  /// Reads an uploaded bordereau. [data] is base64, with or without a
  /// `data:` prefix; PDF and JPEG are both accepted.
  ///
  /// Vision over a multi-page PDF is slow, so this carries a longer timeout
  /// than the CRUD calls.
  static Future<ExpedionApiResult> extractBordereau({
    required String data,
    required String mimeType,
    String? filename,
    String? quoteId,
  }) =>
      _send(
        () => http.post(
          _uri('/api/expedion/extract'),
          headers: _headers,
          body: jsonEncode({
            'data': data,
            'mimeType': mimeType,
            if (filename != null) 'filename': filename,
            if (quoteId != null) 'quoteId': quoteId,
          }),
        ),
        timeout: const Duration(seconds: 120),
      );

  // ========================================
  // Transport
  // ========================================

  static Future<ExpedionApiResult> _send(
    Future<http.Response> Function() request, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!isConfigured) {
      return ExpedionApiResult.failure(
        code: 'NOT_CONFIGURED',
        message:
            'EXPEDION_API_BASE_URL and EXPEDION_API_KEY must be provided at '
            'build time via --dart-define.',
      );
    }

    try {
      final response = await request().timeout(timeout);
      final decoded = response.body.isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ExpedionApiResult(
          success: true,
          statusCode: response.statusCode,
          data: decoded['data'],
          meta: decoded['meta'] as Map<String, dynamic>?,
        );
      }

      final error = decoded['error'] as Map<String, dynamic>?;
      return ExpedionApiResult.failure(
        statusCode: response.statusCode,
        code: error?['code']?.toString() ?? 'HTTP_${response.statusCode}',
        message: error?['message']?.toString() ?? 'Une erreur est survenue.',
      );
    } catch (e) {
      return ExpedionApiResult.failure(
        code: 'NETWORK_ERROR',
        message: 'Connexion impossible. Vérifiez votre réseau.',
        cause: e,
      );
    }
  }
}

class ExpedionApiResult {
  const ExpedionApiResult({
    required this.success,
    this.statusCode = 0,
    this.data,
    this.meta,
    this.code,
    this.message,
    this.cause,
  });

  factory ExpedionApiResult.failure({
    required String code,
    required String message,
    int statusCode = 0,
    Object? cause,
  }) =>
      ExpedionApiResult(
        success: false,
        statusCode: statusCode,
        code: code,
        message: message,
        cause: cause,
      );

  final bool success;
  final int statusCode;

  /// Decoded `data` from the response envelope: a `List` for collections, a
  /// `Map` for single resources.
  final dynamic data;
  final Map<String, dynamic>? meta;
  final String? code;
  final String? message;
  final Object? cause;

  List<dynamic> get list => data is List ? data as List<dynamic> : const [];
  Map<String, dynamic> get map =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : const {};
}
