import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '/flutter_flow/upload_data.dart';

/// What the landing page's quote forms collected, held for the devis flow to
/// pick up.
///
/// The site asks for a pickup house, a delivery city, a lot count and so on
/// before the visitor has signed in; the real form (`FormDemandeDevisWidget`)
/// asks for those same things among many more. Rather than widen every route
/// in `nav.dart` with a dozen optional query parameters, the landing page
/// parks what it has here and the form seeds its controllers from it.
///
/// [consume] clears as it reads, so a draft prefills exactly one visit to the
/// form — going back to the landing page and starting again replaces it, and
/// navigating to the form by any other route gets an empty one.
/// Which of the two devis forms a parked draft should be resumed into.
///
/// The fork (`ChoixDevisWidget`) asks one question: *do you have the auction
/// house's slip as a PDF?* A visitor who filled in the landing page has already
/// answered it — by attaching the slip, or by typing the addresses instead —
/// so asking a second time after the sign-in detour is asking them to repeat
/// themselves.
enum QuoteDraftResume {
  /// A bordereau came with the draft; the extractor route reads it for them.
  bordereau,

  /// No slip, but addresses and lot details this form has fields for.
  manual,
}

class QuoteDraft {
  const QuoteDraft({
    this.pickup = '',
    this.delivery = '',
    this.lotCount = '',
    this.lotType = '',
    this.hammerPrice = '',
    this.deadline = '',
    this.email = '',
    this.phone = '',
    this.bordereau,
  });

  /// "Drouot, Paris 9e" — the auction house the lot is collected from.
  final String pickup;

  /// "33000 Bordeaux" — city and postcode, as one string.
  final String delivery;

  final String lotCount;
  final String lotType;

  /// Hammer price, used to size ad valorem cover.
  final String hammerPrice;

  /// The auction house's collection deadline.
  final String deadline;

  final String email;
  final String phone;

  /// The uploaded bordereau, if the visitor attached one.
  final SelectedFile? bordereau;

  bool get isEmpty =>
      pickup.isEmpty &&
      delivery.isEmpty &&
      lotCount.isEmpty &&
      lotType.isEmpty &&
      hammerPrice.isEmpty &&
      deadline.isEmpty &&
      email.isEmpty &&
      phone.isEmpty &&
      bordereau == null;

  /// Splits [delivery] into a postcode and a town, accepting either order —
  /// "33000 Bordeaux" and "Bordeaux 33000" both parse. Returns empty strings
  /// for whichever half is absent rather than guessing.
  ({String postcode, String city}) get deliveryParts {
    final match = RegExp(r'\b(\d{5})\b').firstMatch(delivery);
    final postcode = match?.group(1) ?? '';
    final city = delivery.replaceFirst(postcode, '').trim().replaceAll(
          RegExp(r'^[,\s]+|[,\s]+$'),
          '',
        );
    return (postcode: postcode, city: city);
  }

  /// Where this draft should be picked up again once the visitor is signed
  /// in. See [QuoteDraftResume].
  QuoteDraftResume get resume => bordereau != null
      ? QuoteDraftResume.bordereau
      : QuoteDraftResume.manual;

  /// The typed answers, for [_persist]. The attached slip is deliberately not
  /// here — see [restore].
  Map<String, dynamic> _toJson() => {
        'pickup': pickup,
        'delivery': delivery,
        'lotCount': lotCount,
        'lotType': lotType,
        'hammerPrice': hammerPrice,
        'deadline': deadline,
        'email': email,
        'phone': phone,
      };

  /// Defensive on every field: a stored draft can outlive the version of the
  /// landing page that wrote it.
  static QuoteDraft _fromJson(Map<String, dynamic> json) {
    String read(String key) => json[key] is String ? json[key] as String : '';
    return QuoteDraft(
      pickup: read('pickup'),
      delivery: read('delivery'),
      lotCount: read('lotCount'),
      lotType: read('lotType'),
      hammerPrice: read('hammerPrice'),
      deadline: read('deadline'),
      email: read('email'),
      phone: read('phone'),
    );
  }

  static QuoteDraft? _pending;
  static DateTime? _stagedAt;

  /// One slot, not one per account: a draft is parked *before* signing in, so
  /// there is no account to key it by yet. [_staleAfter] and the sign-out
  /// clear are what keep it from following the next person on a shared
  /// browser.
  static const String _storageKey = 'expedion.landingQuoteDraft';

  /// How long a parked draft stays readable. Long enough to walk from the
  /// landing page to the devis form (signing in on the way), short enough that
  /// on a shared or kiosk browser one visitor's pickup, e-mail, phone and
  /// hammer price cannot prefill the next visitor's form.
  static const Duration _staleAfter = Duration(minutes: 30);

  /// Parks a draft for the next visit to the devis form.
  static void stage(QuoteDraft draft) {
    _pending = draft.isEmpty ? null : draft;
    _stagedAt = _pending == null ? null : DateTime.now();
    _queueWrite();
  }

  /// Drops the parked draft. Called on sign-out so it cannot follow the next
  /// person to use this browser.
  static void clear() {
    _pending = null;
    _stagedAt = null;
    _queueWrite();
  }

  /// The parked draft, or null if there is none or it has gone stale.
  static QuoteDraft? get _fresh {
    final stagedAt = _stagedAt;
    if (_pending == null || stagedAt == null) return null;
    if (DateTime.now().difference(stagedAt) > _staleAfter) {
      clear();
      return null;
    }
    return _pending;
  }

  /// Reads and clears the parked draft.
  static QuoteDraft? consume() {
    final draft = _fresh;
    clear();
    return draft;
  }

  /// Reads without clearing — for a form that only prefills from the draft and
  /// must leave it for the form that can actually submit it.
  static QuoteDraft? peek() => _fresh;

  /// Queued rather than fired: `stage` and `clear` can land in the same frame
  /// — signing out while a draft is parked does exactly that — and two
  /// overlapping `SharedPreferences` writes can finish out of order, leaving
  /// the cleared draft on disk for the next person to use the browser.
  ///
  /// Neither caller awaits this. They are button handlers on their way to a
  /// route change, and the in-memory copy is what that route reads; the write
  /// is insurance for the visitor who reloads instead.
  static Future<void> _writes = Future<void>.value();

  static void _queueWrite() {
    _writes = _writes.then((_) => _persist());
  }

  /// Resolves once every queued write has landed.
  static Future<void> get settled => _writes;

  /// Mirrors [_pending] to this device, or removes it when there is none.
  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = _pending;
      final stagedAt = _stagedAt;
      if (draft == null || stagedAt == null) {
        await prefs.remove(_storageKey);
        return;
      }
      await prefs.setString(
        _storageKey,
        jsonEncode({
          'stagedAt': stagedAt.toIso8601String(),
          'values': draft._toJson(),
        }),
      );
    } catch (_) {
      // Private browsing, a locked profile. The in-memory draft still stands
      // for this session, which is the case the landing page actually needs;
      // only the reload survives being lost.
    }
  }

  /// Reads back a draft parked before the tab was reloaded.
  ///
  /// Called once from `main()`, ahead of the first frame, because the devis
  /// forms read the draft synchronously in `initState` and would otherwise see
  /// nothing. Without this, "save as a draft" is only true for as long as the
  /// tab lives — and the sign-in detour the landing page sends people on is
  /// exactly where a tab gets reloaded.
  ///
  /// The attached bordereau is not restored: file bytes do not belong in
  /// `shared_preferences`, so a reload keeps the typed answers and loses the
  /// slip, which the form then asks for again rather than pretending to hold.
  static Future<void> restore() async {
    // A draft staged this session is newer than anything on disk.
    if (_pending != null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      final values = decoded is Map ? decoded['values'] : null;
      final stagedAt =
          decoded is Map ? DateTime.tryParse('${decoded['stagedAt']}') : null;

      if (values is! Map ||
          stagedAt == null ||
          DateTime.now().difference(stagedAt) > _staleAfter) {
        await prefs.remove(_storageKey);
        return;
      }

      final draft = _fromJson(values.cast<String, dynamic>());
      if (draft.isEmpty) {
        await prefs.remove(_storageKey);
        return;
      }

      _pending = draft;
      _stagedAt = stagedAt;
    } catch (_) {
      // Unreadable storage is the same as no draft.
    }
  }
}
