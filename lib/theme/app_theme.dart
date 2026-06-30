import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium Material 3 theme — dark first, with a polished light variant.
class AppTheme {
  AppTheme._();

  // Core palette.
  static const Color accent = Color(0xFF7C5CFC); // violet (CRED-like)
  static const Color accentAlt = Color(0xFF00E0B8); // teal pop

  static const Color darkBg = Color(0xFF0D0F14);
  static const Color darkSurface = Color(0xFF161A23);
  static const Color darkCard = Color(0xFF1C212C);
  static const Color darkElevated = Color(0xFF232936);

  static const Color lightBg = Color(0xFFF4F5F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  static const double radius = 24;

  static SystemUiOverlayStyle overlay(bool dark) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: dark ? darkBg : lightBg,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      secondary: accentAlt,
      surface: darkSurface,
    );
    return _base(scheme, darkBg, darkCard, Brightness.dark);
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    ).copyWith(
      primary: accent,
      secondary: const Color(0xFF00B89C),
      surface: lightSurface,
    );
    return _base(scheme, lightBg, lightCard, Brightness.light);
  }

  static ThemeData _base(
    ColorScheme scheme,
    Color bg,
    Color card,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',
      splashFactory: InkSparkle.splashFactory,
    );

    final onBg = isDark ? Colors.white : const Color(0xFF14161C);
    final muted = isDark ? Colors.white70 : const Color(0xFF5B5F6B);

    return base.copyWith(
      cardColor: card,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlay(isDark),
        titleTextStyle: TextStyle(
          color: onBg,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: onBg),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: onBg,
        displayColor: onBg,
      ).copyWith(
        titleLarge: TextStyle(
          color: onBg,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        bodyMedium: TextStyle(color: muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkElevated : const Color(0xFFEDEEF4),
        hintStyle: TextStyle(color: muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isDark ? darkElevated : const Color(0xFFEDEEF4),
        selectedColor: scheme.primary,
        labelStyle: TextStyle(color: onBg, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white10 : Colors.black12,
        thickness: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? darkSurface : lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkElevated : const Color(0xFF2A2E3A),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
