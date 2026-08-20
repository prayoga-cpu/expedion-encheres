import 'package:flutter/widgets.dart';

import '/flutter_flow/flutter_flow_util.dart';

/// French/English copy for the hand-written screens.
///
/// The FlutterFlow-generated pages get their strings from
/// `internationalization.dart`, keyed by opaque ids like `'0qmoygh5'`. That
/// generator only knows about widgets it produced, so every screen rebuilt onto
/// the design system has to carry its own copy — and each one had grown a
/// private `_t(fr, en)` helper, which is why the header read "My quotes" in
/// English while the card beneath it still said "Livré".
///
/// One helper, used everywhere, is what keeps a newly-translated screen from
/// being the only one that is translated.
bool xpdIsEnglish(BuildContext context) =>
    FFLocalizations.of(context).languageCode.startsWith('en');

/// Picks [fr] or [en] for the active locale.
String xpdT(BuildContext context, String fr, String en) =>
    xpdIsEnglish(context) ? en : fr;

/// Localizes a data-layer failure `code` into copy in the reader's language.
///
/// Every Expedion API result (`ExpedionApiResult`, `QuoteListResult`,
/// `QuoteWriteResult`, `AiEstimateResult`, ...) carries a `code` next to a
/// `message` — but `message` is whichever language the failure happened to
/// speak: a hardcoded French string from a local network failure, or
/// whatever the server answered with. Showing `result.message` straight to
/// the UI is why "Connexion impossible" used to appear under the English
/// toggle. Every failure state should read through this instead, passing
/// [fallbackFr]/[fallbackEn] for whatever it wants to say when [code] is not
/// one of the well-known ones below.
String xpdApiErrorMessage(
  BuildContext context,
  String? code, {
  String fallbackFr = 'Une erreur est survenue.',
  String fallbackEn = 'Something went wrong.',
}) {
  switch (code) {
    case 'NETWORK_ERROR':
      return xpdT(
        context,
        'Connexion impossible. Vérifiez votre réseau.',
        'Could not connect. Check your network.',
      );
    case 'UNAUTHENTICATED':
    case 'UNAUTHORIZED':
      return xpdT(
        context,
        'Connectez-vous pour continuer.',
        'Sign in to continue.',
      );
    case 'QUOTE_NOT_FOUND':
      return xpdT(context, 'Devis introuvable.', 'Quote not found.');
    case 'QUOTE_ALREADY_PRICED':
      return xpdT(
        context,
        'Votre devis a déjà été chiffré.',
        'Your quote has already been priced.',
      );
    case 'QUOTE_LOCKED':
      return xpdT(
        context,
        'Le devis ne peut plus être modifié à ce stade.',
        'This quote can no longer be edited.',
      );
    case 'QUOTE_NOT_PRICED':
      return xpdT(
        context,
        "Ce devis n'a pas encore de prix.",
        'This quote has no price yet.',
      );
    case 'PRICE_SUGGESTION_UNAVAILABLE':
    case 'EXTRACTION_UNAVAILABLE':
      return xpdT(
        context,
        'Service temporairement indisponible.',
        'Service temporarily unavailable.',
      );
    default:
      return xpdT(context, fallbackFr, fallbackEn);
  }
}
