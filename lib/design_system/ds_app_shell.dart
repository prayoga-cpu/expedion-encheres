import 'package:flutter/material.dart';

import 'ds_logo.dart';
import 'ds_palette.dart';
import 'ds_site.dart';

/// One destination in the signed-in navigation.
class XpdShellLink {
  const XpdShellLink({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
}

/// Page chrome for every screen behind the login.
///
/// The marketing page and the app used to draw two different headers, which is
/// why the signed-in pages had a clipped nav row and a red-outlined "Logout"
/// that appeared nowhere else in the design. This is the one header: the same
/// lockup, links, language and theme toggles the landing page uses, plus the
/// account action, over a page body the caller supplies.
///
/// Links scroll rather than clip when there are more than the width allows,
/// and collapse into the drawer below [XpdLayout.tablet].
class XpdAppShell extends StatelessWidget {
  const XpdAppShell({
    super.key,
    required this.body,
    required this.links,
    required this.languageCode,
    required this.onLanguageChanged,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLogoTap,
    this.accountLabel,
    this.onAccountTap,
    this.onSignOut,
    this.signOutLabel = 'Déconnexion',
    this.floatingActionButton,
    this.background,
  });

  final Widget body;
  final List<XpdShellLink> links;
  final String languageCode;
  final ValueChanged<String> onLanguageChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onLogoTap;

  final String? accountLabel;
  final VoidCallback? onAccountTap;

  /// Rendered as a quiet outline action, not the alarming red-bordered button
  /// the generated pages carried — signing out is routine, not destructive.
  final VoidCallback? onSignOut;
  final String signOutLabel;

  final Widget? floatingActionButton;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: background ?? palette.bg,
      floatingActionButton: floatingActionButton,
      endDrawer: _ShellDrawer(
        links: links,
        languageCode: languageCode,
        onLanguageChanged: onLanguageChanged,
        accountLabel: accountLabel,
        onAccountTap: onAccountTap,
        onSignOut: onSignOut,
        signOutLabel: signOutLabel,
      ),
      appBar: XpdHeader(
        languageCode: languageCode,
        onLanguageChanged: onLanguageChanged,
        themeMode: themeMode,
        onThemeChanged: onThemeChanged,
        onLogoTap: onLogoTap,
        onMenuTap: () => scaffoldKey.currentState?.openEndDrawer(),
        links: [
          for (final link in links)
            XpdNavItem(label: link.label, onTap: link.onTap),
        ],
        trailing: [
          if (accountLabel != null && onAccountTap != null)
            XpdButton(
              label: accountLabel!,
              variant: XpdButtonVariant.outline,
              fontSize: 14.5,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 9.0,
              ),
              radius: 10.0,
              onPressed: onAccountTap,
            ),
          if (onSignOut != null)
            XpdButton(
              label: signOutLabel,
              variant: XpdButtonVariant.outline,
              fontSize: 14.5,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 9.0,
              ),
              radius: 10.0,
              onPressed: onSignOut,
            ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}

class _ShellDrawer extends StatelessWidget {
  const _ShellDrawer({
    required this.links,
    required this.languageCode,
    required this.onLanguageChanged,
    required this.accountLabel,
    required this.onAccountTap,
    required this.onSignOut,
    required this.signOutLabel,
  });

  final List<XpdShellLink> links;
  final String languageCode;
  final ValueChanged<String> onLanguageChanged;
  final String? accountLabel;
  final VoidCallback? onAccountTap;
  final VoidCallback? onSignOut;
  final String signOutLabel;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return Drawer(
      backgroundColor: palette.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: XpdLogo(markSize: 26.0)),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: palette.text),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final link in links)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          link.label,
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 16.0,
                            fontWeight: link.selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color:
                                link.selected ? palette.blueLink : palette.text,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          link.onTap();
                        },
                      ),
                  ],
                ),
              ),
              XpdLanguageToggle(
                languageCode: languageCode,
                onChanged: onLanguageChanged,
              ),
              if (accountLabel != null && onAccountTap != null) ...[
                const SizedBox(height: 16.0),
                XpdButton(
                  label: accountLabel!,
                  variant: XpdButtonVariant.outline,
                  expand: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAccountTap!();
                  },
                ),
              ],
              if (onSignOut != null) ...[
                const SizedBox(height: 10.0),
                XpdButton(
                  label: signOutLabel,
                  variant: XpdButtonVariant.outline,
                  expand: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSignOut!();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The blue banner that opens each signed-in page — title, subtitle and an
/// optional action on the right.
class XpdPageHeader extends StatelessWidget {
  const XpdPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = XpdLayout.gutterFor(width);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(gutter, 16.0, gutter, 0.0),
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: XpdPalette.blue,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 26.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 26.0 * -0.03,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 15.0,
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 20.0), action!],
        ],
      ),
    );
  }
}

/// A figure and its label — the Total / Validés / Payés row.
class XpdStatTile extends StatelessWidget {
  const XpdStatTile({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
    this.loading = false,
  });

  final String value;
  final String label;
  final Color? valueColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return XpdPanel(
      radius: 16.0,
      padding: const EdgeInsets.symmetric(vertical: 22.0, horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox(
              height: 30.0,
              width: 30.0,
              child: Center(
                child: SizedBox(
                  height: 18.0,
                  width: 18.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(palette.faint),
                  ),
                ),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Geist Mono',
                fontSize: 26.0,
                fontWeight: FontWeight.w500,
                color: valueColor ?? palette.text,
              ),
            ),
          const SizedBox(height: 6.0),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14.0,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}
