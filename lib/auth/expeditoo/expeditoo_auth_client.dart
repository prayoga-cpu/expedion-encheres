import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '/backend/expedion_api/expedion_config.dart';

/// Talks to Expeditoo's Better Auth, which is the account system both products
/// share (`expeditoo-ship/src/lib/auth.ts`).
///
/// Better Auth is cookie-first: a browser signs in and the session rides in a
/// `better-auth.session_token` cookie. Flutter has no cookie jar on native
/// targets, so the server carries the `bearer` plugin and hands the session
/// token back in a `set-auth-token` response header; this client stores that
/// token and presents it as `Authorization: Bearer …` on every later call.
///
/// The base URL is shared with [ExpedionApi] via [ExpedionConfig], since both
/// are served by the same Next.js app. It resolves without any build flag —
/// localhost in debug, the production deployment in release — and
/// `--dart-define=EXPEDION_API_BASE_URL=…` overrides it.
///
/// Sign-in failing for want of a backend is reported as an ordinary auth
/// failure, so the app falls back to Firebase rather than refusing to start.
class ExpeditooAuthClient {
  ExpeditooAuthClient._();

  /// Shared with [ExpedionApi] — the same Next.js app serves auth and quotes.
  /// Never empty: see [ExpedionConfig] for how it resolves.
  static String get baseUrl => ExpedionConfig.baseUrl;

  /// Better Auth mounts its whole surface under one catch-all route.
  static const String _authPath = '/api/auth';

  /// Where Better Auth returns the session token on sign-in, and the key this
  /// client persists it under.
  static const String _tokenHeader = 'set-auth-token';
  static const String _tokenKey = '__expeditoo_session_token__';
  static const String _userKey = '__expeditoo_session_user__';

  /// There is always a host to talk to, so this is always true. Kept as a
  /// named concept because callers read it to mean "the Expeditoo backend is
  /// reachable in principle", which is still the question they are asking.
  static bool get isConfigured => baseUrl.isNotEmpty;

  static String? _token;
  static ExpeditooUser? _cachedUser;
  static SharedPreferences? _prefs;

  /// Reads the persisted session token and the user it belonged to. Call once
  /// during start-up, before the first [session] lookup.
  ///
  /// The user is cached alongside the token so the app can come up already
  /// signed in and revalidate in the background. Without it the first frame
  /// would render signed-out while `/get-session` is in flight, bouncing a
  /// returning visitor to the landing page and then back again.
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs?.getString(_tokenKey);
    final raw = _prefs?.getString(_userKey);
    if (raw != null && hasToken) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _cachedUser = ExpeditooUser.fromJson(decoded);
        }
      } catch (_) {
        // A corrupt cache is not worth failing start-up over; the background
        // revalidation will replace it or sign the user out.
      }
    }
  }

  static String? get token => _token;
  static bool get hasToken => (_token ?? '').isNotEmpty;

  /// The last known user, available before `/get-session` has answered.
  static ExpeditooUser? get cachedUser => hasToken ? _cachedUser : null;

  static Future<void> _storeToken(String? value) async {
    _token = (value ?? '').isEmpty ? null : value;
    _prefs ??= await SharedPreferences.getInstance();
    if (_token == null) {
      _cachedUser = null;
      await _prefs?.remove(_tokenKey);
      await _prefs?.remove(_userKey);
    } else {
      await _prefs?.setString(_tokenKey, _token!);
    }
  }

  static Future<void> _storeUser(ExpeditooUser? user) async {
    _cachedUser = user;
    _prefs ??= await SharedPreferences.getInstance();
    if (user == null) {
      await _prefs?.remove(_userKey);
    } else {
      await _prefs?.setString(_userKey, jsonEncode(user.toJson()));
    }
  }

  static Uri _uri(String path) => Uri.parse('$baseUrl$_authPath$path');

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (hasToken) 'Authorization': 'Bearer $_token',
      };

  // ========================================
  // Session
  // ========================================

  /// The signed-in user, or null when there is no valid session.
  ///
  /// Better Auth answers 200 with a `null` body rather than 401 for an expired
  /// session, so an empty body is treated as signed-out and the stale token is
  /// dropped.
  static Future<ExpeditooUser?> session() async {
    if (!isConfigured || !hasToken) return null;
    final result = await _send(
      () => http.get(_uri('/get-session'), headers: _headers),
    );
    if (!result.succeeded) {
      // Only clear on an explicit rejection. A network blip must not sign the
      // user out — they would be logged out every time the phone loses signal.
      if (result.statusCode == 401 || result.statusCode == 403) {
        await _storeToken(null);
      }
      return null;
    }
    final user = result.body['user'];
    if (user is! Map) {
      await _storeToken(null);
      return null;
    }
    final parsed = ExpeditooUser.fromJson(user.cast<String, dynamic>());
    await _storeUser(parsed);
    return parsed;
  }

  // ========================================
  // Email and password
  // ========================================

  static Future<ExpeditooAuthResult> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = true,
  }) =>
      _authenticate(
        '/sign-in/email',
        {'email': email, 'password': password, 'rememberMe': rememberMe},
      );

  /// Better Auth is configured with `requireEmailVerification: true` and
  /// `autoSignIn: false`, so a successful sign-up returns a user but no
  /// session — the caller must tell the visitor to check their inbox rather
  /// than treating this as a login.
  static Future<ExpeditooAuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) =>
      _authenticate(
        '/sign-up/email',
        {'email': email, 'password': password, 'name': name},
      );

  /// Sends Better Auth's reset-password mail.
  static Future<ExpeditooAuthResult> requestPasswordReset(String email) =>
      _authenticate('/forget-password', {'email': email});

  // ========================================
  // Google
  // ========================================

  /// Exchanges a Google ID token for a Better Auth session.
  ///
  /// This is the native shape of `sign-in/social`: rather than sending the
  /// visitor through a browser redirect, `google_sign_in` obtains the ID token
  /// on-device and the server verifies it against Google. The result is the
  /// same account row a web visitor would land on, keyed on the verified
  /// email, so signing in with Google here and with Google on Expeditoo's web
  /// app reaches one account.
  static Future<ExpeditooAuthResult> signInWithGoogleIdToken({
    required String idToken,
    String? accessToken,
  }) =>
      _authenticate('/sign-in/social', {
        'provider': 'google',
        'idToken': {
          'token': idToken,
          if (accessToken != null) 'accessToken': accessToken,
        },
      });

  /// The redirect flow, for web where `google_sign_in` yields no ID token.
  /// Returns the Google consent URL for the caller to open.
  static Future<String?> googleRedirectUrl(
      {required String callbackUrl}) async {
    final result = await _send(
      () => http.post(
        _uri('/sign-in/social'),
        headers: _headers,
        body: jsonEncode({'provider': 'google', 'callbackURL': callbackUrl}),
      ),
    );
    final url = result.body['url'];
    return url is String && url.isNotEmpty ? url : null;
  }

  // ========================================
  // Sign out
  // ========================================

  static Future<void> signOut() async {
    if (isConfigured && hasToken) {
      await _send(() => http.post(_uri('/sign-out'), headers: _headers));
    }
    await _storeToken(null);
  }

  // ========================================
  // Plumbing
  // ========================================

  /// Posts [payload], and on success captures the session token Better Auth
  /// returns in the `set-auth-token` header.
  static Future<ExpeditooAuthResult> _authenticate(
    String path,
    Map<String, dynamic> payload,
  ) async {
    if (!isConfigured) {
      return const ExpeditooAuthResult._(
        succeeded: false,
        code: 'NOT_CONFIGURED',
        message: 'Expeditoo authentication is not configured for this build.',
      );
    }

    final result = await _send(
      () => http.post(_uri(path), headers: _headers, body: jsonEncode(payload)),
    );

    if (!result.succeeded) {
      return ExpeditooAuthResult._(
        succeeded: false,
        code: result.body['code']?.toString() ?? 'AUTH_FAILED',
        message: result.body['message']?.toString(),
        statusCode: result.statusCode,
      );
    }

    // The header is authoritative; the JSON `token` is a fallback for older
    // server builds that only put it in the body.
    final headerToken = result.headers[_tokenHeader];
    final bodyToken = result.body['token'];
    final token = (headerToken ?? '').isNotEmpty
        ? headerToken
        : (bodyToken is String ? bodyToken : null);
    if ((token ?? '').isNotEmpty) await _storeToken(token);

    final rawUser = result.body['user'];
    final user = rawUser is Map
        ? ExpeditooUser.fromJson(rawUser.cast<String, dynamic>())
        : null;
    // Only cache once a token exists — a sign-up under
    // `requireEmailVerification` returns a user with no session, and caching
    // that would present an unverified account as signed in.
    if (user != null && hasToken) await _storeUser(user);

    return ExpeditooAuthResult._(
      succeeded: true,
      statusCode: result.statusCode,
      user: user,
    );
  }

  static Future<_Response> _send(Future<http.Response> Function() call) async {
    try {
      final response = await call().timeout(const Duration(seconds: 20));
      Map<String, dynamic> body = const {};
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      }
      return _Response(
        statusCode: response.statusCode,
        headers: response.headers,
        body: body,
      );
    } catch (error) {
      if (kDebugMode) debugPrint('[ExpeditooAuth] $error');
      return _Response(
        statusCode: 0,
        headers: const {},
        body: {'message': '$error'},
      );
    }
  }
}

class _Response {
  const _Response({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final Map<String, String> headers;
  final Map<String, dynamic> body;

  bool get succeeded => statusCode >= 200 && statusCode < 300;
}

/// A Better Auth `user` row, with the extra columns Expeditoo declares in
/// `user.additionalFields`.
@immutable
class ExpeditooUser {
  const ExpeditooUser({
    required this.id,
    required this.email,
    this.name,
    this.image,
    this.emailVerified = false,
    this.banned = false,
  });

  factory ExpeditooUser.fromJson(Map<String, dynamic> json) => ExpeditooUser(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        name: json['name']?.toString(),
        image: json['image']?.toString(),
        emailVerified: json['emailVerified'] == true,
        banned: json['banned'] == true,
      );

  final String id;
  final String email;
  final String? name;
  final String? image;
  final bool emailVerified;
  final bool banned;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'image': image,
        'emailVerified': emailVerified,
        'banned': banned,
      };
}

/// The outcome of a sign-in, sign-up or reset call.
@immutable
class ExpeditooAuthResult {
  const ExpeditooAuthResult._({
    required this.succeeded,
    this.user,
    this.code,
    this.message,
    this.statusCode = 0,
  });

  final bool succeeded;
  final ExpeditooUser? user;

  /// Better Auth's machine-readable failure code, e.g. `INVALID_EMAIL_OR_PASSWORD`.
  final String? code;
  final String? message;
  final int statusCode;

  /// True when the account exists but has not confirmed its address. Better
  /// Auth refuses the sign-in in that state, and the UI should say so rather
  /// than reporting a wrong password.
  bool get needsEmailVerification =>
      code == 'EMAIL_NOT_VERIFIED' || code == 'EMAIL_VERIFICATION_REQUIRED';
}
