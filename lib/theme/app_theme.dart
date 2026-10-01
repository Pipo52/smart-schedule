import 'package:flutter/material.dart';

/// Jewel tones for lesson types. Shared so the home list and the editor
/// stay the same color without a second palette.
abstract final class LessonColors {
  static const lecture = Color(0xFF2C5F7C);
  static const practical = Color(0xFF2F6D52);
  static const laboratory = Color(0xFFB86A32);
}

abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final darkMode = brightness == Brightness.dark;
    const paper = Color(0xFFF3F0E8);
    const card = Color(0xFFFFFCF8);
    const ink = Color(0xFF1C1B19);
    const muted = Color(0xFF5E5A54);
    const line = Color(0xFFE4DDD1);
    const lineStrong = Color(0xFFD4CBBC);
    const pine = Color(0xFF1B3A34);
    const pineSoft = Color(0xFFDCE7E2);
    const pineInk = Color(0xFF10241F);

    const night = Color(0xFF101412);
    const nightCard = Color(0xFF1A1F1C);
    const nightInk = Color(0xFFE8E4DC);
    const nightMuted = Color(0xFFB7B1A6);
    const nightLine = Color(0xFF2A312E);
    const sage = Color(0xFFC9DDD4);
    const sageDeep = Color(0xFF24312C);

    final scheme = darkMode
        ? ColorScheme.dark(
            primary: sage,
            onPrimary: pineInk,
            primaryContainer: sageDeep,
            onPrimaryContainer: const Color(0xFFD7E6DF),
            secondary: const Color(0xFFD7C4B0),
            onSecondary: const Color(0xFF2C211A),
            secondaryContainer: const Color(0xFF3A312A),
            onSecondaryContainer: const Color(0xFFF0E6DC),
            tertiary: const Color(0xFFE2B07A),
            onTertiary: const Color(0xFF3A250E),
            tertiaryContainer: const Color(0xFF3D2E22),
            onTertiaryContainer: const Color(0xFFF3E0C8),
            error: const Color(0xFFFFB4AB),
            onError: const Color(0xFF690005),
            errorContainer: const Color(0xFF93000A),
            onErrorContainer: const Color(0xFFFFDAD6),
            surface: nightCard,
            onSurface: nightInk,
            surfaceContainerHighest: const Color(0xFF262C29),
            onSurfaceVariant: nightMuted,
            outline: const Color(0xFF8A847A),
            outlineVariant: nightLine,
          )
        : ColorScheme.light(
            primary: pine,
            onPrimary: const Color(0xFFF6F3EC),
            primaryContainer: pineSoft,
            onPrimaryContainer: pineInk,
            secondary: const Color(0xFF6B5344),
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFFF0E6DC),
            onSecondaryContainer: const Color(0xFF2C211A),
            tertiary: const Color(0xFF8A5A2B),
            onTertiary: Colors.white,
            tertiaryContainer: const Color(0xFFF6E7D4),
            onTertiaryContainer: const Color(0xFF3A250E),
            error: const Color(0xFF9C3B32),
            onError: Colors.white,
            errorContainer: const Color(0xFFF8D9D4),
            onErrorContainer: const Color(0xFF4A1612),
            surface: card,
            onSurface: ink,
            surfaceContainerHighest: const Color(0xFFEBE6DC),
            onSurfaceVariant: muted,
            outline: lineStrong,
            outlineVariant: line,
          );

    final scaffold = darkMode ? night : paper;
    final inkColor = darkMode ? nightInk : ink;
    final mutedColor = darkMode ? nightMuted : muted;
    final baseText = darkMode
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme.copyWith(surfaceTint: Colors.transparent),
      scaffoldBackgroundColor: scaffold,
      splashFactory: InkRipple.splashFactory,
      textTheme: baseText.copyWith(
        headlineSmall: baseText.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: inkColor,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: inkColor,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: inkColor,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          color: inkColor,
          height: 1.35,
        ),
        bodySmall: baseText.bodySmall?.copyWith(color: mutedColor, height: 1.3),
        labelLarge: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffold,
        foregroundColor: inkColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.45,
          color: inkColor,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffold,
        elevation: 0,
        height: 64,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.1,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const CircleBorder(),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.primary;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.onPrimary;
            return scheme.onSurface;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: darkMode ? sage : ink,
        contentTextStyle: TextStyle(color: darkMode ? pineInk : paper),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
