import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/expedion_api/expedion_api.dart';
import '/backend/expedion_api/expedion_config.dart';
import '/backend/quote_draft.dart';
import '/design_system/ds_app_shell.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/main.dart';

/// The destinations the signed-in navigation offers, in the order they appear.
///
/// [none] is for pages that live off the nav — a form reached from a card, a
/// detail screen — which still get the same header, just with nothing selected.
enum XpdDestination { none, home, requestQuote, quotes, payments, faq, contact }

/// The one page chrome for every screen in the app.
///
/// Each generated page used to carry its own ~550-line `PreferredSize` header,
/// so the same product had three different navbars: one lockup here, another
/// there, a red-outlined "Logout" on one page and an overflowing one on the
/// next. They also hardcoded their link lists, so a signed-out visitor saw
/// "Mes paiements" and a signed-in one saw no way back to their account.
///
/// This wraps [XpdAppShell] with the app's own routes and reads everything
/// else from state: the selected link comes from [current], the language and
/// theme toggles from [MyApp], and the link set and account actions from
/// whether anyone is signed in. Pages pass a body and nothing else.
class XpdPage extends StatelessWidget {
  const XpdPage({
    super.key,
    required this.body,
    this.current = XpdDestination.none,
    this.onBack,
    this.floatingActionButton,
    this.background,
  });

  final Widget body;

  /// Which nav link renders as active on this page.
  final XpdDestination current;

  /// Set on screens reached from somewhere else — a quote's detail, its
  /// tracking, an edit form. The header is the same everywhere, so the way
  /// back rides above the body rather than replacing the lockup with an arrow
  /// the way the generated `AppBar`s did.
  final VoidCallback? onBack;

  final Widget? floatingActionButton;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    // The admin entry point appears only for operators, and whether someone is
    // one is a server fact. Listening rather than reading once means the link
    // appears as soon as the answer arrives, without this page re-fetching on
    // every rebuild.
    return ValueListenableBuilder<bool>(
      valueListenable: ExpedionAdminAccess.isAdmin,
      builder: (context, isAdmin, _) => _build(context, isAdmin),
    );
  }

  Widget _build(BuildContext context, bool isAdmin) {
    final isEnglish = FFLocalizations.of(context).languageCode.startsWith('en');
    String t(String fr, String en) => isEnglish ? en : fr;

    // Tapping the link you are already on should do nothing rather than push a
    // second copy of the page onto the stack.
    XpdShellLink link(XpdDestination destination, String label, String route) {
      final selected = destination == current;
      return XpdShellLink(
        label: label,
        selected: selected,
        onTap: selected ? () {} : () => context.pushNamed(route),
      );
    }

    return XpdAppShell(
      themeMode: MyApp.of(context).themeMode,
      onThemeChanged: (mode) => MyApp.of(context).setThemeMode(mode),
      languageCode: isEnglish ? 'en' : 'fr',
      onLanguageChanged: (code) => MyApp.of(context).setLocale(code),
      onLogoTap: () => context.pushNamed(AccueilWidget.routeName),

      // Signed out, the account slot is the way in; signed in, it is the way
      // to the profile, and only then is there a session to end.
      accountLabel: loggedIn
          ? t('Espace personnel', 'Personal space')
          : t('Se connecter', 'Sign in'),
      onAccountTap: () => context.pushNamed(loggedIn
          ? EspacePersonnelWidget.routeName
          : SeConnecterWidget.routeName),
      signOutLabel: t('Déconnexion', 'Log out'),
      onSignOut: loggedIn ? () => _signOut(context) : null,

      // The same filled action the landing page ends its header with, so the
      // primary path is in the same place on every screen. It stays visible on
      // the quote flow itself — a header that loses a button on one page is
      // the inconsistency this shell exists to remove — but does not push a
      // second copy of the page you are already on.
      ctaLabel: t('Demander un devis', 'Request a quote'),
      onCtaTap: current == XpdDestination.requestQuote
          ? () {}
          : () => context.pushNamed(ChoixDevisWidget.routeName),

      // "Demander un devis" is deliberately absent here: it is the filled CTA
      // above, and listing it twice in one row is what the old per-page navbars
      // did. The links are where you go, the CTA is what you do.
      links: [
        link(
            XpdDestination.home, t('Accueil', 'Home'), AccueilWidget.routeName),
        // A visitor with no session has no quotes or payments to show, and
        // both routes would bounce them to sign-in.
        if (loggedIn) ...[
          link(XpdDestination.quotes, t('Mes devis', 'My quotes'),
              MesDevisWidget.routeName),
          link(XpdDestination.payments, t('Mes paiements', 'My payments'),
              MesPaiementsWidget.routeName),
        ],
        link(XpdDestination.faq, 'FAQ', FaqWidget.routeName),
        link(XpdDestination.contact, 'Contact', ContactWidget.routeName),
        // Operators only. It leaves the app — the dashboard is served by
        // Expeditoo's Next.js side, on a different origin — so it opens
        // externally rather than being pushed onto this router, which has no
        // such route and would fall through to the quote chooser.
        if (isAdmin)
          XpdShellLink(
            label: t('Administration', 'Admin'),
            onTap: () => _openAdminDashboard(context, t),
          ),
      ],

      floatingActionButton: floatingActionButton,
      background: background,
      body: onBack == null ? body : _withBackRow(context, t),
    );
  }

  Widget _withBackRow(BuildContext context, String Function(String, String) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 0.0),
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 18.0),
            label: Text(t('Retour', 'Back')),
            style: TextButton.styleFrom(
              foregroundColor: FlutterFlowTheme.of(context).secondaryText,
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  /// Opens Expeditoo's operator dashboard.
  ///
  /// A different origin, so it cannot be a route: `context.pushNamed` would
  /// look for `/admin/expedion` in Flutter's own router, miss, and land on the
  /// error builder — which is exactly the "can't find the admin page" this
  /// link exists to answer.
  Future<void> _openAdminDashboard(
    BuildContext context,
    String Function(String, String) t,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(ExpedionConfig.adminDashboardUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          t(
            "Impossible d'ouvrir ${ExpedionConfig.adminDashboardUrl}",
            'Could not open ${ExpedionConfig.adminDashboardUrl}',
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final router = GoRouter.of(context);
    router.prepareAuthEvent();
    await authManager.signOut();
    ExpedionAdminAccess.clear();
    // So one visitor's staged pickup, e-mail and hammer price cannot prefill
    // the next person's form on a shared browser.
    QuoteDraft.clear();
    if (!context.mounted) return;
    router.clearRedirectLocation();
    context.goNamedAuth(AccueilWidget.routeName, context.mounted);
  }
}
