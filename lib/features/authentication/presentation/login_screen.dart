import 'dart:math' as math;
import 'dart:ui';

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
  const LoginScreen({this.showLoginInitially = false, super.key});

  final bool showLoginInitially;

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
  late bool _showLoginPanel;

  @override
  void initState() {
    super.initState();
    _showLoginPanel = widget.showLoginInitially;
  }

  void _openLoginPanel() {
    context.push(AppRoutes.login);
  }

  void _closeLoginPanel() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (context.canPop()) {
      context.pop();
      return;
    }
    setState(() => _showLoginPanel = false);
  }

  void _openPlans() => context.push(AppRoutes.plans);

  void _openRegister() => context.push(AppRoutes.register);

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
                  _LoginBackground(
                    assetPath: _wideBackgroundAsset,
                    isWide: true,
                    isLanding: !_showLoginPanel,
                  ),
                  if (!_showLoginPanel) const _LandingAtmosphere(),
                  _HeroContent(
                    locale: locale,
                    onLocaleChanged: onLocaleChanged,
                    isWide: true,
                    isLanding: !_showLoginPanel,
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            reverseDuration: const Duration(milliseconds: 250),
                            transitionBuilder: _panelTransition,
                            child: SingleChildScrollView(
                              key: ValueKey(_showLoginPanel),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: EdgeInsets.only(
                                bottom: bottomInset + AppSpacing.md,
                              ),
                              child: _showLoginPanel
                                  ? _buildLoginPanel(context)
                                  : _buildLandingPanel(context),
                            ),
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
                _LoginBackground(
                  assetPath: _backgroundAsset,
                  isLanding: !_showLoginPanel,
                ),
                if (!_showLoginPanel) const _LandingAtmosphere(),
                _HeroContent(
                  locale: locale,
                  onLocaleChanged: onLocaleChanged,
                  isLanding: !_showLoginPanel,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  reverseDuration: const Duration(milliseconds: 250),
                  transitionBuilder: _panelTransition,
                  child: SingleChildScrollView(
                    key: ValueKey(_showLoginPanel),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom: bottomInset + AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: _showLoginPanel
                              ? heroHeight
                              : (constraints.maxHeight - 292).clamp(
                                  310.0,
                                  560.0,
                                ),
                        ),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _contentMaxWidth,
                            ),
                            child: _showLoginPanel
                                ? _buildLoginPanel(context)
                                : _buildLandingPanel(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _panelTransition(Widget child, Animation<double> animation) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }

  Widget _buildLandingPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.darkGreen.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.42),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.24),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.landingTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.white,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.landingSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.82),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _PlansButton(label: l10n.viewPlans, onPressed: _openPlans),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _LandingOutlineButton(
                        label: l10n.login,
                        onPressed: _openLoginPanel,
                        muted: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _LandingOutlineButton(
                        label: l10n.register,
                        onPressed: _openRegister,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.darkGreen.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: _closeLoginPanel,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                ],
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
  const _LoginBackground({
    required this.assetPath,
    this.isWide = false,
    this.isLanding = false,
  });

  final String assetPath;
  final bool isWide;
  final bool isLanding;

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
            gradient: isLanding
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.emeraldGreen.withValues(alpha: 0.70),
                      AppColors.emeraldGreen.withValues(alpha: 0.16),
                      AppColors.darkGreen.withValues(alpha: 0.68),
                    ],
                    stops: const [0, 0.52, 1],
                  )
                : isWide
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

class _LandingAtmosphere extends StatefulWidget {
  const _LandingAtmosphere();

  @override
  State<_LandingAtmosphere> createState() => _LandingAtmosphereState();
}

class _LandingAtmosphereState extends State<_LandingAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.18),
                radius: 0.72,
                colors: [Color(0x26CEF17B), Color(0x0000674E)],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => CustomPaint(
              painter: _ParticlePainter(progress: _controller.value),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({required this.progress});

  static const _particles = <Offset>[
    Offset(0.08, 0.23),
    Offset(0.17, 0.55),
    Offset(0.88, 0.20),
    Offset(0.79, 0.47),
    Offset(0.92, 0.68),
    Offset(0.11, 0.76),
  ];

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < _particles.length; index++) {
      final particle = _particles[index];
      final phase = (progress + (index * 0.17)) * math.pi * 2;
      final center = Offset(
        particle.dx * size.width + math.sin(phase) * 5,
        particle.dy * size.height + math.cos(phase * 0.72) * 9,
      );
      final opacity = 0.06 + ((math.sin(phase) + 1) * 0.03);
      final radius = 1.8 + (index % 3) * 0.8;
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = AppColors.limeGlow.withValues(alpha: opacity),
      );
      canvas.drawCircle(
        center,
        radius * 3.2,
        Paint()..color = AppColors.limeGlow.withValues(alpha: opacity * 0.16),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.locale,
    required this.onLocaleChanged,
    this.isWide = false,
    this.isLanding = false,
  });

  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final bool isWide;
  final bool isLanding;

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
                : Alignment(0, isLanding ? -0.35 : -0.72),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLogo(
                  width: isLanding ? 84 : (isWide ? 150 : 116),
                  color: isLanding
                      ? AppColors.darkGreen
                      : (isWide ? AppColors.emeraldGreen : AppColors.white),
                ),
                SizedBox(height: isLanding ? AppSpacing.xxs : AppSpacing.xs),
                Text(
                  l10n.healthy,
                  style: AppTypography.display.copyWith(
                    color: isLanding
                        ? AppColors.darkGreen
                        : (isWide ? AppColors.emeraldGreen : AppColors.white),
                    fontSize: isLanding ? 40 : (isWide ? 48 : 38),
                    fontStyle: isLanding ? FontStyle.normal : FontStyle.italic,
                    fontWeight: isLanding ? FontWeight.w700 : FontWeight.w500,
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
                    color: isLanding
                        ? AppColors.darkGreen
                        : (isWide ? AppColors.darkGreen : AppColors.white),
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
          color: AppColors.white.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.30)),
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
        backgroundColor: selected ? AppColors.darkGreen : AppColors.transparent,
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

class _PlansButton extends StatefulWidget {
  const _PlansButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_PlansButton> createState() => _PlansButtonState();
}

class _PlansButtonState extends State<_PlansButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = reduceMotion ? 0.0 : _controller.value;
          final wave = math.sin(progress * math.pi * 2);
          final glow = 0.32 + ((wave + 1) * 0.11);
          final shimmerX = (constraints.maxWidth + 64) * progress - 64;
          return Transform.translate(
            offset: Offset(0, reduceMotion ? 0 : -1 - wave),
            child: Transform.scale(
              scale: reduceMotion ? 1 : 1 + (wave * 0.008),
              child: SizedBox(
                height: AppButton.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.limeGlow.withValues(alpha: glow),
                        blurRadius: 16 + ((wave + 1) * 3),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      OutlinedButton(
                        onPressed: widget.onPressed,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          backgroundColor: AppColors.emeraldGreen.withValues(
                            alpha: 0.38,
                          ),
                          side: const BorderSide(
                            color: AppColors.teaGreen,
                            width: 1.5,
                          ),
                          textStyle: AppTypography.title.copyWith(fontSize: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        child: Text(widget.label),
                      ),
                      if (!reduceMotion)
                        IgnorePointer(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: Transform.translate(
                              offset: Offset(shimmerX, 0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 54,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.transparent,
                                        AppColors.white.withValues(alpha: 0.22),
                                        AppColors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LandingOutlineButton extends StatelessWidget {
  const _LandingOutlineButton({
    required this.label,
    required this.onPressed,
    this.muted = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppButton.height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white.withValues(alpha: muted ? 0.68 : 1),
          side: BorderSide(
            color: AppColors.white.withValues(alpha: muted ? 0.60 : 0.88),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: Text(label),
      ),
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
