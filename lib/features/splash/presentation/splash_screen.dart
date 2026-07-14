import 'dart:math' as math;

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_spacing.dart';
import 'package:diet_time/app/theme/app_typography.dart';
import 'package:diet_time/core/widgets/app_logo.dart';
import 'package:diet_time/features/authentication/data/mock_authentication_service.dart';
import 'package:diet_time/features/onboarding/presentation/onboarding_screen.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _visualDuration = Duration(milliseconds: 5250);
  static const _reducedMotionDuration = Duration(milliseconds: 450);
  static const _logoWidth = 218.0;
  static const _ringSize = 304.0;

  late final AnimationController _controller;
  late final Animation<double> _backgroundReveal;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoEntranceScale;
  late final Animation<double> _logoBreath;
  late final Animation<double> _logoLift;
  late final Animation<double> _clockProgress;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _taglineLift;
  late final Animation<double> _progressReveal;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _visualDuration);
    _backgroundReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.12, curve: Curves.easeOut),
    );
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.07, 0.24, curve: Curves.easeOutCubic),
    );
    _logoEntranceScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.07, 0.30, curve: Curves.elasticOut),
      ),
    );
    _logoBreath = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 35),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.025,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.025,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 40,
      ),
    ]).animate(_controller);
    _logoLift = Tween<double>(begin: 18, end: -10).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.07, 0.33, curve: Curves.easeOutCubic),
      ),
    );
    _clockProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.13, 0.48, curve: Curves.easeInOutCubic),
    );
    _taglineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.58, curve: Curves.easeOut),
    );
    _taglineLift = Tween<double>(begin: 14, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.60, curve: Curves.easeOutCubic),
      ),
    );
    _progressReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.57, 0.67, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
    _finish(reducedMotion);
  }

  Future<void> _finish(bool reducedMotion) async {
    final authCheck = ref.read(authenticationServiceProvider).isLoggedIn();
    final onboardingCheck = ref.read(onboardingSeenProvider.future);
    await Future<void>.delayed(
      reducedMotion ? _reducedMotionDuration : _visualDuration,
    );
    final isLoggedIn = await authCheck;
    final hasSeenOnboarding = await onboardingCheck;
    if (!mounted) return;
    context.go(
      isLoggedIn
          ? AppRoutes.home
          : hasSeenOnboarding
          ? AppRoutes.landing
          : AppRoutes.onboarding,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emeraldGreen,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _AmbientBackground(
                reveal: _backgroundReveal.value,
                progress: _controller.value,
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: _ringSize,
                        height: _ringSize,
                        child: CustomPaint(
                          painter: _ClockStrokePainter(
                            progress: _clockProgress.value,
                            activity: _controller.value,
                            opacity: _logoOpacity.value,
                          ),
                          child: Center(
                            child: Transform.translate(
                              offset: Offset(0, _logoLift.value),
                              child: Transform.scale(
                                scale:
                                    _logoEntranceScale.value *
                                    _logoBreath.value,
                                child: Opacity(
                                  opacity: _logoOpacity.value,
                                  child: _LogoGlow(
                                    intensity: _logoBreath.value,
                                    child: const AppLogo(
                                      width: _logoWidth,
                                      onDarkBackground: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Transform.translate(
                        offset: Offset(0, _taglineLift.value),
                        child: Opacity(
                          opacity: _taglineOpacity.value,
                          child: Text(
                            AppLocalizations.of(context).tagline,
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.35,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Opacity(
                        opacity: _progressReveal.value,
                        child: _ProgressPulse(progress: _controller.value),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.reveal, required this.progress});

  final double reveal;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final drift = Curves.easeInOutSine.transform(progress);
    return Opacity(
      opacity: reveal,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              top: -210 + (drift * 34),
              right: -190 + (drift * 22),
              child: const _SoftOrb(
                size: 480,
                color: AppColors.limeGlow,
                opacity: 0.13,
              ),
            ),
            Positioned(
              bottom: -230 + (drift * 26),
              left: -200 + (drift * 34),
              child: const _SoftOrb(
                size: 510,
                color: AppColors.teaGreen,
                opacity: 0.10,
              ),
            ),
            Center(
              child: _SoftOrb(
                size: 410,
                color: AppColors.limeGlow,
                opacity: 0.045 + (0.015 * math.sin(progress * math.pi * 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.45),
              AppColors.transparent,
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
      ),
    );
  }
}

class _LogoGlow extends StatelessWidget {
  const _LogoGlow({required this.intensity, required this.child});

  final double intensity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.limeGlow.withValues(
              alpha: 0.10 + ((intensity - 1) * 1.6),
            ),
            blurRadius: 42,
            spreadRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ProgressPulse extends StatelessWidget {
  const _ProgressPulse({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final wave =
              (math.sin((progress * 8 - (index * 0.55)) * math.pi) + 1) / 2;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Transform.scale(
              scale: 0.78 + (wave * 0.28),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.limeGlow.withValues(
                    alpha: 0.30 + (wave * 0.55),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ClockStrokePainter extends CustomPainter {
  const _ClockStrokePainter({
    required this.progress,
    required this.activity,
    required this.opacity,
  });

  final double progress;
  final double activity;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(3);
    final basePaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.08 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawOval(rect, basePaint);

    final progressPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.42 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );

    if (progress <= 0) return;
    final angle = (-math.pi / 2) + (math.pi * 2 * activity);
    final center = rect.center;
    final endpoint = Offset(
      center.dx + (math.cos(angle) * rect.width / 2),
      center.dy + (math.sin(angle) * rect.height / 2),
    );
    final orbitPaint = Paint()
      ..color = AppColors.limeGlow.withValues(alpha: 0.78 * opacity);
    canvas.drawCircle(endpoint, 3.5, orbitPaint);
    canvas.drawCircle(
      endpoint,
      8,
      orbitPaint..color = AppColors.limeGlow.withValues(alpha: 0.10 * opacity),
    );
  }

  @override
  bool shouldRepaint(_ClockStrokePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.activity != activity ||
      oldDelegate.opacity != opacity;
}
