import 'package:flutter/material.dart';

import '/design_system/ds_loader.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'page_contact_devis_model.dart';
export 'page_contact_devis_model.dart';

/// `/pageContactDevis` — kept alive only to forward.
///
/// This was the per-quote contact form: the "CONTACT" button on each Mes Devis
/// card pushed here with the quote number in `numDevis`, and the page posted
/// six fields into the Airtable `MESSAGERIE` table. Commit `143c2da` rewrote
/// Mes Devis and dropped the button; the card now opens [SupportContact]'s
/// sheet instead, which carries the same quote reference. The page has had no
/// in-app entry point since, but it stayed registered in the router with no
/// `requireAuth`, so the URL still resolved — and still rendered a live form
/// whose submit handler validated nothing, reported nothing, and dropped its
/// own errors on the floor.
///
/// Deleting the route would have 404'd links that are plausibly still in
/// circulation: this URL went out in per-quote correspondence while the button
/// existed. Forwarding is the honest option — the visitor asked to talk about
/// a quote, and `/contact` is where that conversation now happens. `numDevis`
/// rides along and seeds the composer, so the reference survives the move.
class PageContactDevisWidget extends StatefulWidget {
  const PageContactDevisWidget({super.key, this.numDevis});

  final String? numDevis;

  static String routeName = 'Page_Contact-Devis';
  static String routePath = '/pageContactDevis';

  @override
  State<PageContactDevisWidget> createState() => _PageContactDevisWidgetState();
}

class _PageContactDevisWidgetState extends State<PageContactDevisWidget> {
  late PageContactDevisModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PageContactDevisModel());

    // After the first frame: redirecting during build throws, and GoRouter has
    // no route to replace until this one has been placed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // FlutterFlow's serializer hands through the literal string 'null' for a
      // missing param, which would otherwise seed the composer with
      // "Devis null —".
      final reference = widget.numDevis;
      final carry = (reference == null || reference == 'null' || reference.isEmpty)
          ? null
          : reference;

      // `goNamed`, not `pushNamed`: this page is a waypoint, and Back should
      // return where the visitor came from rather than here, which would
      // forward them again.
      context.goNamed(
        ContactWidget.routeName,
        queryParameters: {
          if (carry != null)
            'numDevis': serializeParam(carry, ParamType.String)!,
        },
      );
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: DSPageLoader(),
      );
}
