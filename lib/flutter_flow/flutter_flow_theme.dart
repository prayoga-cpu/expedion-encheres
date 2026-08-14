// ignore_for_file: overridden_fields, annotate_overrides

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '/design_system/ds_palette.dart';

const kThemeModeKey = '__theme_mode__';

SharedPreferences? _prefs;

abstract class FlutterFlowTheme {
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();

  static ThemeMode get themeMode {
    final darkMode = _prefs?.getBool(kThemeModeKey);
    return darkMode == null
        ? ThemeMode.system
        : darkMode
            ? ThemeMode.dark
            : ThemeMode.light;
  }

  static void saveThemeMode(ThemeMode mode) => mode == ThemeMode.system
      ? _prefs?.remove(kThemeModeKey)
      : _prefs?.setBool(kThemeModeKey, mode == ThemeMode.dark);

  static FlutterFlowTheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? DarkModeTheme()
        : LightModeTheme();
  }

  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary;
  late Color secondary;
  late Color tertiary;
  late Color alternate;
  late Color primaryText;
  late Color secondaryText;
  late Color primaryBackground;
  late Color secondaryBackground;
  late Color accent1;
  late Color accent2;
  late Color accent3;
  late Color accent4;
  late Color success;
  late Color warning;
  late Color error;
  late Color info;

  FFDesignTokens get designToken => FFDesignTokens(this);

  @Deprecated('Use displaySmallFamily instead')
  String get title1Family => displaySmallFamily;
  @Deprecated('Use displaySmall instead')
  TextStyle get title1 => typography.displaySmall;
  @Deprecated('Use headlineMediumFamily instead')
  String get title2Family => typography.headlineMediumFamily;
  @Deprecated('Use headlineMedium instead')
  TextStyle get title2 => typography.headlineMedium;
  @Deprecated('Use headlineSmallFamily instead')
  String get title3Family => typography.headlineSmallFamily;
  @Deprecated('Use headlineSmall instead')
  TextStyle get title3 => typography.headlineSmall;
  @Deprecated('Use titleMediumFamily instead')
  String get subtitle1Family => typography.titleMediumFamily;
  @Deprecated('Use titleMedium instead')
  TextStyle get subtitle1 => typography.titleMedium;
  @Deprecated('Use titleSmallFamily instead')
  String get subtitle2Family => typography.titleSmallFamily;
  @Deprecated('Use titleSmall instead')
  TextStyle get subtitle2 => typography.titleSmall;
  @Deprecated('Use bodyMediumFamily instead')
  String get bodyText1Family => typography.bodyMediumFamily;
  @Deprecated('Use bodyMedium instead')
  TextStyle get bodyText1 => typography.bodyMedium;
  @Deprecated('Use bodySmallFamily instead')
  String get bodyText2Family => typography.bodySmallFamily;
  @Deprecated('Use bodySmall instead')
  TextStyle get bodyText2 => typography.bodySmall;

  String get displayLargeFamily => typography.displayLargeFamily;
  bool get displayLargeIsCustom => typography.displayLargeIsCustom;
  TextStyle get displayLarge => typography.displayLarge;
  String get displayMediumFamily => typography.displayMediumFamily;
  bool get displayMediumIsCustom => typography.displayMediumIsCustom;
  TextStyle get displayMedium => typography.displayMedium;
  String get displaySmallFamily => typography.displaySmallFamily;
  bool get displaySmallIsCustom => typography.displaySmallIsCustom;
  TextStyle get displaySmall => typography.displaySmall;
  String get headlineLargeFamily => typography.headlineLargeFamily;
  bool get headlineLargeIsCustom => typography.headlineLargeIsCustom;
  TextStyle get headlineLarge => typography.headlineLarge;
  String get headlineMediumFamily => typography.headlineMediumFamily;
  bool get headlineMediumIsCustom => typography.headlineMediumIsCustom;
  TextStyle get headlineMedium => typography.headlineMedium;
  String get headlineSmallFamily => typography.headlineSmallFamily;
  bool get headlineSmallIsCustom => typography.headlineSmallIsCustom;
  TextStyle get headlineSmall => typography.headlineSmall;
  String get titleLargeFamily => typography.titleLargeFamily;
  bool get titleLargeIsCustom => typography.titleLargeIsCustom;
  TextStyle get titleLarge => typography.titleLarge;
  String get titleMediumFamily => typography.titleMediumFamily;
  bool get titleMediumIsCustom => typography.titleMediumIsCustom;
  TextStyle get titleMedium => typography.titleMedium;
  String get titleSmallFamily => typography.titleSmallFamily;
  bool get titleSmallIsCustom => typography.titleSmallIsCustom;
  TextStyle get titleSmall => typography.titleSmall;
  String get labelLargeFamily => typography.labelLargeFamily;
  bool get labelLargeIsCustom => typography.labelLargeIsCustom;
  TextStyle get labelLarge => typography.labelLarge;
  String get labelMediumFamily => typography.labelMediumFamily;
  bool get labelMediumIsCustom => typography.labelMediumIsCustom;
  TextStyle get labelMedium => typography.labelMedium;
  String get labelSmallFamily => typography.labelSmallFamily;
  bool get labelSmallIsCustom => typography.labelSmallIsCustom;
  TextStyle get labelSmall => typography.labelSmall;
  String get bodyLargeFamily => typography.bodyLargeFamily;
  bool get bodyLargeIsCustom => typography.bodyLargeIsCustom;
  TextStyle get bodyLarge => typography.bodyLarge;
  String get bodyMediumFamily => typography.bodyMediumFamily;
  bool get bodyMediumIsCustom => typography.bodyMediumIsCustom;
  TextStyle get bodyMedium => typography.bodyMedium;
  String get bodySmallFamily => typography.bodySmallFamily;
  bool get bodySmallIsCustom => typography.bodySmallIsCustom;
  TextStyle get bodySmall => typography.bodySmall;
  String get monoFamily => typography.monoFamily;
  TextStyle get monoLarge => typography.monoLarge;
  TextStyle get monoMedium => typography.monoMedium;
  TextStyle get monoSmall => typography.monoSmall;

  Typography get typography => ThemeTypography(this);
}

class LightModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  // Expedion Enchères site tokens — the `light` map in the marketing page's
  // `applyTheme()`. The full set, including the greys and tinted pairs that
  // have no FlutterFlow slot, is in `design_system/ds_palette.dart`; these are
  // the same values under the names FlutterFlow-generated pages already read.
  late Color primary = XpdPalette.blue; // CTA blue, un-themed
  late Color secondary = const Color(0xFFE7E9EE); // `chip` on an opaque ground
  late Color tertiary = const Color(0xFFC27B00); // `amber`
  late Color alternate = const Color(0x1A0C121C); // `line`
  late Color primaryText = const Color(0xFF111419); // `text`
  late Color secondaryText = const Color(0xFF4E5866); // `muted`
  late Color primaryBackground = const Color(0xFFF4F5F8); // `bg`
  late Color secondaryBackground = const Color(0xFFFFFFFF); // `bg2`
  late Color accent1 = const Color(0xFFF4F5F8); // `input` fill
  late Color accent2 = const Color(0x1A0E8A5F); // `greenbg`
  late Color accent3 = const Color(0x1FFFA91F); // amber tint
  late Color accent4 = const Color(0xDBFFFFFF); // `headbg`
  late Color success = const Color(0xFF0E8A5F); // `green`
  late Color warning = const Color(0xFFC27B00); // `amber`
  late Color error = const Color(0xFFC2413B); // `red`
  late Color info = const Color(0xFFFFFFFF); // on-primary foreground
}

abstract class Typography {
  String get displayLargeFamily;
  bool get displayLargeIsCustom;
  TextStyle get displayLarge;
  String get displayMediumFamily;
  bool get displayMediumIsCustom;
  TextStyle get displayMedium;
  String get displaySmallFamily;
  bool get displaySmallIsCustom;
  TextStyle get displaySmall;
  String get headlineLargeFamily;
  bool get headlineLargeIsCustom;
  TextStyle get headlineLarge;
  String get headlineMediumFamily;
  bool get headlineMediumIsCustom;
  TextStyle get headlineMedium;
  String get headlineSmallFamily;
  bool get headlineSmallIsCustom;
  TextStyle get headlineSmall;
  String get titleLargeFamily;
  bool get titleLargeIsCustom;
  TextStyle get titleLarge;
  String get titleMediumFamily;
  bool get titleMediumIsCustom;
  TextStyle get titleMedium;
  String get titleSmallFamily;
  bool get titleSmallIsCustom;
  TextStyle get titleSmall;
  String get labelLargeFamily;
  bool get labelLargeIsCustom;
  TextStyle get labelLarge;
  String get labelMediumFamily;
  bool get labelMediumIsCustom;
  TextStyle get labelMedium;
  String get labelSmallFamily;
  bool get labelSmallIsCustom;
  TextStyle get labelSmall;
  String get bodyLargeFamily;
  bool get bodyLargeIsCustom;
  TextStyle get bodyLarge;
  String get bodyMediumFamily;
  bool get bodyMediumIsCustom;
  TextStyle get bodyMedium;
  String get bodySmallFamily;
  bool get bodySmallIsCustom;
  TextStyle get bodySmall;
  String get monoFamily;
  TextStyle get monoLarge;
  TextStyle get monoMedium;
  TextStyle get monoSmall;
}

class ThemeTypography extends Typography {
  ThemeTypography(this.theme);

  final FlutterFlowTheme theme;

  /// Geist (SIL OFL 1.1) is the site's `font-family` and ships as a bundled
  /// asset — it is not in google_fonts 6.3.3, so there is no runtime fetch and
  /// `isCustom` is true throughout.
  static const String _sans = 'Geist';

  /// The site tracks its headings tighter the larger they get:
  /// `-0.035em` at 56px down to `-0.01em` at 16px. Expressed here in logical
  /// pixels, which is what [TextStyle.letterSpacing] takes.
  static double _track(double size, double em) => size * em;

  String get displayLargeFamily => _sans;
  bool get displayLargeIsCustom => true;
  TextStyle get displayLarge => TextStyle(
        fontFamily: _sans,
        color: theme.primaryText,
        fontWeight: FontWeight.w700,
        fontSize: 32.0,
        letterSpacing: _track(32.0, -0.035),
        height: 1.08,
      );
  String get displayMediumFamily => _sans;
  bool get displayMediumIsCustom => true;
  TextStyle get displayMedium => TextStyle(
        fontFamily: _sans,
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 30.0,
        letterSpacing: _track(30.0, -0.03),
        height: 1.1,
      );
  String get displaySmallFamily => _sans;
  bool get displaySmallIsCustom => true;
  TextStyle get displaySmall => TextStyle(
        fontFamily: _sans,
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 28.0,
        letterSpacing: _track(28.0, -0.025),
        height: 1.12,
      );
  String get headlineLargeFamily => _sans;
  bool get headlineLargeIsCustom => true;
  TextStyle get headlineLarge => TextStyle(
        fontFamily: _sans,
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 26.0,
        letterSpacing: _track(26.0, -0.025),
        height: 1.15,
      );
  String get headlineMediumFamily => _sans;
  bool get headlineMediumIsCustom => true;
  TextStyle get headlineMedium => TextStyle(
        fontFamily: _sans,
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 24.0,
        letterSpacing: _track(24.0, -0.02),
        height: 1.2,
      );
  String get headlineSmallFamily => _sans;
  bool get headlineSmallIsCustom => true;
  TextStyle get headlineSmall => TextStyle(
        fontFamily: _sans,
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 22.0,
        letterSpacing: _track(22.0, -0.02),
        height: 1.2,
      );
  String get titleLargeFamily => _sans;
  bool get titleLargeIsCustom => true;
  TextStyle get titleLarge => TextStyle(
        fontFamily: _sans,
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 20.0,
        letterSpacing: _track(20.0, -0.015),
      );
  String get titleMediumFamily => _sans;
  bool get titleMediumIsCustom => true;
  TextStyle get titleMedium => TextStyle(
        fontFamily: _sans,
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 17.0,
        letterSpacing: _track(17.0, -0.01),
      );
  String get titleSmallFamily => _sans;
  bool get titleSmallIsCustom => true;
  TextStyle get titleSmall => TextStyle(
        fontFamily: _sans,
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 15.0,
        letterSpacing: _track(15.0, -0.01),
      );
  String get labelLargeFamily => _sans;
  bool get labelLargeIsCustom => true;
  TextStyle get labelLarge => TextStyle(
        fontFamily: _sans,
        color: theme.secondaryText,
        fontWeight: FontWeight.w400,
        fontSize: 15.0,
      );
  String get labelMediumFamily => _sans;
  bool get labelMediumIsCustom => true;
  TextStyle get labelMedium => TextStyle(
        fontFamily: _sans,
        color: theme.secondaryText,
        fontWeight: FontWeight.w400,
        fontSize: 13.5,
      );
  String get labelSmallFamily => _sans;
  bool get labelSmallIsCustom => true;
  TextStyle get labelSmall => TextStyle(
        fontFamily: _sans,
        color: theme.secondaryText,
        fontWeight: FontWeight.w400,
        fontSize: 13.0,
      );
  String get bodyLargeFamily => _sans;
  bool get bodyLargeIsCustom => true;
  TextStyle get bodyLarge => TextStyle(
        fontFamily: _sans,
        color: theme.primaryText,
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        height: 1.6,
      );
  String get bodyMediumFamily => _sans;
  bool get bodyMediumIsCustom => true;
  TextStyle get bodyMedium => TextStyle(
        fontFamily: _sans,
        color: theme.primaryText,
        fontWeight: FontWeight.w400,
        fontSize: 14.5,
        height: 1.55,
      );
  String get bodySmallFamily => _sans;
  bool get bodySmallIsCustom => true;
  TextStyle get bodySmall => TextStyle(
        fontFamily: _sans,
        color: theme.primaryText,
        fontWeight: FontWeight.w400,
        fontSize: 13.0,
        height: 1.5,
      );

  // Geist Mono — numerals, bordereau numbers, prices, tracking codes.
  // Not published in google_fonts 6.3.3, so it ships as a bundled asset
  // (assets/fonts/GeistMono-*.ttf, declared in pubspec.yaml).
  String get monoFamily => 'Geist Mono';
  TextStyle get monoLarge => TextStyle(
        fontFamily: monoFamily,
        color: theme.primaryText,
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
      );
  TextStyle get monoMedium => TextStyle(
        fontFamily: monoFamily,
        color: theme.primaryText,
        fontWeight: FontWeight.w400,
        fontSize: 14.0,
      );
  TextStyle get monoSmall => TextStyle(
        fontFamily: monoFamily,
        color: theme.secondaryText,
        fontWeight: FontWeight.w400,
        fontSize: 12.0,
      );
}

class DarkModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  // The `dark` map in the marketing page's `applyTheme()`. The CTA blue and the
  // logo amber are un-themed and shared with light mode; only the neutral ramp
  // inverts and the amber/green/red shift for contrast on a near-black ground.
  late Color primary = XpdPalette.blue; // CTA blue, un-themed
  late Color secondary = const Color(0xFF1B1E24); // `chip` on an opaque ground
  late Color tertiary = const Color(0xFFFFA91F); // `amber`
  late Color alternate = const Color(0x14FFFFFF); // `line`
  late Color primaryText = const Color(0xFFEDEFF3); // `text`
  late Color secondaryText = const Color(0xFF98A1AE); // `muted`
  late Color primaryBackground = const Color(0xFF08090B); // `bg`
  late Color secondaryBackground = const Color(0xFF0E1014); // `bg2`
  late Color accent1 = const Color(0xFF08090B); // `input` fill
  late Color accent2 = const Color(0x212FBF87); // `greenbg`
  late Color accent3 = const Color(0x1FFFA91F); // amber tint
  late Color accent4 = const Color(0xD108090B); // `headbg`
  late Color success = const Color(0xFF2FBF87); // `green`
  late Color warning = const Color(0xFFFFA91F); // `amber`
  late Color error = const Color(0xFFFF7A7A); // `red`
  late Color info = const Color(0xFFFFFFFF); // on-primary foreground
}

class FFDesignTokens {
  const FFDesignTokens(this.theme);
  final FlutterFlowTheme theme;
  FFSpacing get spacing => const FFSpacing();
  FFRadius get radius => const FFRadius();
  FFShadows get shadow => FFShadows(theme);
  FFMotion get motion => const FFMotion();
}

class FFSpacing {
  const FFSpacing();
  double get xs => 4.0;
  double get sm => 8.0;

  /// Card padding floor. Expeditoo cards run 16–20px.
  double get md => 16.0;
  double get cardPadding => 20.0;

  /// Gap between page sections.
  double get lg => 24.0;
  double get xl => 32.0;
}

/// Mirrors Expeditoo's `--radius` scale (`0.5rem` base).
///
/// `sm` = calc(radius - 2px), `md` = radius, `lg` = calc(radius + 4px),
/// `xl` = calc(radius + 8px). Buttons and inputs take `md`, cards take `lg`,
/// bottom sheets take `xl`. `full` is reserved for status chips — nothing else
/// in either app is a pill.
class FFRadius {
  const FFRadius();
  double get sm => 6.0;
  double get md => 8.0;
  double get lg => 12.0;
  double get xl => 16.0;
  double get full => 9999.0;
}

class FFShadows {
  const FFShadows(this.theme);
  final FlutterFlowTheme theme;

  /// Tailwind `shadow-xs`, used on buttons and inputs.
  BoxShadow get xs => const BoxShadow(
      blurRadius: 2.0,
      color: Color(0x0D000000),
      offset: Offset(0.0, 1.0),
      spreadRadius: 0.0);
  BoxShadow get sm => const BoxShadow(
      blurRadius: 3.0,
      color: Color(0x1A000000),
      offset: Offset(0.0, 1.0),
      spreadRadius: 0.0);
  BoxShadow get md => const BoxShadow(
      blurRadius: 6.0,
      color: Color(0x1A000000),
      offset: Offset(0.0, 3.0),
      spreadRadius: 0.0);
  BoxShadow get lg => const BoxShadow(
      blurRadius: 15.0,
      color: Color(0x1A000000),
      offset: Offset(0.0, 8.0),
      spreadRadius: 0.0);
  BoxShadow get xl => const BoxShadow(
      blurRadius: 25.0,
      color: Color(0x1A000000),
      offset: Offset(0.0, 16.0),
      spreadRadius: 0.0);
}

/// Expeditoo animates colour, border, fill and stroke over 200ms ease-in-out.
class FFMotion {
  const FFMotion();
  Duration get fast => const Duration(milliseconds: 120);
  Duration get standard => const Duration(milliseconds: 200);
  Curve get curve => Curves.easeInOut;
}

/// Projects the Expeditoo tokens onto Material's own surfaces.
///
/// Without this, anything Flutter draws for us — text cursors, selection
/// handles, dialogs, snackbars, progress indicators, the default input border —
/// keeps stock Material colouring and the two apps diverge everywhere the
/// framework paints instead of us.
extension FlutterFlowThemeData on FlutterFlowTheme {
  ThemeData toThemeData(Brightness brightness) {
    final radius = designToken.radius;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: info,
      secondary: tertiary,
      onSecondary: info,
      error: error,
      onError: info,
      surface: secondaryBackground,
      onSurface: primaryText,
    );

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.md),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      brightness: brightness,
      useMaterial3: false,
      colorScheme: scheme,
      primaryColor: primary,
      scaffoldBackgroundColor: primaryBackground,
      canvasColor: secondaryBackground,
      dividerColor: alternate,
      dividerTheme: DividerThemeData(color: alternate, thickness: 1.0),
      fontFamily: displayLargeFamily,
      splashColor: primary.withValues(alpha: 0.08),
      highlightColor: primary.withValues(alpha: 0.04),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.24),
        selectionHandleColor: primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: accent1,
        hintStyle: labelMedium,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 12.0,
        ),
        enabledBorder: border(alternate, 1.0),
        focusedBorder: border(primary, 2.0),
        errorBorder: border(error, 1.0),
        focusedErrorBorder: border(error, 2.0),
        disabledBorder: border(alternate, 1.0),
      ),
      cardTheme: CardThemeData(
        color: secondaryBackground,
        elevation: 0.0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.lg),
          side: BorderSide(color: alternate, width: 1.0),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryBackground,
        foregroundColor: primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0.0,
        iconTheme: IconThemeData(color: primaryText),
        titleTextStyle: titleLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: secondaryBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: secondaryBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0.0,
        titleTextStyle: titleLarge,
        contentTextStyle: bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.lg),
          side: BorderSide(color: alternate, width: 1.0),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryText,
        contentTextStyle: bodyMedium.copyWith(color: primaryBackground),
        actionTextColor: primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        circularTrackColor: alternate,
        linearTrackColor: alternate,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.sm - 2.0),
        ),
        side: BorderSide(color: alternate, width: 1.0),
      ),
      iconTheme: IconThemeData(color: primaryText),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: primaryText,
          borderRadius: BorderRadius.circular(radius.sm),
        ),
        textStyle: bodySmall.copyWith(color: primaryBackground),
      ),
    );
  }
}

extension TextStyleHelper on TextStyle {
  TextStyle override({
    TextStyle? font,
    String? fontFamily,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    FontStyle? fontStyle,
    bool useGoogleFonts = false,
    TextDecoration? decoration,
    double? lineHeight,
    List<Shadow>? shadows,
    String? package,
  }) {
    if (useGoogleFonts && fontFamily != null) {
      font = GoogleFonts.getFont(fontFamily,
          fontWeight: fontWeight ?? this.fontWeight,
          fontStyle: fontStyle ?? this.fontStyle);
    }

    return font != null
        ? font.copyWith(
            color: color ?? this.color,
            fontSize: fontSize ?? this.fontSize,
            letterSpacing: letterSpacing ?? this.letterSpacing,
            fontWeight: fontWeight ?? this.fontWeight,
            fontStyle: fontStyle ?? this.fontStyle,
            decoration: decoration,
            height: lineHeight,
            shadows: shadows,
          )
        : copyWith(
            fontFamily: fontFamily,
            package: package,
            color: color,
            fontSize: fontSize,
            letterSpacing: letterSpacing,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
            decoration: decoration,
            height: lineHeight,
            shadows: shadows,
          );
  }
}
