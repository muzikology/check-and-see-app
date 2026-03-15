// ignore_for_file: overridden_fields, annotate_overrides

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';

const kThemeModeKey = '__theme_mode__';
const kThemeModeNameKey = '__theme_mode_name__';
const kAmoledDarkKey = '__amoled_dark__';
const _headlineFontFamily = 'Times New Roman MT';
const _subheadingFontFamily = 'Perandory SemiCondensed';
const _bodyFontFamily = 'Poppins';
const _accentFontFamily = 'Sloop Script Pro';

SharedPreferences? _prefs;

abstract class FlutterFlowTheme {
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();

  static ThemeMode get themeMode {
    final namedMode = _prefs?.getString(kThemeModeNameKey);
    if (namedMode != null) {
      switch (namedMode) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
        default:
          return ThemeMode.system;
      }
    }

    // Backward compatibility for older saved bool preference.
    final darkMode = _prefs?.getBool(kThemeModeKey);
    return darkMode == null
        ? ThemeMode.system
        : darkMode
            ? ThemeMode.dark
            : ThemeMode.light;
  }

  static void saveThemeMode(ThemeMode mode) {
    final modeName = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    _prefs?.setString(kThemeModeNameKey, modeName);

    // Keep legacy key updated so existing logic still has a fallback.
    if (mode == ThemeMode.system) {
      _prefs?.remove(kThemeModeKey);
    } else {
      _prefs?.setBool(kThemeModeKey, mode == ThemeMode.dark);
    }
  }

  static bool get amoledDarkEnabled => _prefs?.getBool(kAmoledDarkKey) ?? false;

  static void saveAmoledDarkEnabled(bool enabled) =>
      _prefs?.setBool(kAmoledDarkKey, enabled);

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

  Typography get typography => ThemeTypography(this);
}

class LightModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary = const Color(0xFF5C4033);
  late Color secondary = const Color(0xFFC8A97E);
  late Color tertiary = const Color(0xFFEDE3D1);
  late Color alternate = const Color(0xFFE6D8C3);
  late Color primaryText = const Color(0xFF3B2F2F);
  late Color secondaryText = const Color(0xFF8B7765);
  late Color primaryBackground = const Color(0xFFF5F0E6);
  late Color secondaryBackground = const Color(0xFFFCF8F2);
  late Color accent1 = const Color(0x335C4033);
  late Color accent2 = const Color(0x33C8A97E);
  late Color accent3 = const Color(0x33EDE3D1);
  late Color accent4 = const Color(0xCCFCF8F2);
  late Color success = const Color(0xFF249689);
  late Color warning = const Color(0xFFF9CF58);
  late Color error = const Color(0xFFFF5963);
  late Color info = const Color(0xFFFFFFFF);
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
}

class ThemeTypography extends Typography {
  ThemeTypography(this.theme);

  final FlutterFlowTheme theme;

  String get displayLargeFamily => _headlineFontFamily;
  bool get displayLargeIsCustom => false;
    TextStyle get displayLarge => TextStyle(
      fontFamily: _headlineFontFamily,
        color: theme.primaryText,
      fontWeight: FontWeight.w700,
        fontSize: 64.0,
      );
  String get displayMediumFamily => _headlineFontFamily;
  bool get displayMediumIsCustom => false;
    TextStyle get displayMedium => TextStyle(
      fontFamily: _headlineFontFamily,
        color: theme.primaryText,
      fontWeight: FontWeight.w700,
        fontSize: 44.0,
      );
  String get displaySmallFamily => _headlineFontFamily;
  bool get displaySmallIsCustom => false;
    TextStyle get displaySmall => TextStyle(
      fontFamily: _headlineFontFamily,
        color: theme.primaryText,
      fontWeight: FontWeight.w700,
        fontSize: 36.0,
      );
  String get headlineLargeFamily => _headlineFontFamily;
  bool get headlineLargeIsCustom => false;
    TextStyle get headlineLarge => TextStyle(
      fontFamily: _headlineFontFamily,
        color: theme.primaryText,
      fontWeight: FontWeight.w700,
        fontSize: 32.0,
      );
  String get headlineMediumFamily => _headlineFontFamily;
  bool get headlineMediumIsCustom => false;
    TextStyle get headlineMedium => TextStyle(
      fontFamily: _headlineFontFamily,
        color: theme.primaryText,
      fontWeight: FontWeight.w700,
        fontSize: 28.0,
      );
  String get headlineSmallFamily => _headlineFontFamily;
  bool get headlineSmallIsCustom => false;
    TextStyle get headlineSmall => TextStyle(
      fontFamily: _headlineFontFamily,
        color: theme.primaryText,
      fontWeight: FontWeight.w700,
        fontSize: 24.0,
      );
    String get titleLargeFamily => _subheadingFontFamily;
  bool get titleLargeIsCustom => false;
    TextStyle get titleLarge => TextStyle(
      fontFamily: _subheadingFontFamily,
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 20.0,
      );
    String get titleMediumFamily => _subheadingFontFamily;
  bool get titleMediumIsCustom => false;
    TextStyle get titleMedium => TextStyle(
      fontFamily: _subheadingFontFamily,
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 18.0,
      );
    String get titleSmallFamily => _subheadingFontFamily;
  bool get titleSmallIsCustom => false;
    TextStyle get titleSmall => TextStyle(
      fontFamily: _subheadingFontFamily,
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 16.0,
      );
  String get labelLargeFamily => _bodyFontFamily;
  bool get labelLargeIsCustom => false;
  TextStyle get labelLarge => GoogleFonts.poppins(
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
      );
  String get labelMediumFamily => _bodyFontFamily;
  bool get labelMediumIsCustom => false;
  TextStyle get labelMedium => GoogleFonts.poppins(
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );
  String get labelSmallFamily => _bodyFontFamily;
  bool get labelSmallIsCustom => false;
    TextStyle get labelSmall => const TextStyle(
      fontFamily: _accentFontFamily,
      color: Color(0xFFC8A97E),
      fontWeight: FontWeight.w400,
        fontSize: 12.0,
      );
  String get bodyLargeFamily => _bodyFontFamily;
  bool get bodyLargeIsCustom => false;
  TextStyle get bodyLarge => GoogleFonts.poppins(
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
      );
  String get bodyMediumFamily => _bodyFontFamily;
  bool get bodyMediumIsCustom => false;
  TextStyle get bodyMedium => GoogleFonts.poppins(
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );
  String get bodySmallFamily => _bodyFontFamily;
  bool get bodySmallIsCustom => false;
  TextStyle get bodySmall => GoogleFonts.poppins(
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
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

  late Color primary = const Color(0xFFD1A98A);
  late Color secondary = const Color(0xFFC8A97E);
  late Color tertiary = const Color(0xFF5C4033);
  late Color alternate = const Color(0xFF2B2520);
  late Color primaryText = const Color(0xFFF7EFE3);
  late Color secondaryText = const Color(0xFFD9C4A8);
  late Color primaryBackground = const Color(0xFF1E1814);
  late Color secondaryBackground = const Color(0xFF2A221C);
  late Color accent1 = const Color(0x33D1A98A);
  late Color accent2 = const Color(0x33C8A97E);
  late Color accent3 = const Color(0x335C4033);
  late Color accent4 = const Color(0xB22A221C);
  late Color success = const Color(0xFF249689);
  late Color warning = const Color(0xFFF9CF58);
  late Color error = const Color(0xFFFF5963);
  late Color info = const Color(0xFFFFFFFF);
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
    final resolvedFontFamily = _resolvePremiumFontFamily(
      fontFamily ?? font?.fontFamily ?? this.fontFamily,
    );

    if (useGoogleFonts && resolvedFontFamily != null) {
      try {
        font = GoogleFonts.getFont(
          resolvedFontFamily,
          fontWeight: fontWeight ?? font?.fontWeight ?? this.fontWeight,
          fontStyle: fontStyle ?? font?.fontStyle ?? this.fontStyle,
        );
      } catch (_) {
        font = (font ?? this).copyWith(fontFamily: resolvedFontFamily);
      }
    }

    if (font != null && resolvedFontFamily != null) {
      try {
        font = GoogleFonts.getFont(
          resolvedFontFamily,
          color: font.color,
          fontSize: font.fontSize,
          fontWeight: font.fontWeight,
          fontStyle: font.fontStyle,
          letterSpacing: font.letterSpacing,
          height: font.height,
          decoration: font.decoration,
          shadows: font.shadows,
        );
      } catch (_) {
        font = (font ?? this).copyWith(fontFamily: resolvedFontFamily);
      }
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
            fontFamily: resolvedFontFamily ?? fontFamily,
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

String? _resolvePremiumFontFamily(String? fontFamily) {
  if (fontFamily == null) {
    return null;
  }

  final normalized =
      fontFamily.replaceAll(RegExp(r'[_-]+'), ' ').trim().toLowerCase();
  final normalizedNoWeight = normalized.replaceAll(RegExp(r'\s\d{3}$'), '');
  final strippedVariant = normalizedNoWeight
      .replaceAll(
        RegExp(
          r'(\s+(thin|extralight|light|regular|medium|semibold|demibold|bold|extrabold|black|italic|oblique))+$',
        ),
        '',
      )
      .trim();
  final squashed = strippedVariant.replaceAll(' ', '');

  if (normalized.startsWith('inter tight')) {
    return _headlineFontFamily;
  }
  if (normalized.startsWith('inter')) {
    return _bodyFontFamily;
  }
  if (squashed.startsWith('poppins')) {
    return _bodyFontFamily;
  }
  if (squashed.startsWith('timesnewroman')) {
    return _headlineFontFamily;
  }
  if (squashed.startsWith('perandory')) {
    return _subheadingFontFamily;
  }
  if (squashed.startsWith('sloopscriptpro')) {
    return _accentFontFamily;
  }
  if (squashed.startsWith('nunito')) {
    return _headlineFontFamily;
  }
  if (squashed.startsWith('opensans')) {
    return _bodyFontFamily;
  }

  switch (fontFamily) {
    case 'Inter Tight':
    case _headlineFontFamily:
      return _headlineFontFamily;
    case 'Inter':
    case _bodyFontFamily:
      return _bodyFontFamily;
    case _subheadingFontFamily:
      return _subheadingFontFamily;
    case _accentFontFamily:
      return _accentFontFamily;
    default:
      return fontFamily;
  }
}
