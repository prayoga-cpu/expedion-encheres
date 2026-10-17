import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';

import '/backend/expedion_api/expedion_api.dart' show ExpedionAdminAccess;
import '/backend/quote_draft.dart';
import '/flutter_flow/nav/nav.dart' show AppStateNotifier;
import '../auth_manager.dart';
import '../firebase_auth/firebase_auth_manager.dart';
import '../firebase_auth/firebase_user_provider.dart';
import 'expeditoo_auth_client.dart';

export 'expeditoo_auth_client.dart' show ExpeditooUser, ExpeditooAuthResult;
export 'google_identity_button_web.dart'
    if (dart.library.io) 'google_identity_button_stub.dart'
    show googleIdentityButton, googleIdentityButtonSupported;

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
    lastExpeditooResult = null;

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

    final legacy = await _firebase.signInWithEmail(context, email, password);
    if (legacy != null) {
      // This is the only place the app still learns a legacy password, and it
      // is the moment the account can be moved. See [_migrateLegacyAccount].
      unawaited(_migrateLegacyAccount(email, password));
    }
    return legacy;
  }

  /// Whether the last sign-in came from a Firebase-era account.
  ///
  /// Read by the UI to explain the verification mail that is about to arrive,
  /// and counted so the size of the un-migrated population is observable. The
  /// server cannot measure this on its own: a legacy visitor who signs in but
  /// never opens a quote makes no authenticated API call, so nothing reaches
  /// `requireExpedionCaller` to be logged there.
  bool lastSignInUsedLegacyAccount = false;

  /// Whether that account has just been offered a Better Auth replacement.
  ExpeditooAuthResult? lastMigrationResult;

  /// Moves a Firebase-era account onto Better Auth, once, at sign-in.
  ///
  /// There are 48 of these accounts and every one of them is password-only, so
  /// there is no provider credential to re-link — the only thing that can
  /// recreate them is the password, and the only moment the app ever holds it
  /// is the instant a legacy sign-in succeeds. A background sweep could not do
  /// this: password hashes do not transfer between the two systems.
  ///
  /// Deliberately best-effort and never surfaced as a sign-in failure. The
  /// visitor has already authenticated; if this call fails they stay signed in
  /// on the legacy path and the next sign-in tries again. An account that has
  /// already been migrated comes back as "user already exists", which is the
  /// success case on every attempt after the first.
  ///
  /// The new account starts unverified, because a correct password proves
  /// control of the credential and not of the inbox — and 44 of the 48 were
  /// never verified in Firebase either. Better Auth sends its verification mail
  /// on creation, so the visitor is told to expect it rather than discovering
  /// on some later day that their password no longer works.
  Future<void> _migrateLegacyAccount(String email, String password) async {
    lastSignInUsedLegacyAccount = true;
    if (kDebugMode) {
      debugPrint('[ExpedionAuth] legacy Firebase sign-in; migrating $email');
    }
    try {
      final migration = await ExpeditooAuthClient.signUpWithEmail(
        email: email,
        password: password,
        name: email.split('@').first,
      );
      lastMigrationResult = migration;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[ExpedionAuth] legacy migration failed: $error');
      }
    }
  }

  @override
  Future<BaseAuthUser?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password, {
    String? firstName,
    String? lastName,
  }) async {
    lastExpeditooResult = null;

    final result = await ExpeditooAuthClient.signUpWithEmail(
      email: email,
      password: password,
      name: email.split('@').first,
      firstName: firstName,
      lastName: lastName,
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

  /// Google sign-in, on every platform, through Better Auth.
  ///
  /// Firebase is no longer involved. It used to be, on web, because of a
  /// `!kIsWeb` guard justified by the belief that `google_sign_in` could not
  /// produce an ID token in a browser — which sent every web visitor into
  /// `signInWithPopup` and, on a Vercel host that was never added to Firebase's
  /// authorized-domains list, into `auth/unauthorized-domain`.
  ///
  /// That belief was wrong in a specific way: `signIn()` cannot produce an ID
  /// token on web, but `renderButton` and `signInSilently` can. Web therefore
  /// takes the same Better Auth exchange as native, differing only in how the
  /// token is obtained — see [googleWebSignIns].
  @override
  Future<BaseAuthUser?> signInWithGoogle(BuildContext context) async {
    lastExpeditooResult = null;

    if (kIsWeb) {
      // The credential arrives asynchronously from the Google-rendered button,
      // not from this call. Sign-in screens render [googleIdentityButton] and
      // listen on [googleWebSignIns]; there is nothing to await here, and
      // falling back to a Firebase popup is exactly the bug this removed.
      listenForGoogleWebSignIn();
      return null;
    }

    try {
      await _google.signOut().catchError((_) => null);
      final account = await _google.signIn();
      if (account == null) return null; // The visitor dismissed the sheet.
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        lastExpeditooResult = const ExpeditooAuthResult.failure(
          code: 'GOOGLE_NO_ID_TOKEN',
          message: 'Google did not return an identity token.',
        );
        return null;
      }
      return await _exchangeGoogleIdToken(idToken, auth.accessToken);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[ExpedionAuth] Google via Expeditoo: $error');
      }
      lastExpeditooResult = ExpeditooAuthResult.failure(
        code: 'GOOGLE_FAILED',
        message: '$error',
      );
      return null;
    }
  }

  /// Outcomes of the web Google Identity Services button.
  ///
  /// Web has no awaitable call: the visitor clicks a button Google renders and
  /// controls, and the resulting credential is published by the plugin on
  /// `onCurrentUserChanged`. Sign-in screens listen here to know when to
  /// navigate.
  ///
  /// **A null event is a failure, and screens must handle it.** Publishing only
  /// successes would leave a visitor whose exchange was refused — a mismatched
  /// audience, an account Better Auth declined to link, a 5xx, a blocked
  /// origin — staring at a button that visibly did nothing, with the reason
  /// available nowhere but a debug console. [lastExpeditooResult] carries the
  /// detail whenever null is emitted.
  Stream<BaseAuthUser?> get googleWebSignIns => _googleWebSignIns.stream;

  final StreamController<BaseAuthUser?> _googleWebSignIns =
      StreamController<BaseAuthUser?>.broadcast();

  StreamSubscription<GoogleSignInAccount?>? _googleWebSubscription;

  /// Subscribes to the plugin's account stream so a credential produced by the
  /// Google-rendered button is exchanged for a Better Auth session.
  ///
  /// Idempotent, and a no-op off web. Sign-in screens call it when they mount
  /// the button; calling it more than once keeps the single subscription.
  void listenForGoogleWebSignIn() {
    if (!kIsWeb || _googleWebSubscription != null) return;
    _googleWebSubscription =
        _google.onCurrentUserChanged.listen((account) async {
      // Null here is the plugin reporting "nobody is signed in", which is the
      // resting state and not an attempt that failed.
      if (account == null) return;
      lastExpeditooResult = null;
      try {
        final auth = await account.authentication;
        final idToken = auth.idToken;
        if (idToken == null || idToken.isEmpty) {
          lastExpeditooResult = const ExpeditooAuthResult.failure(
            code: 'GOOGLE_NO_ID_TOKEN',
            message: 'Google did not return an identity token.',
          );
          _googleWebSignIns.add(null);
          return;
        }
        // The screen navigates itself once this stream fires, so the router
        // must not also refresh on the auth change and interrupt it. The
        // native paths get this from `prepareAuthEvent()` before their
        // awaited call; this path has no such call to sit in front of, so the
        // suppression happens here, immediately before `_adopt` publishes the
        // new user. `update()` re-arms the flag itself afterwards.
        AppStateNotifier.instance.updateNotifyOnAuthChange(false);
        final user = await _exchangeGoogleIdToken(idToken, auth.accessToken);
        _googleWebSignIns.add(user);
      } catch (error) {
        if (kDebugMode) {
          debugPrint('[ExpedionAuth] Google (web) exchange: $error');
        }
        lastExpeditooResult = ExpeditooAuthResult.failure(
          code: 'GOOGLE_FAILED',
          message: '$error',
        );
        _googleWebSignIns.add(null);
      }
    });
  }

  /// Trades a Google ID token for a Better Auth session.
  ///
  /// Shared by both platforms: the server verifies the token against Google's
  /// public keys and matches its audience to `GOOGLE_CLIENT_ID`, so the account
  /// reached here is the same row a visitor would land on signing in with
  /// Google on Expeditoo's own web app.
  Future<BaseAuthUser?> _exchangeGoogleIdToken(
    String idToken,
    String? accessToken,
  ) async {
    final result = await ExpeditooAuthClient.signInWithGoogleIdToken(
      idToken: idToken,
      accessToken: accessToken,
    );
    lastExpeditooResult = result;
    if (result.succeeded && ExpeditooAuthClient.hasToken) {
      final user = result.user ?? await ExpeditooAuthClient.session();
      if (user != null) return _adopt(user);
    }
    return null;
  }

  /// Apple sign-in is not offered by this app.
  ///
  /// The mixin requires the method, and the Firebase implementation behind it
  /// used `signInWithPopup` — the same call that broke Google on web. No screen
  /// has ever called this, so rather than leave a popup nobody can reach but
  /// everybody inherits, it reports itself as unsupported.
  @override
  Future<BaseAuthUser?> signInWithApple(BuildContext context) async {
    lastExpeditooResult = const ExpeditooAuthResult.failure(
      code: 'PROVIDER_UNSUPPORTED',
      message: 'Apple sign-in is not available on Expedion.',
    );
    return null;
  }

  /// Anonymous sign-in is not offered by this app.
  ///
  /// Quotes belong to an identifiable buyer — the server keys them on a real
  /// user id — so an anonymous session has nothing it could own.
  @override
  Future<BaseAuthUser?> signInAnonymously(BuildContext context) async {
    lastExpeditooResult = const ExpeditooAuthResult.failure(
      code: 'PROVIDER_UNSUPPORTED',
      message: 'Anonymous sign-in is not available on Expedion.',
    );
    return null;
  }

  @override
  Future signOut() async {
    // Anything the landing page parked belongs to the person signing out, not
    // to whoever uses this browser next.
    QuoteDraft.clear();
    // Same argument, and it used to be made in only one of the two places that
    // sign out: `app_shell.dart` cleared the operator flag and the personal
    // space did not, so signing out from that screen left admin access live for
    // the next person to sign in on the device. Clearing it here means every
    // sign-out clears it, whatever called it.
    ExpedionAdminAccess.clear();
    await ExpeditooAuthClient.signOut();
    _expeditooSession.add(null);
    await _google.signOut().catchError((_) => null);
    // The web button's subscription belongs to the session that mounted it.
    // Left alive, a credential replayed after sign-out would silently sign the
    // visitor back in.
    await _googleWebSubscription?.cancel();
    _googleWebSubscription = null;
    lastSignInUsedLegacyAccount = false;
    lastMigrationResult = null;
    await _firebase.signOut();
  }

  /// Account deletion is not offered by this app.
  ///
  /// It used to delegate to Firebase, which acts on `FirebaseAuth.currentUser`
  /// — null for a Better Auth session, so the call did nothing at all and said
  /// nothing about it. No screen calls this; an unimplemented operation should
  /// announce itself rather than quietly succeed.
  @override
  Future deleteUser(BuildContext context) async {
    throw UnsupportedError(
      'Account deletion is handled from the Expeditoo account settings.',
    );
  }

  /// Changing the address is not offered by this app, for the same reason.
  ///
  /// Better Auth does expose `/change-email`, so this can be implemented when a
  /// screen needs it — but it requires confirming the new address, and there is
  /// nothing in Expedion that asks for one today.
  @override
  Future updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    throw UnsupportedError(
      'Changing your address is handled from the Expeditoo account settings.',
    );
  }

  @override
  Future resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    lastExpeditooResult = null;

    final result = await ExpeditooAuthClient.requestPasswordReset(email);
    lastExpeditooResult = result;

    // Both systems are asked, and the reason is the shape of Better Auth's
    // answer rather than distrust of it.
    //
    // The previous code returned as soon as Better Auth said `succeeded`, which
    // worked only because it never did: the client was posting to a route that
    // 404s, so every reset silently fell through to Firebase. With the route
    // fixed, `/request-password-reset` answers 200 for *any* address — it will
    // not confirm whether an account exists — so `succeeded` no longer
    // distinguishes "mail sent" from "nobody here". Keying the fallback on it
    // would simply invert the old bug and strand the legacy accounts instead.
    //
    // A legacy account is exactly the one that cannot migrate on its own: the
    // ramp in [_migrateLegacyAccount] runs at sign-in, and someone resetting a
    // password is by definition not signing in. Until that population is empty,
    // Firebase has to be asked too.
    //
    // The cost is one duplicate mail for an address that exists in both
    // systems. Firebase throws `user-not-found` for the rest, so the ordinary
    // Better-Auth-only visitor is unaffected. Two mails is a nuisance; being
    // unable to recover an account is not, so this is the right way round.
    if (_legacyFirebaseAccountsMayExist) {
      try {
        await _firebase.resetPassword(email: email, context: context);
      } catch (error) {
        if (kDebugMode) {
          debugPrint('[ExpedionAuth] legacy reset skipped: $error');
        }
      }
    }
  }

  /// Whether any Firebase-era account might still be un-migrated.
  ///
  /// Flip to `false` once the backfill reports no unmatched owners and the
  /// legacy sign-in counter has been flat at zero — that is the same gate that
  /// allows the Firebase dependency to be removed altogether, and this is the
  /// last behaviour that depends on it.
  static const bool _legacyFirebaseAccountsMayExist = true;

  /// Asks for the verification mail to be sent again.
  ///
  /// [ExpeditooAuthUser.sendEmailVerification] is an empty method — account
  /// mutation belongs to Expeditoo's own settings UI — so routing through
  /// `currentUser` meant this did nothing for a Better Auth account while the
  /// personal space reported "Email envoyé" regardless. Better Auth serves
  /// `/send-verification-email`, so the request is made here instead and the
  /// caller is told what actually happened.
  ///
  /// Returns true when the server accepted the request.
  @override
  Future<bool> sendEmailVerification() async {
    final address = currentUser?.email ?? '';
    if (address.isEmpty) return false;

    if (currentUser is ExpeditooAuthUser) {
      final result = await ExpeditooAuthClient.resendVerificationEmail(
        email: address,
      );
      lastExpeditooResult = result;
      return result.succeeded;
    }

    // A legacy Firebase session can still send its own verification mail.
    await currentUser?.sendEmailVerification();
    return true;
  }

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
