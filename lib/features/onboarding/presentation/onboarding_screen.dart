import 'dart:async';
import 'dart:math' as math;

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageDuration = Duration(milliseconds: 2800);
  static const _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      image: 'assets/images/onboarding_1.png',
      title: 'Healthy Meals,',
      accent: 'Made Simple.',
      description:
          'Delicious, balanced meals delivered daily to support your healthy lifestyle.',
    ),
    _OnboardingPageData(
      image: 'assets/images/onboarding_2.png',
      title: 'Plans That Fit',
      accent: 'You Perfectly',
      description:
          "Tell us your goals, we'll handle the rest with personalised plans just for you.",
    ),
    _OnboardingPageData(
      image: 'assets/images/onboarding_3.png',
      title: 'Fresh. Clean.',
      accent: 'Always.',
      description:
          'We use real ingredients with no artificial colors, preservatives or unhealthy fillers.',
    ),
    _OnboardingPageData(
      image: 'assets/images/onboarding_4.png',
      title: 'Track. Improve.',
      accent: 'Live Better.',
      description:
          'Simple tracking helps you stay consistent and achieve your health goals.',
    ),
    _OnboardingPageData(
      image: 'assets/images/onboarding_5.png',
      title: 'Better Together,',
      accent: 'Stronger Together',
      description:
          'Invite friends, share your journey and achieve more together.',
    ),
  ];

  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _scheduleAdvance();
  }

  void _scheduleAdvance() {
    _timer?.cancel();
    if (_index == _pages.length - 1) return;
    _timer = Timer(_pageDuration, () {
      if (!mounted || !_controller.hasClients) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _scheduleAdvance();
  }

  void _finish(String route) {
    _timer?.cancel();
    context.go(route);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F0E),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) => _OnboardingPage(
                data: _pages[index],
                index: index,
                pageCount: _pages.length,
                onMenu: () => _finish(AppRoutes.landing),
                onStart: () => _finish(AppRoutes.plans),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _SegmentedProgress(currentIndex: _index),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.index,
    required this.pageCount,
    required this.onMenu,
    required this.onStart,
  });

  final _OnboardingPageData data;
  final int index;
  final int pageCount;
  final VoidCallback onMenu;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isLast = index == pageCount - 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final artworkHeight = constraints.maxHeight * (isLast ? .60 : .61);
        return Column(
          children: [
            SizedBox(
              height: artworkHeight,
              width: double.infinity,
              child: _AnimatedArtwork(
                image: data.image,
                pageIndex: index,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
                child: Column(
                  children: [
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.55,
                      ),
                    ),
                    Text(
                      data.accent,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF62CE55),
                        fontSize: 28,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.55,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 330),
                      child: Text(
                        data.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: .66),
                          fontSize: 14,
                          height: 1.55,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isLast)
                      _FinalActions(onMenu: onMenu, onStart: onStart)
                    else
                      _PageDots(count: pageCount, current: index),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedArtwork extends StatefulWidget {
  const _AnimatedArtwork({required this.image, required this.pageIndex});

  final String image;
  final int pageIndex;

  @override
  State<_AnimatedArtwork> createState() => _AnimatedArtworkState();
}

class _AnimatedArtworkState extends State<_AnimatedArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _reducedMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion == reduceMotion) return;
    _reducedMotion = reduceMotion;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = .45;
    } else {
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
    final direction = widget.pageIndex.isEven ? 1.0 : -1.0;
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final phase = _controller.value * math.pi * 2;
          final drift = math.sin(phase);
          final breathe = (math.cos(phase) + 1) / 2;
          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(direction * drift * 4, drift * -3),
                child: Transform.scale(
                  scale: 1.015 + (breathe * .02),
                  child: Image.asset(widget.image, fit: BoxFit.cover),
                ),
              ),
              Transform.translate(
                offset: Offset(direction * (drift * 28), 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(direction * -.35, -.05),
                      radius: .75,
                      colors: [
                        const Color(0xFF62CE55).withValues(
                          alpha: .045 + (breathe * .025),
                        ),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _ParticlePainter(
                    progress: _controller.value,
                    pageIndex: widget.pageIndex,
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x330D0F0E),
                      Color(0x000D0F0E),
                      Color(0xFF0D0F0E),
                    ],
                    stops: [0, .63, 1],
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

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({required this.progress, required this.pageIndex});

  final double progress;
  final int pageIndex;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < 12; index++) {
      final phase = ((index * .71) + (pageIndex * .37)) * math.pi;
      final angle = (progress * math.pi * 2) + phase;
      final xBase = ((index * 83 + pageIndex * 37) % 100) / 100;
      final yBase = ((index * 47 + pageIndex * 61) % 78) / 100;
      final center = Offset(
        (xBase * size.width) + (math.sin(angle) * 4),
        (yBase * size.height) + (math.cos(angle * .83) * 5),
      );
      final pulse = (math.sin(angle) + 1) / 2;
      final radius = .65 + ((index % 3) * .32);
      final glowPaint = Paint()
        ..color = const Color(0xFF62CE55).withValues(
          alpha: .025 + (pulse * .035),
        );
      final particlePaint = Paint()
        ..color = const Color(0xFF8BEA78).withValues(
          alpha: .09 + (pulse * .08),
        );
      canvas.drawCircle(center, radius * 4, glowPaint);
      canvas.drawCircle(center, radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.pageIndex != pageIndex;
}

class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            margin: EdgeInsets.only(right: index == 4 ? 0 : 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: index == currentIndex
                  ? const Color(0xFF62CE55)
                  : AppColors.white.withValues(alpha: .20),
            ),
          ),
        );
      }),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${current + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: index == current ? 9 : 7,
            height: index == current ? 9 : 7,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == current
                  ? const Color(0xFF62CE55)
                  : AppColors.white.withValues(alpha: .22),
            ),
          );
        }),
      ),
    );
  }
}

class _FinalActions extends StatelessWidget {
  const _FinalActions({required this.onMenu, required this.onStart});

  final VoidCallback onMenu;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton(
          onPressed: onMenu,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.white,
            side: BorderSide(color: AppColors.white.withValues(alpha: .20)),
            minimumSize: const Size(74, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: const Text('Menu'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF62CE55),
              foregroundColor: const Color(0xFF10210E),
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Start your Plan',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(width: 14),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.white,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF10210E),
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

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.image,
    required this.title,
    required this.accent,
    required this.description,
  });

  final String image;
  final String title;
  final String accent;
  final String description;
}
