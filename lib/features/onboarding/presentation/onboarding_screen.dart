import 'dart:async';
import 'dart:math' as math;

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/authentication/data/mock_authentication_service.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/personalization/data/allergen_repository.dart';
import 'package:diet_time/features/personalization/domain/personalization_draft.dart';
import 'package:diet_time/features/personalization/domain/personalization_options.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PersonalizationScreen extends ConsumerStatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  ConsumerState<PersonalizationScreen> createState() =>
      _PersonalizationScreenState();
}

class _PersonalizationScreenState extends ConsumerState<PersonalizationScreen> {
  static const _stepCount = 9;
  late final PageController _controller;

  int _index = 0;
  bool _isNavigating = false;
  bool _profileLoadStarted = false;
  final List<int> _history = [];
  String? _validationMessage;
  String? _goal;
  String? _gender;
  int? _age;
  int? _height;
  int? _weight;
  String? _lifestyle;
  String? _activity;
  final Set<String> _preferences = {};
  final Set<String> _allergies = {};
  String _allergyQuery = '';

  @override
  void initState() {
    super.initState();
    // This is a one-shot local flow; legacy server progress must not skip pages.
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileLoadStarted) return;
    _profileLoadStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadProfile());
    });
  }

  Future<void> _loadProfile() async {
    final cachedProfile = ref.read(personalizationControllerProvider);
    if (cachedProfile.isCompleted || cachedProfile.hasCapturedQuestionnaire) {
      if (mounted) context.go(AppRoutes.plans);
      return;
    }
    final authenticated = await ref
        .read(authenticationServiceProvider)
        .isLoggedIn();
    if (!mounted) return;
    if (!authenticated) {
      context.go(
        AppRoutes.phoneLogin,
        extra: const PendingAuthDestination(route: AppRoutes.personalization),
      );
      return;
    }
    final existingPersistence = ref.read(profilePersistenceControllerProvider);
    final profile = existingPersistence.hasLoaded
        ? ref.read(personalizationControllerProvider)
        : await ref.read(profilePersistenceControllerProvider.notifier).load();
    if (!mounted || profile == null) return;
    if (profile.isCompleted) {
      context.go(AppRoutes.plans);
      return;
    }
    _startFreshDraft(profile);
  }

  void _startFreshDraft(CustomerProfile profile) {
    ref
        .read(personalizationControllerProvider.notifier)
        .replace(
          CustomerProfile(
            profileId: profile.profileId,
            preferredLanguage: Localizations.localeOf(context).languageCode,
            updatedAt: profile.updatedAt,
            rowVersion: profile.rowVersion,
          ),
        );
    setState(() {
      _goal = null;
      _gender = null;
      _age = null;
      _height = null;
      _weight = null;
      _lifestyle = null;
      _activity = null;
      _preferences.clear();
      _allergies.clear();
    });
  }

  void _restoreVisibleValues(CustomerProfile profile) {
    setState(() {
      _goal = profile.goalCode;
      _gender = profile.genderCode?.toLowerCase();
      _age = profile.age > 0 ? profile.age : null;
      _height = profile.heightCm?.round();
      _weight = profile.weightKg?.round();
      _lifestyle = profile.dailyRoutineCode;
      _activity = profile.activityLevelCode;
      _preferences
        ..clear()
        ..addAll(profile.preferences);
      _allergies
        ..clear()
        ..addAll(profile.allergens);
    });
  }

  Future<void> _goTo(int target, {bool recordHistory = true}) async {
    if (_isNavigating || !_controller.hasClients) return;
    final destination = target.clamp(0, _stepCount - 1);
    if (destination == _index) return;
    _isNavigating = true;
    setState(() {
      if (recordHistory) _history.add(_index);
      _index = destination;
    });
    try {
      await _controller.animateToPage(
        destination,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context);
    final invalid =
        (_index == 1 && _goal == null) ||
        (_index == 2 &&
            (_gender == null ||
                _age == null ||
                _height == null ||
                _weight == null)) ||
        (_index == 3 && _lifestyle == null) ||
        (_index == 4 && _activity == null);
    if (invalid) {
      setState(() => _validationMessage = l10n.personalizationSelectOption);
      return;
    }
    if (_validationMessage != null) {
      setState(() => _validationMessage = null);
    }
    ref
        .read(personalizationControllerProvider.notifier)
        .setPreferredLanguage(Localizations.localeOf(context).languageCode);
    if (_index == 2) {
      final controller = ref.read(personalizationControllerProvider.notifier);
      controller
        ..setGender(_gender!.toUpperCase())
        ..setAge(_age!)
        ..setHeight(_height!.toDouble())
        ..setWeight(_weight!.toDouble());
    }
    if (_index == 5) {
      ref.read(personalizationControllerProvider.notifier).confirmPreferences();
    }
    if (_index == 6) {
      ref.read(personalizationControllerProvider.notifier).confirmAllergens();
    }
    if (_index == 6) {
      final saved = await ref
          .read(profilePersistenceControllerProvider.notifier)
          .save(complete: true);
      if (!mounted) return;
      if (!saved) {
        if (ref.read(profilePersistenceControllerProvider).errorMessage ==
            'profile_conflict') {
          _restoreVisibleValues(ref.read(personalizationControllerProvider));
        }
        return;
      }
      await _goTo(7);
      return;
    }
    if (_index == _stepCount - 1) {
      context.go(AppRoutes.menu);
      return;
    }
    await _goTo(_index + 1);
  }

  void _previous() {
    if (_history.isEmpty) return;
    final target = _history.removeLast();
    unawaited(_goTo(target, recordHistory: false));
  }

  void _selectGoal(String value) {
    setState(() {
      _goal = value;
      _validationMessage = null;
    });
    ref.read(personalizationControllerProvider.notifier).setGoal(value);
  }

  void _selectLifestyle(String value) {
    setState(() {
      _lifestyle = value;
      _validationMessage = null;
    });
    ref.read(personalizationControllerProvider.notifier).setRoutine(value);
  }

  void _selectActivity(String value) {
    setState(() {
      _activity = value;
      _validationMessage = null;
    });
    ref.read(personalizationControllerProvider.notifier).setActivity(value);
  }

  void _togglePreference(String value) {
    setState(() {
      if (value == 'NONE') {
        _preferences
          ..clear()
          ..add(value);
      } else {
        _preferences.remove('NONE');
        if (!_preferences.add(value)) _preferences.remove(value);
      }
      if (_preferences.isNotEmpty) _validationMessage = null;
    });
    ref
        .read(personalizationControllerProvider.notifier)
        .togglePreference(value);
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
      if (_allergies.isNotEmpty) _validationMessage = null;
    });
    ref
        .read(personalizationControllerProvider.notifier)
        .toggleAllergy(value == 'none' ? 'NONE' : value);
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
    final allergenState = _index == 6
        ? ref.watch(guestAllergensProvider(locale.languageCode))
        : const AsyncValue<List<GuestAllergen>>.loading();
    final steps = _buildSteps(l10n, locale.languageCode, allergenState);
    final persistence = ref.watch(profilePersistenceControllerProvider);
    final localCompletionPercentage = (_index * 100 / (_stepCount - 1)).round();
    final persistenceErrorMessage = switch (persistence.errorMessage) {
      'profile_load' => _wellnessCopy(
        context,
        'Unable to load your saved profile.',
        'تعذر تحميل ملفك المحفوظ.',
      ),
      'profile_conflict' => _wellnessCopy(
        context,
        'Your profile changed elsewhere. We reloaded it; please review and retry.',
        'تم تحديث ملفك من مكان آخر. أعدنا تحميله؛ راجعه وحاول مجدداً.',
      ),
      'profile_save' => _wellnessCopy(
        context,
        'Could not save your progress. Check your connection.',
        'تعذر حفظ تقدمك. تحقق من اتصالك.',
      ),
      _ => null,
    };
    final errorMessage = _validationMessage ?? persistenceErrorMessage;
    return PopScope(
      canPop: _history.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _history.isNotEmpty) _previous();
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
                    showBack: _history.isNotEmpty,
                    onBack: _previous,
                  ),
                  _StepProgress(
                    current: _index,
                    count: _stepCount,
                    completionPercentage: localCompletionPercentage,
                  ),
                  Expanded(
                    child: PageView.builder(
                      key: const ValueKey('onboardingPageView'),
                      controller: _controller,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _stepCount,
                      onPageChanged: (index) => setState(() => _index = index),
                      itemBuilder: (context, index) => KeyedSubtree(
                        key: ValueKey('onboardingStep-$index'),
                        child: steps[index],
                      ),
                    ),
                  ),
                  if (errorMessage != null)
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
                              errorMessage,
                              key: const ValueKey('personalizationError'),
                              style: const TextStyle(
                                color: AppColors.darkGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (persistence.errorMessage != null)
                            TextButton(
                              key: const ValueKey('retryProfilePersistence'),
                              onPressed: persistence.isSaving
                                  ? null
                                  : () => unawaited(
                                      _index == 0
                                          ? _loadProfile()
                                          : _continue(),
                                    ),
                              child: Text(
                                _wellnessCopy(
                                  context,
                                  'Retry',
                                  'إعادة المحاولة',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  _OnboardingNavigation(
                    index: _index,
                    onPrevious: _previous,
                    onContinue: () => unawaited(_continue()),
                    isSaving: persistence.isSaving,
                    canGoBack: _history.isNotEmpty,
                  ),
                ],
              ),
            ),
            if (persistence.isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0xEFFFFFFB),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.emeraldGreen,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSteps(
    AppLocalizations l10n,
    String language,
    AsyncValue<List<GuestAllergen>> allergenState,
  ) => [
    _WelcomeStep(l10n: l10n, onNotNow: () => context.go(AppRoutes.menu)),
    _StepFrame(
      title: l10n.onboardingGoalTitle,
      subtitle: l10n.onboardingGoalSubtitle,
      child: Column(
        children: [
          _SelectionCard(
            key: const ValueKey('goal-lose'),
            icon: Icons.trending_down_rounded,
            title: personalizationOptionLabel(
              goalLabels,
              'LOSE_WEIGHT',
              language,
            ),
            description: l10n.onboardingLoseWeightDescription,
            selected: _goal == 'LOSE_WEIGHT',
            onTap: () => _selectGoal('LOSE_WEIGHT'),
          ),
          _SelectionCard(
            key: const ValueKey('goal-maintain'),
            icon: Icons.balance_rounded,
            title: personalizationOptionLabel(
              goalLabels,
              'MAINTAIN_WEIGHT',
              language,
            ),
            description: l10n.onboardingMaintainWeightDescription,
            selected: _goal == 'MAINTAIN_WEIGHT',
            onTap: () => _selectGoal('MAINTAIN_WEIGHT'),
          ),
          _SelectionCard(
            key: const ValueKey('goal-gain'),
            icon: Icons.trending_up_rounded,
            title: personalizationOptionLabel(
              goalLabels,
              'GAIN_WEIGHT',
              language,
            ),
            description: l10n.onboardingGainWeightDescription,
            selected: _goal == 'GAIN_WEIGHT',
            onTap: () => _selectGoal('GAIN_WEIGHT'),
          ),
          _SelectionCard(
            key: const ValueKey('goal-muscle'),
            icon: Icons.fitness_center_rounded,
            title: personalizationOptionLabel(
              goalLabels,
              'BUILD_MUSCLE',
              language,
            ),
            description: l10n.onboardingBuildMuscleDescription,
            selected: _goal == 'BUILD_MUSCLE',
            onTap: () => _selectGoal('BUILD_MUSCLE'),
          ),
          _SelectionCard(
            key: const ValueKey('goal-healthy'),
            icon: Icons.favorite_rounded,
            title: personalizationOptionLabel(
              goalLabels,
              'EAT_HEALTHIER',
              language,
            ),
            description: l10n.onboardingEatHealthierDescription,
            selected: _goal == 'EAT_HEALTHIER',
            onTap: () => _selectGoal('EAT_HEALTHIER'),
          ),
        ],
      ),
    ),
    _StepFrame(
      title: l10n.onboardingProfileTitle,
      subtitle: l10n.onboardingProfileSubtitle,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Wrap(
                runSpacing: 10,
                children: [
                  _ProfileCard(
                    key: const ValueKey('profileGender'),
                    width: width,
                    label: l10n.onboardingGender,
                    value: switch (_gender) {
                      'male' => l10n.onboardingMale,
                      'female' => l10n.onboardingFemale,
                      'other' => l10n.onboardingPreferNotToSay,
                      _ => _wellnessCopy(context, 'Select', 'اختر'),
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
                        'other' => 2,
                        _ => 0,
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
                    value:
                        _age?.toString() ??
                        _wellnessCopy(context, 'Select', 'اختر'),
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
                          selectedIndex: (_age ?? 28) - 16,
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
                    value: _height == null
                        ? _wellnessCopy(context, 'Select', 'اختر')
                        : '$_height cm',
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
                          selectedIndex: (_height ?? 170) - 130,
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
                    value: _weight == null
                        ? _wellnessCopy(context, 'Select', 'اختر')
                        : '$_weight kg',
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
                          selectedIndex: (_weight ?? 70) - 40,
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
            label: personalizationOptionLabel(
              dailyRoutineLabels,
              'OFFICE_WORK',
              language,
            ),
            selected: _lifestyle == 'OFFICE_WORK',
            onTap: () => _selectLifestyle('OFFICE_WORK'),
          ),
          _CompactOption(
            icon: Icons.home_work_outlined,
            label: personalizationOptionLabel(
              dailyRoutineLabels,
              'WORK_FROM_HOME',
              language,
            ),
            selected: _lifestyle == 'WORK_FROM_HOME',
            onTap: () => _selectLifestyle('WORK_FROM_HOME'),
          ),
          _CompactOption(
            icon: Icons.school_outlined,
            label: personalizationOptionLabel(
              dailyRoutineLabels,
              'STUDENT',
              language,
            ),
            selected: _lifestyle == 'STUDENT',
            onTap: () => _selectLifestyle('STUDENT'),
          ),
          _CompactOption(
            icon: Icons.directions_walk_rounded,
            label: personalizationOptionLabel(
              dailyRoutineLabels,
              'ACTIVE_JOB',
              language,
            ),
            selected: _lifestyle == 'ACTIVE_JOB',
            onTap: () => _selectLifestyle('ACTIVE_JOB'),
          ),
          _CompactOption(
            icon: Icons.nightlight_outlined,
            label: personalizationOptionLabel(
              dailyRoutineLabels,
              'SHIFT_WORKER',
              language,
            ),
            selected: _lifestyle == 'SHIFT_WORKER',
            onTap: () => _selectLifestyle('SHIFT_WORKER'),
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
            label: personalizationOptionLabel(
              activityLevelLabels,
              'MOSTLY_SITTING',
              language,
            ),
            selected: _activity == 'MOSTLY_SITTING',
            onTap: () => _selectActivity('MOSTLY_SITTING'),
          ),
          _ActivityCard(
            icon: Icons.directions_walk_rounded,
            label: personalizationOptionLabel(
              activityLevelLabels,
              'LIGHT_ACTIVITY',
              language,
            ),
            selected: _activity == 'LIGHT_ACTIVITY',
            onTap: () => _selectActivity('LIGHT_ACTIVITY'),
          ),
          _ActivityCard(
            icon: Icons.directions_run_rounded,
            label: personalizationOptionLabel(
              activityLevelLabels,
              'ACTIVE_LIFESTYLE',
              language,
            ),
            selected: _activity == 'ACTIVE_LIFESTYLE',
            onTap: () => _selectActivity('ACTIVE_LIFESTYLE'),
          ),
          _ActivityCard(
            icon: Icons.sports_gymnastics_rounded,
            label: personalizationOptionLabel(
              activityLevelLabels,
              'ATHLETE',
              language,
            ),
            selected: _activity == 'ATHLETE',
            onTap: () => _selectActivity('ATHLETE'),
          ),
        ],
      ),
    ),
    _StepFrame(
      title: l10n.onboardingPreferencesTitle,
      subtitle: l10n.onboardingPreferencesSubtitle,
      child: _ChoiceWrap(
        choices: {
          'HIGH_PROTEIN': l10n.onboardingHighProtein,
          'LOW_CARB': l10n.onboardingLowCarb,
          'VEGETARIAN': l10n.onboardingVegetarian,
          'VEGAN': l10n.onboardingVegan,
          'SEAFOOD': l10n.onboardingSeafood,
          'CHICKEN': l10n.onboardingChicken,
          'BEEF': l10n.onboardingBeef,
          'ARABIC_CUISINE': l10n.onboardingArabicCuisine,
          'INTERNATIONAL': l10n.onboardingInternational,
          'MEDITERRANEAN': l10n.onboardingMediterranean,
          'HEALTHY_SNACKS': l10n.onboardingHealthySnacks,
          'BREAKFAST_LOVER': l10n.onboardingBreakfastLover,
          'NONE': _wellnessCopy(
            context,
            'No food preferences',
            'لا توجد تفضيلات غذائية',
          ),
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
          TextField(
            key: const ValueKey('allergySearch'),
            onChanged: (value) => setState(() => _allergyQuery = value),
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: _wellnessCopy(
                context,
                'Search allergies...',
                'ابحث عن الحساسية...',
              ),
              suffixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.emeraldGreen,
                size: 24,
              ),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(
                  color: AppColors.darkGreen.withValues(alpha: .06),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.emeraldGreen,
                  width: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DynamicAllergenChoices(
            state: allergenState,
            query: _allergyQuery,
            selected: _allergies,
            onSelected: _toggleAllergy,
            onRetry: () => ref.invalidate(guestAllergensProvider(language)),
          ),
        ],
      ),
    ),
    _BmiSummaryStep(
      l10n: l10n,
      draft: ref.watch(personalizationControllerProvider),
    ),
    const _AllSetStep(),
  ];
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.showBack, required this.onBack});

  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 14, 12),
      child: Row(
        children: [
          if (showBack) ...[
            IconButton(
              key: const ValueKey('onboardingHeaderBack'),
              onPressed: onBack,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 30, height: 38),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.emeraldGreen,
                size: 21,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Container(
            width: 31,
            height: 31,
            decoration: const BoxDecoration(
              color: AppColors.emeraldGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppColors.white,
              size: 17,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.onboardingBrand,
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.current,
    required this.count,
    required this.completionPercentage,
  });

  final int current;
  final int count;
  final int completionPercentage;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).pageProgress(current + 1, count),
      child: Padding(
        key: const ValueKey('onboardingProgress'),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: SizedBox(
                height: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Color(0xFFD6E2DC)),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AnimatedFractionallySizedBox(
                        key: ValueKey(
                          'serverCompletionPercentage-$completionPercentage',
                        ),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        widthFactor: completionPercentage.clamp(0, 100) / 100,
                        heightFactor: 1,
                        child: const ColoredBox(color: AppColors.emeraldGreen),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (current > 0) ...[
              const SizedBox(height: 9),
              Text(
                '$completionPercentage%',
                key: const ValueKey('serverCompletionPercentageLabel'),
                style: const TextStyle(
                  color: AppColors.emeraldGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
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
    required this.isSaving,
    required this.canGoBack,
  });

  final int index;
  final VoidCallback onPrevious;
  final VoidCallback onContinue;
  final bool isSaving;
  final bool canGoBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = index == 0
        ? l10n.personalizationBegin
        : index == 7
        ? l10n.onboardingContinue
        : index == 8
        ? _wellnessCopy(context, 'Browse Menu', 'تصفح القائمة')
        : l10n.onboardingContinue;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 9, 20, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9).withValues(alpha: .96),
        border: Border(
          top: BorderSide(color: AppColors.darkGreen.withValues(alpha: .06)),
        ),
      ),
      child: index == 0
          ? AppButton(
              key: const ValueKey('onboardingContinue'),
              label: label,
              onPressed: isSaving ? null : onContinue,
              isLoading: isSaving,
            )
          : index == 8
          ? AppButton(
              key: const ValueKey('onboardingContinue'),
              label: label,
              onPressed: isSaving ? null : onContinue,
              isLoading: isSaving,
            )
          : Row(
              children: [
                if (canGoBack) ...[
                  TextButton.icon(
                    key: const ValueKey('onboardingPrevious'),
                    onPressed: isSaving ? null : onPrevious,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(l10n.onboardingPrevious),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.darkGreen,
                      minimumSize: const Size(104, AppButton.height),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: AppButton(
                    key: const ValueKey('onboardingContinue'),
                    label: label,
                    onPressed: isSaving ? null : onContinue,
                    isLoading: isSaving,
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
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0, constraints.maxHeight - 28),
            maxWidth: 620,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 27,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .62),
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
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
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 36),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.personalizationIntroTitle,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: compact ? 29 : 33,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.personalizationIntroSubtitle,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .64),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: compact ? 10 : 18),
                _WelcomeArtwork(height: compact ? 230 : 290),
                SizedBox(height: compact ? 8 : 16),
                const _WelcomeBenefits(),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    key: const ValueKey('personalizationNotNow'),
                    onPressed: onNotNow,
                    child: Text(
                      l10n.personalizationNotNow,
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
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
        alignment: Alignment.center,
        children: [
          Container(
            width: height * .82,
            height: height * .82,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4E7),
              shape: BoxShape.circle,
              boxShadow: _cardShadow(.12),
            ),
            child: Image.asset(
              'assets/images/onboarding_1.png',
              key: const ValueKey('onboardingWelcomeImage'),
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ),
          PositionedDirectional(
            start: 6,
            bottom: 20,
            child: Transform.rotate(
              angle: -.35,
              child: const Icon(
                Icons.energy_savings_leaf_rounded,
                color: Color(0xFFB8D0A4),
                size: 56,
              ),
            ),
          ),
          PositionedDirectional(
            end: 4,
            top: 30,
            child: Transform.rotate(
              angle: .42,
              child: const Icon(
                Icons.eco_rounded,
                color: Color(0xFFC5D9B4),
                size: 48,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBenefits extends StatelessWidget {
  const _WelcomeBenefits();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.person_rounded, 'Personalized'),
      (Icons.balance_rounded, 'Balanced'),
      (Icons.favorite_rounded, 'Made for you'),
    ];
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Column(
                children: [
                  Icon(item.$1, color: const Color(0xFF68A96E), size: 24),
                  const SizedBox(height: 6),
                  Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
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
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFF006A4E), Color(0xFF007A58)],
              )
            : null,
        color: selected ? null : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
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
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.white.withValues(alpha: .14)
                        : const Color(0xFFDDF4EA),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? AppColors.white : AppColors.emeraldGreen,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: foreground.withValues(alpha: .70),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedScale(
                  scale: 1,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected
                        ? AppColors.white
                        : AppColors.darkGreen.withValues(alpha: .30),
                    size: 21,
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
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.emeraldGreen.withValues(alpha: .10),
              ),
              boxShadow: _cardShadow(.05),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.emeraldGreen, size: 24),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: AppColors.darkGreen.withValues(alpha: .60),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.emeraldGreen,
                  size: 22,
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
        final width = constraints.maxWidth;
        return Wrap(
          runSpacing: 9,
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
      height: 68,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F6EF),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: AppColors.emeraldGreen, size: 25),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 13,
                      height: 1.18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected
                      ? AppColors.emeraldGreen
                      : AppColors.darkGreen.withValues(alpha: .28),
                  size: 20,
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
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF0F6ED) : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.emeraldGreen.withValues(alpha: selected ? .65 : .10),
        ),
        boxShadow: _cardShadow(selected ? .14 : .05),
      ),
      child: ListTile(
        minTileHeight: 66,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        leading: Icon(icon, color: AppColors.emeraldGreen, size: 27),
        title: Text(
          label,
          style: TextStyle(
            color: AppColors.darkGreen,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        trailing: Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: selected
              ? AppColors.emeraldGreen
              : AppColors.emeraldGreen.withValues(alpha: .24),
        ),
      ),
    );
  }
}

class _DynamicAllergenChoices extends StatelessWidget {
  const _DynamicAllergenChoices({
    required this.state,
    required this.query,
    required this.selected,
    required this.onSelected,
    required this.onRetry,
  });

  final AsyncValue<List<GuestAllergen>> state;
  final String query;
  final Set<String> selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return state.when(
      data: (allergens) {
        final normalizedQuery = query.trim().toLowerCase();
        final filtered = allergens
            .where(
              (allergen) =>
                  normalizedQuery.isEmpty ||
                  allergen.name.toLowerCase().contains(normalizedQuery) ||
                  allergen.code.toLowerCase().contains(normalizedQuery),
            )
            .toList(growable: false);
        final showNone =
            normalizedQuery.isEmpty ||
            l10n.onboardingNoAllergies.toLowerCase().contains(normalizedQuery);
        return Column(
          children: [
            _ChoiceWrap(
              leadingIcon: Icons.health_and_safety_outlined,
              choices: {
                for (final allergen in filtered) allergen.id: allergen.name,
                if (showNone) 'none': l10n.onboardingNoAllergies,
              },
              choiceCodes: {
                for (final allergen in filtered) allergen.id: allergen.code,
              },
              selected: selected,
              onSelected: onSelected,
            ),
            if (normalizedQuery.isEmpty) ...[
              const SizedBox(height: 14),
              const _AllergenSafetyCard(),
            ],
          ],
        );
      },
      loading: () => Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(
              color: AppColors.emeraldGreen,
              strokeWidth: 2.5,
            ),
          ),
          _ChoiceWrap(
            leadingIcon: Icons.health_and_safety_outlined,
            choices: {'none': l10n.onboardingNoAllergies},
            selected: selected,
            onSelected: onSelected,
          ),
        ],
      ),
      error: (error, stackTrace) => Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EC),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.portlandOrange.withValues(alpha: .18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.portlandOrange,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _wellnessCopy(
                      context,
                      'Unable to load allergens.',
                      'تعذر تحميل مسببات الحساسية.',
                    ),
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  key: const ValueKey('retryAllergens'),
                  onPressed: onRetry,
                  child: Text(
                    _wellnessCopy(context, 'Retry', 'إعادة المحاولة'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ChoiceWrap(
            leadingIcon: Icons.health_and_safety_outlined,
            choices: {'none': l10n.onboardingNoAllergies},
            selected: selected,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class _AllergenSafetyCard extends StatelessWidget {
  const _AllergenSafetyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5EC),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.emeraldGreen.withValues(alpha: .055),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.health_and_safety_outlined,
            color: AppColors.emeraldGreen,
            size: 31,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _wellnessCopy(
                      context,
                      'Your health & safety is our priority.\n',
                      'صحتك وسلامتك هي أولويتنا.\n',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  TextSpan(
                    text: _wellnessCopy(
                      context,
                      "We'll always highlight meals that are safe for you.",
                      'سنوضح لك دائمًا الوجبات الآمنة لك.',
                    ),
                  ),
                ],
              ),
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ),
        ],
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
    this.choiceCodes = const {},
  });

  final Map<String, String> choices;
  final Map<String, String> choiceCodes;
  final Set<String> selected;
  final ValueChanged<String> onSelected;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    if (leadingIcon != null) {
      final regularChoices = choices.entries
          .where((entry) => entry.key != 'none')
          .toList(growable: false);
      final noAllergies = choices.entries
          .where((entry) => entry.key == 'none')
          .firstOrNull;

      Widget allergyRow(
        MapEntry<String, String> entry, {
        required bool showDivider,
      }) {
        final isSelected = selected.contains(entry.key);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              key: ValueKey('choice-${entry.key}'),
              height: 47,
              child: InkWell(
                onTap: () => onSelected(entry.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 25,
                        child: Text(
                          _choiceEmoji(choiceCodes[entry.key] ?? entry.key),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 21, height: 1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 21,
                        color: isSelected
                            ? AppColors.emeraldGreen
                            : AppColors.darkGreen.withValues(alpha: .28),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                indent: 47,
                color: AppColors.darkGreen.withValues(alpha: .075),
              ),
          ],
        );
      }

      return Column(
        children: [
          if (regularChoices.isNotEmpty)
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.darkGreen.withValues(alpha: .055),
                ),
                boxShadow: _cardShadow(.045),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < regularChoices.length; index++)
                    allergyRow(
                      regularChoices[index],
                      showDivider: index < regularChoices.length - 1,
                    ),
                ],
              ),
            ),
          if (noAllergies != null) ...[
            if (regularChoices.isNotEmpty) const SizedBox(height: 13),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.darkGreen.withValues(alpha: .055),
                ),
                boxShadow: _cardShadow(.045),
              ),
              child: allergyRow(noAllergies, showDivider: false),
            ),
          ],
          if (choices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Text(
                _wellnessCopy(
                  context,
                  'No allergies found.',
                  'لم يتم العثور على حساسية.',
                ),
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .55),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 16) / 3;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: choices.entries
              .map((entry) {
                final isSelected = selected.contains(entry.key);
                return InkWell(
                  key: ValueKey('choice-${entry.key}'),
                  onTap: () => onSelected(entry.key),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: tileWidth,
                    height: 86,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF0F6ED)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.emeraldGreen.withValues(
                          alpha: isSelected ? .55 : .09,
                        ),
                      ),
                      boxShadow: _cardShadow(.04),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _choiceIcon(entry.key),
                                color: AppColors.emeraldGreen,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                entry.value,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.darkGreen,
                                  fontSize: 10,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const PositionedDirectional(
                            end: 0,
                            top: 0,
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.emeraldGreen,
                              size: 17,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  IconData _choiceIcon(String key) =>
      switch (key.replaceAll('_', '').toLowerCase()) {
        'protein' => Icons.fitness_center_rounded,
        'lowcarb' => Icons.eco_rounded,
        'vegetarian' || 'vegan' => Icons.spa_rounded,
        'seafood' || 'fish' || 'shellfish' => Icons.set_meal_rounded,
        'chicken' => Icons.dinner_dining_rounded,
        'beef' => Icons.lunch_dining_rounded,
        'arabic' || 'international' || 'mediterranean' => Icons.public_rounded,
        'snacks' => Icons.cookie_rounded,
        'breakfast' || 'egg' => Icons.egg_alt_rounded,
        'milk' => Icons.local_drink_rounded,
        'treenuts' || 'peanuts' => Icons.grass_rounded,
        'soy' || 'sesame' || 'gluten' => Icons.grain_rounded,
        'none' => Icons.health_and_safety_rounded,
        _ => Icons.restaurant_rounded,
      };

  String _choiceEmoji(String key) =>
      switch (key.replaceAll('_', '').toLowerCase()) {
        'celery' => '🥬',
        'crustaceans' || 'crustacean' => '🦀',
        'egg' || 'eggs' => '🥚',
        'fish' => '🐟',
        'gluten' || 'glutencereals' || 'cerealscontaininggluten' => '🌾',
        'lupin' => '🪻',
        'milk' => '🍼',
        'molluscs' || 'mollusks' => '🐚',
        'mustard' => '🫙',
        'peanuts' => '🥜',
        'sesame' => '🫘',
        'soy' || 'soybeans' => '🫛',
        'sulphites' || 'sulfites' => '⚗️',
        'treenuts' => '🌰',
        'shellfish' => '🦐',
        'none' => '🛡️',
        _ => '🍽️',
      };
}

class _BmiSummaryStep extends StatelessWidget {
  const _BmiSummaryStep({required this.l10n, required this.draft});

  final AppLocalizations l10n;
  final PersonalizationDraft draft;

  @override
  Widget build(BuildContext context) {
    final bmi = draft.bmi ?? _bmiFromMeasurements(draft) ?? 0;
    final marker = ((bmi.clamp(14, 40) - 14) / 26).toDouble();
    final category = bmi <= 0
        ? _wellnessCopy(context, 'Pending', 'قيد الحساب')
        : draft.age < 18
        ? l10n.bmiYouthNote
        : bmi < 18.5
        ? l10n.bmiBelowRange
        : bmi < 25
        ? l10n.bmiWithinRange
        : bmi < 30
        ? l10n.bmiAboveRange
        : l10n.bmiWellAboveRange;
    final language = Localizations.localeOf(context).languageCode;
    final goal = personalizationOptionLabel(
      goalLabels,
      draft.primaryGoal ?? 'EAT_HEALTHIER',
      language,
    );
    final activity = personalizationOptionLabel(
      activityLevelLabels,
      draft.activityLevel ?? 'LIGHT_ACTIVITY',
      language,
    );
    final calorieTarget = draft.nutritionTargets?.calories?.round();
    final proteinTarget = draft.nutritionTargets?.proteinGrams?.round();
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0, constraints.maxHeight - 14),
          ),
          child: Column(
            children: [
              const _WellnessSuccessBadge(),
              const SizedBox(height: 8),
              Text(
                l10n.bmiSummaryTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 21,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _wellnessCopy(
                  context,
                  "Here's a quick overview of you.",
                  'إليك نظرة سريعة على بياناتك.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .62),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                key: const ValueKey('bmiRange'),
                height: 170,
                padding: const EdgeInsets.fromLTRB(14, 15, 12, 15),
                decoration: _wellnessCardDecoration(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 103,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _wellnessCopy(
                              context,
                              'Your BMI',
                              'مؤشر كتلة جسمك',
                            ),
                            style: TextStyle(
                              color: AppColors.darkGreen.withValues(alpha: .62),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bmi.toStringAsFixed(1),
                            key: const ValueKey('bmiValue'),
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontSize: 34,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4F4E5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category,
                              maxLines: 2,
                              style: const TextStyle(
                                color: AppColors.emeraldGreen,
                                fontSize: 9,
                                height: 1.05,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBFD8CB),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    Expanded(
                      child: _BmiScale(marker: marker, bmi: bmi),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _WellnessTile(
                      icon: Icons.track_changes_rounded,
                      label: _wellnessCopy(context, 'Goal', 'الهدف'),
                      value: goal,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _WellnessTile(
                      icon: Icons.directions_walk_rounded,
                      label: _wellnessCopy(
                        context,
                        'Activity Level',
                        'مستوى النشاط',
                      ),
                      value: activity,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: _WellnessTile(
                      icon: Icons.local_fire_department_outlined,
                      label: l10n.caloriesLabel,
                      value: calorieTarget == null
                          ? '—'
                          : l10n.dailyCalories(calorieTarget),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _WellnessTile(
                      icon: Icons.fitness_center_rounded,
                      label: '${l10n.proteinLabel} Target',
                      value: proteinTarget == null
                          ? '—'
                          : '$proteinTarget g/day',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 94),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5E9),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.emeraldGreen,
                      size: 25,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: _wellnessCopy(
                                context,
                                "Great! We'll use this information to\n",
                                'رائع! سنستخدم هذه المعلومات\n',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(
                              text: _wellnessCopy(
                                context,
                                'personalize your Diet Time experience.',
                                'لتخصيص تجربتك مع دايت تايم.',
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 10,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: Icon(
                        Icons.eco_rounded,
                        color: Color(0xFF58A56B),
                        size: 42,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WellnessSuccessBadge extends StatelessWidget {
  const _WellnessSuccessBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 94,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final item in const [
            (Alignment(-.72, -.35), Color(0xFF74C99D), 4.0),
            (Alignment(-.56, .35), Color(0xFFF1C75B), 3.0),
            (Alignment(.67, -.24), Color(0xFFEF7C5B), 4.0),
            (Alignment(.52, .42), Color(0xFFA7D36F), 3.0),
            (Alignment(-.28, -.78), Color(0xFF76B82A), 3.0),
            (Alignment(.25, -.74), Color(0xFFF1C75B), 3.0),
          ])
            Align(
              alignment: item.$1,
              child: Container(
                width: item.$3,
                height: item.$3,
                decoration: BoxDecoration(
                  color: item.$2,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2F2E4), width: 8),
              boxShadow: _cardShadow(.13),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.white,
              size: 43,
              weight: 900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BmiScale extends StatelessWidget {
  const _BmiScale({required this.marker, required this.bmi});

  final double marker;
  final double bmi;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const markerWidth = 44.0;
        final markerLeft =
            (marker.clamp(0.0, 1.0) * availableWidth - markerWidth / 2)
                .clamp(0.0, math.max(0.0, availableWidth - markerWidth))
                .toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _wellnessCopy(context, 'BMI Scale', 'مقياس كتلة الجسم'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGreen.withValues(alpha: .62),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            SizedBox(
              width: double.infinity,
              height: 49,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 3,
                    height: 11,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: const Row(
                        children: [
                          Expanded(child: ColoredBox(color: Color(0xFF8EDCF0))),
                          Expanded(child: ColoredBox(color: Color(0xFF9BCB37))),
                          Expanded(child: ColoredBox(color: Color(0xFFFFCD3C))),
                          Expanded(child: ColoredBox(color: Color(0xFFFF5F42))),
                        ],
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    left: markerLeft,
                    top: 0,
                    child: SizedBox(
                      key: const ValueKey('bmiScaleMarker'),
                      width: markerWidth,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              boxShadow: _cardShadow(.12),
                            ),
                            child: Text(
                              bmi.toStringAsFixed(1),
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 7,
                            color: AppColors.emeraldGreen,
                          ),
                          Container(
                            key: const ValueKey('bmiScaleIndicatorDot'),
                            width: 17,
                            height: 17,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.emeraldGreen,
                                width: 4,
                              ),
                              boxShadow: _cardShadow(.18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              textDirection: TextDirection.ltr,
              children: [
                Expanded(child: _ScaleLabel('Under', '<18.5')),
                Expanded(child: _ScaleLabel('Normal', '18.5–24.9')),
                Expanded(child: _ScaleLabel('Over', '25–29.9')),
                Expanded(child: _ScaleLabel('Obese', '30+')),
              ],
            ),
          ],
        );
      },
    );
  }
}

double? _bmiFromMeasurements(CustomerProfile profile) {
  final heightCm = profile.heightCm;
  final weightKg = profile.weightKg;
  if (heightCm == null || weightKg == null || heightCm <= 0 || weightKg <= 0) {
    return null;
  }
  final heightM = heightCm / 100;
  return weightKg / (heightM * heightM);
}

class _ScaleLabel extends StatelessWidget {
  const _ScaleLabel(this.label, this.range);

  final String label;
  final String range;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label\n$range',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.darkGreen,
        fontSize: 6.8,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _WellnessTile extends StatelessWidget {
  const _WellnessTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _wellnessCardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: AppColors.emeraldGreen, size: 28),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .58),
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
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

BoxDecoration _wellnessCardDecoration() => BoxDecoration(
  color: AppColors.white,
  borderRadius: BorderRadius.circular(AppRadius.md),
  border: Border.all(color: AppColors.darkGreen.withValues(alpha: .045)),
  boxShadow: _cardShadow(.045),
);

String _wellnessCopy(BuildContext context, String english, String arabic) =>
    Localizations.localeOf(context).languageCode == 'ar' ? arabic : english;

class _AllSetStep extends StatelessWidget {
  const _AllSetStep();

  @override
  Widget build(BuildContext context) {
    final items = [
      _wellnessCopy(context, 'Your goals', 'أهدافك'),
      _wellnessCopy(context, 'Your profile', 'ملفك الشخصي'),
      _wellnessCopy(context, 'Your lifestyle', 'نمط حياتك'),
      _wellnessCopy(context, 'Your food preferences', 'تفضيلاتك الغذائية'),
      _wellnessCopy(context, 'Your health & allergies', 'صحتك والحساسيات'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 560;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 18),
            ),
            child: Column(
              children: [
                _AllSetArtwork(height: compact ? 190 : 230),
                SizedBox(height: compact ? 9 : 17),
                Text(
                  _wellnessCopy(context, "You're all set!", 'أنت جاهز!'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _wellnessCopy(
                    context,
                    "We've saved your nutrition profile.\n"
                        "You can now explore the Diet Time menu.",
                    'لقد حفظنا ملفك الغذائي.\nيمكنك الآن تصفح قائمة دايت تايم.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .65),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: compact ? 17 : 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: Column(
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 13),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: AppColors.emeraldGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.white,
                                    size: 15,
                                    weight: 900,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      color: AppColors.darkGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AllSetArtwork extends StatelessWidget {
  const _AllSetArtwork({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: height * .90,
            height: height * .90,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4E8),
              shape: BoxShape.circle,
            ),
          ),
          PositionedDirectional(
            start: 15,
            bottom: 18,
            child: Transform.rotate(
              angle: -.35,
              child: Icon(
                Icons.energy_savings_leaf_rounded,
                size: height * .32,
                color: const Color(0xFFB9D2AD),
              ),
            ),
          ),
          ClipOval(
            child: Container(
              width: height * .72,
              height: height * .72,
              color: const Color(0xFF07130E),
              child: Image.asset(
                'assets/images/onboarding_1.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                excludeFromSemantics: true,
              ),
            ),
          ),
          PositionedDirectional(
            end: 31,
            bottom: 13,
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 5),
                boxShadow: _cardShadow(.14),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.white,
                size: 31,
                weight: 900,
              ),
            ),
          ),
        ],
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
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFDF9), Color(0xFFFBF9F4)],
            ),
          ),
        ),
        PositionedDirectional(
          top: 80,
          end: -150,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEAF3E3).withValues(alpha: .30),
            ),
          ),
        ),
        PositionedDirectional(
          bottom: -80,
          start: -150,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF3EDE0).withValues(alpha: .42),
            ),
          ),
        ),
      ],
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
