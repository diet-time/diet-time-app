import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/language/presentation/language_controller.dart';
import 'package:diet_time/features/onboarding/data/journey_state_repository.dart';
import 'package:diet_time/features/personalization/domain/personalization_draft.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pageDuration = Duration(milliseconds: 2800);
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;
  bool _showFinalChoice = false;

  List<({String image, String title, String accent, String description})>
  _pages(AppLocalizations l10n) => [
    (
      image: 'assets/images/onboarding_1.png',
      title: l10n.onboardingHealthyMealsTitle,
      accent: l10n.onboardingHealthyMealsAccent,
      description: l10n.onboardingHealthyMealsDescription,
    ),
    (
      image: 'assets/images/onboarding_2.png',
      title: l10n.onboardingPlansTitle,
      accent: l10n.onboardingPlansAccent,
      description: l10n.onboardingPlansDescription,
    ),
    (
      image: 'assets/images/onboarding_3.png',
      title: l10n.onboardingFreshTitle,
      accent: l10n.onboardingFreshAccent,
      description: l10n.onboardingFreshDescription,
    ),
    (
      image: 'assets/images/onboarding_4.png',
      title: l10n.onboardingTrackTitle,
      accent: l10n.onboardingTrackAccent,
      description: l10n.onboardingTrackDescription,
    ),
    (
      image: 'assets/images/onboarding_5.png',
      title: l10n.onboardingTogetherTitle,
      accent: l10n.onboardingTogetherAccent,
      description: l10n.onboardingTogetherDescription,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scheduleAdvance();
  }

  void _scheduleAdvance() {
    _timer?.cancel();
    _timer = Timer(_pageDuration, () {
      if (!mounted || !_controller.hasClients) return;
      final count = _pages(AppLocalizations.of(context)).length;
      if (_index < count - 1) {
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
    final count = _pages(AppLocalizations.of(context)).length;
    if (_index == count - 1) {
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

  @override
  void dispose() {
    _timer?.cancel();
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
                  child: Row(
                    children: List.generate(
                      pages.length,
                      (index) => Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          height: 4,
                          margin: EdgeInsetsDirectional.only(
                            end: index == pages.length - 1 ? 0 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: index <= _index
                                ? const Color(0xFF62CE55)
                                : AppColors.white.withValues(alpha: .20),
                            borderRadius: BorderRadius.circular(99),
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
                          image: page.image,
                          title: page.title,
                          accent: page.accent,
                          description: page.description,
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
              onMenu: () async {
                await ref
                    .read(journeyStateRepositoryProvider)
                    .markOnboardingComplete();
                if (!context.mounted) return;
                await context.push<void>(AppRoutes.menu);
              },
              onStartPlan: () async {
                await ref
                    .read(journeyStateRepositoryProvider)
                    .markOnboardingComplete();
                if (!context.mounted) return;
                await context.push<void>(AppRoutes.personalization);
              },
            ),
        ],
      ),
    );
  }
}

class _CarouselPage extends StatelessWidget {
  const _CarouselPage({
    required this.image,
    required this.title,
    required this.accent,
    required this.description,
    required this.current,
    required this.count,
  });

  final String image;
  final String title;
  final String accent;
  final String description;
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
                  Image.asset(image, fit: BoxFit.cover),
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
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: compact ? 23 : 28,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            accent,
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
            description,
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

class PersonalizationScreen extends ConsumerStatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  ConsumerState<PersonalizationScreen> createState() =>
      _PersonalizationScreenState();
}

class _PersonalizationScreenState extends ConsumerState<PersonalizationScreen> {
  static const _stepCount = 8;
  final PageController _controller = PageController();

  int _index = 0;
  bool _isNavigating = false;
  String? _validationMessage;
  String? _goal;
  String _gender = 'female';
  int _age = 28;
  int _height = 170;
  int _weight = 70;
  String? _lifestyle;
  String? _activity;
  final Set<String> _preferences = {};
  final Set<String> _allergies = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goTo(int target) async {
    if (_isNavigating || !_controller.hasClients) return;
    _isNavigating = true;
    try {
      await _controller.animateToPage(
        target.clamp(0, _stepCount - 1),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _isNavigating = false;
    }
  }

  void _continue() {
    final l10n = AppLocalizations.of(context);
    final invalid =
        (_index == 1 && _goal == null) ||
        (_index == 3 && _lifestyle == null) ||
        (_index == 4 && _activity == null);
    if (invalid) {
      setState(() => _validationMessage = l10n.personalizationSelectOption);
      return;
    }
    if (_validationMessage != null) {
      setState(() => _validationMessage = null);
    }
    if (_index == _stepCount - 1) {
      final route = ref.read(otpAuthControllerProvider).isAuthenticated
          ? AppRoutes.recommendation
          : AppRoutes.phoneLogin;
      if (route == AppRoutes.phoneLogin) {
        unawaited(
          context.push<void>(
            route,
            extra: const PendingAuthDestination(
              route: AppRoutes.recommendation,
            ),
          ),
        );
      } else {
        unawaited(context.push<void>(route));
      }
      return;
    }
    unawaited(_goTo(_index + 1));
  }

  void _previous() {
    if (_index > 0) unawaited(_goTo(_index - 1));
  }

  void _selectGoal(String value) {
    setState(() {
      _goal = value;
      _validationMessage = null;
    });
    ref
        .read(personalizationControllerProvider.notifier)
        .setGoal(value.toUpperCase());
  }

  void _selectLifestyle(String value) {
    setState(() {
      _lifestyle = value;
      _validationMessage = null;
    });
    ref
        .read(personalizationControllerProvider.notifier)
        .setRoutine(value.toUpperCase());
  }

  void _selectActivity(String value) {
    setState(() {
      _activity = value;
      _validationMessage = null;
    });
    ref
        .read(personalizationControllerProvider.notifier)
        .setActivity(value.toUpperCase());
  }

  void _togglePreference(String value) {
    setState(() {
      if (!_preferences.add(value)) _preferences.remove(value);
    });
    ref
        .read(personalizationControllerProvider.notifier)
        .togglePreference(value.toUpperCase());
  }

  void _toggleAllergy(String value) {
    setState(() {
      if (value == 'none') {
        _allergies
          ..clear()
          ..add(value);
      } else {
        _allergies.remove('none');
        if (!_allergies.add(value)) _allergies.remove(value);
      }
    });
    ref
        .read(personalizationControllerProvider.notifier)
        .toggleAllergy(value.toUpperCase());
  }

  Future<void> _showPicker({
    required String title,
    required List<String> values,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) async {
    var currentIndex = selectedIndex;
    final pickerController = FixedExtentScrollController(
      initialItem: selectedIndex,
    );
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFEFB),
      builder: (context) => SafeArea(
        top: false,
        child: SizedBox(
          height: 360,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(22, 0, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        onSelected(currentIndex);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        MaterialLocalizations.of(context).saveButtonLabel,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  key: const ValueKey('onboardingWheelPicker'),
                  scrollController: pickerController,
                  itemExtent: 48,
                  useMagnifier: true,
                  magnification: 1.08,
                  onSelectedItemChanged: (index) => currentIndex = index,
                  children: values
                      .map(
                        (value) => Center(
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    pickerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final steps = _buildSteps(l10n);
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index > 0) _previous();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F2),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _OrganicBackground(),
            SafeArea(
              child: Column(
                children: [
                  _OnboardingHeader(
                    languageCode: locale.languageCode,
                    onLanguageSelected: (languageCode) {
                      unawaited(
                        ref
                            .read(languageControllerProvider.notifier)
                            .selectLanguage(languageCode),
                      );
                    },
                  ),
                  _StepProgress(current: _index, count: _stepCount),
                  Expanded(
                    child: PageView.builder(
                      key: const ValueKey('onboardingPageView'),
                      controller: _controller,
                      itemCount: _stepCount,
                      onPageChanged: (index) => setState(() => _index = index),
                      itemBuilder: (context, index) => KeyedSubtree(
                        key: ValueKey('onboardingStep-$index'),
                        child: steps[index],
                      ),
                    ),
                  ),
                  if (_validationMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 17,
                            color: AppColors.portlandOrange,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              _validationMessage!,
                              key: const ValueKey('personalizationError'),
                              style: const TextStyle(
                                color: AppColors.darkGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _OnboardingNavigation(
                    index: _index,
                    onPrevious: _previous,
                    onContinue: _continue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSteps(AppLocalizations l10n) => [
    _WelcomeStep(l10n: l10n, onNotNow: () => context.go(AppRoutes.menu)),
    _StepFrame(
      title: l10n.onboardingGoalTitle,
      subtitle: l10n.onboardingGoalSubtitle,
      child: Column(
        children: [
          _SelectionCard(
            key: const ValueKey('goal-lose'),
            icon: Icons.trending_down_rounded,
            title: l10n.onboardingLoseWeight,
            description: l10n.onboardingLoseWeightDescription,
            selected: _goal == 'lose_weight',
            onTap: () => _selectGoal('lose_weight'),
          ),
          _SelectionCard(
            key: const ValueKey('goal-maintain'),
            icon: Icons.balance_rounded,
            title: l10n.onboardingMaintainWeight,
            description: l10n.onboardingMaintainWeightDescription,
            selected: _goal == 'maintain_weight',
            onTap: () => _selectGoal('maintain_weight'),
          ),
          _SelectionCard(
            key: const ValueKey('goal-gain'),
            icon: Icons.trending_up_rounded,
            title: l10n.onboardingGainWeight,
            description: l10n.onboardingGainWeightDescription,
            selected: _goal == 'gain_weight',
            onTap: () => _selectGoal('gain_weight'),
          ),
          _SelectionCard(
            key: const ValueKey('goal-muscle'),
            icon: Icons.fitness_center_rounded,
            title: l10n.onboardingBuildMuscle,
            description: l10n.onboardingBuildMuscleDescription,
            selected: _goal == 'build_muscle',
            onTap: () => _selectGoal('build_muscle'),
          ),
          _SelectionCard(
            key: const ValueKey('goal-healthy'),
            icon: Icons.favorite_rounded,
            title: l10n.onboardingEatHealthier,
            description: l10n.onboardingEatHealthierDescription,
            selected: _goal == 'eat_healthier',
            onTap: () => _selectGoal('eat_healthier'),
          ),
        ],
      ),
    ),
    _StepFrame(
      title: l10n.onboardingProfileTitle,
      subtitle: l10n.onboardingProfileSubtitle,
      child: Column(
        children: [
          const _ProfileIllustration(),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ProfileCard(
                    key: const ValueKey('profileGender'),
                    width: width,
                    label: l10n.onboardingGender,
                    value: switch (_gender) {
                      'male' => l10n.onboardingMale,
                      'female' => l10n.onboardingFemale,
                      _ => l10n.onboardingPreferNotToSay,
                    },
                    icon: Icons.person_outline_rounded,
                    onTap: () => _showPicker(
                      title: l10n.onboardingGender,
                      values: [
                        l10n.onboardingFemale,
                        l10n.onboardingMale,
                        l10n.onboardingPreferNotToSay,
                      ],
                      selectedIndex: switch (_gender) {
                        'female' => 0,
                        'male' => 1,
                        _ => 2,
                      },
                      onSelected: (index) {
                        final value = ['female', 'male', 'other'][index];
                        setState(() => _gender = value);
                        ref
                            .read(personalizationControllerProvider.notifier)
                            .setGender(value.toUpperCase());
                      },
                    ),
                  ),
                  _ProfileCard(
                    key: const ValueKey('profileAge'),
                    width: width,
                    label: l10n.onboardingAge,
                    value: '$_age',
                    icon: Icons.cake_outlined,
                    onTap: () {
                      final values = List.generate(
                        65,
                        (index) => '${index + 16}',
                      );
                      unawaited(
                        _showPicker(
                          title: l10n.onboardingAge,
                          values: values,
                          selectedIndex: _age - 16,
                          onSelected: (index) {
                            final value = index + 16;
                            setState(() => _age = value);
                            ref
                                .read(
                                  personalizationControllerProvider.notifier,
                                )
                                .setAge(value);
                          },
                        ),
                      );
                    },
                  ),
                  _ProfileCard(
                    key: const ValueKey('profileHeight'),
                    width: width,
                    label: l10n.onboardingHeight,
                    value: '$_height cm',
                    icon: Icons.height_rounded,
                    onTap: () {
                      final values = List.generate(
                        91,
                        (index) => '${index + 130} cm',
                      );
                      unawaited(
                        _showPicker(
                          title: l10n.onboardingHeight,
                          values: values,
                          selectedIndex: _height - 130,
                          onSelected: (index) {
                            final value = index + 130;
                            setState(() => _height = value);
                            ref
                                .read(
                                  personalizationControllerProvider.notifier,
                                )
                                .setHeight(value.toDouble());
                          },
                        ),
                      );
                    },
                  ),
                  _ProfileCard(
                    key: const ValueKey('profileWeight'),
                    width: width,
                    label: l10n.onboardingWeight,
                    value: '$_weight kg',
                    icon: Icons.monitor_weight_outlined,
                    onTap: () {
                      final values = List.generate(
                        141,
                        (index) => '${index + 40} kg',
                      );
                      unawaited(
                        _showPicker(
                          title: l10n.onboardingWeight,
                          values: values,
                          selectedIndex: _weight - 40,
                          onSelected: (index) {
                            final value = index + 40;
                            setState(() => _weight = value);
                            ref
                                .read(
                                  personalizationControllerProvider.notifier,
                                )
                                .setWeight(value.toDouble());
                          },
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
    _StepFrame(
      title: l10n.onboardingLifestyleTitle,
      subtitle: l10n.onboardingLifestyleSubtitle,
      child: _OptionGrid(
        children: [
          _CompactOption(
            key: const ValueKey('lifestyle-office'),
            icon: Icons.apartment_rounded,
            label: l10n.onboardingOfficeWork,
            selected: _lifestyle == 'office_work',
            onTap: () => _selectLifestyle('office_work'),
          ),
          _CompactOption(
            icon: Icons.home_work_outlined,
            label: l10n.onboardingWorkFromHome,
            selected: _lifestyle == 'work_from_home',
            onTap: () => _selectLifestyle('work_from_home'),
          ),
          _CompactOption(
            icon: Icons.school_outlined,
            label: l10n.onboardingStudent,
            selected: _lifestyle == 'student',
            onTap: () => _selectLifestyle('student'),
          ),
          _CompactOption(
            icon: Icons.directions_walk_rounded,
            label: l10n.onboardingActiveJob,
            selected: _lifestyle == 'active_job',
            onTap: () => _selectLifestyle('active_job'),
          ),
          _CompactOption(
            icon: Icons.nightlight_outlined,
            label: l10n.onboardingShiftWorker,
            selected: _lifestyle == 'shift_work',
            onTap: () => _selectLifestyle('shift_work'),
          ),
        ],
      ),
    ),
    _StepFrame(
      title: l10n.onboardingActivityTitle,
      subtitle: l10n.onboardingActivitySubtitle,
      child: Column(
        children: [
          _ActivityCard(
            key: const ValueKey('activity-sitting'),
            icon: Icons.weekend_outlined,
            label: l10n.onboardingMostlySitting,
            selected: _activity == 'mostly_seated',
            onTap: () => _selectActivity('mostly_seated'),
          ),
          _ActivityCard(
            icon: Icons.directions_walk_rounded,
            label: l10n.onboardingLightActivity,
            selected: _activity == 'lightly_active',
            onTap: () => _selectActivity('lightly_active'),
          ),
          _ActivityCard(
            icon: Icons.directions_run_rounded,
            label: l10n.onboardingActiveLifestyle,
            selected: _activity == 'moderately_active',
            onTap: () => _selectActivity('moderately_active'),
          ),
          _ActivityCard(
            icon: Icons.sports_gymnastics_rounded,
            label: l10n.onboardingAthlete,
            selected: _activity == 'very_active',
            onTap: () => _selectActivity('very_active'),
          ),
        ],
      ),
    ),
    _StepFrame(
      title: l10n.onboardingPreferencesTitle,
      subtitle: l10n.onboardingPreferencesSubtitle,
      child: _ChoiceWrap(
        choices: {
          'protein': l10n.onboardingHighProtein,
          'lowCarb': l10n.onboardingLowCarb,
          'vegetarian': l10n.onboardingVegetarian,
          'vegan': l10n.onboardingVegan,
          'seafood': l10n.onboardingSeafood,
          'chicken': l10n.onboardingChicken,
          'beef': l10n.onboardingBeef,
          'arabic': l10n.onboardingArabicCuisine,
          'international': l10n.onboardingInternational,
          'mediterranean': l10n.onboardingMediterranean,
          'snacks': l10n.onboardingHealthySnacks,
          'breakfast': l10n.onboardingBreakfastLover,
        },
        selected: _preferences,
        onSelected: _togglePreference,
      ),
    ),
    _StepFrame(
      title: l10n.onboardingAllergiesTitle,
      subtitle: l10n.onboardingAllergiesSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChoiceWrap(
            leadingIcon: Icons.health_and_safety_outlined,
            choices: {
              'milk': l10n.onboardingMilk,
              'egg': l10n.onboardingEgg,
              'fish': l10n.onboardingFish,
              'shellfish': l10n.onboardingShellfish,
              'treeNuts': l10n.onboardingTreeNuts,
              'peanuts': l10n.onboardingPeanuts,
              'soy': l10n.onboardingSoy,
              'sesame': l10n.onboardingSesame,
              'gluten': l10n.onboardingGluten,
              'none': l10n.onboardingNoAllergies,
            },
            selected: _allergies,
            onSelected: _toggleAllergy,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.allergySafetyNote,
            style: TextStyle(
              color: AppColors.darkGreen.withValues(alpha: .62),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    ),
    _BmiSummaryStep(
      l10n: l10n,
      draft: ref.watch(personalizationControllerProvider),
    ),
  ];
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.languageCode,
    required this.onLanguageSelected,
  });

  final String languageCode;
  final ValueChanged<String> onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 12, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.emeraldGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppColors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.onboardingBrand,
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -.3,
              ),
            ),
          ),
          PopupMenuButton<String>(
            key: const ValueKey('onboardingLanguageSelector'),
            initialValue: languageCode,
            onSelected: onLanguageSelected,
            color: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'ar', child: Text('العربية')),
            ],
            child: Container(
              constraints: const BoxConstraints(minWidth: 92, minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: .86),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppColors.emeraldGreen.withValues(alpha: .15),
                ),
                boxShadow: _cardShadow(.06),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 17,
                    color: AppColors.emeraldGreen,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    languageCode == 'ar' ? 'العربية' : 'English',
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 17,
                    color: AppColors.emeraldGreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).pageProgress(current + 1, count),
      child: Padding(
        key: const ValueKey('onboardingProgress'),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: List.generate(
            count,
            (index) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                height: 4,
                margin: EdgeInsetsDirectional.only(
                  end: index == count - 1 ? 0 : 5,
                ),
                decoration: BoxDecoration(
                  color: index <= current
                      ? AppColors.emeraldGreen
                      : AppColors.emeraldGreen.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingNavigation extends StatelessWidget {
  const _OnboardingNavigation({
    required this.index,
    required this.onPrevious,
    required this.onContinue,
  });

  final int index;
  final VoidCallback onPrevious;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = index == 0
        ? l10n.personalizationBegin
        : index == 7
        ? l10n.onboardingContinue
        : l10n.onboardingContinue;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F2).withValues(alpha: .94),
        border: Border(
          top: BorderSide(color: AppColors.darkGreen.withValues(alpha: .06)),
        ),
      ),
      child: index == 0
          ? AppButton(
              key: const ValueKey('onboardingContinue'),
              label: label,
              onPressed: onContinue,
            )
          : Row(
              children: [
                TextButton.icon(
                  key: const ValueKey('onboardingPrevious'),
                  onPressed: onPrevious,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(l10n.onboardingPrevious),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.darkGreen,
                    minimumSize: const Size(112, AppButton.height),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    key: const ValueKey('onboardingContinue'),
                    label: label,
                    onPressed: onContinue,
                  ),
                ),
              ],
            ),
    );
  }
}

class _StepFrame extends StatelessWidget {
  const _StepFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0, constraints.maxHeight - 46),
            maxWidth: 620,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 30,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .62),
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.l10n, required this.onNotNow});

  final AppLocalizations l10n;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 590;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 36),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WelcomeArtwork(height: compact ? 240 : 330),
                SizedBox(height: compact ? 16 : 26),
                Text(
                  l10n.personalizationIntroTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: compact ? 29 : 34,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.personalizationIntroSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .64),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  key: const ValueKey('personalizationNotNow'),
                  onPressed: onNotNow,
                  child: Text(l10n.personalizationNotNow),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeArtwork extends StatelessWidget {
  const _WelcomeArtwork({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF4EA),
              borderRadius: BorderRadius.circular(52),
              boxShadow: _cardShadow(.10),
            ),
            child: Image.asset(
              'assets/images/onboarding_1.png',
              key: const ValueKey('onboardingWelcomeImage'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          const PositionedDirectional(
            start: 0,
            top: 34,
            child: _FloatingFoodIcon(
              icon: Icons.eco_rounded,
              color: Color(0xFF0F7A5C),
            ),
          ),
          const PositionedDirectional(
            end: 0,
            bottom: 48,
            child: _FloatingFoodIcon(
              icon: Icons.spa_rounded,
              color: Color(0xFFE29A57),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingFoodIcon extends StatelessWidget {
  const _FloatingFoodIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .92),
        shape: BoxShape.circle,
        boxShadow: _cardShadow(.10),
      ),
      child: Icon(icon, color: color, size: 27),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.white : AppColors.darkGreen;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.emeraldGreen : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected
              ? AppColors.emeraldGreen
              : AppColors.emeraldGreen.withValues(alpha: .10),
        ),
        boxShadow: selected ? _cardShadow(.16) : _cardShadow(.06),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.white.withValues(alpha: .14)
                        : const Color(0xFFDDF4EA),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? AppColors.white : AppColors.emeraldGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: foreground.withValues(alpha: .70),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileIllustration extends StatelessWidget {
  const _ProfileIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 116,
        height: 116,
        decoration: BoxDecoration(
          color: const Color(0xFFDDF4EA),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 7),
          boxShadow: _cardShadow(.08),
        ),
        child: const Icon(
          Icons.person_rounded,
          size: 62,
          color: AppColors.emeraldGreen,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            height: 118,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.emeraldGreen.withValues(alpha: .10),
              ),
              boxShadow: _cardShadow(.05),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.emeraldGreen, size: 22),
                const Spacer(),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .52),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

class _CompactOption extends StatelessWidget {
  const _CompactOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 132,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFDDF4EA) : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.emeraldGreen.withValues(alpha: selected ? .65 : .10),
          width: selected ? 1.5 : 1,
        ),
        boxShadow: _cardShadow(selected ? .09 : .05),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.emeraldGreen, size: 31),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 14,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.emeraldGreen : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: _cardShadow(selected ? .14 : .05),
      ),
      child: ListTile(
        minTileHeight: 76,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        leading: Icon(
          icon,
          color: selected ? AppColors.white : AppColors.emeraldGreen,
          size: 29,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.darkGreen,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        trailing: Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: selected
              ? AppColors.white
              : AppColors.emeraldGreen.withValues(alpha: .24),
        ),
      ),
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.choices,
    required this.selected,
    required this.onSelected,
    this.leadingIcon,
  });

  final Map<String, String> choices;
  final Set<String> selected;
  final ValueChanged<String> onSelected;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 9,
      runSpacing: 10,
      children: choices.entries
          .map((entry) {
            final isSelected = selected.contains(entry.key);
            return FilterChip(
              key: ValueKey('choice-${entry.key}'),
              selected: isSelected,
              onSelected: (_) => onSelected(entry.key),
              showCheckmark: true,
              avatar: leadingIcon == null
                  ? null
                  : Icon(
                      leadingIcon,
                      size: 17,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.emeraldGreen,
                    ),
              label: Text(entry.value),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.darkGreen,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              selectedColor: AppColors.emeraldGreen,
              checkmarkColor: AppColors.white,
              backgroundColor: AppColors.white,
              side: BorderSide(
                color: AppColors.emeraldGreen.withValues(
                  alpha: isSelected ? 1 : .13,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _BmiSummaryStep extends StatelessWidget {
  const _BmiSummaryStep({required this.l10n, required this.draft});

  final AppLocalizations l10n;
  final PersonalizationDraft draft;

  @override
  Widget build(BuildContext context) {
    final bmi = draft.bmi;
    final marker = ((bmi.clamp(14, 40) - 14) / 26).toDouble();
    final category = draft.age < 18
        ? l10n.bmiYouthNote
        : bmi < 18.5
        ? l10n.bmiBelowRange
        : bmi < 25
        ? l10n.bmiWithinRange
        : bmi < 30
        ? l10n.bmiAboveRange
        : l10n.bmiWellAboveRange;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0, constraints.maxHeight - 50),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.bmiSummaryTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                bmi.toStringAsFixed(1),
                key: const ValueKey('bmiValue'),
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: AppColors.emeraldGreen,
                  fontSize: 68,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.bmiCalculatedLabel),
              const SizedBox(height: 28),
              SizedBox(
                key: const ValueKey('bmiRange'),
                height: 34,
                child: LayoutBuilder(
                  builder: (context, rangeConstraints) => Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: const Row(
                          children: [
                            Expanded(
                              child: ColoredBox(color: Color(0xFFB8D8EA)),
                            ),
                            Expanded(
                              child: ColoredBox(color: Color(0xFF9BD3A8)),
                            ),
                            Expanded(
                              child: ColoredBox(color: Color(0xFFF0C878)),
                            ),
                            Expanded(
                              child: ColoredBox(color: Color(0xFFE89A78)),
                            ),
                          ],
                        ),
                      ),
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                        alignment: AlignmentDirectional((marker * 2) - 1, 0),
                        child: Container(
                          width: 5,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.darkGreen,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                category,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.bmiDisclaimer,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .58),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganicBackground extends StatelessWidget {
  const _OrganicBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFF8F6F2)),
        PositionedDirectional(
          top: -110,
          end: -100,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFDDF4EA).withValues(alpha: .72),
            ),
          ),
        ),
        PositionedDirectional(
          bottom: 80,
          start: -130,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFEBD9).withValues(alpha: .35),
            ),
          ),
        ),
      ],
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
          boxShadow: _cardShadow(.18),
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

List<BoxShadow> _cardShadow(double opacity) => [
  BoxShadow(
    color: AppColors.darkGreen.withValues(alpha: opacity),
    blurRadius: 24,
    offset: const Offset(0, 10),
  ),
];
