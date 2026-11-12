import 'package:declara_ucr/models/declaration_status.dart';
import 'package:flutter/material.dart';

/// Colors of the UCR Visual Identity Manual (2019, p. 28) and of the
/// accessible digital palette of the Centro de Informática (2025, p. 3).
/// The only place with color codes: widgets read the theme.
class UcrColors {
  const UcrColors._();

  /// "Celeste UCR": headers and institutional accents.
  static const Color skyBlue = Color(0xFF00C0F3);

  /// "Azul UCR": buttons, navigation and titles.
  static const Color blue = Color(0xFF005DA4);

  /// "Azul 1" of the accessible palette: dark blue for the status bar and
  /// text on light blue.
  static const Color navy = Color(0xFF0C344E);

  /// "Blanco": backgrounds and surfaces.
  static const Color white = Color(0xFFFFFFFF);

  /// Blue-tinted page background, so white cards stand out.
  static const Color canvas = Color(0xFFF3F6FA);

  /// "Amarillo UCR": secondary accents.
  static const Color yellow = Color(0xFFFFE06A);

  /// "Verde UCR": accents and states with enough contrast.
  static const Color green = Color(0xFF6DC067);

  /// "Gris 3" of the accessible palette: text on sky blue, yellow and green,
  /// where white stays below 4.5:1 (accessibility, 5.3).
  static const Color ink = Color(0xFF232323);

  /// Flat "Azul UCR" for the hero areas (login, home, summary): the manual
  /// asks apps for flat designs and measured use of gradients (p. 122).
  static const Color hero = blue;
}

/// Declaration status colors, as a theme extension.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors(this.background);

  final Map<DeclarationStatus, Color> background;

  Color of(DeclarationStatus status) => background[status] ?? UcrColors.skyBlue;

  @override
  StatusColors copyWith({Map<DeclarationStatus, Color>? background}) =>
      StatusColors(background ?? this.background);

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) => this;
}

ThemeData buildUcrTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: UcrColors.blue, // buttons, navigation and titles
    onPrimary: UcrColors.white, // 6.5:1 on blue
    primaryContainer: Color(0xFFD9ECFA),
    onPrimaryContainer: UcrColors.navy,
    secondary: UcrColors.skyBlue, // headers and accents
    onSecondary: UcrColors.ink,
    tertiary: UcrColors.green,
    onTertiary: UcrColors.ink,
    error: Color(0xFFB3261E),
    onError: UcrColors.white,
    errorContainer: Color(0xFFFBE4E2),
    onErrorContainer: Color(0xFF5C1410),
    surface: UcrColors.white, // backgrounds and surfaces
    onSurface: UcrColors.ink,
    onSurfaceVariant: Color(0xFF4A5565),
    outline: Color(0xFF7A8594),
    outlineVariant: Color(0xFFDDE4EC),
    surfaceContainerLowest: UcrColors.white,
    surfaceContainerLow: Color(0xFFF6F9FC),
    surfaceContainer: Color(0xFFEDF3F9),
    surfaceContainerHigh: Color(0xFFE5EDF5),
  );
  const radius = BorderRadius.all(Radius.circular(14));
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    // Institutional typeface (5.2). If Trueno is not bundled, Flutter falls
    // back to Arial / the system font; see assets/fonts/README.txt.
    fontFamily: 'Trueno',
    fontFamilyFallback: const <String>['Arial'],
  );
  final text = base.textTheme.apply(
    bodyColor: UcrColors.ink,
    displayColor: UcrColors.ink,
  );

  return base.copyWith(
    scaffoldBackgroundColor: UcrColors.canvas,
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: text.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: UcrColors.canvas,
      foregroundColor: UcrColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: scheme.outlineVariant,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: UcrColors.blue,
      foregroundColor: UcrColors.white,
      elevation: 2,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    // Touch targets of at least 48 dp (5.2 and 5.3).
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: const RoundedRectangleBorder(borderRadius: radius),
        textStyle: text.labelLarge?.copyWith(fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: const RoundedRectangleBorder(borderRadius: radius),
        side: BorderSide(color: scheme.outlineVariant, width: 1.5),
        backgroundColor: UcrColors.white,
        textStyle: text.labelLarge?.copyWith(fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: UcrColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: const OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.outlineVariant, width: 1.5),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: UcrColors.blue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: UcrColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outlineVariant),
        borderRadius: const BorderRadius.all(Radius.circular(18)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: UcrColors.ink,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: UcrColors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: UcrColors.blue,
      linearTrackColor: scheme.surfaceContainerHigh,
    ),
    extensions: const <ThemeExtension<dynamic>>[
      StatusColors(<DeclarationStatus, Color>{
        DeclarationStatus.draft: UcrColors.yellow,
        DeclarationStatus.validated: UcrColors.green,
        DeclarationStatus.pendingDeclarantSignature: UcrColors.skyBlue,
      }),
    ],
  );
}
