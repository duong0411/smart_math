import 'dart:ui';

import 'package:flutter/material.dart';

@immutable
class GlassTheme extends ThemeExtension<GlassTheme> {
  const GlassTheme({
    required this.blurSigma,
    required this.fillOpacity,
    required this.borderOpacity,
    required this.borderRadius,
  });

  final double blurSigma;
  final double fillOpacity;
  final double borderOpacity;
  final double borderRadius;

  static const light = GlassTheme(
    blurSigma: 24,
    fillOpacity: 0.65,
    borderOpacity: 0.35,
    borderRadius: 24,
  );

  static const dark = GlassTheme(
    blurSigma: 24,
    fillOpacity: 0.15,
    borderOpacity: 0.15,
    borderRadius: 24,
  );

  @override
  GlassTheme copyWith({
    double? blurSigma,
    double? fillOpacity,
    double? borderOpacity,
    double? borderRadius,
  }) {
    return GlassTheme(
      blurSigma: blurSigma ?? this.blurSigma,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      borderOpacity: borderOpacity ?? this.borderOpacity,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  GlassTheme lerp(ThemeExtension<GlassTheme>? other, double t) {
    if (other is! GlassTheme) return this;
    return GlassTheme(
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      fillOpacity: lerpDouble(fillOpacity, other.fillOpacity, t)!,
      borderOpacity: lerpDouble(borderOpacity, other.borderOpacity, t)!,
      borderRadius: lerpDouble(borderRadius, other.borderRadius, t)!,
    );
  }
}

abstract final class AppTheme {
  // Template palette: Neon Blue + Cyan
  static const _seed = Color(0xFF2563EB); // Blue
  static const _secondary = Color(0xFF00E5FF); // Cyan

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      secondary: _secondary,
      brightness: Brightness.light,
      surface: const Color(0xFFF8FAFC),
    );
    return _base(scheme, GlassTheme.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      secondary: _secondary,
      brightness: Brightness.dark,
      surface: const Color(0xFF090E17), // Very dark template background
    );
    return _base(scheme, GlassTheme.dark);
  }

  static ThemeData _base(ColorScheme scheme, GlassTheme glass) {
    final textTheme = Typography.material2021(
      platform: TargetPlatform.android,
      colorScheme: scheme,
    ).black.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [glass],
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(glass.borderRadius),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.45),
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          // Do NOT use Size.fromHeight — that sets width to infinity and
          // breaks AlertDialog actions (Cancel above a full-width primary).
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface.withValues(alpha: 0.97),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
      ),
    );
  }
}
