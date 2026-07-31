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
        style: _metallicButtonStyle(
          elevation: 6,
          borderColor: AppColors.white.withValues(alpha: .24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _metallicButtonStyle(
          elevation: 6,
          borderColor: AppColors.white.withValues(alpha: .22),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _metallicButtonStyle(
          elevation: 2,
          borderColor: AppColors.emeraldGreen.withValues(alpha: .46),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style:
            _metallicButtonStyle(
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

  static ButtonStyle _metallicButtonStyle({
    required double elevation,
    required Color borderColor,
  }) {
    return ButtonStyle(
      animationDuration: const Duration(milliseconds: 180),
      backgroundBuilder: _metallicLayer,
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return 0;
        if (states.contains(WidgetState.pressed)) {
          return (elevation - 2).clamp(0, elevation);
        }
        if (states.contains(WidgetState.hovered)) return elevation + 2;
        return elevation;
      }),
      shadowColor: WidgetStatePropertyAll(
        AppColors.darkGreen.withValues(alpha: .30),
      ),
      surfaceTintColor: WidgetStatePropertyAll(
        AppColors.white.withValues(alpha: .16),
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return AppColors.white.withValues(alpha: .15);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return AppColors.limeGlow.withValues(alpha: .10);
        }
        return AppColors.transparent;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        final opacity = states.contains(WidgetState.disabled) ? .35 : 1.0;
        return BorderSide(color: borderColor.withValues(alpha: opacity));
      }),
    );
  }

  static Widget _metallicLayer(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
    final pressed = states.contains(WidgetState.pressed);
    final disabled = states.contains(WidgetState.disabled);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, .22, .48, .72, 1],
          colors: disabled
              ? const [
                  Color(0x12FFFFFF),
                  Color(0x06FFFFFF),
                  Color(0x00000000),
                  Color(0x06000000),
                  Color(0x0AFFFFFF),
                ]
              : [
                  AppColors.white.withValues(alpha: pressed ? .10 : .24),
                  AppColors.white.withValues(alpha: pressed ? .04 : .09),
                  AppColors.transparent,
                  AppColors.black.withValues(alpha: pressed ? .09 : .05),
                  AppColors.white.withValues(alpha: pressed ? .05 : .13),
                ],
        ),
      ),
      child: child,
    );
  }
}
