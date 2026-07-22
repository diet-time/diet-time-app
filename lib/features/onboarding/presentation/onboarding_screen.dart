import 'dart:async';
import 'dart:math' as math;

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/l10n/app_localizations.dart';
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
  static const _pageTransitionDuration = Duration(milliseconds: 350);
  List<_OnboardingPageData> _pages(AppLocalizations l10n) => [
    _OnboardingPageData(
      image: 'assets/images/onboarding_1.png',
      title: l10n.onboardingHealthyMealsTitle,
      accent: l10n.onboardingHealthyMealsAccent,
      description: l10n.onboardingHealthyMealsDescription,
    ),
    _OnboardingPageData(
      image: 'assets/images/onboarding_2.png',
      title: l10n.onboardingPlansTitle,
      accent: l10n.onboardingPlansAccent,
      description: l10n.onboardingPlansDescription,
    ),
    _OnboardingPageData(
      image: 'assets/images/onboarding_3.png',
      title: l10n.onboardingFreshTitle,
      accent: l10n.onboardingFreshAccent,
      description: l10n.onboardingFreshDescription,
    ),
    _OnboardingPageData(
      image: 'assets/images/onboarding_4.png',
      title: l10n.onboardingTrackTitle,
      accent: l10n.onboardingTrackAccent,
      description: l10n.onboardingTrackDescription,
    ),
    _OnboardingPageData(
      image: 'assets/images/onboarding_bmi.png',
      title: l10n.onboardingBmiTitle,
      accent: l10n.onboardingBmiAccent,
      description: l10n.onboardingBmiDescription,
    ),
    _OnboardingPageData(
      image: 'assets/images/onboarding_5.png',
      title: l10n.onboardingTogetherTitle,
      accent: l10n.onboardingTogetherAccent,
      description: l10n.onboardingTogetherDescription,
    ),
  ];

  late final PageController _controller;
  late final AnimationController _progressController;
  int _index = 0;
  bool _isNavigating = false;

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

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _progressController.forward(from: 0);
  }

  void _onProgressStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        !mounted ||
        !_controller.hasClients ||
        _isNavigating) {
      return;
    }
    final pageCount = _pages(AppLocalizations.of(context)).length;
    if (_index >= pageCount - 1) return;
    unawaited(_advanceToNextPage());
  }

  Future<void> _advanceToNextPage() async {
    _isNavigating = true;
    try {
      await _controller.nextPage(
        duration: _pageTransitionDuration,
        curve: Curves.easeInOut,
      );
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _handleTap(int pageCount) async {
    if (_isNavigating || !_controller.hasClients) return;
    if (_index < pageCount - 1) {
      await _advanceToNextPage();
      return;
    }
    _isNavigating = true;
    _progressController.stop();
    if (mounted) context.go(AppRoutes.login);
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
    final pages = _pages(AppLocalizations.of(context));
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F0E),
      body: SafeArea(
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _handleTap(pages.length),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _SegmentedProgress(
                    count: pages.length,
                    currentIndex: _index,
                    progress: _progressController.value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: NotificationListener<ScrollNotification>(
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
                  itemCount: pages.length,
                  itemBuilder: (context, index) => GestureDetector(
                    key: ValueKey('onboardingTapArea-$index'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleTap(pages.length),
                    child: _OnboardingPage(
                      data: pages[index],
                      index: index,
                      pageCount: pages.length,
                      isActive: index == _index,
                    ),
                  ),
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
  });

  final _OnboardingPageData data;
  final int index;
  final int pageCount;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isLast = index == pageCount - 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 600;
        final horizontalPadding = constraints.maxWidth < 500 ? 24.0 : 48.0;
        final titleSize = compact ? 23.0 : 28.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            16,
          ),
          child: Column(
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _AnimatedArtwork(
                    image: data.image,
                    pageIndex: index,
                    isActive: isActive,
                    isCommunityArtwork: isLast,
                  ),
                ),
              ),
              SizedBox(height: compact ? 12 : 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: titleSize,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.55,
                      ),
                    ),
                    Text(
                      data.accent,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF62CE55),
                        fontSize: titleSize,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.55,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 330),
                      child: Text(
                        data.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: .66),
                          fontSize: compact ? 13 : 14,
                          height: compact ? 1.35 : 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 20),
                    _PageDots(count: pageCount, current: index),
                  ],
                ),
              ),
            ],
          ),
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
                        const Color(
                          0xFF62CE55,
                        ).withValues(alpha: .04 + (breathe * .025)),
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
                      alignment: AlignmentDirectional.centerStart,
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
