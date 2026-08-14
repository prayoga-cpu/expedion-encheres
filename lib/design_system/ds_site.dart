import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'ds_logo.dart';
import 'ds_palette.dart';

/// Section scaffolding shared by every page of the site.
///
/// The marketing page is one long column of `<section>`s that each centre a
/// 1180px container inside a 32px gutter and open with `padding-top:110px`.
/// [XpdSection] is that shape; [XpdEyebrow] and [XpdSectionHeading] are the
/// mono-spaced label and heading pair that opens most of them.

/// One `<section>`: full-bleed background, gutter, centred max-width column.
class XpdSection extends StatelessWidget {
  const XpdSection({
    super.key,
    required this.child,
    this.top = XpdLayout.sectionGap,
    this.bottom = 0.0,
    this.maxWidth = XpdLayout.maxWidth,
    this.background,
  });

  final Widget child;
  final double top;
  final double bottom;
  final double maxWidth;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = XpdLayout.gutterFor(width);
    // The 110px rhythm is tuned for a desktop viewport; on a phone it eats the
    // screen, so it compresses rather than scrolling the reader past emptiness.
    final scale = width < XpdLayout.tablet ? 0.55 : 1.0;

    return Container(
      width: double.infinity,
      color: background,
      padding: EdgeInsets.fromLTRB(
        gutter,
        top * scale,
        gutter,
        bottom * scale,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// `font-family:'Geist Mono'; font-size:11px; letter-spacing:0.16em` — the
/// small caps label above each section heading.
class XpdEyebrow extends StatelessWidget {
  const XpdEyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Geist Mono',
        fontSize: 11.0,
        letterSpacing: 11.0 * 0.16,
        color: color ?? palette.dim,
        height: 1.4,
      ),
    );
  }
}

/// The 38px `<h2>` every section leads with.
class XpdSectionHeading extends StatelessWidget {
  const XpdSectionHeading(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final size = width < XpdLayout.tablet ? 28.0 : 38.0;
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Geist',
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: size * -0.03,
        height: 1.1,
        color: color ?? palette.text,
      ),
    );
  }
}

/// Eyebrow + heading + optional lead paragraph, in the site's 14px stack.
class XpdSectionIntro extends StatelessWidget {
  const XpdSectionIntro({
    super.key,
    required this.eyebrow,
    required this.heading,
    this.lead,
    this.maxWidth = 640.0,
  });

  final String eyebrow;
  final String heading;
  final String? lead;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          XpdEyebrow(eyebrow),
          const SizedBox(height: 14.0),
          XpdSectionHeading(heading),
          if (lead != null) ...[
            const SizedBox(height: 14.0),
            Text(
              lead!,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 16.0,
                height: 1.6,
                color: palette.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The bordered panel the whole page is built from — `--bg2` on a `--line`
/// hairline at a 20px radius, with the design's optional drop shadow.
class XpdPanel extends StatelessWidget {
  const XpdPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(28.0),
    this.radius = 20.0,
    this.background,
    this.borderColor,
    this.gradient,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? background;
  final Color? borderColor;
  final Gradient? gradient;

  /// Applies `--shadow`, the deep card shadow on the hero and app mockups.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (background ?? palette.bg2) : null,
        gradient: gradient,
        border: Border.all(color: borderColor ?? palette.line, width: 1.0),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevated ? [palette.shadow] : null,
      ),
      child: child,
    );
  }
}

/// The hatched placeholder plate — `--stripebg` under a 135° repeating stripe.
/// The design uses it for the coverage map, the phone screenshot and the
/// partner logos, all of which are still awaiting real assets.
class XpdStripePlate extends StatelessWidget {
  const XpdStripePlate({
    super.key,
    required this.height,
    this.label,
    this.radius = 14.0,
    this.child,
  });

  final double height;
  final String? label;
  final double radius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _StripePainter(
          background: palette.stripeBg,
          stripe: palette.stripeLine,
        ),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Center(
            child: child ??
                (label == null
                    ? null
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13.0,
                          vertical: 9.0,
                        ),
                        decoration: BoxDecoration(
                          color: palette.bg2,
                          border: Border.all(color: palette.line),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          label!,
                          style: TextStyle(
                            fontFamily: 'Geist Mono',
                            fontSize: 12.0,
                            letterSpacing: 12.0 * 0.12,
                            color: palette.faint,
                          ),
                        ),
                      )),
          ),
        ),
      ),
    );
  }
}

/// `repeating-linear-gradient(135deg, <stripe> 0 2px, transparent 2px 11px)`.
class _StripePainter extends CustomPainter {
  const _StripePainter({required this.background, required this.stripe});

  final Color background;
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    // 135° in CSS runs down-left; drawn here as parallel lines on that
    // diagonal, 2px wide on an 11px period.
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const period = 11.0 * 1.4142135624; // period measured along the diagonal
    final extent = size.width + size.height;
    for (double d = -size.height; d < extent; d += period) {
      canvas.drawLine(Offset(d, 0.0), Offset(d + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) =>
      old.background != background || old.stripe != stripe;
}

/// The site's filled call-to-action — `background:#0052FF`, white label, 12px
/// radius, brightening to [XpdPalette.blueHover] on hover.
class XpdButton extends StatefulWidget {
  const XpdButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = XpdButtonVariant.filled,
    this.fontSize = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 26.0, vertical: 15.0),
    this.radius = 12.0,
    this.expand = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final XpdButtonVariant variant;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool expand;
  final bool busy;

  @override
  State<XpdButton> createState() => _XpdButtonState();
}

enum XpdButtonVariant { filled, outline }

class _XpdButtonState extends State<XpdButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    final filled = widget.variant == XpdButtonVariant.filled;
    final enabled = widget.onPressed != null && !widget.busy;

    final background = filled
        ? (_hovered && enabled ? XpdPalette.blueHover : XpdPalette.blue)
        : (_hovered && enabled ? palette.chip : Colors.transparent);
    final foreground = filled ? Colors.white : palette.text;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: widget.expand ? double.infinity : null,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(widget.radius),
            border: filled ? null : Border.all(color: palette.line2),
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.busy) ...[
                SizedBox(
                  width: widget.fontSize,
                  height: widget.fontSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                ),
                const SizedBox(width: 10.0),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w500,
                    color: enabled ? foreground : foreground.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An inline text link in [XpdPalette.blueLink].
class XpdLink extends StatelessWidget {
  const XpdLink({
    super.key,
    required this.label,
    this.onTap,
    this.fontSize = 14.0,
    this.weight = FontWeight.w500,
  });

  final String label;
  final VoidCallback? onTap;
  final double fontSize;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: fontSize,
            fontWeight: weight,
            color: palette.blueLink,
          ),
        ),
      ),
    );
  }
}

/// The announcement strip above the header, pointing carriers at Expeditoo.
class XpdAnnouncementBar extends StatelessWidget {
  const XpdAnnouncementBar({
    super.key,
    required this.message,
    required this.linkLabel,
    this.onLinkTap,
  });

  final String message;
  final String linkLabel;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    final gutter = XpdLayout.gutterFor(MediaQuery.sizeOf(context).width);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.blueTint(0.10),
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      padding: EdgeInsets.symmetric(horizontal: gutter, vertical: 9.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: XpdLayout.maxWidth),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10.0,
            runSpacing: 4.0,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13.0,
                  color: palette.muted,
                ),
              ),
              XpdLink(label: linkLabel, onTap: onLinkTap, fontSize: 13.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// FR / EN segmented switch, as drawn in the header.
class XpdLanguageToggle extends StatelessWidget {
  const XpdLanguageToggle({
    super.key,
    required this.languageCode,
    required this.onChanged,
  });

  /// Either `fr` or `en`; anything else reads as `fr`.
  final String languageCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    final current = languageCode == 'en' ? 'en' : 'fr';

    Widget cell(String code) {
      final on = current == code;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onChanged(code),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
            color: on ? const Color(0x247F7F7F) : Colors.transparent,
            child: Text(
              code.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Geist Mono',
                fontSize: 11.0,
                letterSpacing: 11.0 * 0.08,
                color: on ? palette.text : palette.dim,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: palette.line2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(mainAxisSize: MainAxisSize.min, children: [cell('fr'), cell('en')]),
    );
  }
}

/// The three theme choices, in the order the menu lists them.
///
/// [ThemeMode.values] leads with `system`; the design puts it last, after the
/// two explicit choices.
const List<ThemeMode> kXpdThemeModes = [
  ThemeMode.light,
  ThemeMode.dark,
  ThemeMode.system,
];

/// The sun/moon/monitor button that opens the theme menu.
///
/// A port of the Expeditoo header control: the current choice as a bare glyph,
/// and a menu offering light, dark and "system" with the active row ticked in
/// brand blue. "System" is a real third state, not a synonym for light — it
/// follows the platform, so [mode] is the stored [ThemeMode] rather than the
/// resolved brightness.
class XpdThemeToggle extends StatelessWidget {
  const XpdThemeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
    this.languageCode = 'fr',
  });

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  /// `'fr'` or `'en'`, matching [XpdLanguageToggle]. The design system has no
  /// localisation layer, so the three labels are carried here.
  final String languageCode;

  static IconData _iconFor(ThemeMode mode) => switch (mode) {
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
        ThemeMode.system => Icons.desktop_windows_outlined,
      };

  String _labelFor(ThemeMode mode) {
    final english = languageCode == 'en';
    return switch (mode) {
      ThemeMode.light => english ? 'Light' : 'Clair',
      ThemeMode.dark => english ? 'Dark' : 'Sombre',
      ThemeMode.system => english ? 'System' : 'Système',
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return PopupMenuButton<ThemeMode>(
      tooltip: languageCode == 'en' ? 'Theme' : 'Thème',
      initialValue: mode,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      offset: const Offset(0.0, 6.0),
      color: palette.bg2,
      surfaceTintColor: Colors.transparent,
      elevation: 8.0,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: BorderSide(color: palette.line),
      ),
      itemBuilder: (context) => [
        for (final option in kXpdThemeModes)
          PopupMenuItem<ThemeMode>(
            value: option,
            height: 44.0,
            // The menu sizes itself to its widest item's intrinsic width, so
            // the row is pinned rather than left to a flexible gap: every row
            // is then the same width and the ticks line up.
            child: SizedBox(
              width: 132.0,
              child: Row(
                children: [
                  Icon(_iconFor(option), size: 18.0, color: palette.muted),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      _labelFor(option),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.text, fontSize: 14.5),
                    ),
                  ),
                  if (option == mode)
                    const Icon(Icons.check_rounded,
                        size: 18.0, color: XpdPalette.blue),
                ],
              ),
            ),
          ),
      ],
      // Borderless, but still a 34px hit target so the header keeps its rhythm.
      child: SizedBox(
        width: 34.0,
        height: 34.0,
        child: Icon(_iconFor(mode), size: 18.0, color: palette.text),
      ),
    );
  }
}

/// One destination in the header's link row.
class XpdNavItem {
  const XpdNavItem({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;
}

/// The sticky, translucent site header.
///
/// Below [XpdLayout.tablet] the link row collapses to a menu button, since the
/// four links plus both toggles plus two actions cannot share a phone's width.
class XpdHeader extends StatelessWidget implements PreferredSizeWidget {
  const XpdHeader({
    super.key,
    required this.links,
    required this.languageCode,
    required this.onLanguageChanged,
    required this.themeMode,
    required this.onThemeChanged,
    this.onLogoTap,
    this.onMenuTap,
    this.trailing = const [],
  });

  final List<XpdNavItem> links;
  final String languageCode;
  final ValueChanged<String> onLanguageChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback? onLogoTap;
  final VoidCallback? onMenuTap;

  /// Log-in link, quote button, account button — whatever the page needs after
  /// the toggles.
  final List<Widget> trailing;

  static const double height = 66.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = XpdLayout.gutterFor(width);
    final compact = width < XpdLayout.tablet;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: palette.headBg,
            border: Border(bottom: BorderSide(color: palette.line)),
          ),
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: XpdLayout.maxWidth),
              child: Row(
                children: [
                  XpdLogo(onTap: onLogoTap),
                  if (!compact) ...[
                    const SizedBox(width: 22.0),
                    Expanded(
                      child: Row(
                        children: [
                          for (final link in links)
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: _HeaderLink(item: link),
                            ),
                        ],
                      ),
                    ),
                    XpdLanguageToggle(
                      languageCode: languageCode,
                      onChanged: onLanguageChanged,
                    ),
                    const SizedBox(width: 12.0),
                    XpdThemeToggle(
                      mode: themeMode,
                      onChanged: onThemeChanged,
                      languageCode: languageCode,
                    ),
                    for (final widget in trailing) ...[
                      const SizedBox(width: 12.0),
                      widget,
                    ],
                  ] else ...[
                    const Spacer(),
                    XpdThemeToggle(
                      mode: themeMode,
                      onChanged: onThemeChanged,
                      languageCode: languageCode,
                    ),
                    const SizedBox(width: 8.0),
                    IconButton(
                      onPressed: onMenuTap,
                      icon: Icon(Icons.menu_rounded, color: palette.text),
                      splashRadius: 22.0,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderLink extends StatefulWidget {
  const _HeaderLink({required this.item});
  final XpdNavItem item;

  @override
  State<_HeaderLink> createState() => _HeaderLinkState();
}

class _HeaderLinkState extends State<_HeaderLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.item.onTap,
        child: Text(
          widget.item.label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14.5,
            color: _hovered ? palette.blueLink : palette.muted,
          ),
        ),
      ),
    );
  }
}

/// A labelled text input in the site's shape: `--input` fill on a `--line2`
/// hairline at an 11px radius, with the border going [XpdPalette.blue] on
/// focus (`style-focus="border-color:#0052FF"`).
class XpdField extends StatefulWidget {
  const XpdField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.verticalPadding = 13.0,
    this.validator,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final double verticalPadding;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  State<XpdField> createState() => _XpdFieldState();
}

class _XpdFieldState extends State<XpdField> {
  late final FocusNode _focus = FocusNode()..addListener(_onFocusChange);

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13.0,
            color: palette.muted,
          ),
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 15.0,
            color: palette.text,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: palette.input,
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontFamily: 'Geist',
              fontSize: 15.0,
              color: palette.faint,
            ),
            suffixIcon: widget.suffix,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: widget.verticalPadding,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.0),
              borderSide: BorderSide(color: palette.line2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.0),
              borderSide: const BorderSide(color: XpdPalette.blue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.0),
              borderSide: BorderSide(color: palette.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.0),
              borderSide: BorderSide(color: palette.red),
            ),
          ),
        ),
      ],
    );
  }
}

/// The same shell as [XpdField] but wrapping a dropdown, for "Type de lot".
class XpdSelect extends StatelessWidget {
  const XpdSelect({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13.0,
            color: palette.muted,
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          decoration: BoxDecoration(
            color: palette.input,
            border: Border.all(color: palette.line2),
            borderRadius: BorderRadius.circular(11.0),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              padding: const EdgeInsets.symmetric(vertical: 13.0),
              dropdownColor: palette.bg2,
              icon: Icon(Icons.expand_more_rounded, color: palette.muted, size: 20.0),
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15.0,
                color: palette.text,
              ),
              borderRadius: BorderRadius.circular(11.0),
              onChanged: onChanged,
              items: [
                for (final option in options)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The dashed bordereau drop zone. Once a file is chosen the caption is
/// replaced by its name in [XpdPalette.green], as the page's `onFile` does.
class XpdFileDrop extends StatefulWidget {
  const XpdFileDrop({
    super.key,
    required this.title,
    required this.caption,
    required this.fileName,
    required this.onTap,
    this.chipSize = 42.0,
    this.padding = const EdgeInsets.all(20.0),
    this.trailingLabel,
  });

  final String title;
  final String caption;

  /// Null until a file is picked.
  final String? fileName;
  final VoidCallback onTap;
  final double chipSize;
  final EdgeInsetsGeometry padding;
  final String? trailingLabel;

  @override
  State<XpdFileDrop> createState() => _XpdFileDropState();
}

class _XpdFileDropState extends State<XpdFileDrop> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    final picked = widget.fileName != null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: _hovered ? XpdPalette.blue : palette.line2,
            radius: widget.chipSize > 38.0 ? 14.0 : 12.0,
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: palette.chip,
              borderRadius:
                  BorderRadius.circular(widget.chipSize > 38.0 ? 14.0 : 12.0),
            ),
            child: Row(
              children: [
                Container(
                  width: widget.chipSize,
                  height: widget.chipSize,
                  decoration: BoxDecoration(
                    color: palette.amberTint(0.12),
                    border: Border.all(color: palette.amberTint(0.30)),
                    borderRadius:
                        BorderRadius.circular(widget.chipSize > 38.0 ? 11.0 : 9.0),
                  ),
                  child: Center(
                    child: Text(
                      'PDF',
                      style: TextStyle(
                        fontFamily: 'Geist Mono',
                        fontSize: widget.chipSize > 38.0 ? 12.0 : 10.5,
                        color: palette.amber,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: widget.chipSize > 38.0 ? 15.0 : 14.0,
                          fontWeight: FontWeight.w500,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 3.0),
                      Text(
                        widget.fileName ?? widget.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: widget.chipSize > 38.0 ? 13.0 : 12.5,
                          color: picked ? palette.green : palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.trailingLabel != null) ...[
                  const SizedBox(width: 12.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 9.0,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: palette.line2),
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                    child: Text(
                      widget.trailingLabel!,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13.5,
                        color: palette.text,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `border:1px dashed` — Flutter's [Border] has no dash, so it is stroked here.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// `★★★★★` in amber, at the design's 0.14em tracking.
class XpdStars extends StatelessWidget {
  const XpdStars({super.key, this.size = 14.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return Text(
      '★★★★★',
      style: TextStyle(
        fontSize: size,
        letterSpacing: size * 0.14,
        color: palette.amber,
      ),
    );
  }
}

/// A pill chip — the hero's "Enlèvement et livraison partout en France" badge.
class XpdChip extends StatelessWidget {
  const XpdChip({super.key, required this.label, this.dotColor});

  final String label;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: palette.chip,
        border: Border.all(color: palette.line2),
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 7.0,
              height: 7.0,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
            ),
            const SizedBox(width: 9.0),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13.0,
                color: palette.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A mono-spaced tag — "RÉPONSE 48 H", "CÔTÉ ACHETEUR · MOBILE", "LE PLUS
/// FRÉQUENT". [filled] paints the solid amber/blue variants.
class XpdTag extends StatelessWidget {
  const XpdTag({
    super.key,
    required this.label,
    required this.color,
    this.background,
    this.borderColor,
    this.filled = false,
  });

  final String label;
  final Color color;
  final Color? background;
  final Color? borderColor;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: filled ? 8.0 : 7.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: background,
        border: borderColor == null ? null : Border.all(color: borderColor!),
        borderRadius: BorderRadius.circular(filled ? 5.0 : 6.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Geist Mono',
          fontSize: 10.0,
          letterSpacing: 10.0 * 0.13,
          color: color,
        ),
      ),
    );
  }
}
