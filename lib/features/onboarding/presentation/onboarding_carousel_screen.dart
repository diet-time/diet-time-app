import 'dart:async';
import 'dart:ui';

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/authentication/data/mock_authentication_service.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/onboarding/data/journey_state_repository.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingCarouselScreen extends ConsumerStatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  ConsumerState<OnboardingCarouselScreen> createState() =>
      _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState
    extends ConsumerState<OnboardingCarouselScreen>
    with SingleTickerProviderStateMixin {
  static const _pageDuration = Duration(milliseconds: 2800);
  static const _imageAssets = [
    'assets/images/onboarding_1.png',
    'assets/images/onboarding_2.png',
    'assets/images/onboarding_3.png',
    'assets/images/onboarding_4.png',
    'assets/images/onboarding_5.png',
  ];

  final PageController _controller = PageController();
  late final AnimationController _progressController;
  Timer? _timer;
  int _index = 0;
  bool _showFinalChoice = false;
  bool _imagesPrecached = false;

  List<_CarouselContent> _pages(AppLocalizations l10n) => [
    _CarouselContent(
      image: _imageAssets[0],
      title: l10n.onboardingHealthyMealsTitle,
      accent: l10n.onboardingHealthyMealsAccent,
      description: l10n.onboardingHealthyMealsDescription,
    ),
    _CarouselContent(
      image: _imageAssets[1],
      title: l10n.onboardingPlansTitle,
      accent: l10n.onboardingPlansAccent,
      description: l10n.onboardingPlansDescription,
    ),
    _CarouselContent(
      image: _imageAssets[2],
      title: l10n.onboardingFreshTitle,
      accent: l10n.onboardingFreshAccent,
      description: l10n.onboardingFreshDescription,
    ),
    _CarouselContent(
      image: _imageAssets[3],
      title: l10n.onboardingTrackTitle,
      accent: l10n.onboardingTrackAccent,
      description: l10n.onboardingTrackDescription,
    ),
    _CarouselContent(
      image: _imageAssets[4],
      title: l10n.onboardingTogetherTitle,
      accent: l10n.onboardingTogetherAccent,
      description: l10n.onboardingTogetherDescription,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _pageDuration,
    );
    _scheduleAdvance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imagesPrecached) return;
    _imagesPrecached = true;
    for (final asset in _imageAssets) {
      unawaited(precacheImage(AssetImage(asset), context));
    }
  }

  void _scheduleAdvance() {
    _timer?.cancel();
    _progressController.forward(from: 0);
    _timer = Timer(_pageDuration, () {
      if (!mounted || !_controller.hasClients) return;
      final pageCount = _pages(AppLocalizations.of(context)).length;
      if (_index < pageCount - 1) {
        unawaited(
          _controller.nextPage(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          ),
        );
      } else {
        setState(() => _showFinalChoice = true);
      }
    });
  }

  void _advance() {
    final pageCount = _pages(AppLocalizations.of(context)).length;
    if (_index == pageCount - 1) {
      _timer?.cancel();
      setState(() => _showFinalChoice = true);
      return;
    }
    unawaited(
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _openMenu() async {
    await ref.read(journeyStateRepositoryProvider).markOnboardingComplete();
    if (!mounted) return;
    await context.push<void>(AppRoutes.menu);
  }

  Future<void> _startPlan() async {
    await ref.read(journeyStateRepositoryProvider).markOnboardingComplete();
    if (!mounted) return;
    final profile = ref.read(personalizationControllerProvider);
    if (!profile.hasCapturedQuestionnaire) {
      await context.push<void>(AppRoutes.personalization);
      return;
    }
    final authenticated = await ref
        .read(authenticationServiceProvider)
        .isLoggedIn();
    if (!mounted) return;
    if (authenticated) {
      await context.push<void>(AppRoutes.plans);
      return;
    }
    await context.push<void>(
      AppRoutes.phoneLogin,
      extra: const PendingAuthDestination(route: AppRoutes.plans),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages(AppLocalizations.of(context));
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F0E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, _) => Row(
                      children: List.generate(
                        pages.length,
                        (index) => Expanded(
                          child: _CarouselProgressSegment(
                            key: ValueKey('onboardingImageProgress-$index'),
                            progress: index < _index
                                ? 1.0
                                : index == _index
                                ? _progressController.value
                                : 0.0,
                            addEndMargin: index != pages.length - 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: PageView.builder(
                    key: const ValueKey('onboardingCarousel'),
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _index = index;
                        _showFinalChoice = false;
                      });
                      _scheduleAdvance();
                    },
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      return GestureDetector(
                        key: ValueKey('onboardingTapArea-$index'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _advance,
                        child: _CarouselPage(
                          content: page,
                          current: index,
                          count: pages.length,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_showFinalChoice)
            _FinalChoiceSheet(
              onDismiss: () => setState(() => _showFinalChoice = false),
              onMenu: _openMenu,
              onStartPlan: _startPlan,
            ),
        ],
      ),
    );
  }
}

class _CarouselProgressSegment extends StatelessWidget {
  const _CarouselProgressSegment({
    required this.progress,
    required this.addEndMargin,
    super.key,
  });

  final double progress;
  final bool addEndMargin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      margin: EdgeInsetsDirectional.only(end: addEndMargin ? 5 : 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .20),
        borderRadius: BorderRadius.circular(99),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: progress.clamp(0, 1).toDouble(),
        heightFactor: 1,
        child: const ColoredBox(color: Color(0xFF62CE55)),
      ),
    );
  }
}

class _CarouselContent {
  const _CarouselContent({
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

class _CarouselPage extends StatelessWidget {
  const _CarouselPage({
    required this.content,
    required this.current,
    required this.count,
  });

  final _CarouselContent content;
  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 650;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          Expanded(
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    content.image,
                    key: ValueKey(content.image),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFF14231C),
                      child: Center(
                        child: Icon(
                          Icons.restaurant_rounded,
                          color: Color(0xFF62CE55),
                          size: 72,
                        ),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x000D0F0E),
                          Color(0x000D0F0E),
                          Color(0xFF0D0F0E),
                        ],
                        stops: [0, .62, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 16),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: compact ? 23 : 28,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            content.accent,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF62CE55),
              fontSize: compact ? 23 : 28,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: .66),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Semantics(
            label: AppLocalizations.of(
              context,
            ).pageProgress(current + 1, count),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                count,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: index == current ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == current
                        ? const Color(0xFF62CE55)
                        : AppColors.white.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalChoiceSheet extends StatefulWidget {
  const _FinalChoiceSheet({
    required this.onDismiss,
    required this.onMenu,
    required this.onStartPlan,
  });

  final VoidCallback onDismiss;
  final Future<void> Function() onMenu;
  final Future<void> Function() onStartPlan;

  @override
  State<_FinalChoiceSheet> createState() => _FinalChoiceSheetState();
}

class _FinalChoiceSheetState extends State<_FinalChoiceSheet> {
  bool _hasNavigated = false;

  Future<void> _navigate(Future<void> Function() action) async {
    if (_hasNavigated) return;
    setState(() => _hasNavigated = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _hasNavigated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: widget.onDismiss,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3 * value, sigmaY: 3 * value),
              child: ColoredBox(
                color: AppColors.darkGreen.withValues(alpha: .25 * value),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, 260 * (1 - value)),
                child: child,
              ),
            ),
          ),
        ],
      ),
      child: Container(
        key: const ValueKey('onboardingFinalChoicePanel'),
        constraints: const BoxConstraints(maxWidth: 620),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFB),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGreen.withValues(alpha: .18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkGreen.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide = constraints.maxWidth >= 300;
                final buttonWidth = sideBySide
                    ? (constraints.maxWidth - 10) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      height: AppButton.height,
                      child: OutlinedButton(
                        key: const ValueKey('onboardingMenuChoice'),
                        onPressed: _hasNavigated
                            ? null
                            : () => unawaited(_navigate(widget.onMenu)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.emeraldGreen,
                          side: const BorderSide(color: AppColors.emeraldGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        child: Text(l10n.onboardingMenu),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: AppButton(
                        key: const ValueKey('onboardingPlanChoice'),
                        label: l10n.onboardingStartPlan,
                        onPressed: _hasNavigated
                            ? null
                            : () => unawaited(_navigate(widget.onStartPlan)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
