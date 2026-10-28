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
      filledButtonTheme: FilledButtonThemeData(
        style: _matteButtonStyle(
          elevation: 1,
          borderColor: AppColors.transparent,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _matteButtonStyle(
          elevation: 1,
          borderColor: AppColors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _matteButtonStyle(
          elevation: 0,
          borderColor: AppColors.emeraldGreen.withValues(alpha: .32),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style:
            _matteButtonStyle(
              elevation: 0,
              borderColor: AppColors.transparent,
            ).copyWith(
              foregroundColor: const WidgetStatePropertyAll(
                AppColors.emeraldGreen,
              ),
              textStyle: WidgetStatePropertyAll(AppTypography.label),
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

  static ButtonStyle _matteButtonStyle({
    required double elevation,
    required Color borderColor,
  }) {
    return ButtonStyle(
      animationDuration: const Duration(milliseconds: 180),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return 0;
        if (states.contains(WidgetState.pressed)) {
          return 0;
        }
        if (states.contains(WidgetState.hovered) && elevation > 0) {
          return elevation + 1;
        }
        return elevation;
      }),
      shadowColor: WidgetStatePropertyAll(
        AppColors.darkGreen.withValues(alpha: .12),
      ),
      surfaceTintColor: const WidgetStatePropertyAll(AppColors.transparent),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return AppColors.darkGreen.withValues(alpha: .10);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return AppColors.teaGreen.withValues(alpha: .08);
        }
        return AppColors.transparent;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        return BorderSide(
          color: states.contains(WidgetState.disabled)
              ? borderColor.withValues(alpha: borderColor.a * .35)
              : borderColor,
        );
      }),
    );
  }
}
