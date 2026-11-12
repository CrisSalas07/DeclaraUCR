import 'package:declara_ucr/models/declaration_status.dart';
import 'package:flutter/material.dart';

/// Reference colors of the UCR Visual Identity Manual (lab PDF, 5.1).
/// The only place with color codes: widgets read the theme.
class UcrColors {
  const UcrColors._();

  /// "Celeste UCR": headers and institutional accents.
  static const Color skyBlue = Color(0xFF00C0F3);

  /// "Azul UCR": buttons, navigation and titles.
  static const Color blue = Color(0xFF005DA4);

  /// "Blanco": backgrounds and surfaces.
  static const Color white = Color(0xFFFFFFFF);

  /// "Amarillo UCR": secondary accents.
  static const Color yellow = Color(0xFFFFE06A);

  /// "Verde UCR": accents and states with enough contrast.
  static const Color green = Color(0xFF6DC067);

  /// Dark text for sky blue, yellow and green: white on them stays below
  /// 4.5:1, this one passes (accessibility, 5.3).
  static const Color ink = Color(0xFF1B1B1F);
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
    secondary: UcrColors.skyBlue, // headers and accents
    onSecondary: UcrColors.ink,
    tertiary: UcrColors.green,
    onTertiary: UcrColors.ink,
    error: Color(0xFFB3261E),
    onError: UcrColors.white,
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: UcrColors.white, // backgrounds and surfaces
    onSurface: UcrColors.ink,
    onSurfaceVariant: Color(0xFF44474E),
    outline: Color(0xFF74777F),
    outlineVariant: Color(0xFFD5DCE3),
    surfaceContainerLow: Color(0xFFF3F8FC),
    surfaceContainer: Color(0xFFEAF3FA),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    // Institutional typeface (5.2). If Trueno is not bundled, Flutter falls
    // back to Arial / the system font; see assets/fonts/README.txt.
    fontFamily: 'Trueno',
    fontFamilyFallback: const <String>['Arial'],
    scaffoldBackgroundColor: UcrColors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: UcrColors.blue,
      foregroundColor: UcrColors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: UcrColors.blue,
      foregroundColor: UcrColors.white,
    ),
    // Touch targets of at least 48 dp (5.2 and 5.3).
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    cardTheme: const CardThemeData(
      color: UcrColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Color(0xFFD5DCE3)),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
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
