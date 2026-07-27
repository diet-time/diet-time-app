import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/app/theme/app_spacing.dart';
import 'package:diet_time/core/widgets/app_logo.dart';
import 'package:diet_time/features/language/presentation/language_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthFlowBackground extends StatelessWidget {
  const AuthFlowBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFFAF8F1)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 72,
            right: -110,
            child: _AuthGlow(size: 310, color: Color(0x1AFFF1A7)),
          ),
          const Positioned(
            top: 260,
            left: -130,
            child: _AuthGlow(size: 340, color: Color(0x143CA78D)),
          ),
          const Positioned(
            bottom: -120,
            right: -90,
            child: _AuthGlow(size: 310, color: Color(0x123CA78D)),
          ),
          child,
        ],
      ),
    );
  }
}

class _AuthGlow extends StatelessWidget {
  const _AuthGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, AppColors.transparent]),
          ),
        ),
      ),
    );
  }
}

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
          SizedBox.square(
            dimension: 52,
            child: IconButton.filled(
              key: const ValueKey('otpFlowBack'),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFD8EEE6),
                foregroundColor: AppColors.darkGreen,
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 23),
            ),
          )
        else
          const SizedBox(width: 52),
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
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.darkGreen.withValues(alpha: .08),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkGreen.withValues(alpha: .04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
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
    final compact = MediaQuery.sizeOf(context).height < 700;
    final size = compact ? 112.0 : 132.0;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(compact ? 16 : 18),
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
      child: Center(child: AppLogo(width: compact ? 80 : 94)),
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
    final disabled = onPressed == null && !isLoading;
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: disabled
                ? const [Color(0xFFA4CDBF), Color(0xFF87BFAF)]
                : const [Color(0xFF55A696), Color(0xFF2D837F)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF2D837F).withValues(alpha: .18),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
        ),
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.transparent,
            disabledBackgroundColor: AppColors.transparent,
            foregroundColor: AppColors.white,
            disabledForegroundColor: AppColors.white.withValues(alpha: .58),
            shadowColor: AppColors.transparent,
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
                      const SizedBox(width: 30),
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
                      const _ButtonSparkleArrow(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ButtonSparkleArrow extends StatelessWidget {
  const _ButtonSparkleArrow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 30,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 0,
            child: Icon(Icons.arrow_forward_rounded, size: 22),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Icon(Icons.auto_awesome, size: 13),
          ),
        ],
      ),
    );
  }
}
