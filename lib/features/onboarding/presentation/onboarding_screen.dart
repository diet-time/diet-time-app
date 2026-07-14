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

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
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
      image: 'assets/images/onboarding_bmi.png',
      title: 'Know Your BMI,',
      accent: 'Build a Better Plan',
      description:
          'Calculate your BMI and get a plan shaped around your body and goals.',
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
  late final AnimationController _progressController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: _pageDuration,
    )..addStatusListener(_onProgressStatusChanged);
    _progressController.forward();
  }

  void _onProgressStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        _index == _pages.length - 1 ||
        !mounted ||
        !_controller.hasClients) {
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _progressController.forward(from: 0);
  }

  void _finish(String route) {
    _progressController.stop();
    context.go(route);
  }

  @override
  void dispose() {
    _progressController
      ..removeStatusListener(_onProgressStatusChanged)
      ..dispose();
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
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null) {
                  _progressController.stop();
                } else if (notification is ScrollEndNotification &&
                    !_progressController.isCompleted) {
                  _progressController.forward();
                }
                return false;
              },
              child: PageView.builder(
                controller: _controller,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) => _OnboardingPage(
                  data: _pages[index],
                  index: index,
                  pageCount: _pages.length,
                  isActive: index == _index,
                  onMenu: () => _finish(AppRoutes.landing),
                  onStart: () => _finish(AppRoutes.plans),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) => _SegmentedProgress(
                  count: _pages.length,
                  currentIndex: _index,
                  progress: _progressController.value,
                ),
              ),
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
    required this.isActive,
    required this.onMenu,
    required this.onStart,
  });

  final _OnboardingPageData data;
  final int index;
  final int pageCount;
  final bool isActive;
  final VoidCallback onMenu;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isLast = index == pageCount - 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final artworkHeight = constraints.maxHeight * (isLast ? .60 : .66);
        return Column(
          children: [
            SizedBox(
              height: artworkHeight,
              width: double.infinity,
              child: _AnimatedArtwork(
                image: data.image,
                pageIndex: index,
                isActive: isActive,
                isCommunityArtwork: isLast,
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
                    if (isLast)
                      const Spacer()
                    else
                      const SizedBox(height: 28),
                    if (isLast)
                      _FinalActions(
                        isActive: isActive,
                        onMenu: onMenu,
                        onStart: onStart,
                      )
                    else
                      _PageDots(count: pageCount, current: index),
                    if (!isLast) const Spacer(),
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
  const _AnimatedArtwork({
    required this.image,
    required this.pageIndex,
    required this.isActive,
    required this.isCommunityArtwork,
  });

  final String image;
  final int pageIndex;
  final bool isActive;
  final bool isCommunityArtwork;

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
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _AnimatedArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if ((_reducedMotion ?? false) || !widget.isActive) {
      _controller.stop();
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
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final phase = _controller.value * math.pi * 2;
          final drift = math.sin(phase);
          final breathe = (math.cos(phase) + 1) / 2;
          final direction = widget.pageIndex.isEven ? 1.0 : -1.0;
          final isCommunityArtwork = widget.isCommunityArtwork;
          final isBmiArtwork = widget.pageIndex == 4;
          final usesPortraitFit = isCommunityArtwork || isBmiArtwork;
          var artworkScale = 1.015 + (breathe * .02);
          var artworkAlignment = Alignment.center;
          if (isCommunityArtwork) {
            artworkScale = 1.0;
            artworkAlignment = const Alignment(0, -.20);
          } else if (isBmiArtwork) {
            artworkScale = 1.0 + (breathe * .005);
            artworkAlignment = const Alignment(0, .10);
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(
                  direction * drift * (usesPortraitFit ? 2 : 4),
                  isCommunityArtwork ? 0 : drift * -3,
                ),
                child: Transform.scale(
                  scale: artworkScale,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: usesPortraitFit ? 22 : 0,
                    ),
                    child: Image.asset(
                      widget.image,
                      fit: BoxFit.cover,
                      alignment: artworkAlignment,
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(direction * drift * 24, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(direction * -.35, -.05),
                      radius: .78,
                      colors: [
                        const Color(0xFF62CE55).withValues(
                          alpha: .04 + (breathe * .025),
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
    for (var index = 0; index < 14; index++) {
      final phase = ((index * .71) + (pageIndex * .37)) * math.pi;
      final angle = (progress * math.pi * 2) + phase;
      final xBase = ((index * 83 + pageIndex * 37) % 100) / 100;
      final yBase = ((index * 47 + pageIndex * 61) % 80) / 100;
      final center = Offset(
        (xBase * size.width) + (math.sin(angle) * 4),
        (yBase * size.height) + (math.cos(angle * .83) * 5),
      );
      final pulse = (math.sin(angle) + 1) / 2;
      final radius = .65 + ((index % 3) * .3);
      final isWhite = index % 4 == 0;
      canvas.drawCircle(
        center,
        radius * 4,
        Paint()
          ..color = (isWhite ? AppColors.white : const Color(0xFF62CE55))
              .withValues(alpha: .02 + (pulse * .03)),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = (isWhite ? AppColors.white : const Color(0xFF8BEA78))
              .withValues(alpha: .08 + (pulse * .07)),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.pageIndex != pageIndex;
}

class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({
    required this.count,
    required this.currentIndex,
    required this.progress,
  });

  final int count;
  final int currentIndex;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == count - 1 ? 0 : 5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: index < currentIndex
                        ? const Color(0xFF62CE55)
                        : AppColors.white.withValues(alpha: .20),
                  ),
                  if (index == currentIndex)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0).toDouble(),
                        heightFactor: 1,
                        child: const ColoredBox(color: Color(0xFF62CE55)),
                      ),
                    ),
                ],
              ),
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

class _FinalActions extends StatefulWidget {
  const _FinalActions({
    required this.isActive,
    required this.onMenu,
    required this.onStart,
  });

  final bool isActive;
  final VoidCallback onMenu;
  final VoidCallback onStart;

  @override
  State<_FinalActions> createState() => _FinalActionsState();
}

class _FinalActionsState extends State<_FinalActions> {
  static const _revealDelay = Duration(milliseconds: 1800);
  Timer? _revealTimer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _syncVisibility();
  }

  @override
  void didUpdateWidget(covariant _FinalActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncVisibility();
    }
  }

  void _syncVisibility() {
    _revealTimer?.cancel();
    if (!widget.isActive) {
      _isVisible = false;
      return;
    }
    _revealTimer = Timer(_revealDelay, () {
      if (mounted) setState(() => _isVisible = true);
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _isVisible ? Offset.zero : const Offset(0, 1.35),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _isVisible ? 1 : 0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF151816),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.white.withValues(alpha: .08),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: .34),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: widget.onMenu,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: BorderSide(
                    color: AppColors.white.withValues(alpha: .20),
                  ),
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
                  onPressed: widget.onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF62CE55),
                    foregroundColor: const Color(0xFF10210E),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Start your Plan',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
