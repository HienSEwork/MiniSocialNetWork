import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const ink = Color(0xFF172033);
  static const cloud = Color(0xFFF7F3FF);
  static const indigo = Color(0xFF5D38F5);
  static const violet = Color(0xFF2D0879);
  static const grape = Color(0xFF43108B);
  static const electric = Color(0xFF7668FF);
  static const porcelain = Color(0xFFF9F8FC);
  static const lavender = Color(0xFF7C62FF);
  static const coral = Color(0xFFFF6B6B);
  static const mint = Color(0xFF22B8A7);
  static const line = Color(0xFFE8E1F7);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.indigo,
      brightness: brightness,
      primary: AppColors.indigo,
      secondary: AppColors.coral,
      surface: isDark ? const Color(0xFF171925) : Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0F111A)
          : AppColors.cloud,
      dividerColor: isDark ? Colors.white12 : AppColors.line,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(height: 1.45),
        bodyMedium: TextStyle(height: 1.4),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : AppColors.ink,
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 6,
        color: isDark ? const Color(0xFF171925) : Colors.white,
        margin: EdgeInsets.zero,
        shadowColor: AppColors.violet.withValues(alpha: .08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white10 : Colors.white.withValues(alpha: .7),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: .06) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.indigo, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 54,
        backgroundColor: isDark
            ? const Color(0xFF1D1F2B)
            : const Color(0xFF8C8C8C).withValues(alpha: .86),
        indicatorColor: Colors.white,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.grape
                : Colors.white.withValues(alpha: .78),
            size: 20,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 10,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.grape
                : Colors.white.withValues(alpha: .78),
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
