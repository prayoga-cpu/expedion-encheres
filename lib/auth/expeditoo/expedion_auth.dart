import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';

import '/backend/quote_draft.dart';
import '../auth_manager.dart';
import '../firebase_auth/firebase_auth_manager.dart';
import '../firebase_auth/firebase_user_provider.dart';
import 'expeditoo_auth_client.dart';

export 'expeditoo_auth_client.dart' show ExpeditooUser, ExpeditooAuthResult;

/// A signed-in Expeditoo (Better Auth) account, in the shape the rest of the
/// app already understands.
///
/// Everything outside `lib/auth` reads identity through [BaseAuthUser] —
/// `currentUserUid`, `currentUserEmail`, `loggedIn` — so presenting the
/// Better Auth session under the same interface means no page had to change
/// when the account system moved.
class ExpeditooAuthUser extends BaseAuthUser {
  ExpeditooAuthUser(this.user);

  ExpeditooUser? user;

  @override
  bool get loggedIn => user != null;

  @override
  bool get emailVerified => user?.emailVerified ?? false;

  @override
  AuthUserInfo get authUserInfo => AuthUserInfo(
        uid: user?.id,
        email: user?.email,
        displayName: user?.name,
        photoUrl: user?.image,
        // Better Auth's user table has no phone column in Expeditoo's schema.
        phoneNumber: null,
      );

  /// Account mutation lives in Expeditoo's own settings UI; Expedion does not
  /// own these operations, so they are no-ops here rather than silent lies
  /// implemented against the wrong backend.
  @override
  Future? delete() async {}

  @override
  Future? updateEmail(String email) async {}

  @override
  Future? updatePassword(String newPassword) async {}

  @override
  Future? sendEmailVerification() async {}

  @override
  Future refreshUser() async {
    final fresh = await ExpeditooAuthClient.session();
    if (fresh != null) user = fresh;
  }
}

/// Pushes the current Expeditoo session into the auth stream.
///
/// Seeded from [ExpeditooAuthClient.cachedUser] so the first frame already
/// knows who is signed in; [refreshExpeditooSession] then confirms or clears
/// it against the server.
final BehaviorSubject<ExpeditooUser?> _expeditooSession =
    BehaviorSubject<ExpeditooUser?>.seeded(ExpeditooAuthClient.cachedUser);

/// Revalidates the stored session in the background. Safe to call at start-up
/// and after returning from the background.
Future<void> refreshExpeditooSession() async {
  if (!ExpeditooAuthClient.isConfigured || !ExpeditooAuthClient.hasToken) {
    return;
  }
  final user = await ExpeditooAuthClient.session();
  // A null answer here means the server rejected the token, not that the
  // network failed — `session()` only clears on 401/403.
  if (user == null && !ExpeditooAuthClient.hasToken) {
    _expeditooSession.add(null);
  } else if (user != null) {
    _expeditooSession.add(user);
  }
}

/// The app's identity stream: Expeditoo when there is a session, Firebase
/// otherwise.
///
/// Better Auth is primary and Firebase is the fallback, so accounts created
/// before the migration keep working. Both sources are watched at once because
/// either can change without the other: an Expeditoo token can expire while a
/// Firebase session is still live, and vice versa.
Stream<BaseAuthUser> expedionAuthUserStream() =>
    Rx.combineLatest2<ExpeditooUser?, fb.User?, BaseAuthUser>(
      _expeditooSession.stream,
      fb.FirebaseAuth.instance
          .authStateChanges()
          .startWith(fb.FirebaseAuth.instance.currentUser),
      (expeditooUser, firebaseUser) {
        currentUser = expeditooUser != null
            ? ExpeditooAuthUser(expeditooUser)
            : ExpedionEncheresFirebaseUser(firebaseUser);
        return currentUser!;
      },
    ).asBroadcastStream();

/// Routes authentication to Expeditoo first and Firebase second.
///
/// The fallback is deliberately narrow. It runs only when Expeditoo says it
/// does not know these credentials, or when the build has no Expeditoo
/// configuration at all — never when Expeditoo answered but refused, since a
/// wrong password or an unverified address must surface as itself rather than
/// being retried against a second system and reported as a different failure.
class ExpedionAuthManager extends AuthManager
    with
        EmailSignInManager,
        GoogleSignInManager,
        AppleSignInManager,
        AnonymousSignInManager {
  final FirebaseAuthManager _firebase = FirebaseAuthManager();

  final GoogleSignIn _google = GoogleSignIn(scopes: const ['profile', 'email']);

  /// Failures that mean "Expeditoo has no such account", and so are worth
  /// retrying against Firebase. Anything else is a real answer.
  static const _fallbackCodes = {
    'NOT_CONFIGURED',
    'USER_NOT_FOUND',
    'INVALID_EMAIL_OR_PASSWORD',
    'INVALID_CREDENTIALS',
  };

  /// The most recent Expeditoo failure, for the UI to explain. Cleared on the
  /// next attempt.
  ExpeditooAuthResult? lastExpeditooResult;

  @override
  Future<BaseAuthUser?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    final result = await ExpeditooAuthClient.signInWithEmail(
      email: email,
      password: password,
    );
    lastExpeditooResult = result;

    if (result.succeeded && ExpeditooAuthClient.hasToken) {
      final user = result.user ?? await ExpeditooAuthClient.session();
      if (user != null) return _adopt(user);
    }

    // An unverified account exists — do not fall through to Firebase and
    // report it as a bad password.
    if (result.needsEmailVerification) return null;
    if (!_fallbackCodes.contains(result.code)) return null;

    return _firebase.signInWithEmail(context, email, password);
  }

  @override
  Future<BaseAuthUser?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    final result = await ExpeditooAuthClient.signUpWithEmail(
      email: email,
      password: password,
      name: email.split('@').first,
    );
    lastExpeditooResult = result;

    if (result.succeeded) {
      // Expeditoo runs `requireEmailVerification: true` with
      // `autoSignIn: false`, so a new account has no session yet. Returning
      // null here is correct: the caller must send the visitor to their inbox,
      // not into the app.
      if (ExpeditooAuthClient.hasToken && result.user != null) {
        return _adopt(result.user!);
      }
      return null;
    }

    if (result.code == 'NOT_CONFIGURED') {
      return _firebase.createAccountWithEmail(context, email, password);
    }
    return null;
  }

  @override
  Future<BaseAuthUser?> signInWithGoogle(BuildContext context) async {
    // On web `google_sign_in` does not surface an ID token, so the Better Auth
    // exchange is unavailable and Firebase's popup handles it.
    if (!kIsWeb && ExpeditooAuthClient.isConfigured) {
      try {
        await _google.signOut().catchError((_) => null);
        final account = await _google.signIn();
        final auth = await account?.authentication;
        final idToken = auth?.idToken;
        if (idToken != null && idToken.isNotEmpty) {
          final result = await ExpeditooAuthClient.signInWithGoogleIdToken(
            idToken: idToken,
            accessToken: auth?.accessToken,
          );
          lastExpeditooResult = result;
          if (result.succeeded && ExpeditooAuthClient.hasToken) {
            final user = result.user ?? await ExpeditooAuthClient.session();
            if (user != null) return _adopt(user);
          }
        } else if (account == null) {
          // The visitor dismissed the Google sheet; do not silently retry on
          // Firebase and open a second one.
          return null;
        }
      } catch (error) {
        if (kDebugMode)
          debugPrint('[ExpedionAuth] Google via Expeditoo: $error');
      }
    }
    return _firebase.signInWithGoogle(context);
  }

  @override
  Future<BaseAuthUser?> signInWithApple(BuildContext context) =>
      _firebase.signInWithApple(context);

  @override
  Future<BaseAuthUser?> signInAnonymously(BuildContext context) =>
      _firebase.signInAnonymously(context);

  @override
  Future signOut() async {
    // Anything the landing page parked belongs to the person signing out, not
    // to whoever uses this browser next.
    QuoteDraft.clear();
    await ExpeditooAuthClient.signOut();
    _expeditooSession.add(null);
    await _google.signOut().catchError((_) => null);
    await _firebase.signOut();
  }

  @override
  Future deleteUser(BuildContext context) => _firebase.deleteUser(context);

  @override
  Future updateEmail({
    required String email,
    required BuildContext context,
  }) =>
      _firebase.updateEmail(email: email, context: context);

  @override
  Future resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    final result = await ExpeditooAuthClient.requestPasswordReset(email);
    lastExpeditooResult = result;
    if (result.succeeded) return;
    return _firebase.resetPassword(email: email, context: context);
  }

  @override
  Future sendEmailVerification() async => currentUser?.sendEmailVerification();

  @override
  Future refreshUser() async {
    await refreshExpeditooSession();
    await currentUser?.refreshUser();
  }

  /// Publishes a fresh Expeditoo session to the auth stream and returns the
  /// user in the app's own shape.
  BaseAuthUser _adopt(ExpeditooUser user) {
    _expeditooSession.add(user);
    final adopted = ExpeditooAuthUser(user);
    currentUser = adopted;
    return adopted;
  }
}
