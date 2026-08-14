import 'dart:convert';

import 'package:http/http.dart' as http;

import '/auth/expeditoo/expeditoo_auth_client.dart';
import '/auth/firebase_auth/auth_util.dart';

/// Client for the Expedion quotes API served by Expeditoo's Next.js app.
///
/// This is the whole data layer: quotes, their events and bordereau extraction
/// all come from the PostgreSQL database shared with Expeditoo. It replaces the
/// Airtable `CONTACTS` table the app used to read.
///
/// Configuration is one define, shared with [ExpeditooAuthClient] since the
/// same Next.js app serves both:
///
///   --dart-define=EXPEDION_API_BASE_URL=https://app.expeditoo.fr
///
/// ## Authentication
///
/// Calls carry the signed-in user's **Better Auth session token**, which the
/// server resolves to a real user (`requireExpedionCaller` in
/// `expeditoo-ship/src/lib/expedion-auth.ts`). Nothing about the caller's
/// identity is client-asserted, so this is safe to ship on web — the earlier
/// shared-key design, where a compiled-in key let any holder claim any UID, is
/// no longer used for user calls.
///
/// `EXPEDION_API_KEY` remains supported for one case only: a client still
/// signed in through Firebase, which has no Better Auth session for the server
/// to read. That path names the Firebase UID in `x-expedion-uid` and keeps the
/// old trust model, so **do not supply that define to a web build** — leave it
/// unset and web users will authenticate by session or not at all.
class ExpedionApi {
  ExpedionApi._();

  static const String baseUrl = String.fromEnvironment('EXPEDION_API_BASE_URL');

  /// Legacy app-level key. Native builds only — see the class comment.
  static const String _apiKey = String.fromEnvironment('EXPEDION_API_KEY');

  /// The API needs a base URL and *some* way to identify the caller: either a
  /// Better Auth session, or the legacy key paired with a Firebase UID.
  static bool get isConfigured =>
      baseUrl.isNotEmpty && (_hasSession || _hasLegacyKey);

  static bool get _hasSession =>
      ExpeditooAuthClient.isConfigured && ExpeditooAuthClient.hasToken;

  static bool get _hasLegacyKey =>
      _apiKey.isNotEmpty && currentUserUid.isNotEmpty;

  /// True when the caller is a real Better Auth user rather than the app
  /// asserting a UID. Screens can use this to decide whether an action that
  /// requires a verified identity is safe to offer.
  static bool get hasUserSession => _hasSession;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        // Prefer the user's own session. Only fall back to the app key when
        // there is none, so a signed-in user is never impersonated by it.
        if (_hasSession)
          'Authorization': 'Bearer ${ExpeditooAuthClient.token}'
        else if (_hasLegacyKey) ...{
          'Authorization': 'Bearer $_apiKey',
          'x-expedion-uid': currentUserUid,
        },
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

  static Future<ExpedionApiResult> acceptQuote(String id, String kind) => _send(
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
    if (baseUrl.isEmpty) {
      return ExpedionApiResult.failure(
        code: 'NOT_CONFIGURED',
        message: 'EXPEDION_API_BASE_URL must be provided at build time via '
            '--dart-define.',
      );
    }
    if (!_hasSession && !_hasLegacyKey) {
      return ExpedionApiResult.failure(
        code: 'UNAUTHENTICATED',
        statusCode: 401,
        message: 'Connectez-vous pour accéder à vos devis.',
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
