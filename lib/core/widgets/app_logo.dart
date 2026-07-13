import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/app/theme/app_spacing.dart';
import 'package:diet_time/app/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width = 180,
    this.onDarkBackground = false,
    this.color,
  });

  static const assetPath = 'assets/logo/diet_time_logo.png';

  final double width;
  final bool onDarkBackground;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final logoColor =
        color ??
        (onDarkBackground ? AppColors.limeGlow : AppColors.emeraldGreen);
    return Semantics(
      image: true,
      label: 'Diet Time',
      child: Image.asset(
        assetPath,
        width: width,
        fit: BoxFit.contain,
        color: logoColor,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (context, error, stackTrace) =>
            _LogoPlaceholder(width: width, color: logoColor),
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final foreground = color;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: foreground.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        'DIET TIME',
        textAlign: TextAlign.center,
        style: AppTypography.label.copyWith(
          color: foreground,
          letterSpacing: 2.4,
        ),
      ),
    );
  }
}
