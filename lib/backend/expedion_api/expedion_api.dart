import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '/auth/expeditoo/expeditoo_auth_client.dart';
import 'expedion_config.dart';
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

  /// Resolved from [ExpedionConfig]: the `--dart-define` when given, otherwise
  /// localhost in debug and the production deployment in release. It is never
  /// empty, so a missing build flag is no longer a failure mode.
  static String get baseUrl => ExpedionConfig.baseUrl;

  /// Legacy app-level key. Native builds only — see the class comment.
  static const String _apiKey = String.fromEnvironment('EXPEDION_API_KEY');

  /// The API always has a host now; what it may lack is a way to identify the
  /// caller — a Better Auth session, a Firebase ID token, or the legacy key
  /// paired with a Firebase UID.
  static bool get isConfigured =>
      _hasSession || _hasFirebaseToken || _hasLegacyKey;

  static bool get _hasSession =>
      ExpeditooAuthClient.isConfigured && ExpeditooAuthClient.hasToken;

  /// A signed-in Firebase user's ID token.
  ///
  /// Google signs it, so the server can verify the UID rather than take the
  /// app's word for it — which is what lets accounts predating the Better Auth
  /// migration reach the API from a browser, where [_apiKey] must never be.
  /// `jwtTokenStream` in `auth_util.dart` keeps this fresh; Firebase rotates
  /// the token hourly.
  static bool get _hasFirebaseToken => currentJwtToken.isNotEmpty;

  /// Never true on web, whatever the build passed.
  ///
  /// The class comment says the key must not reach a web build; `vercel-build.sh`
  /// passed it anyway, which put a credential that can name any UID into a
  /// public bundle. A comment is not an enforcement mechanism, so the check
  /// lives here too — the only build this project produces is `flutter build
  /// web`, and on web the honest options are a verified session or nothing.
  static bool get _hasLegacyKey =>
      !kIsWeb && _apiKey.isNotEmpty && currentUserUid.isNotEmpty;

  /// True when the caller is a real Better Auth user rather than the app
  /// asserting a UID. Screens can use this to decide whether an action that
  /// requires a verified identity is safe to offer.
  static bool get hasUserSession => _hasSession;

  /// Credentials, strongest first.
  ///
  /// A Better Auth session and a Firebase ID token both identify a real user
  /// the server can verify. The shared key identifies only the app and lets its
  /// holder claim any UID, so it is the last resort and is only reached when
  /// nobody is signed in by either system.
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_hasSession)
          'Authorization': 'Bearer ${ExpeditooAuthClient.token}'
        else if (_hasFirebaseToken)
          'Authorization': 'Bearer $currentJwtToken'
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

  /// Who the presented credential resolves to, and whether they are an admin.
  static Future<ExpedionApiResult> me() => _send(
        () => http.get(_uri('/api/expedion/me'), headers: _headers),
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

  /// The client's attestation that a milestone the transporter recorded really
  /// happened.
  ///
  /// It moves nothing on either side: the transporter drives the status and
  /// this records that the client agrees, so the two are separate facts about
  /// one moment (expeditoo-ship
  /// docs/specs/transport_status_confirmation_spec.md §1).
  ///
  /// [milestone] is `PICKED_UP` or `DELIVERED` — the two moments goods change
  /// hands, and the only two the client is ever asked about.
  static Future<ExpedionApiResult> confirmMilestone(
    String id,
    String milestone,
  ) =>
      _send(
        () => http.post(
          _uri('/api/expedion/quotes/$id/confirm'),
          headers: _headers,
          body: jsonEncode({'milestone': milestone}),
        ),
      );

  /// The shared status feed behind the tracking screen.
  /// The pickup and delivery photos the transporter took, grouped by stage.
  ///
  /// `data` is a map of two lists — `pickup` and `delivery` — each entry
  /// carrying a `url`, the coordinates, the address when one could be named,
  /// and both timestamps. Both keys are always present, empty when the run has
  /// not reached that stage, so a screen can render the sections without
  /// checking whether the key exists (expeditoo-ship
  /// docs/specs/shipment_photos_spec.md §7.3).
  ///
  /// The `url` is a path on the Expeditoo API, not an image host: it
  /// authorises the caller and only then redirects to a short-lived link, so
  /// it must be fetched with [photoHeaders] and cannot be handed to anything
  /// that would load it anonymously.
  static Future<ExpedionApiResult> listShipmentPhotos(String id) => _send(
        () => http.get(
          _uri('/api/expedion/quotes/$id/photos'),
          headers: _headers,
        ),
      );

  /// The absolute URL of a photo whose `url` came back relative.
  static String photoUrl(String path) =>
      path.startsWith('http') ? path : '$baseUrl$path';

  /// Headers for `Image.network` on a photo URL.
  ///
  /// The same credential every other call carries, minus the JSON content type
  /// — the server authorises the reader before it will redirect to the object,
  /// so an image request with no credential gets a 401 rather than a picture.
  static Map<String, String> get photoHeaders {
    final headers = Map<String, String>.from(_headers);
    headers.remove('Content-Type');
    return headers;
  }

  static Future<ExpedionApiResult> listEvents(String id) => _send(
        () => http.get(
          _uri('/api/expedion/quotes/$id/events'),
          headers: _headers,
        ),
      );

  /// The client-facing AI price estimate for a still-pending quote. Cached
  /// server-side after the first call — reopening the sheet is cheap.
  static Future<ExpedionApiResult> estimateQuote(String id) => _send(
        () => http.post(
          _uri('/api/expedion/quotes/$id/estimate'),
          headers: _headers,
        ),
        timeout: const Duration(seconds: 60),
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
  // Uploads
  // ========================================

  /// Stores a bordereau or a lot photo and returns `{ fileId, url, kind }`.
  ///
  /// [data] is base64 with or without a `data:` prefix, exactly as
  /// [extractBordereau] takes it — deliberately the same shape, because the
  /// two calls carry the same bytes and a caller that has already encoded
  /// them for the check can hand the same string to both rather than paying
  /// for a second `base64Encode` of a 3 MB scan.
  ///
  /// `data.url` is an absolute, permanent `…/api/expedion/files/<id>` link on
  /// the ship, which is what goes into `bordereauDocUrl` / `photoUrls`. The
  /// object key is deliberately never returned: the bytes live in a private
  /// bucket and are only served through that route, to the file's owner or an
  /// admin. Nothing here is publicly readable, which is the point — a
  /// bordereau carries the buyer's name, address and the declared value of
  /// what they bought.
  ///
  /// The server refuses anything that is not a PDF/JPEG/PNG/WEBP (415) or
  /// larger than 3 MB once decoded (413). Those refusals come
  /// back as ordinary [ExpedionApiResult] failures with a `code`, so callers
  /// can say which one happened instead of showing "upload failed".
  static Future<ExpedionApiResult> uploadFile({
    required String data,
    required String mimeType,
    String? filename,
    String kind = 'bordereau',
  }) =>
      _send(
        () => http.post(
          _uri('/api/expedion/upload'),
          headers: _headers,
          body: jsonEncode({
            'data': data,
            'mimeType': mimeType,
            if (filename != null) 'filename': filename,
            'kind': kind,
          }),
        ),
        // A 3 MB scan is ~4 MB of base64 on the wire and the function still has
        // to put it to R2, so this gets more room than the CRUD calls — but far
        // less than extraction, which waits on a vision model.
        timeout: const Duration(seconds: 60),
      );

  // ========================================
  // Support chat
  // ========================================

  /// The signed-in visitor's support thread, oldest message first.
  ///
  /// Creates the thread on first call, so there is no separate "start a
  /// conversation" step — an empty list simply means nobody has written yet.
  /// The same conversation is what Expeditoo's operators answer from
  /// `/admin/support`, which is the whole point: the old contact form posted
  /// into Airtable, where a reply had to leave the product entirely.
  static Future<ExpedionApiResult> supportThread({int limit = 50}) => _send(
        () => http.get(
          _uri('/api/expedion/support', {'limit': '$limit'}),
          headers: _headers,
        ),
      );

  /// Posts one message into that thread.
  static Future<ExpedionApiResult> sendSupportMessage(String content) => _send(
        () => http.post(
          _uri('/api/expedion/support'),
          headers: _headers,
          body: jsonEncode({'content': content}),
        ),
      );

  // ========================================
  // Profile
  // ========================================

  /// The signed-in client's name, phone and postal address.
  ///
  /// Needs a Better Auth session. A Firebase-era session or the legacy key gets
  /// 403 `PROFILE_NEEDS_ACCOUNT`: there is no Expeditoo account to read.
  static Future<ExpedionApiResult> getProfile() => _send(
        () => http.get(_uri('/api/expedion/me/profile'), headers: _headers),
      );

  /// Saves the keys present in [payload] and leaves the others as they are.
  /// Answers with the saved profile, in the same shape as [getProfile].
  static Future<ExpedionApiResult> updateProfile(
    Map<String, dynamic> payload,
  ) =>
      _send(
        () => http.put(
          _uri('/api/expedion/me/profile'),
          headers: _headers,
          body: jsonEncode(payload),
        ),
      );

  // ========================================
  // Transport
  // ========================================

  /// Quick retries an outright connection failure absorbs, most commonly a
  /// local `pnpm dev` still mid cold-compile: the first request after a
  /// fresh `flutter run` can easily beat Next.js to a bound port. A response
  /// that arrived and said something we didn't like is never retried here —
  /// only "could not connect at all" is indistinguishable from "not ready
  /// yet".
  static const int _maxAttempts = 3;
  static const Duration _retryDelay = Duration(milliseconds: 700);

  static Future<ExpedionApiResult> _send(
    Future<http.Response> Function() request, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!isConfigured) {
      return ExpedionApiResult.failure(
        code: 'UNAUTHENTICATED',
        statusCode: 401,
        message: 'Connectez-vous pour accéder à vos devis.',
      );
    }

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
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
        final details = error?['details'];
        return ExpedionApiResult.failure(
          statusCode: response.statusCode,
          code: error?['code']?.toString() ?? 'HTTP_${response.statusCode}',
          message: error?['message']?.toString() ?? 'Une erreur est survenue.',
          details: details is Map<String, dynamic> ? details : null,
        );
      } catch (e) {
        // `http`'s `ClientException` covers every connection-level failure on
        // both native (it also implements `SocketException`) and web (a
        // failed `fetch`); `TimeoutException` comes from the `.timeout()`
        // above. Anything else — a malformed response body, for instance —
        // is a real bug and should surface immediately, not retry.
        final isConnectionFailure =
            e is http.ClientException || e is TimeoutException;
        if (isConnectionFailure && attempt < _maxAttempts) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        }
        return ExpedionApiResult.failure(
          code: 'NETWORK_ERROR',
          message: 'Connexion impossible. Vérifiez votre réseau.',
          cause: e,
        );
      }
    }

    // Unreachable — the loop above always returns by its last iteration.
    throw StateError('_send: retry loop exited without returning');
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
    this.details,
    this.cause,
  });

  factory ExpedionApiResult.failure({
    required String code,
    required String message,
    int statusCode = 0,
    Map<String, dynamic>? details,
    Object? cause,
  }) =>
      ExpedionApiResult(
        success: false,
        statusCode: statusCode,
        code: code,
        message: message,
        details: details,
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

  /// `error.details` from a refusal, keyed by field — what a
  /// `VALIDATION_ERROR` says was wrong with each one.
  final Map<String, dynamic>? details;
  final Object? cause;

  List<dynamic> get list => data is List ? data as List<dynamic> : const [];
  Map<String, dynamic> get map =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : const {};
}

/// Who the current credential resolves to, server-side.
///
/// The one fact the client cannot derive: "admin" lives in Expeditoo's
/// `user_roles`, which the app has no view of. Cached in a notifier rather than
/// re-fetched per build, because the header rebuilds on every theme flip,
/// language switch and keystroke.
///
/// This gates *visibility*, never access. Every guarded route re-derives the
/// role server-side, so flipping [isAdmin] locally reveals a link and nothing
/// behind it.
class ExpedionAdminAccess {
  ExpedionAdminAccess._();

  static final ValueNotifier<bool> isAdmin = ValueNotifier<bool>(false);

  /// Re-asks the server. Safe to call on every auth change; a failure leaves
  /// the previous answer alone rather than flickering the entry point away.
  static Future<void> refresh() async {
    if (!ExpedionApi.isConfigured) {
      isAdmin.value = false;
      return;
    }
    final result = await ExpedionApi.me();
    if (!result.success) return;
    isAdmin.value = result.map['isAdmin'] == true;
  }

  /// Called on sign-out, where dropping the flag immediately matters more than
  /// waiting for a round trip.
  static void clear() => isAdmin.value = false;
}
