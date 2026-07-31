import 'dart:async';

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/app/theme/app_spacing.dart';
import 'package:diet_time/features/authentication/data/mock_authentication_service.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/language/presentation/language_controller.dart';
import 'package:diet_time/features/menu/data/guest_menu_repository.dart';
import 'package:diet_time/features/menu/domain/guest_home_models.dart';
import 'package:diet_time/features/menu/presentation/meal_detail_viewer.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BrowseMenuScreen extends ConsumerStatefulWidget {
  const BrowseMenuScreen({super.key});

  @override
  ConsumerState<BrowseMenuScreen> createState() => _BrowseMenuScreenState();
}

class _BrowseMenuScreenState extends ConsumerState<BrowseMenuScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _planScrollController = ScrollController();
  final ScrollController _dateScrollController = ScrollController();
  final ScrollController _filterScrollController = ScrollController();
  GuestHomeData? _homeData;
  GuestMenuData? _menuData;
  final Map<String, GuestMenuData> _menuCache = {};
  List<GuestMeal> _visibleMeals = const [];
  String? _language;
  String? _selectedPlanCode;
  DateTime? _selectedDate;
  String _selectedMealTimeCode = 'ALL';
  bool _isHomeLoading = false;
  bool _isHomeRefreshing = false;
  bool _isMenuLoading = false;
  bool _hasLoaded = false;
  bool _hasHomeError = false;
  bool _hasMenuError = false;
  int _homeRequestId = 0;
  int _menuRequestId = 0;
  int _selectionRequestId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_language == language) return;
    final isLanguageChange = _language != null;
    _language = language;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadHome(
          force: isLanguageChange,
          preserveSelections: isLanguageChange,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _planScrollController.dispose();
    _dateScrollController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHome({
    bool force = false,
    bool preserveSelections = true,
  }) async {
    if (!force && (_hasLoaded || _isHomeLoading || _isHomeRefreshing)) {
      return;
    }
    final selectionRequestId = ++_selectionRequestId;
    final homeRequestId = ++_homeRequestId;
    ++_menuRequestId;
    final hadData = _homeData != null;
    setState(() {
      _hasHomeError = false;
      _hasMenuError = false;
      if (!hadData) {
        _isHomeLoading = true;
      } else {
        _isHomeRefreshing = true;
        _isMenuLoading = true;
      }
    });
    try {
      final response = await ref
          .read(guestMenuRepositoryProvider)
          .getGuestHome(
            language: _language ?? 'en',
            date: preserveSelections ? _selectedDate : null,
            planCode: preserveSelections ? _selectedPlanCode : null,
          );
      if (!mounted ||
          homeRequestId != _homeRequestId ||
          selectionRequestId != _selectionRequestId) {
        return;
      }
      final data = response.data;
      final planCode = _resolvePlan(
        data,
        preserveSelections ? _selectedPlanCode : null,
      );
      final selectedDate = _resolveDate(
        data,
        preserveSelections ? _selectedDate : null,
      );
      setState(() {
        _homeData = data;
        _selectedPlanCode = planCode;
        _selectedDate = selectedDate;
        _isHomeLoading = false;
        _isHomeRefreshing = false;
        _hasLoaded = true;
      });
      if (planCode != null && selectedDate != null) {
        await _loadMenu(
          planCode: planCode,
          date: selectedDate,
          selectionRequestId: selectionRequestId,
          force: force,
        );
      } else {
        setState(() {
          _menuData = null;
          _visibleMeals = const [];
          _isMenuLoading = false;
        });
      }
    } on Object {
      if (!mounted ||
          homeRequestId != _homeRequestId ||
          selectionRequestId != _selectionRequestId) {
        return;
      }
      setState(() {
        _isHomeLoading = false;
        _isHomeRefreshing = false;
        _isMenuLoading = false;
        _hasHomeError = true;
      });
    }
  }

  String? _resolvePlan(GuestHomeData data, String? preferredCode) {
    if (preferredCode != null &&
        data.mealPlans.any((plan) => plan.code == preferredCode)) {
      return preferredCode;
    }
    return _firstSelected(data.mealPlans, (plan) => plan.isSelected)?.code ??
        data.mealPlans.firstOrNull?.code;
  }

  DateTime? _resolveDate(GuestHomeData data, DateTime? preferredDate) {
    if (preferredDate != null && _isDateAvailable(data, preferredDate)) {
      return preferredDate;
    }
    final initiallySelected = _firstSelected(
      data.weeklyCalendar,
      (item) => item.isSelected && item.isAvailable && item.date != null,
    )?.date;
    if (initiallySelected != null) return initiallySelected;
    return data.weeklyCalendar
        .where((item) => item.isAvailable && item.date != null)
        .firstOrNull
        ?.date;
  }

  Future<void> _selectPlan(GuestMealPlan plan) async {
    final planCode = plan.code;
    if (_homeData == null ||
        planCode.trim().isEmpty ||
        planCode == _selectedPlanCode) {
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    await _refreshSelection(planCode: planCode, date: _selectedDate);
  }

  Future<void> _refreshSelection({
    required String planCode,
    required DateTime? date,
  }) async {
    if (planCode.trim().isEmpty || date == null) {
      return;
    }
    final selectionRequestId = ++_selectionRequestId;
    final homeRequestId = ++_homeRequestId;
    ++_menuRequestId;
    setState(() {
      _selectedPlanCode = planCode;
      _selectedDate = date;
      _isHomeRefreshing = true;
      _isMenuLoading = true;
      _hasHomeError = false;
      _hasMenuError = false;
    });
    try {
      final response = await ref
          .read(guestMenuRepositoryProvider)
          .getGuestHome(
            language: _language ?? 'en',
            date: date,
            planCode: planCode,
          );
      if (!mounted ||
          selectionRequestId != _selectionRequestId ||
          homeRequestId != _homeRequestId) {
        return;
      }
      final data = response.data;
      final selectedPlanCode =
          _firstSelected(data.mealPlans, (plan) => plan.isSelected)?.code ??
          _resolvePlan(data, planCode);
      final selectedDate = _resolveDate(data, date);
      setState(() {
        _homeData = data;
        _selectedPlanCode = selectedPlanCode;
        _selectedDate = selectedDate;
        _isHomeRefreshing = false;
        _hasLoaded = true;
      });
      if (selectedPlanCode != null && selectedDate != null) {
        await _loadMenu(
          planCode: selectedPlanCode,
          date: selectedDate,
          selectionRequestId: selectionRequestId,
        );
      } else {
        setState(() {
          _menuData = null;
          _visibleMeals = const [];
          _isMenuLoading = false;
        });
      }
    } on Object {
      if (!mounted ||
          selectionRequestId != _selectionRequestId ||
          homeRequestId != _homeRequestId) {
        return;
      }
      setState(() {
        _isHomeRefreshing = false;
        _isMenuLoading = false;
        _hasHomeError = true;
      });
    }
  }

  Future<void> _selectDate(GuestCalendarDate date) async {
    final data = _homeData;
    if (data == null ||
        !date.isAvailable ||
        _sameDate(date.date, _selectedDate) ||
        date.date == null ||
        _selectedPlanCode == null) {
      return;
    }
    await _refreshSelection(planCode: _selectedPlanCode!, date: date.date);
  }

  void _selectMealTime(GuestMealTime filter) {
    if (_menuData == null ||
        normalizeMealTimeCode(filter.code) ==
            normalizeMealTimeCode(_selectedMealTimeCode)) {
      return;
    }
    setState(() {
      _selectedMealTimeCode = filter.code;
      _visibleMeals = _filterMeals(_menuData!, filter.code);
    });
  }

  Future<void> _loadMenu({
    required String planCode,
    required DateTime date,
    required int selectionRequestId,
    bool force = false,
  }) async {
    final language = _language ?? 'en';
    final cacheKey = _menuCacheKey(language, planCode, date);
    final cached = _menuCache[cacheKey];
    if (!force && cached != null) {
      if (!mounted || selectionRequestId != _selectionRequestId) return;
      _applyMenu(cached);
      return;
    }
    final menuRequestId = ++_menuRequestId;
    setState(() {
      _isMenuLoading = true;
      _hasMenuError = false;
    });
    try {
      final response = await ref
          .read(guestMenuRepositoryProvider)
          .getGuestMenu(planCode: planCode, date: date, language: language);
      if (!mounted ||
          selectionRequestId != _selectionRequestId ||
          menuRequestId != _menuRequestId) {
        return;
      }
      _menuCache[cacheKey] = response.data;
      _applyMenu(response.data);
    } on Object {
      if (!mounted ||
          selectionRequestId != _selectionRequestId ||
          menuRequestId != _menuRequestId) {
        return;
      }
      setState(() {
        _isMenuLoading = false;
        _hasMenuError = true;
        _menuData = null;
        _visibleMeals = const [];
      });
    }
  }

  void _applyMenu(GuestMenuData data) {
    final filters = _filtersFor(data);
    final hasSelectedFilter = filters.any(
      (filter) =>
          normalizeMealTimeCode(filter.code) ==
          normalizeMealTimeCode(_selectedMealTimeCode),
    );
    final selectedMealTimeCode = hasSelectedFilter
        ? _selectedMealTimeCode
        : 'ALL';
    final visibleMeals = _filterMeals(data, selectedMealTimeCode);
    setState(() {
      _menuData = data;
      _selectedMealTimeCode = selectedMealTimeCode;
      _visibleMeals = visibleMeals;
      _isMenuLoading = false;
      _hasMenuError = false;
    });
    final home = _homeData;
    if (home != null) {
      _precacheMenuImages(home, _selectedPlanCode, visibleMeals);
    }
  }

  List<GuestMealTime> _filtersFor(GuestMenuData? data) {
    final filters = <GuestMealTime>[
      GuestMealTime(code: 'ALL', name: _language == 'ar' ? 'الكل' : 'All'),
    ];
    final seen = <String>{'ALL'};
    for (final slot in data?.slots ?? const <GuestMenuSlot>[]) {
      final normalized = normalizeMealTimeCode(slot.mealTime.code);
      if (normalized.isNotEmpty && seen.add(normalized)) {
        filters.add(slot.mealTime);
      }
    }
    return filters;
  }

  void _keepFilterVisible(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_filterScrollController.hasClients) return;
      final position = _filterScrollController.position;
      final target = (index * 104.0).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _filterScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _changeLanguage(String languageCode) {
    if (languageCode == _language) return;
    ref
        .read(languageControllerProvider.notifier)
        .setLocale(Locale(languageCode));
  }

  void _precacheMenuImages(
    GuestHomeData data,
    String? selectedPlanCode,
    List<GuestMeal> meals,
  ) {
    final selectedPlan = data.mealPlans
        .where((plan) => plan.code == selectedPlanCode)
        .firstOrNull;
    final heroUrl = resolveMediaUrl(selectedPlan?.imageUrl);
    final urls = <String>{
      heroUrl,
      for (final meal in meals.take(6))
        resolveMediaUrl(
          (meal.thumbnailUrl ?? '').isNotEmpty
              ? meal.thumbnailUrl
              : meal.imageUrl,
        ),
      for (final plan in data.mealPlans) resolveMediaUrl(plan.imageUrl),
    }..removeWhere((url) => url.isEmpty);
    for (final url in urls) {
      unawaited(_precacheImage(url));
    }
  }

  Future<void> _precacheImage(String url) async {
    try {
      await precacheImage(
        NetworkImage(url),
        context,
        onError: (_, _) {
          // The normal image placeholder remains available.
        },
      );
    } on Object {
      // The normal image placeholder remains available if preloading fails.
    }
  }

  bool _isDateAvailable(GuestHomeData data, DateTime? date) {
    if (date == null) return false;
    return data.weeklyCalendar.any(
      (item) => item.isAvailable && _sameDate(item.date, date),
    );
  }

  List<GuestMeal> _filterMeals(GuestMenuData data, String filterCode) {
    final meals = data.meals;
    final normalizedFilter = normalizeMealTimeCode(filterCode);
    final filtered = normalizedFilter == 'ALL'
        ? meals
        : meals.where(
            (meal) =>
                normalizeMealTimeCode(meal.mealTime.code) == normalizedFilter,
          );
    return filtered.toList(growable: false)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  Future<void> _startPlan() async {
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

  Widget _startPlanButton(AppLocalizations l10n) {
    return FloatingActionButton.extended(
      key: const ValueKey('guestStartPlan'),
      onPressed: () => unawaited(_startPlan()),
      backgroundColor: AppColors.emeraldGreen,
      foregroundColor: AppColors.white,
      label: Text(
        l10n.onboardingStartPlan,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isHomeLoading || (_homeData == null && !_hasHomeError)) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F8F3),
        floatingActionButton: _startPlanButton(l10n),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: _MealContentLoader(
                  key: const ValueKey('guestHomeLoader'),
                  title: l10n.mealContentLoadingTitle,
                  subtitle: l10n.mealContentLoadingSubtitle,
                  fullPage: true,
                ),
              ),
              if (Navigator.of(context).canPop())
                PositionedDirectional(
                  top: AppSpacing.md,
                  start: AppSpacing.md,
                  child: const _GuestMenuBackButton(),
                ),
            ],
          ),
        ),
      );
    }
    if (_homeData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F8F3),
        floatingActionButton: _startPlanButton(l10n),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: _GuestMenuError(
                  message: l10n.guestMenuLoadError,
                  retryLabel: l10n.retry,
                  onRetry: () => _loadHome(force: true),
                ),
              ),
              if (Navigator.of(context).canPop())
                const PositionedDirectional(
                  top: AppSpacing.md,
                  start: AppSpacing.md,
                  child: _GuestMenuBackButton(),
                ),
            ],
          ),
        ),
      );
    }

    final data = _homeData!;
    final plans = [...data.mealPlans]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final filters = _filtersFor(_menuData);
    final meals = _visibleMeals;
    final selectedPlan = plans
        .where((plan) => plan.code == _selectedPlanCode)
        .firstOrNull;
    final width = MediaQuery.sizeOf(context).width;
    const columns = 2;
    final compactMealCards = width < 680;
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1, 1.4).toDouble();
    final mealCardExtent = compactMealCards
        ? 315 + ((textScale - 1) * 420)
        : 365 + ((textScale - 1) * 220);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      floatingActionButton: _startPlanButton(l10n),
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.emeraldGreen,
              onRefresh: () => _loadHome(force: true),
              child: CustomScrollView(
                controller: _scrollController,
                key: const PageStorageKey('guestMenuScroll'),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    sliver: SliverList.list(
                      children: [
                        Row(
                          children: [
                            if (Navigator.of(context).canPop())
                              const _GuestMenuBackButton()
                            else
                              const SizedBox(width: 48),
                            const Spacer(),
                            _GuestLanguageSelector(
                              languageCode: _language ?? 'en',
                              onSelected: _changeLanguage,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _GuestMenuHeader(
                          plan: selectedPlan,
                          title: l10n.mealPlanHeaderTitle,
                          subtitle: l10n.mealPlanHeaderSubtitle,
                        ),
                        const SizedBox(height: 22),
                        _SectionTitle(label: l10n.guestMealPlansTitle),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 68 + ((textScale - 1) * 12),
                          child: ListView.separated(
                            key: const ValueKey('guestPlanScroller'),
                            controller: _planScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            itemCount: plans.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final plan = plans[index];
                              return _GuestPlanCard(
                                key: ValueKey('guest-plan-${plan.code}'),
                                plan: plan,
                                selected: plan.code == _selectedPlanCode,
                                onTap: () => unawaited(_selectPlan(plan)),
                              );
                            },
                          ),
                        ),
                        if (_hasHomeError) ...[
                          const SizedBox(height: 16),
                          _InlineError(
                            message: l10n.guestPlanLoadError,
                            retryLabel: l10n.retry,
                            onRetry: () {
                              final planCode = _selectedPlanCode;
                              final date = _selectedDate;
                              if (planCode == null || date == null) {
                                unawaited(_loadHome(force: true));
                                return;
                              }
                              unawaited(
                                _refreshSelection(
                                  planCode: planCode,
                                  date: date,
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _GuestMenuFiltersHeader(
                      title: l10n.guestWeeklyMenuTitle,
                      data: data,
                      filters: filters,
                      selectedPlanCode: _selectedPlanCode,
                      selectedDate: _selectedDate,
                      selectedMealTimeCode: _selectedMealTimeCode,
                      dateScrollController: _dateScrollController,
                      filterScrollController: _filterScrollController,
                      textScale: textScale,
                      isDateAvailable: (date) => _isDateAvailable(data, date),
                      onDateSelected: (date) => unawaited(_selectDate(date)),
                      onFilterSelected: (filter, index) {
                        _selectMealTime(filter);
                        _keepFilterVisible(index);
                      },
                    ),
                  ),
                  if (_isMenuLoading)
                    SliverPadding(
                      key: const ValueKey('guestMealResultsLoading'),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: compactMealCards ? 12 : 16,
                          crossAxisSpacing: compactMealCards ? 12 : 16,
                          mainAxisExtent: mealCardExtent,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          childCount: meals.isEmpty ? 4 : meals.length,
                          (context, index) => _GuestMealSkeletonCard(
                            key: ValueKey('guest-meal-skeleton-$index'),
                            compact: compactMealCards,
                          ),
                        ),
                      ),
                    )
                  else if (_hasMenuError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _GuestMenuError(
                        message: l10n.guestPlanLoadError,
                        retryLabel: l10n.retry,
                        onRetry: () {
                          final planCode = _selectedPlanCode;
                          final date = _selectedDate;
                          if (planCode == null || date == null) return;
                          unawaited(
                            _loadMenu(
                              planCode: planCode,
                              date: date,
                              selectionRequestId: _selectionRequestId,
                              force: true,
                            ),
                          );
                        },
                      ),
                    )
                  else if (meals.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _GuestMenuEmpty(
                        title: l10n.noMealsAvailableForPlan,
                        subtitle: l10n.tryAnotherMealFilter,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: compactMealCards ? 12 : 16,
                          crossAxisSpacing: compactMealCards ? 12 : 16,
                          mainAxisExtent: mealCardExtent,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          childCount: meals.length,
                          (context, index) => _GuestMealCard(
                            key: ValueKey('guest-meal-${meals[index].id}'),
                            meal: meals[index],
                            l10n: l10n,
                            compact: compactMealCards,
                            onTap: () => unawaited(
                              showMealDetailViewer(
                                context: context,
                                meals: meals,
                                initialIndex: index,
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
        ],
      ),
    );
  }
}

class _GuestMenuBackButton extends StatelessWidget {
  const _GuestMenuBackButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: IconButton.filled(
        key: const ValueKey('guestMenuBack'),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.darkGreen,
          side: BorderSide(color: AppColors.darkGreen.withValues(alpha: .08)),
          shadowColor: AppColors.darkGreen.withValues(alpha: .10),
          elevation: 2,
        ),
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
      ),
    );
  }
}

class _GuestLanguageSelector extends StatelessWidget {
  const _GuestLanguageSelector({
    required this.languageCode,
    required this.onSelected,
  });

  final String languageCode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isArabic = languageCode == 'ar';
    return Semantics(
      label: 'Language',
      button: true,
      child: PopupMenuButton<String>(
        key: const ValueKey('guestLanguageSelector'),
        tooltip: 'Language',
        onSelected: onSelected,
        position: PopupMenuPosition.under,
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (context) => [
          CheckedPopupMenuItem(
            key: const ValueKey('guest-language-en'),
            value: 'en',
            checked: !isArabic,
            child: const Text('English'),
          ),
          CheckedPopupMenuItem(
            key: const ValueKey('guest-language-ar'),
            value: 'ar',
            checked: isArabic,
            child: const Text('العربية'),
          ),
        ],
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 10, 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: AppColors.emeraldGreen.withValues(alpha: .18),
            ),
            boxShadow: _softShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language_rounded,
                size: 18,
                color: AppColors.emeraldGreen,
              ),
              const SizedBox(width: 7),
              Text(
                isArabic ? 'العربية' : 'English',
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.emeraldGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestMenuHeader extends StatelessWidget {
  const _GuestMenuHeader({
    required this.plan,
    required this.title,
    required this.subtitle,
  });

  final GuestMealPlan? plan;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(plan?.imageUrl);
    final planKey = ValueKey(plan?.code ?? 'meal-plan-placeholder');
    final planName = (plan?.name ?? '').trim().isEmpty ? title : plan!.name;
    final planDescription = (plan?.description ?? '').trim().isEmpty
        ? subtitle
        : plan!.description!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final imageWidth = constraints.maxWidth * (compact ? .40 : .42);
        final textWidth = constraints.maxWidth * (compact ? .64 : .62);
        final titleLength = planName.characters.length;
        final titleSize = titleLength > 34
            ? (compact ? 18.0 : 20.0)
            : titleLength > 24
            ? (compact ? 20.0 : 22.0)
            : (compact ? 23.0 : 27.0);
        return Container(
          key: const ValueKey('guestMealPlanHeader'),
          height: compact ? 180 : 190,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.darkGreen.withValues(alpha: .07),
            ),
            boxShadow: _softShadow,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: 0,
                width: imageWidth,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: SizedBox.expand(
                    key: planKey,
                    child: imageUrl.isEmpty
                        ? Image.asset(
                            'assets/images/onboarding_1.png',
                            key: const ValueKey('guestHeroImage'),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            excludeFromSemantics: true,
                          )
                        : Image.network(
                            imageUrl,
                            key: const ValueKey('guestHeroImage'),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            excludeFromSemantics: true,
                            errorBuilder: (_, _, _) => Image.asset(
                              'assets/images/onboarding_1.png',
                              fit: BoxFit.cover,
                              excludeFromSemantics: true,
                            ),
                          ),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFFDFEF9),
                      Color(0xE6F4FAEE),
                      Color(0x00F4FAEE),
                    ],
                    stops: [0, .48, .70, 1],
                  ),
                ),
              ),
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: textWidth,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, .08),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: Padding(
                    key: planKey,
                    padding: EdgeInsetsDirectional.fromSTEB(
                      compact ? 18 : 22,
                      14,
                      8,
                      14,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          style: TextStyle(
                            color: AppColors.emeraldGreen,
                            fontSize: compact ? 10.5 : 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          planName,
                          key: const ValueKey('guestHeroTitle'),
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: titleSize,
                            height: 1.06,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          planDescription,
                          key: const ValueKey('guestHeroDescription'),
                          maxLines: 3,
                          softWrap: true,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            color: AppColors.darkGreen.withValues(alpha: .68),
                            fontSize: compact ? 10.5 : 12.0,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.darkGreen,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -.3,
      ),
    );
  }
}

class _GuestMenuFiltersHeader extends SliverPersistentHeaderDelegate {
  _GuestMenuFiltersHeader({
    required this.title,
    required this.data,
    required this.filters,
    required this.selectedPlanCode,
    required this.selectedDate,
    required this.selectedMealTimeCode,
    required this.dateScrollController,
    required this.filterScrollController,
    required this.textScale,
    required this.isDateAvailable,
    required this.onDateSelected,
    required this.onFilterSelected,
  });

  final String title;
  final GuestHomeData data;
  final List<GuestMealTime> filters;
  final String? selectedPlanCode;
  final DateTime? selectedDate;
  final String selectedMealTimeCode;
  final ScrollController dateScrollController;
  final ScrollController filterScrollController;
  final double textScale;
  final bool Function(DateTime? date) isDateAvailable;
  final ValueChanged<GuestCalendarDate> onDateSelected;
  final void Function(GuestMealTime filter, int index) onFilterSelected;

  double get _scale => textScale.clamp(1, 1.4);

  @override
  double get minExtent => 161 + ((_scale - 1) * 54);

  @override
  double get maxExtent => 175 + ((_scale - 1) * 54);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapseRange = maxExtent - minExtent;
    final stickyProgress = collapseRange == 0
        ? 1.0
        : (shrinkOffset / collapseRange).clamp(0.0, 1.0);
    final topPadding = _lerp(8, 4, stickyProgress);
    final titleHeight = 32 + ((_scale - 1) * 22);
    final dateHeight = _lerp(72, 68, stickyProgress) + ((_scale - 1) * 16);
    final rowGap = _lerp(8, 6, stickyProgress);
    final filterHeight = _lerp(42, 40, stickyProgress) + ((_scale - 1) * 16);
    final bottomPadding = _lerp(8, 6, stickyProgress);
    return Material(
      key: const ValueKey('guestStickyFilterPanel'),
      color: const Color(0xFFF8F8F3),
      elevation: 2 * stickyProgress,
      shadowColor: AppColors.darkGreen.withValues(alpha: .12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPadding),
          SizedBox(
            height: titleHeight,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
                child: _SectionTitle(
                  key: const ValueKey('guestWeeklyMenuHeading'),
                  label: title,
                ),
              ),
            ),
          ),
          SizedBox(
            height: dateHeight,
            child: ListView.separated(
              key: const ValueKey('guestDateScroller'),
              controller: dateScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 0),
              itemCount: data.weeklyCalendar.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final date = data.weeklyCalendar[index];
                return _GuestDateCard(
                  key: ValueKey('guest-date-${date.date?.toIso8601String()}'),
                  date: date,
                  selected: _sameDate(date.date, selectedDate),
                  available: isDateAvailable(date.date),
                  onTap: () => onDateSelected(date),
                );
              },
            ),
          ),
          SizedBox(height: rowGap),
          SizedBox(
            height: filterHeight,
            child: ListView.separated(
              key: const ValueKey('guestMealTypeScroller'),
              controller: filterScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 0),
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final filter = filters[index];
                return _GuestFilterChip(
                  key: ValueKey(
                    'guest-filter-${normalizeMealTimeCode(filter.code)}',
                  ),
                  filter: filter,
                  selected:
                      normalizeMealTimeCode(filter.code) ==
                      normalizeMealTimeCode(selectedMealTimeCode),
                  onTap: () => onFilterSelected(filter, index),
                );
              },
            ),
          ),
          SizedBox(height: bottomPadding),
          Container(
            height: 1,
            color: AppColors.darkGreen.withValues(alpha: .08 * stickyProgress),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _GuestMenuFiltersHeader oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.filters != filters ||
      oldDelegate.selectedPlanCode != selectedPlanCode ||
      !_sameDate(oldDelegate.selectedDate, selectedDate) ||
      oldDelegate.selectedMealTimeCode != selectedMealTimeCode ||
      oldDelegate.textScale != textScale ||
      oldDelegate.title != title;
}

class _GuestPlanCard extends StatelessWidget {
  const _GuestPlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final GuestMealPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700);
    final textScaler = MediaQuery.textScalerOf(context);
    final textPainter = TextPainter(
      text: TextSpan(text: plan.name, style: labelStyle),
      textDirection: Directionality.of(context),
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final width = (textPainter.width + 104).clamp(150.0, 230.0).toDouble();
    final scale = textScaler.scale(1).clamp(1, 1.4).toDouble();
    final height = 60 + ((scale - 1) * 12);
    final foreground = selected ? AppColors.white : AppColors.darkGreen;
    return Semantics(
      button: true,
      selected: selected,
      label: AppLocalizations.of(context).selectMealPlanSemantics(plan.name),
      excludeSemantics: true,
      child: AnimatedScale(
        scale: selected ? 1.02 : 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: width,
          height: height,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.emeraldGreen : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.emeraldGreen.withValues(
                alpha: selected ? 1 : .30,
              ),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.emeraldGreen.withValues(alpha: .22),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 10, 6),
                child: Row(
                  children: [
                    _PlanThumbnail(plan: plan, selected: selected),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        plan.name,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle.copyWith(color: foreground),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutBack,
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: selected
                            ? const Icon(
                                Icons.check_rounded,
                                key: ValueKey('selected-plan-check'),
                                size: 18,
                                color: AppColors.white,
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('unselected-plan-check'),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanThumbnail extends StatelessWidget {
  const _PlanThumbnail({required this.plan, required this.selected});

  final GuestMealPlan plan;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(plan.imageUrl);
    final fallbackColor = selected ? AppColors.white : AppColors.emeraldGreen;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.white.withValues(alpha: .16)
            : AppColors.teaGreen.withValues(alpha: .22),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppColors.white.withValues(alpha: .72)
              : AppColors.emeraldGreen.withValues(alpha: .14),
        ),
      ),
      child: imageUrl.isEmpty
          ? Icon(Icons.restaurant_rounded, size: 20, color: fallbackColor)
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => Icon(
                Icons.restaurant_rounded,
                size: 20,
                color: fallbackColor,
              ),
            ),
    );
  }
}

class _GuestDateCard extends StatelessWidget {
  const _GuestDateCard({
    required this.date,
    required this.selected,
    required this.available,
    required this.onTap,
    super.key,
  });

  final GuestCalendarDate date;
  final bool selected;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.white : AppColors.darkGreen;
    return Opacity(
      opacity: available ? 1 : .38,
      child: InkWell(
        onTap: available ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 62,
          decoration: BoxDecoration(
            color: selected ? AppColors.emeraldGreen : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: date.isToday && !selected
                  ? AppColors.emeraldGreen
                  : AppColors.darkGreen.withValues(alpha: .06),
            ),
            boxShadow: _softShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                date.shortDayName,
                style: TextStyle(
                  color: foreground.withValues(alpha: .72),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${date.dayNumber}',
                style: TextStyle(
                  color: foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestFilterChip extends StatelessWidget {
  const _GuestFilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final GuestMealTime filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      avatar: Icon(
        _filterIcon(filter.code),
        size: 16,
        color: selected ? AppColors.white : AppColors.emeraldGreen,
      ),
      label: Text(filter.name, maxLines: 1, softWrap: false),
      labelStyle: TextStyle(
        color: selected ? AppColors.white : AppColors.darkGreen,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: AppColors.emeraldGreen,
      backgroundColor: AppColors.white,
      side: BorderSide(
        color: selected
            ? AppColors.emeraldGreen
            : AppColors.darkGreen.withValues(alpha: .08),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
    );
  }
}

class _GuestMealSkeletonCard extends StatelessWidget {
  const _GuestMealSkeletonCard({required this.compact, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final base = AppColors.darkGreen.withValues(alpha: .07);
    return Semantics(
      label: AppLocalizations.of(context).mealContentLoadingTitle,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(compact ? 20 : 26),
          boxShadow: _softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: compact ? 130 : 165,
              color: AppColors.teaGreen.withValues(alpha: .20),
              child: const Center(child: _FreshMealLoaderIcon(size: 58)),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(compact ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(color: base, widthFactor: .82, height: 15),
                    const SizedBox(height: 10),
                    _SkeletonLine(color: base, widthFactor: 1, height: 10),
                    const SizedBox(height: 7),
                    _SkeletonLine(color: base, widthFactor: .64, height: 10),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        3,
                        (index) => Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: index == 2 ? 0 : 8,
                            ),
                            child: _SkeletonLine(
                              color: base,
                              widthFactor: 1,
                              height: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.color,
    required this.widthFactor,
    required this.height,
  });

  final Color color;
  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

class _GuestMealCard extends StatelessWidget {
  const _GuestMealCard({
    required this.meal,
    required this.l10n,
    required this.compact,
    required this.onTap,
    super.key,
  });

  final GuestMeal meal;
  final AppLocalizations l10n;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(
      (meal.thumbnailUrl ?? '').isNotEmpty ? meal.thumbnailUrl : meal.imageUrl,
    );
    return Semantics(
      button: true,
      label: meal.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(compact ? 20 : 26),
            boxShadow: _softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  _NetworkMealImage(url: imageUrl, height: compact ? 130 : 165),
                  if (meal.mealTime.name.trim().isNotEmpty)
                    PositionedDirectional(
                      start: 12,
                      end: 12,
                      top: 12,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          key: ValueKey('guest-meal-time-${meal.id}'),
                          constraints: const BoxConstraints(
                            minHeight: 28,
                            maxWidth: 150,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: .94),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            meal.mealTime.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              color: AppColors.emeraldGreen,
                              fontSize: 11,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    end: 12,
                    bottom: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 7 : 10,
                        vertical: compact ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldGreen,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        l10n.kcal(meal.nutrition.calories.round()),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 11 : 16,
                    compact ? 10 : 14,
                    compact ? 11 : 16,
                    compact ? 10 : 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: compact ? 14 : 16.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: compact ? 4 : 6),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.topStart,
                          child: Text(
                            meal.description ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.darkGreen.withValues(alpha: .60),
                              fontSize: compact ? 10.5 : 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _NutritionValue(
                            value: l10n.gramsValue(
                              _nutrition(meal.nutrition.protein),
                            ),
                            label: l10n.proteinLabel,
                            compact: compact,
                          ),
                          _NutritionValue(
                            value: l10n.gramsValue(
                              _nutrition(meal.nutrition.carbs),
                            ),
                            label: l10n.carbsLabel,
                            compact: compact,
                          ),
                          _NutritionValue(
                            value: l10n.gramsValue(
                              _nutrition(meal.nutrition.fat),
                            ),
                            label: l10n.fatLabel,
                            compact: compact,
                          ),
                        ],
                      ),
                    ],
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

class _NutritionValue extends StatelessWidget {
  const _NutritionValue({
    required this.value,
    required this.label,
    required this.compact,
  });

  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.emeraldGreen,
              fontSize: compact ? 11.5 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.darkGreen.withValues(alpha: .52),
              fontSize: compact ? 8.5 : 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkMealImage extends StatelessWidget {
  const _NetworkMealImage({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.teaGreen.withValues(alpha: .22),
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: AppColors.emeraldGreen,
          size: 30,
        ),
      ),
    );
    if (url.isEmpty) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: placeholder,
      );
    }
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          placeholder,
          Image.network(
            url,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            frameBuilder: (context, child, frame, _) => AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: child,
            ),
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MealContentLoader extends StatelessWidget {
  const _MealContentLoader({
    required this.title,
    required this.subtitle,
    this.fullPage = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool fullPage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: fullPage ? AppSpacing.xl : AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.darkGreen.withValues(alpha: .06)),
          boxShadow: _softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FreshMealLoaderIcon(size: fullPage ? 82 : 70),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGreen.withValues(alpha: .60),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _AnimatedLoadingDots(),
          ],
        ),
      ),
    );
  }
}

class _FreshMealLoaderIcon extends StatelessWidget {
  const _FreshMealLoaderIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.teaGreen.withValues(alpha: .22),
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(dimension: size),
          ),
          Icon(
            Icons.soup_kitchen_outlined,
            size: size * .48,
            color: AppColors.emeraldGreen,
          ),
          PositionedDirectional(
            top: size * .08,
            end: size * .10,
            child: Icon(
              Icons.eco_rounded,
              size: size * .24,
              color: AppColors.emeraldGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLoadingDots extends StatefulWidget {
  const _AnimatedLoadingDots();

  @override
  State<_AnimatedLoadingDots> createState() => _AnimatedLoadingDotsState();
}

class _AnimatedLoadingDotsState extends State<_AnimatedLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final phase = (_controller.value - (index * .16)) % 1;
          final pulse = (1 - ((phase - .5).abs() * 2)).clamp(0.0, 1.0);
          return Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(
                alpha: .24 + (.76 * pulse),
              ),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

class _GuestMenuError extends StatelessWidget {
  const _GuestMenuError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.emeraldGreen,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.jasper.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: AppColors.jasper),
        title: Text(message),
        trailing: TextButton(onPressed: onRetry, child: Text(retryLabel)),
      ),
    );
  }
}

class _GuestMenuEmpty extends StatelessWidget {
  const _GuestMenuEmpty({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGreen.withValues(alpha: .60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

T? _firstSelected<T>(Iterable<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

bool _sameDate(DateTime? a, DateTime? b) =>
    a != null &&
    b != null &&
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day;

String normalizeMealTimeCode(String? value) {
  final code = value?.trim().toUpperCase() ?? '';
  return code == 'SNACK_DESSERT' ? 'SNACK' : code;
}

String _menuCacheKey(String language, String planCode, DateTime date) =>
    '$language|$planCode|${formatGuestDate(date)}';

IconData _filterIcon(String code) {
  return switch (normalizeMealTimeCode(code)) {
    'BREAKFAST' => Icons.wb_sunny_outlined,
    'LUNCH' => Icons.lunch_dining_outlined,
    'DINNER' => Icons.nightlight_outlined,
    'SNACK' => Icons.apple_outlined,
    _ => Icons.grid_view_rounded,
  };
}

String _nutrition(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

double _lerp(double start, double end, double progress) =>
    start + ((end - start) * progress);

const _softShadow = [
  BoxShadow(color: Color(0x120B3226), blurRadius: 24, offset: Offset(0, 9)),
];
