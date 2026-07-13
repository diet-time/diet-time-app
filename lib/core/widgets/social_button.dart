import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/app/theme/app_spacing.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

enum SocialButtonVariant { light, dark }

class SocialButton extends StatelessWidget {
  const SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.variant = SocialButtonVariant.light,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final SocialButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final isDark = variant == SocialButtonVariant.dark;
    return SizedBox(
      width: double.infinity,
      height: AppButton.height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 21),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.white : AppColors.darkGreen,
          backgroundColor: isDark ? AppColors.black : AppColors.white,
          side: BorderSide(
            color: isDark
                ? AppColors.black
                : AppColors.darkGreen.withValues(alpha: 0.16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),
    );
  }
}
