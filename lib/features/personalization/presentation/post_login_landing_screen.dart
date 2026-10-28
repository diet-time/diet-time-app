import 'dart:async';
import 'dart:math' as math;

import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/core/widgets/app_logo.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PostLoginLandingScreen extends StatefulWidget {
  const PostLoginLandingScreen({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  State<PostLoginLandingScreen> createState() => _PostLoginLandingScreenState();
}

class _PostLoginLandingScreenState extends State<PostLoginLandingScreen>
    with TickerProviderStateMixin {
  static const _assets = [
    'assets/images/login_meal_background.png',
    'assets/images/onboarding_1.png',
    'assets/images/onboarding_3.png',
  ];

  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  Timer? _successTimer;
  bool _assetsPrecached = false;
  bool _showSuccess = true;
  bool _isNavigating = false;
  bool? _reducedMotion;

  @override
  void initState() {
    super.initState();
    _successTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSuccess = false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_assetsPrecached) {
      _assetsPrecached = true;
      for (final asset in _assets) {
        unawaited(precacheImage(AssetImage(asset), context));
      }
    }
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion == reducedMotion) return;
    _reducedMotion = reducedMotion;
    if (reducedMotion) {
      _entranceController.value = 1;
      _floatController.stop();
    } else {
      _entranceController.forward(from: 0);
      _floatController.repeat();
    }
  }

  void _continue() {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    widget.onContinue();
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 700;
    final horizontalPadding = size.width < 360 ? 16.0 : 22.0;
    final compositionHeight = compact
        ? 210.0
        : (size.width * .70).clamp(230.0, 310.0);
    final titleSize = compact ? 34.0 : (size.width * .105).clamp(38.0, 46.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                const Positioned.fill(child: _LandingBackground()),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact ? 12 : 18,
                    horizontalPadding,
                    math.max(18, MediaQuery.paddingOf(context).bottom + 12),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (compact ? 30 : 36),
                      maxWidth: 620,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            _EntranceTransition(
                              controller: _entranceController,
                              interval: const Interval(0, .24),
                              offset: const Offset(0, -.12),
                              child: _WelcomePill(
                                label: l10n.postLoginWelcomeLabel,
                              ),
                            ),
                            SizedBox(height: compact ? 12 : 16),
                            _EntranceTransition(
                              controller: _entranceController,
                              interval: const Interval(.10, .42),
                              offset: const Offset(0, .12),
                              child: Semantics(
                                header: true,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${l10n.postLoginTitleLead}\n',
                                      ),
                                      TextSpan(
                                        text: l10n.postLoginTitleAccent,
                                        style: const TextStyle(
                                          color: AppColors.emeraldGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.darkGreen,
                                    fontSize: titleSize,
                                    height: 1.04,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 8 : 12),
                        SizedBox(
                          height: compositionHeight,
                          width: double.infinity,
                          child: _FoodComposition(
                            entranceController: _entranceController,
                            floatController: _floatController,
                            reducedMotion: _reducedMotion ?? false,
                            balancedLabel: l10n.postLoginMealBalanced,
                            flexibleLabel: l10n.postLoginMealFlexible,
                            goalsLabel: l10n.postLoginMealGoals,
                          ),
                        ),
                        SizedBox(height: compact ? 10 : 14),
                        _EntranceTransition(
                          controller: _entranceController,
                          interval: const Interval(.62, .84),
                          offset: const Offset(0, .12),
                          child: Column(
                            children: [
                              Text(
                                l10n.postLoginSupporting,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.darkGreen,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                l10n.postLoginSecondary,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.darkGreen.withValues(
                                        alpha: .64,
                                      ),
                                      height: 1.35,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: compact ? 16 : 22),
                        _EntranceTransition(
                          controller: _entranceController,
                          interval: const Interval(.76, 1),
                          offset: const Offset(0, .18),
                          child: _PersonalizeButton(
                            label: l10n.postLoginCta,
                            onPressed: _isNavigating ? null : _continue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 6,
                  start: horizontalPadding,
                  end: horizontalPadding,
                  child: IgnorePointer(
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      offset: _showSuccess
                          ? Offset.zero
                          : const Offset(0, -1.2),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: _showSuccess ? 1 : 0,
                        child: _SuccessCard(label: l10n.postLoginAccountReady),
                      ),
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
}

class _LandingBackground extends StatelessWidget {
  const _LandingBackground();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFDF7), Color(0xFFFAF8F1), Color(0xFFF2F5EA)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 145,
              left: -90,
              child: _Glow(
                size: 250,
                color: AppColors.teaGreen.withValues(alpha: .22),
              ),
            ),
            Positioned(
              top: 300,
              right: -105,
              child: _Glow(
                size: 290,
                color: AppColors.limeGlow.withValues(alpha: .14),
              ),
            ),
            const Positioned(
              right: 38,
              top: 122,
              child: _IngredientMark(angle: .3),
            ),
            const Positioned(
              left: 34,
              top: 345,
              child: _IngredientMark(angle: -.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, AppColors.transparent]),
        ),
      ),
    );
  }
}

class _IngredientMark extends StatelessWidget {
  const _IngredientMark({required this.angle});

  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 18,
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.teaGreen.withValues(alpha: .48),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

class _WelcomePill extends StatelessWidget {
  const _WelcomePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .86),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.emeraldGreen.withValues(alpha: .12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(width: 25),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.darkGreen.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGreen.withValues(alpha: .18),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.teaGreen,
              size: 20,
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntranceTransition extends StatelessWidget {
  const _EntranceTransition({
    required this.controller,
    required this.interval,
    required this.offset,
    required this.child,
  });

  final AnimationController controller;
  final Interval interval;
  final Offset offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(interval.begin, interval.end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: offset,
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _FoodComposition extends StatefulWidget {
  const _FoodComposition({
    required this.entranceController,
    required this.floatController,
    required this.reducedMotion,
    required this.balancedLabel,
    required this.flexibleLabel,
    required this.goalsLabel,
  });

  final AnimationController entranceController;
  final AnimationController floatController;
  final bool reducedMotion;
  final String balancedLabel;
  final String flexibleLabel;
  final String goalsLabel;

  @override
  State<_FoodComposition> createState() => _FoodCompositionState();
}

class _FoodCompositionState extends State<_FoodComposition> {
  Timer? _labelTimer;
  String? _label;

  void _showLabel(String label) {
    _labelTimer?.cancel();
    setState(() => _label = label);
    _labelTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _label = null);
    });
  }

  @override
  void dispose() {
    _labelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: ValueKey(
        widget.reducedMotion
            ? 'reducedMotionFoodComposition'
            : 'animatedFoodComposition',
      ),
      child: AnimatedBuilder(
        animation: widget.floatController,
        builder: (context, child) {
          final phase = widget.reducedMotion
              ? 0.0
              : widget.floatController.value * math.pi * 2;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: Offset(0, math.sin(phase) * 5),
                child: ScaleTransition(
                  scale: Tween<double>(begin: .88, end: 1).animate(
                    CurvedAnimation(
                      parent: widget.entranceController,
                      curve: const Interval(
                        .26,
                        .58,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                  ),
                  child: _FoodPlate(
                    key: const ValueKey('mainFoodPlate'),
                    asset: 'assets/images/login_meal_background.png',
                    size: 184,
                    alignment: const Alignment(0, -.42),
                    semanticLabel: widget.balancedLabel,
                    onTap: () => _showLabel(widget.balancedLabel),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(-.82, .45),
                child: Transform.translate(
                  offset: Offset(
                    math.cos(phase * .78) * 3,
                    math.sin(phase * .78) * -4,
                  ),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(-.45, .10),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: widget.entranceController,
                            curve: const Interval(
                              .38,
                              .68,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                        ),
                    child: _FoodPlate(
                      key: const ValueKey('secondaryFoodPlate'),
                      asset: 'assets/images/onboarding_1.png',
                      size: 96,
                      alignment: const Alignment(0, -.17),
                      semanticLabel: widget.flexibleLabel,
                      onTap: () => _showLabel(widget.flexibleLabel),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(.86, -.34),
                child: Transform.translate(
                  offset: Offset(
                    math.cos(phase * .63) * -3,
                    math.sin(phase * .63) * 4,
                  ),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(.45, -.08),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: widget.entranceController,
                            curve: const Interval(
                              .48,
                              .76,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                        ),
                    child: _FoodPlate(
                      key: const ValueKey('tertiaryFoodPlate'),
                      asset: 'assets/images/onboarding_3.png',
                      size: 82,
                      alignment: const Alignment(0, -.06),
                      semanticLabel: widget.goalsLabel,
                      onTap: () => _showLabel(widget.goalsLabel),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(.64, .68),
                child: Transform.rotate(
                  angle: widget.reducedMotion
                      ? -.35
                      : -.35 + (math.sin(phase) * .07),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.emeraldGreen,
                    size: 30,
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, .92),
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _label == null
                        ? const SizedBox.shrink()
                        : Container(
                            key: ValueKey(_label),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.darkGreen,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              _label!,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
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

class _FoodPlate extends StatefulWidget {
  const _FoodPlate({
    required this.asset,
    required this.size,
    required this.alignment,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  final String asset;
  final double size;
  final Alignment alignment;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  State<_FoodPlate> createState() => _FoodPlateState();
}

class _FoodPlateState extends State<_FoodPlate> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 130),
          scale: _pressed ? .96 : 1,
          child: Container(
            width: widget.size,
            height: widget.size,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkGreen.withValues(alpha: .15),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                widget.asset,
                alignment: widget.alignment,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalizeButton extends StatelessWidget {
  const _PersonalizeButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? const [Color(0xFF16806A), AppColors.emeraldGreen]
                  : const [Color(0xFF8CB9AA), Color(0xFF78A898)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.emeraldGreen.withValues(alpha: .24),
                      blurRadius: 20,
                      offset: const Offset(0, 9),
                    ),
                  ]
                : null,
          ),
          child: FilledButton(
            key: const ValueKey('postLoginCta'),
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.transparent,
              disabledBackgroundColor: AppColors.transparent,
              foregroundColor: AppColors.white,
              shadowColor: AppColors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 28),
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
                const SizedBox(
                  width: 28,
                  child: Icon(Icons.arrow_forward_rounded, size: 23),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
