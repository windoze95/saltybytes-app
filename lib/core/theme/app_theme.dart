import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Bold palette
  static const Color _coral = Color(0xFFFF3B5C);
  static const Color _purple = Color(0xFF6C5CE7);
  static const Color _teal = Color(0xFF00C9A7);
  static const Color _ink = Color(0xFF1A1A2E);
  static const Color _errorRed = Color(0xFFFF3B30);

  static final ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _coral,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFFFE0E6),
    onPrimaryContainer: const Color(0xFF5C0018),
    secondary: _purple,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFEDE7FF),
    onSecondaryContainer: const Color(0xFF21005D),
    tertiary: _teal,
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFB2F5EA),
    onTertiaryContainer: const Color(0xFF003D33),
    surface: Colors.white,
    onSurface: _ink,
    surfaceContainerHighest: const Color(0xFFF5F5FA),
    error: _errorRed,
    onError: Colors.white,
    outline: const Color(0xFFD0D0DA),
    shadow: const Color(0x1A000000),
  );

  static final ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFFFF6B85),
    onPrimary: const Color(0xFF5C0018),
    primaryContainer: const Color(0xFF8C0030),
    onPrimaryContainer: const Color(0xFFFFDAE0),
    secondary: const Color(0xFFB4A7FF),
    onSecondary: const Color(0xFF21005D),
    secondaryContainer: const Color(0xFF3F35A0),
    onSecondaryContainer: const Color(0xFFE8DEFF),
    tertiary: const Color(0xFF5CFFD4),
    onTertiary: const Color(0xFF003D33),
    tertiaryContainer: const Color(0xFF005747),
    onTertiaryContainer: const Color(0xFFB2F5EA),
    surface: const Color(0xFF121218),
    onSurface: const Color(0xFFF0F0F5),
    surfaceContainerHighest: const Color(0xFF1E1E28),
    error: const Color(0xFFFF6B6B),
    onError: const Color(0xFF5C0000),
    outline: const Color(0xFF3A3A48),
    shadow: const Color(0x40000000),
  );

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final body = GoogleFonts.interTextTheme();
    final display = GoogleFonts.ralewayTextTheme();

    return body.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: display.displayMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: display.displaySmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: body.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleMedium: body.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      titleSmall: body.titleSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        fontSize: 14,
        height: 1.5,
      ),
      bodySmall: body.bodySmall?.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.6),
        fontSize: 12,
      ),
      labelLarge: body.labelLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.3,
      ),
      labelMedium: body.labelMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      labelSmall: body.labelSmall?.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.55),
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(_lightColorScheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _lightColorScheme.outline.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _coral,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _ink,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: _lightColorScheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _coral,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F8FC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _lightColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _coral, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _errorRed),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: _ink.withValues(alpha: 0.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF5F5FA),
        selectedColor: _coral.withValues(alpha: 0.12),
        labelStyle: textTheme.labelMedium!,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide(color: _lightColorScheme.outline.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: _coral.withValues(alpha: 0.12),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _coral,
        unselectedItemColor: _ink.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _coral,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: _lightColorScheme.outline.withValues(alpha: 0.3),
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(_darkColorScheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: _darkColorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: _darkColorScheme.surface,
        foregroundColor: _darkColorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _darkColorScheme.outline.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        color: _darkColorScheme.surfaceContainerHighest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkColorScheme.primary,
          foregroundColor: _darkColorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkColorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: _darkColorScheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkColorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkColorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkColorScheme.error),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: _darkColorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkColorScheme.surfaceContainerHighest,
        selectedColor: _darkColorScheme.primary.withValues(alpha: 0.2),
        labelStyle: textTheme.labelMedium!,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide(color: _darkColorScheme.outline.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _darkColorScheme.surface,
        indicatorColor: _darkColorScheme.primary.withValues(alpha: 0.15),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkColorScheme.surface,
        selectedItemColor: _darkColorScheme.primary,
        unselectedItemColor: _darkColorScheme.onSurface.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkColorScheme.primary,
        foregroundColor: _darkColorScheme.onPrimary,
        elevation: 3,
        shape: const CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: _darkColorScheme.outline.withValues(alpha: 0.3),
        thickness: 1,
      ),
    );
  }
}

// Custom text style extensions for recipe-specific typography
extension RecipeTextStyles on TextTheme {
  TextStyle get recipeTitle => headlineMedium!.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  TextStyle get recipeSectionHeader => titleLarge!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      );

  TextStyle get ingredientItem => bodyLarge!.copyWith(
        height: 1.8,
      );

  TextStyle get ingredientQuantity => bodyLarge!.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.8,
      );

  TextStyle get instructionStep => bodyLarge!.copyWith(
        height: 1.7,
        fontSize: 15,
      );

  TextStyle get instructionStepNumber => titleMedium!.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 18,
      );

  TextStyle get cookingTimer => displaySmall!.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      );

  TextStyle get allergenBadge => labelSmall!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      );
}
