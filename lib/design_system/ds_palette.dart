import 'package:flutter/material.dart';

/// The Expedion Enchères site palette.
///
/// This is a one-to-one port of the CSS custom properties the marketing site
/// sets in `applyTheme()` — the `dark` and `light` maps written onto the page
/// root. [FlutterFlowTheme] only has slots for the dozen-odd colours
/// FlutterFlow generates, and the design leans on ~20: four separate greys for
/// body copy alone (`soft`, `muted`, `dim`, `faint`), two border strengths, and
/// per-theme amber/blue pairs for tinted panels. Rather than bend those into
/// the FlutterFlow slots and lose the distinctions, the full set lives here and
/// `FlutterFlowTheme` maps the subset it needs onto the same values, so a page
/// built on either layer lands on one colour.
///
/// Read it with `XpdPalette.of(context)`, which picks the map matching the
/// ambient [Brightness] exactly as the site's toggle does.
@immutable
class XpdPalette {
  const XpdPalette._({
    required this.bg,
    required this.bg2,
    required this.line,
    required this.line2,
    required this.text,
    required this.soft,
    required this.muted,
    required this.dim,
    required this.faint,
    required this.chip,
    required this.input,
    required this.headBg,
    required this.glowColor,
    required this.stripeBg,
    required this.stripeLine,
    required this.shadow,
    required this.amber,
    required this.amberText,
    required this.amberSub,
    required this.blueText,
    required this.blueSub,
    required this.blueLink,
    required this.green,
    required this.greenBg,
    required this.red,
    required this.isDark,
  });

  /// Page background — `--bg`.
  final Color bg;

  /// Card and panel background — `--bg2`.
  final Color bg2;

  /// Hairline borders — `--line`.
  final Color line;

  /// The stronger border, on inputs and outline buttons — `--line2`.
  final Color line2;

  /// Headings and high-emphasis copy — `--text`.
  final Color text;

  /// List copy inside cards — `--soft`.
  final Color soft;

  /// Body copy and nav links — `--muted`.
  final Color muted;

  /// Fine print — `--dim`.
  final Color dim;

  /// Placeholder and stripe labels — `--faint`.
  final Color faint;

  /// Tinted fill on chips and dashed drop zones — `--chip`.
  final Color chip;

  /// Text-field fill — `--input`.
  final Color input;

  /// Translucent sticky-header fill — `--headbg`.
  final Color headBg;

  /// Centre stop of the hero's radial glow — `--glow`.
  final Color glowColor;

  /// Placeholder plate background — `--stripebg`.
  final Color stripeBg;

  /// Diagonal hatching drawn over [stripeBg] — `--stripe`.
  final Color stripeLine;

  /// Card drop shadow — `--shadow`.
  final BoxShadow shadow;

  /// Brand amber, theme-adjusted for contrast — `--amber`.
  final Color amber;

  /// Amber heading on tinted amber panels — `--ambertext`.
  final Color amberText;

  /// Amber body copy on tinted amber panels — `--ambersub`.
  final Color amberSub;

  /// Blue heading on tinted blue panels — `--bluetext`.
  final Color blueText;

  /// Blue body copy on tinted blue panels — `--bluesub`.
  final Color blueSub;

  /// Hyperlink blue — `--bluelink`.
  final Color blueLink;

  final Color green;
  final Color greenBg;
  final Color red;

  final bool isDark;

  /// The call-to-action blue. Hard-coded in the markup rather than themed, so
  /// it is identical in both maps — every filled button and the Expeditoo mark.
  static const Color blue = Color(0xFF0052FF);

  /// `style-hover` on those same buttons.
  static const Color blueHover = Color(0xFF1F63FF);

  /// The logo's amber ring. Also un-themed: the mark keeps its own colour while
  /// [amber] darkens in light mode so amber *text* stays legible.
  static const Color brandAmber = Color(0xFFFFA91F);

  static const XpdPalette dark = XpdPalette._(
    bg: Color(0xFF08090B),
    bg2: Color(0xFF0E1014),
    line: Color(0x14FFFFFF),
    line2: Color(0x24FFFFFF),
    text: Color(0xFFEDEFF3),
    soft: Color(0xFFB7BEC9),
    muted: Color(0xFF98A1AE),
    dim: Color(0xFF6C7480),
    faint: Color(0xFF5A6270),
    chip: Color(0x0AFFFFFF),
    input: Color(0xFF08090B),
    headBg: Color(0xD108090B),
    glowColor: Color(0x330052FF),
    stripeBg: Color(0xFF0B0D11),
    stripeLine: Color(0x0BFFFFFF),
    shadow: BoxShadow(
      color: Color(0xE6000000),
      blurRadius: 80.0,
      spreadRadius: -40.0,
      offset: Offset(0.0, 40.0),
    ),
    amber: Color(0xFFFFA91F),
    amberText: Color(0xFFFFC46A),
    amberSub: Color(0xFFA79371),
    blueText: Color(0xFF8FB4FF),
    blueSub: Color(0xFF7C8AA8),
    blueLink: Color(0xFF3D7BFF),
    green: Color(0xFF2FBF87),
    greenBg: Color(0x212FBF87),
    red: Color(0xFFFF7A7A),
    isDark: true,
  );

  static const XpdPalette light = XpdPalette._(
    bg: Color(0xFFF4F5F8),
    bg2: Color(0xFFFFFFFF),
    line: Color(0x1A0C121C),
    line2: Color(0x2E0C121C),
    text: Color(0xFF111419),
    soft: Color(0xFF3B4450),
    muted: Color(0xFF4E5866),
    dim: Color(0xFF69737F),
    faint: Color(0xFF8A93A0),
    chip: Color(0x0A0C121C),
    input: Color(0xFFF4F5F8),
    headBg: Color(0xDBFFFFFF),
    glowColor: Color(0x1A0052FF),
    stripeBg: Color(0xFFEBEDF1),
    stripeLine: Color(0x0D0C121C),
    shadow: BoxShadow(
      color: Color(0x590F1728),
      blurRadius: 60.0,
      spreadRadius: -38.0,
      offset: Offset(0.0, 30.0),
    ),
    amber: Color(0xFFC27B00),
    amberText: Color(0xFF8A5800),
    amberSub: Color(0xFF8A6E3E),
    blueText: Color(0xFF0043D6),
    blueSub: Color(0xFF44506E),
    blueLink: Color(0xFF0047E1),
    green: Color(0xFF0E8A5F),
    greenBg: Color(0x1A0E8A5F),
    red: Color(0xFFC2413B),
    isDark: false,
  );

  static XpdPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// `rgba(255,169,31,α)` — the amber tint behind PDF chips and warning panels.
  /// Keyed off [brandAmber] rather than [amber] so the fill keeps the brand hue
  /// in both themes, as the markup's literal rgba values do.
  Color amberTint(double alpha) => brandAmber.withValues(alpha: alpha);

  /// `rgba(0,82,255,α)` — the blue tint behind Expeditoo panels and the badge.
  Color blueTint(double alpha) => blue.withValues(alpha: alpha);
}

/// Layout constants the site repeats on every section.
class XpdLayout {
  const XpdLayout._();

  /// `max-width:1180px` on every section's inner container.
  static const double maxWidth = 1180.0;

  /// The FAQ column is narrower — `max-width:820px`.
  static const double narrowWidth = 820.0;

  /// `padding:0 32px`, tightened on phones.
  static const double gutter = 32.0;
  static const double gutterMobile = 20.0;

  /// `padding-top:110px` between sections, and the shorter 96px variant.
  static const double sectionGap = 110.0;
  static const double sectionGapSm = 96.0;

  /// Below this the two-column grids stack, matching where the 1180px
  /// container stops having room for side-by-side columns.
  static const double desktop = 1000.0;

  /// Below this the header collapses its link row into the drawer.
  static const double tablet = 860.0;

  static double gutterFor(double width) =>
      width < tablet ? gutterMobile : gutter;
}
