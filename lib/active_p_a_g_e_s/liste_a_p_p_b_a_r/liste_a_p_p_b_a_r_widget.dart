import '/auth/base_auth_user_provider.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'liste_a_p_p_b_a_r_model.dart';
export 'liste_a_p_p_b_a_r_model.dart';

/// The account menu: Accueil, espace personnel, mes devis, demander un devis,
/// mes paiements, contact, paramètres, FAQ.
///
/// Rebuilt on `DSNavItem` so it matches the Expeditoo app sidebar — icon,
/// label, 8px radius, `primary` fill on the active row, `accent1` on hover.
/// Previously eight copies of a bare text row with no icons and no active
/// state, which is the one surface where the two apps looked least alike.
class ListeAPPBARWidget extends StatefulWidget {
  const ListeAPPBARWidget({super.key});

  @override
  State<ListeAPPBARWidget> createState() => _ListeAPPBARWidgetState();
}

class _ListeAPPBARWidgetState extends State<ListeAPPBARWidget> {
  late ListeAPPBARModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListeAPPBARModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  /// Highlights whichever entry corresponds to the route currently on screen.
  bool _isCurrent(String routeName) =>
      GoRouterState.of(context).name == routeName;

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final theme = FlutterFlowTheme.of(context);
    final t = FFLocalizations.of(context);

    final entries = <_NavEntry>[
      _NavEntry(
        icon: Icons.home_outlined,
        label: t.getText('nfdne1z8' /* Accueil */),
        routeName: AccueilWidget.routeName,
        onTap: () => context.pushNamed(AccueilWidget.routeName),
      ),
      if (loggedIn)
        _NavEntry(
          icon: Icons.person_outline_rounded,
          label: t.getText('h29o6hk2' /* Espace Personnel */),
          routeName: EspacePersonnelWidget.routeName,
          onTap: () => context.pushNamed(EspacePersonnelWidget.routeName),
        ),
      if (loggedIn)
        _NavEntry(
          icon: Icons.receipt_long_outlined,
          label: t.getText('6tsupowt' /* Mes devis */),
          routeName: MesDevisWidget.routeName,
          onTap: () => context.pushNamed(MesDevisWidget.routeName),
        ),
      _NavEntry(
        icon: Icons.add_circle_outline_rounded,
        label: t.getText('vv0if3vm' /* Demander un devis  */),
        routeName: ChoixDevisWidget.routeName,
        // Signed-out visitors are sent to log in first, as before.
        onTap: () => context.pushNamed(
          loggedIn ? ChoixDevisWidget.routeName : SeConnecterWidget.routeName,
        ),
      ),
      if (loggedIn)
        _NavEntry(
          icon: Icons.credit_card_outlined,
          label: t.getText('5w0v18l1' /* Mes paiements */),
          routeName: MesPaiementsWidget.routeName,
          onTap: () => context.pushNamed(MesPaiementsWidget.routeName),
        ),
      _NavEntry(
        icon: Icons.chat_bubble_outline_rounded,
        label: t.getText('37jg5lmc' /* Contact */),
        routeName: ContactWidget.routeName,
        onTap: () => context.pushNamed(ContactWidget.routeName),
      ),
      if (loggedIn)
        _NavEntry(
          icon: Icons.settings_outlined,
          label: t.getText('e83ve2tk' /* Paramètres */),
          routeName: ParametreWidget.routeName,
          onTap: () => context.pushNamed(ParametreWidget.routeName),
        ),
      _NavEntry(
        icon: Icons.help_outline_rounded,
        label: t.getText('hk3cws7m' /* FAQ - Questions */),
        routeName: FaqWidget.routeName,
        onTap: () => context.pushNamed(FaqWidget.routeName),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Container(
        width: 260.0,
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(DSShape.card),
          border: Border.all(
            color: theme.alternate,
            width: DSShape.borderWidth,
          ),
          boxShadow: [theme.designToken.shadow.md],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: DSNavItem(
                    icon: entry.icon,
                    label: entry.label,
                    selected: _isCurrent(entry.routeName),
                    onTap: entry.onTap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavEntry {
  const _NavEntry({
    required this.icon,
    required this.label,
    required this.routeName,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String routeName;
  final VoidCallback onTap;
}
