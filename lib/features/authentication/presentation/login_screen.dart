import 'package:diet_time/app/localization/locale_controller.dart';
import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/app/theme/app_spacing.dart';
import 'package:diet_time/app/theme/app_typography.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/core/widgets/app_logo.dart';
import 'package:diet_time/core/widgets/app_textfield.dart';
import 'package:diet_time/core/widgets/social_button.dart';
import 'package:diet_time/features/authentication/domain/login_credentials.dart';
import 'package:diet_time/features/authentication/presentation/login_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _contentMaxWidth = 620.0;
  static const _backgroundAsset = 'assets/images/login_meal_background.png';
  static const _wideBackgroundAsset =
      'assets/images/login_meal_background_wide.png';
  static const _wideBreakpoint = 900.0;

  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final succeeded = await ref
        .read(loginControllerProvider.notifier)
        .signIn(
          LoginCredentials(
            identity: _identityController.text.trim(),
            password: _passwordController.text,
          ),
        );
    if (!mounted) return;
    if (succeeded) {
      context.go(AppRoutes.home);
      return;
    }
    final error = ref.read(loginControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error?.toString() ?? 'Unable to sign in')),
    );
  }

  void _showComingSoon() {
    final message = AppLocalizations.of(context).comingSoon;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateIdentity(String? value) {
    final l10n = AppLocalizations.of(context);
    final input = value?.trim() ?? '';
    if (input.isEmpty) return l10n.requiredField;
    final email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    final mobile = RegExp(r'^\+?[0-9\s()-]{7,}$');
    if (!email.hasMatch(input) && !mobile.hasMatch(input)) {
      return l10n.invalidEmailOrMobile;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return l10n.requiredField;
    if (value.length < 8) return l10n.passwordTooShort;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.emeraldGreen,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            void onLocaleChanged(Locale value) {
              ref.read(localeControllerProvider.notifier).setLocale(value);
            }

            if (constraints.maxWidth >= _wideBreakpoint) {
              final panelWidth = (constraints.maxWidth * 0.34).clamp(
                480.0,
                _contentMaxWidth,
              );
              final endPadding = (constraints.maxWidth * 0.06).clamp(
                AppSpacing.xl,
                120.0,
              );
              return Stack(
                fit: StackFit.expand,
                children: [
                  const _LoginBackground(
                    assetPath: _wideBackgroundAsset,
                    isWide: true,
                  ),
                  _HeroContent(
                    locale: locale,
                    onLocaleChanged: onLocaleChanged,
                    isWide: true,
                  ),
                  SafeArea(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          top: AppSpacing.xxxl,
                          end: endPadding,
                          bottom: AppSpacing.lg,
                        ),
                        child: SizedBox(
                          width: panelWidth,
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.only(
                              bottom: bottomInset + AppSpacing.md,
                            ),
                            child: _buildLoginPanel(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            final heroHeight = (constraints.maxHeight * 0.42).clamp(
              280.0,
              390.0,
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                const _LoginBackground(assetPath: _backgroundAsset),
                _HeroContent(locale: locale, onLocaleChanged: onLocaleChanged),
                SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(bottom: bottomInset + AppSpacing.md),
                  child: Column(
                    children: [
                      SizedBox(height: heroHeight),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _contentMaxWidth,
                          ),
                          child: _buildLoginPanel(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loginState = ref.watch(loginControllerProvider);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkGreen.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.welcomeBack,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontSize: 31),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.loginSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _identityController,
                labelText: l10n.emailOrMobile,
                hintText: '',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                  AutofillHints.telephoneNumber,
                ],
                prefixIcon: const Icon(Icons.person_outline_rounded),
                validator: _validateIdentity,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _passwordController,
                labelText: l10n.password,
                hintText: '',
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: _validatePassword,
                onFieldSubmitted: (_) => _submit(),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? l10n.showPassword
                      : l10n.hidePassword,
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _showComingSoon,
                  child: Text(l10n.forgotPassword),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: l10n.signIn,
                isLoading: loginState.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionDivider(label: l10n.orContinueWith),
              const SizedBox(height: AppSpacing.lg),
              SocialButton(
                label: l10n.continueWithApple,
                icon: Icons.apple,
                variant: SocialButtonVariant.dark,
                onPressed: _showComingSoon,
              ),
              const SizedBox(height: AppSpacing.sm),
              SocialButton(
                label: l10n.continueWithGoogle,
                icon: Icons.g_mobiledata_rounded,
                onPressed: _showComingSoon,
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l10n.noAccount),
                  TextButton(
                    onPressed: _showComingSoon,
                    child: Text(l10n.createAccount),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground({required this.assetPath, this.isWide = false});

  final String assetPath;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: isWide ? Alignment.center : Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) =>
              const ColoredBox(color: AppColors.emeraldGreen),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: isWide
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.emeraldGreen.withValues(alpha: 0.08),
                      AppColors.white.withValues(alpha: 0.02),
                      AppColors.emeraldGreen.withValues(alpha: 0.16),
                    ],
                    stops: const [0, 0.50, 1],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.black.withValues(alpha: 0.40),
                      AppColors.emeraldGreen.withValues(alpha: 0.08),
                      AppColors.emeraldGreen.withValues(alpha: 0.32),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
          ),
        ),
      ],
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.locale,
    required this.onLocaleChanged,
    this.isWide = false,
  });

  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          PositionedDirectional(
            top: AppSpacing.xs,
            end: AppSpacing.md,
            child: _LanguageSwitch(locale: locale, onChanged: onLocaleChanged),
          ),
          Align(
            alignment: isWide
                ? const Alignment(-0.55, -0.48)
                : const Alignment(0, -0.72),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLogo(
                  width: isWide ? 150 : 116,
                  color: isWide ? AppColors.emeraldGreen : AppColors.white,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.healthy,
                  style: AppTypography.display.copyWith(
                    color: isWide ? AppColors.emeraldGreen : AppColors.white,
                    fontSize: isWide ? 48 : 38,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.8,
                    shadows: [
                      Shadow(
                        color: AppColors.black.withValues(alpha: 0.32),
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.journeyStartsHere,
                  style: AppTypography.body.copyWith(
                    color: isWide ? AppColors.darkGreen : AppColors.white,
                    fontSize: isWide ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: AppColors.black.withValues(alpha: 0.40),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({required this.locale, required this.onChanged});

  final Locale locale;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Language',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.12),
              blurRadius: 14,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageOption(
                label: 'EN',
                selected: locale.languageCode == 'en',
                onTap: () => onChanged(const Locale('en')),
              ),
              _LanguageOption(
                label: 'ع',
                selected: locale.languageCode == 'ar',
                onTap: () => onChanged(const Locale('ar')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: selected ? AppColors.white : AppColors.darkGreen,
        backgroundColor: selected
            ? AppColors.emeraldGreen
            : AppColors.transparent,
        minimumSize: const Size(42, 42),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      child: Text(label),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.darkGreen.withValues(alpha: 0.48),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
