import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '/auth/firebase_auth/auth_util.dart';
import 'expedion_api/expedion_api.dart';
import 'expedion_api/expedion_profile.dart';

/// Profile details typed at sign-up, held until there is a session to save
/// them with.
///
/// An e-mail sign-up has no session: Expeditoo runs Better Auth with
/// `requireEmailVerification`, so the account exists but nobody is signed in
/// until the link is opened and the visitor signs in. The address and phone
/// they typed would otherwise be lost, so they are kept on this device and
/// sent by [flush] on the first auth change that carries a session for the
/// same e-mail.
class PendingProfile {
  const PendingProfile._();

  static const String _storageKey = 'expedion.pendingProfile';

  /// Long enough to open a verification mail a few days late, bounded because
  /// this is someone's address sitting on a device that may be shared.
  static const Duration _staleAfter = Duration(days: 7);

  /// Fallback for when the device will not store anything (private browsing).
  static _Pending? _memory;

  /// Flushes run one after another, so two auth events in the same frame
  /// cannot both send.
  static Future<void> _queue = Future<void>.value();

  /// Keeps [update] for [email]'s first session. Replaces anything kept before.
  static Future<void> stage({
    required String email,
    required ExpedionProfileUpdate update,
  }) async {
    if (email.trim().isEmpty || update.isEmpty) return;
    final pending = _Pending(email.trim(), update, DateTime.now());
    _memory = pending;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(pending.toJson()));
    } catch (_) {
      // The in-memory copy still covers a sign-in in this tab.
    }
  }

  /// Sends the kept details if the current session belongs to their owner.
  ///
  /// Safe to call on every auth change. Never throws, and keeps the details
  /// when the request could not be made, so the next auth change retries.
  static Future<void> flush() =>
      _queue = _queue.then((_) => _flushOnce()).catchError((_) {});

  static Future<void> _flushOnce() async {
    if (!ExpedionApi.hasUserSession) return;
    final pending = await _read();
    if (pending == null) return;
    if (pending.email.toLowerCase() != currentUserEmail.trim().toLowerCase()) {
      return;
    }

    var update = pending.update;
    var result = await ProfileRepository.save(update);

    // A mistyped phone should not cost the address that came with it.
    if (result.isValidationError && result.invalidFields.isNotEmpty) {
      update = update.without(result.invalidFields);
      if (!update.isEmpty) result = await ProfileRepository.save(update);
    }

    // Only a failure to get an answer is worth retrying; a refusal will be
    // refused again.
    if (result.succeeded || result.isValidationError || result.needsAccount) {
      await clear();
    }
  }

  static Future<void> clear() async {
    _memory = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  static Future<_Pending?> _read() async {
    var pending = _memory;
    if (pending == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_storageKey);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            pending = _Pending.fromJson(decoded.cast<String, dynamic>());
          }
        }
      } catch (_) {
        pending = null;
      }
    }
    if (pending == null) return null;
    if (pending.email.isEmpty ||
        pending.update.isEmpty ||
        DateTime.now().difference(pending.stagedAt) > _staleAfter) {
      await clear();
      return null;
    }
    return pending;
  }
}

class _Pending {
  const _Pending(this.email, this.update, this.stagedAt);

  factory _Pending.fromJson(Map<String, dynamic> json) {
    final update = json['update'];
    return _Pending(
      json['email'] is String ? json['email'] as String : '',
      update is Map
          ? ExpedionProfileUpdate.fromJson(update.cast<String, dynamic>())
          : const ExpedionProfileUpdate(),
      DateTime.tryParse('${json['stagedAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String email;
  final ExpedionProfileUpdate update;
  final DateTime stagedAt;

  Map<String, dynamic> toJson() => {
        'email': email,
        'update': update.toJson(),
        'stagedAt': stagedAt.toIso8601String(),
      };
}
