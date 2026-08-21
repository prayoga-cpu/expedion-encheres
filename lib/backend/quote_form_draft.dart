import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A half-filled devis form, kept on this device so closing the tab is not the
/// same as losing the afternoon's work.
///
/// Deliberately local rather than a server-side draft: Expeditoo's
/// `expedion_quotes` has no draft state — its status enum starts at `pending`,
/// which already means "filed, awaiting pricing" and puts the quote in the
/// operator queue (`expedion-escalation.service.ts`). Filing an incomplete
/// quote to get a save button would put unfinished work in front of the ops
/// team, so a draft stays here until the visitor submits it.
///
/// The payload is whatever map the form hands over; this class only owns
/// *where* it is kept, how long it lives, and who it belongs to.
class QuoteFormDraft {
  const QuoteFormDraft({required this.values, required this.savedAt});

  /// The form's own snapshot, as passed to [save].
  final Map<String, dynamic> values;
  final DateTime savedAt;

  /// Long enough to come back to a quote after the weekend, short enough that
  /// a browser shared with the rest of the office does not hold a stranger's
  /// half-written address for ever.
  static const Duration keepFor = Duration(days: 30);

  /// Per account: on a shared computer, signing in as someone else must not
  /// surface the previous person's draft. Signed-out visitors share the
  /// `anon` slot, which is also what a draft saved before signing in lands in.
  static String _key(String uid) =>
      'expedion.quoteFormDraft.${uid.isEmpty ? 'anon' : uid}';

  /// Writes the draft. Returns false if this device has no usable storage —
  /// private browsing, a locked profile — so the caller can say so rather than
  /// claim a save that did not happen.
  static Future<bool> save(String uid, Map<String, dynamic> values) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(
        _key(uid),
        jsonEncode({
          'savedAt': DateTime.now().toIso8601String(),
          'values': values,
        }),
      );
    } catch (_) {
      return false;
    }
  }

  /// The stored draft, or null if there is none, it cannot be read, or it has
  /// aged out — in which case it is deleted on the way past.
  static Future<QuoteFormDraft?> load(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(uid));
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await clear(uid);
        return null;
      }

      final savedAt = DateTime.tryParse('${decoded['savedAt']}');
      final values = decoded['values'];
      if (savedAt == null || values is! Map) {
        await clear(uid);
        return null;
      }

      if (DateTime.now().difference(savedAt) > keepFor) {
        await clear(uid);
        return null;
      }

      return QuoteFormDraft(
        values: values.cast<String, dynamic>(),
        savedAt: savedAt,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(uid));
    } catch (_) {
      // Nothing to do — a draft that cannot be deleted will age out.
    }
  }

  // --------------------------------------------------------------------------
  // Reading the payload back
  // --------------------------------------------------------------------------
  // The form writes its own keys; these keep every read defensive, because a
  // draft can outlive the version of the form that wrote it.

  String text(String key) => values[key] is String ? values[key] as String : '';

  bool flag(String key) => values[key] == true;

  double? number(String key) {
    final value = values[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  List<String> strings(String key) {
    final value = values[key];
    return value is List ? value.whereType<String>().toList() : const [];
  }
}
