import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_button.dart';
import 'ds_tokens.dart';

/// A link in the desktop top navigation.
class DSNavLink {
  const DSNavLink({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
}

/// The application header, matching the Expeditoo shell.
///
/// A `card`-coloured bar with a hairline bottom border, the wordmark set in
/// `primary`, medium-weight links that tint to `primary` on hover, and the
/// account action as a real button on the right.
///
/// The previous header painted `primaryBackground`, which in dark mode is
/// `#010408` — that is where the slab of black in the old landing page came
/// from. Headers are chrome, so they sit on `card` like every other surface.
class DSTopNav extends StatelessWidget implements PreferredSizeWidget {
  const DSTopNav({
    super.key,
    required this.brand,
    this.links = const [],
    this.action,
    this.logo,
    this.onBrandTap,
    this.onMenuTap,
    this.trailing,
  });

  final String brand;
  final List<DSNavLink> links;

  /// Right-hand call to action — "se connecter", or the account menu.
  final Widget? action;
  final Widget? logo;
  final VoidCallback? onBrandTap;

  /// Shown instead of the links below the desktop breakpoint.
  final VoidCallback? onMenuTap;
  final List<Widget>? trailing;

  static const double height = 68.0;

  /// Below this the links collapse into the menu button.
  static const double _desktopBreakpoint = 900.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDesktop =
        MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(
          bottom: BorderSide(
            color: theme.alternate,
            width: DSShape.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32.0 : 16.0),
          child: Row(
            children: [
              _brand(context, theme),
              const Spacer(),
              if (isDesktop)
                for (final link in links)
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: _DSNavLinkButton(link: link),
                  ),
              if (trailing != null) ...trailing!,
              if (action != null) ...[
                const SizedBox(width: 12.0),
                action!,
              ],
              if (!isDesktop && onMenuTap != null) ...[
                const SizedBox(width: 4.0),
                IconButton(
                  icon: Icon(Icons.menu_rounded, color: theme.primaryText),
                  onPressed: onMenuTap,
                  tooltip: 'Menu',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _brand(BuildContext context, FlutterFlowTheme theme) {
    return InkWell(
      onTap: onBrandTap,
      borderRadius: BorderRadius.circular(DSShape.control),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(DSShape.small),
                child: SizedBox(width: 28.0, height: 28.0, child: logo),
              ),
              const SizedBox(width: 10.0),
            ],
            Text(
              brand,
              style: theme.titleLarge.copyWith(
                color: theme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DSNavLinkButton extends StatefulWidget {
  const _DSNavLinkButton({required this.link});

  final DSNavLink link;

  @override
  State<_DSNavLinkButton> createState() => _DSNavLinkButtonState();
}

class _DSNavLinkButtonState extends State<_DSNavLinkButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final active = widget.link.selected || _hovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.link.onTap,
        child: AnimatedContainer(
          duration: DSMotion.duration,
          curve: DSMotion.curve,
          padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: _hovered ? theme.accent1 : Colors.transparent,
            borderRadius: BorderRadius.circular(DSShape.control),
          ),
          child: Text(
            widget.link.label,
            style: theme.bodyMedium.copyWith(
              color: active ? theme.primary : theme.primaryText,
              fontWeight:
                  widget.link.selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 15.0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Light-on-dark toggle, as in the Expeditoo header.
class DSThemeToggle extends StatelessWidget {
  const DSThemeToggle({super.key, required this.isDark, required this.onChanged});

  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return IconButton(
      tooltip: isDark ? 'Thème clair' : 'Thème sombre',
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: theme.primaryText,
        size: 20.0,
      ),
      onPressed: () => onChanged(!isDark),
    );
  }
}

/// The hero block: eyebrow badge, a two-tone headline whose second line lands
/// in `primary`, a muted standfirst, then the primary action.
class DSHero extends StatelessWidget {
  const DSHero({
    super.key,
    required this.title,
    this.accentTitle,
    this.badge,
    this.subtitle,
    this.primaryAction,
    this.secondaryAction,
    this.footnote,
  });

  final String title;

  /// Rendered under [title] in `primary`, the way Expeditoo splits
  /// "Enchérissez, Expédiez et Gagnez." from "Votre Marketplace Tout-en-un."
  final String? accentTitle;
  final String? badge;
  final String? subtitle;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final Widget? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: compact ? 48.0 : 80.0,
      ),
      decoration: BoxDecoration(
        // A soft wash rather than a photograph. Body copy over a busy image
        // is the reason the old hero was unreadable.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.primary.withValues(alpha: 0.06),
            theme.primaryBackground,
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null) ...[
                _HeroBadge(label: badge!),
                const SizedBox(height: 24.0),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.displayLarge.copyWith(
                  fontSize: compact ? 32.0 : 46.0,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              if (accentTitle != null)
                Text(
                  accentTitle!,
                  textAlign: TextAlign.center,
                  style: theme.displayLarge.copyWith(
                    fontSize: compact ? 32.0 : 46.0,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.5,
                    color: theme.primary,
                  ),
                ),
              if (subtitle != null) ...[
                const SizedBox(height: 20.0),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560.0),
                  child: Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: theme.bodyLarge.copyWith(
                      color: theme.secondaryText,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
              if (primaryAction != null || secondaryAction != null) ...[
                const SizedBox(height: 32.0),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  alignment: WrapAlignment.center,
                  children: [
                    if (primaryAction != null) primaryAction!,
                    if (secondaryAction != null) secondaryAction!,
                  ],
                ),
              ],
              if (footnote != null) ...[
                const SizedBox(height: 28.0),
                footnote!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(DSShape.pill),
        border: Border.all(color: theme.alternate, width: DSShape.borderWidth),
        boxShadow: [theme.designToken.shadow.xs],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.0,
            height: 6.0,
            decoration: BoxDecoration(
              color: theme.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            label,
            style: theme.labelSmall.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience wrapper so pages can drop in a standard-width centred column.
class DSPageSection extends StatelessWidget {
  const DSPageSection({
    super.key,
    required this.child,
    this.maxWidth = 1100.0,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 24.0,
      vertical: 56.0,
    ),
    this.background,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: background,
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Fallback action used by pages that only need a labelled primary button.
DSButton dsPrimaryAction({
  required String label,
  required VoidCallback onPressed,
  IconData? icon,
}) =>
    DSButton(label: label, icon: icon, onPressed: onPressed);
