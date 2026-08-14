import 'package:flutter/foundation.dart';

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

  static QuoteDraft? _pending;

  /// Parks a draft for the next visit to the devis form.
  static void stage(QuoteDraft draft) => _pending = draft.isEmpty ? null : draft;

  /// Reads and clears the parked draft.
  static QuoteDraft? consume() {
    final draft = _pending;
    _pending = null;
    return draft;
  }

  /// Reads without clearing — for a form that rebuilds before it seeds.
  @visibleForTesting
  static QuoteDraft? peek() => _pending;
}
