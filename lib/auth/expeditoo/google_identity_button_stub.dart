import 'package:flutter/widgets.dart';

/// Non-web stand-in for the Google Identity Services button.
///
/// Native builds do not need it: `google_sign_in` returns an ID token directly
/// from `signIn()` on Android and iOS, so the app keeps its own styled button
/// and calls `ExpedionAuthManager.signInWithGoogle` the ordinary way. This file
/// exists only so the shared sign-in widgets, which compile for every target,
/// can reference the symbol without dragging the web-only library into an
/// Android or iOS build.
///
/// It is never rendered — call sites gate on [googleIdentityButtonSupported] —
/// but it returns an empty box rather than throwing, so a mistake here shows up
/// as a missing button rather than a crash.
Widget googleIdentityButton({double? width}) => const SizedBox.shrink();

/// True where [googleIdentityButton] renders a real, working control.
const bool googleIdentityButtonSupported = false;
