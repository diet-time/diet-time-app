import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/app/theme/app_spacing.dart';
import 'package:diet_time/core/widgets/app_logo.dart';
import 'package:diet_time/features/language/presentation/language_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OtpFlowHeader extends ConsumerWidget {
  const OtpFlowHeader({required this.onBack, super.key});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageControllerProvider);
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        if (onBack != null)
          IconButton.filledTonal(
            key: const ValueKey('otpFlowBack'),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          )
        else
          const SizedBox(width: 48),
        const Spacer(),
        PopupMenuButton<String>(
          key: const ValueKey('otpLanguageSelector'),
          tooltip: l10n.languageLabel,
          initialValue: locale.languageCode,
          onSelected: (value) => ref
              .read(languageControllerProvider.notifier)
              .selectLanguage(value),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'en', child: Text(l10n.english)),
            PopupMenuItem(value: 'ar', child: Text(l10n.arabic)),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.darkGreen.withValues(alpha: .08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.translate_rounded,
                  size: 18,
                  color: AppColors.emeraldGreen,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  locale.languageCode == 'ar' ? l10n.arabic : l10n.english,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OtpBrandMark extends StatelessWidget {
  const OtpBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.teaGreen),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldGreen.withValues(alpha: .09),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Center(child: AppLogo(width: 76)),
    );
  }
}

class OtpFlowButton extends StatelessWidget {
  const OtpFlowButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emeraldGreen,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.darkGreen.withValues(alpha: .25),
          disabledForegroundColor: AppColors.white.withValues(alpha: .86),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? const SizedBox.square(
                  key: ValueKey('otpButtonLoading'),
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.white,
                  ),
                )
              : Row(
                  key: const ValueKey('otpButtonLabel'),
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 22),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 22),
                  ],
                ),
        ),
      ),
    );
  }
}
