import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth_manager.dart';
import '../base_auth_user_provider.dart';
import '../../flutter_flow/flutter_flow_util.dart';

import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stream_transform/stream_transform.dart';
import '../expeditoo/expedion_auth.dart';
import 'firebase_auth_manager.dart';
import 'firebase_user_provider.dart';

export 'firebase_auth_manager.dart';

// Sign-in screens reach the account system through this file, so the web
// Google button comes with it rather than making every screen import the
// conditional shim itself.
export '../expeditoo/expedion_auth.dart'
    show googleIdentityButton, googleIdentityButtonSupported;

/// Authentication runs through Expeditoo's Better Auth, falling back to
/// Firebase for accounts that predate the migration. [ExpedionAuthManager]
/// implements the same mixins [FirebaseAuthManager] does, so every call site
/// — `authManager.signInWithEmail`, `.resetPassword`, `.signOut` — is
/// unchanged by the switch.
final _authManager = ExpedionAuthManager();
ExpedionAuthManager get authManager => _authManager;

// The signed-in session answers first; the Firestore profile only fills gaps.
//
// These used to read the other way round, which was right when Firebase was the
// only account system: `currentUserDocument` was the same person as
// `currentUser`, just with more columns. It is not any more. That document is
// fetched by Firebase UID (see `authenticatedUserStream` below), so for a
// Better Auth session it is null — harmless — but during the migration a
// visitor can briefly hold both sessions at once, and then the old order
// rendered the *Firebase* profile's name and address beside a
// `currentUserUid` belonging to the Better Auth account. One screen, two
// identities, no error.
//
// Preferring the session makes the displayed identity always the one the app
// is actually authenticated as. The document is still consulted for what a
// session genuinely does not carry.
String get currentUserEmail =>
    currentUser?.email ?? currentUserDocument?.email ?? '';

String get currentUserUid => currentUser?.uid ?? '';

String get currentUserDisplayName =>
    currentUser?.displayName ?? currentUserDocument?.displayName ?? '';

String get currentUserPhoto =>
    currentUser?.photoUrl ?? currentUserDocument?.photoUrl ?? '';

/// Better Auth's `user` table has no phone column, so unlike its neighbours
/// this one still reads the profile document first — it is the only source
/// that has ever held a phone number.
String get currentPhoneNumber =>
    currentUserDocument?.phoneNumber ?? currentUser?.phoneNumber ?? '';

String get currentJwtToken => _currentJwtToken ?? '';

bool get currentUserEmailVerified => currentUser?.emailVerified ?? false;

/// Create a Stream that listens to the current user's JWT Token, since Firebase
/// generates a new token every hour.
String? _currentJwtToken;
final jwtTokenStream = FirebaseAuth.instance
    .idTokenChanges()
    .map((user) async => _currentJwtToken = await user?.getIdToken())
    .asBroadcastStream();

/// The signed-in user's Firestore document, when they have one.
///
/// Null for a Better Auth session. That is the whole point of the extra
/// condition: this used to be `loggedIn ? ... : null`, which is true for every
/// signed-in user, so a Better Auth account got back a reference to a document
/// named by its own id — a document that has never existed. Callers read a
/// non-null reference as "this user has a profile document", and were wrong
/// about it for every account created since the migration.
///
/// Gating on the session type rather than on `loggedIn` makes the reference
/// mean what its callers already assume.
DocumentReference? get currentUserReference =>
    loggedIn && currentUser is ExpedionEncheresFirebaseUser
        ? UsersRecord.collection.doc(currentUser!.uid)
        : null;

UsersRecord? currentUserDocument;
final authenticatedUserStream = FirebaseAuth.instance
    .authStateChanges()
    .map<String>((user) => user?.uid ?? '')
    .switchMap(
      (uid) => uid.isEmpty
          ? Stream.value(null)
          : UsersRecord.getDocument(UsersRecord.collection.doc(uid))
              .handleError((_) {}),
    )
    .map((user) {
  currentUserDocument = user;

  return currentUserDocument;
}).asBroadcastStream();

class AuthUserStreamWidget extends StatelessWidget {
  const AuthUserStreamWidget({Key? key, required this.builder})
      : super(key: key);

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: authenticatedUserStream,
        builder: (context, _) => builder(context),
      );
}
