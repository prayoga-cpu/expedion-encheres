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
