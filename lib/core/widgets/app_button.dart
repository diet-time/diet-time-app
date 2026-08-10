import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
    this.backgroundColor,
    super.key,
  });

  static const height = 56.0;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingLabel;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.emeraldGreen,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: (backgroundColor ?? AppColors.emeraldGreen)
              .withValues(alpha: 0.65),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? Row(
                  key: const ValueKey('loading'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.white,
                      ),
                    ),
                    if (loadingLabel case final loadingLabel?) ...[
                      const SizedBox(width: 10),
                      Text(loadingLabel),
                    ],
                  ],
                )
              : Text(label, key: const ValueKey('label')),
        ),
      ),
    );
  }
}
