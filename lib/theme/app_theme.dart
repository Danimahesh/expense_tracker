import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cyberpunk-inspired "financial terminal" palette.
///
/// Dark-first, elegant and minimal — a thin cyan accent on near-black
/// surfaces, not a neon concept.
class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF09090B);
  static const Color surface = Color(0xFF12121A);
  static const Color surface2 = Color(0xFF1A1A24);
  static const Color cyan = Color(0xFF00F5FF);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF00FFA3);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF3D6E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0B5);
  static const Color divider = Color(0x14FFFFFF); // white @ 8%

  /// Limited chart palette (cyan / purple / gray + status colours).
  static const List<Color> chart = [
    cyan,
    purple,
    Color(0xFF5A5A6E),
    success,
    warning,
    danger,
  ];
}

class AppTheme {
  AppTheme._();

  /// Back-compat alias used by shared widgets.
  static const Color accent = AppColors.cyan;

  /// Standard corner radius for cards and inputs.
  static const double radius = 16;

  static const String headingFont = 'Orbitron';
  static const String bodyFont = 'Inter';

  /// Orbitron heading style (major headings only).
  static TextStyle heading({
    double size = 18,
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.w700,
    double spacing = 0.5,
  }) {
    return TextStyle(
      fontFamily: headingFont,
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
    );
  }

  static SystemUiOverlayStyle overlay(bool dark) {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    );
  }

  // The app is dark-first; both entry points return the same terminal theme
  // so the experience stays consistent and on-brand.
  static ThemeData light() => _build();
  static ThemeData dark() => _build();

  static ThemeData _build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.cyan,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.cyan,
      onPrimary: AppColors.bg,
      secondary: AppColors.purple,
      onSecondary: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.surface2,
      error: AppColors.danger,
      onError: AppColors.textPrimary,
      outlineVariant: AppColors.divider,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: bodyFont,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlay(true),
        titleTextStyle: heading(size: 20, spacing: 1),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
        fontFamily: bodyFont,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: AppColors.bg,
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, fontFamily: bodyFont),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cyan,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.cyan, width: 1.2),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, fontFamily: bodyFont),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.cyan),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.cyan,
        foregroundColor: AppColors.bg,
        elevation: 0,
        highlightElevation: 0,
        sizeConstraints: BoxConstraints.tightFor(width: 52, height: 52),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: AppColors.cyan.withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: bodyFont,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.cyan
                : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface2,
        selectedColor: AppColors.cyan.withValues(alpha: 0.18),
        side: const BorderSide(color: AppColors.divider),
        labelStyle: const TextStyle(
            color: AppColors.textPrimary, fontFamily: bodyFont),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface2,
        contentTextStyle: const TextStyle(
            color: AppColors.textPrimary, fontFamily: bodyFont),
        actionTextColor: AppColors.cyan,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 4),
        iconColor: AppColors.cyan,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
