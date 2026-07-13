import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/app/theme/app_typography.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light(Locale locale) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emeraldGreen,
      brightness: Brightness.light,
      primary: AppColors.emeraldGreen,
      onPrimary: AppColors.white,
      secondary: AppColors.limeGlow,
      onSecondary: AppColors.darkGreen,
      surface: AppColors.marshmallow,
      onSurface: AppColors.darkGreen,
      error: AppColors.jasper,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.marshmallow,
      fontFamily: AppTypography.familyFor(locale),
      fontFamilyFallback: const ['Arial', 'sans-serif'],
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: AppTypography.display.copyWith(
          color: AppColors.darkGreen,
        ),
        headlineSmall: AppTypography.title.copyWith(color: AppColors.darkGreen),
        bodyLarge: AppTypography.body.copyWith(color: AppColors.darkGreen),
        bodyMedium: AppTypography.body.copyWith(
          fontSize: 14,
          color: AppColors.darkGreen.withValues(alpha: 0.72),
        ),
        labelLarge: AppTypography.label,
        labelSmall: AppTypography.caption,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white.withValues(alpha: 0.72),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: _border(AppColors.transparent),
        enabledBorder: _border(AppColors.darkGreen.withValues(alpha: 0.10)),
        focusedBorder: _border(AppColors.emeraldGreen, width: 1.5),
        errorBorder: _border(AppColors.jasper),
        focusedErrorBorder: _border(AppColors.jasper, width: 1.5),
        hintStyle: AppTypography.body.copyWith(
          color: AppColors.darkGreen.withValues(alpha: 0.48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.emeraldGreen,
          textStyle: AppTypography.label,
        ),
      ),
      dividerColor: AppColors.darkGreen.withValues(alpha: 0.12),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.darkGreen,
        contentTextStyle: TextStyle(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
