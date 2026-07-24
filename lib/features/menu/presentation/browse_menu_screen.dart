import 'dart:async';

import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/app_logo.dart';
import 'package:diet_time/features/language/presentation/language_controller.dart';
import 'package:diet_time/features/menu/data/guest_menu_repository.dart';
import 'package:diet_time/features/menu/domain/guest_home_models.dart';
import 'package:diet_time/features/menu/presentation/meal_detail_viewer.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  GuestHomeData? _originalData;
  List<GuestMeal> _visibleMeals = const [];
  String? _language;
  String? _selectedPlanCode;
  DateTime? _selectedDate;
  String _selectedMealTimeCode = 'ALL';
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _hasLoaded = false;
  bool _hasError = false;
  int _requestId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_language == language) return;
    final isLanguageChange = _language != null;
    _language = language;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load(force: isLanguageChange, preserveSelections: isLanguageChange);
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

  Future<void> _load({
    bool force = false,
    bool preserveSelections = true,
  }) async {
    if (!force && (_hasLoaded || _isLoading || _isRefreshing)) return;
    final requestId = ++_requestId;
    final hadData = _originalData != null;
    setState(() {
      _hasError = false;
      if (!hadData) {
        _isLoading = true;
      } else {
        _isRefreshing = true;
      }
    });
    try {
      final response = await ref
          .read(guestMenuRepositoryProvider)
          .getGuestHome(
            language: _language ?? 'en',
            date: _selectedDate ?? DateTime.now(),
            includeAll: true,
          );
      if (!mounted || requestId != _requestId) return;
      final data = response.data;
      final planCode = _resolvePlan(
        data,
        preserveSelections ? _selectedPlanCode : null,
      );
      final selectedDate = _resolveDate(
        data,
        planCode,
        preserveSelections ? _selectedDate : null,
      );
      final mealTimeCode = _resolveMealTime(
        data,
        preserveSelections ? _selectedMealTimeCode : null,
      );
      final visibleMeals = _filterMeals(
        data,
        planCode: planCode,
        date: selectedDate,
        mealTimeCode: mealTimeCode,
      );
      setState(() {
        _originalData = data;
        _selectedPlanCode = planCode;
        _selectedDate = selectedDate;
        _selectedMealTimeCode = mealTimeCode;
        _visibleMeals = visibleMeals;
        _isLoading = false;
        _isRefreshing = false;
        _hasLoaded = true;
      });
      _precacheMenuImages(data, planCode, visibleMeals);
    } on Object {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _hasError = true;
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

  DateTime? _resolveDate(
    GuestHomeData data,
    String? planCode,
    DateTime? preferredDate,
  ) {
    if (preferredDate != null &&
        _isDateAvailable(data, planCode, preferredDate)) {
      return preferredDate;
    }
    final initiallySelected = _firstSelected(
      data.weeklyCalendar,
      (item) => item.isSelected && _isDateAvailable(data, planCode, item.date),
    )?.date;
    if (initiallySelected != null) return initiallySelected;
    return data.weeklyCalendar
        .where((item) => _isDateAvailable(data, planCode, item.date))
        .firstOrNull
        ?.date;
  }

  String _resolveMealTime(GuestHomeData data, String? preferredCode) {
    if (preferredCode != null &&
        data.mealTimeFilters.any(
          (filter) =>
              _normalizeMealTimeCode(filter.code) ==
              _normalizeMealTimeCode(preferredCode),
        )) {
      return preferredCode;
    }
    return _firstSelected(
          data.mealTimeFilters,
          (filter) => filter.isSelected,
        )?.code ??
        data.mealTimeFilters.firstOrNull?.code ??
        'ALL';
  }

  void _selectPlan(GuestMealPlan plan) {
    final data = _originalData;
    if (data == null || plan.code == _selectedPlanCode) return;
    final date = _resolveDate(data, plan.code, _selectedDate);
    setState(() {
      _selectedPlanCode = plan.code;
      _selectedDate = date;
      _visibleMeals = _filterMeals(
        data,
        planCode: plan.code,
        date: date,
        mealTimeCode: _selectedMealTimeCode,
      );
    });
  }

  void _selectDate(GuestCalendarDate date) {
    final data = _originalData;
    if (data == null ||
        !_isDateAvailable(data, _selectedPlanCode, date.date) ||
        _sameDate(date.date, _selectedDate) ||
        date.date == null) {
      return;
    }
    setState(() {
      _selectedDate = date.date;
      _visibleMeals = _filterMeals(
        data,
        planCode: _selectedPlanCode,
        date: date.date,
        mealTimeCode: _selectedMealTimeCode,
      );
    });
  }

  void _selectMealTime(GuestMealTimeFilter filter) {
    final data = _originalData;
    if (data == null ||
        _normalizeMealTimeCode(filter.code) ==
            _normalizeMealTimeCode(_selectedMealTimeCode)) {
      return;
    }
    setState(() {
      _selectedMealTimeCode = filter.code;
      _visibleMeals = _filterMeals(
        data,
        planCode: _selectedPlanCode,
        date: _selectedDate,
        mealTimeCode: filter.code,
      );
    });
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
    final heroUrl = resolveMediaUrl(
      selectedPlan?.imageUrl ?? data.hero.bannerImageUrl,
    );
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

  bool _isDateAvailable(GuestHomeData data, String? planCode, DateTime? date) {
    if (planCode == null || date == null) return false;
    return data.menus.any(
      (menu) => menu.planCode == planCode && _sameDate(menu.date, date),
    );
  }

  List<GuestMeal> _filterMeals(
    GuestHomeData data, {
    required String? planCode,
    required DateTime? date,
    required String mealTimeCode,
  }) {
    final selectedMenus = data.menus.where(
      (menu) =>
          menu.planCode == planCode &&
          (date == null || _sameDate(menu.date, date)),
    );
    final meals = selectedMenus
        .expand((menu) => menu.slots)
        .expand((slot) => slot.meals);
    final normalizedFilter = _normalizeMealTimeCode(mealTimeCode);
    final filtered = normalizedFilter == 'ALL'
        ? meals
        : meals.where(
            (meal) =>
                _normalizeMealTimeCode(meal.mealTime.code) == normalizedFilter,
          );
    return filtered.toList(growable: false)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading || (_originalData == null && !_hasError)) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F8F3),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.emeraldGreen),
        ),
      );
    }
    if (_originalData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F8F3),
        body: _GuestMenuError(
          message: l10n.guestMenuLoadError,
          retryLabel: l10n.retry,
          onRetry: _load,
        ),
      );
    }

    final data = _originalData!;
    final plans = [...data.mealPlans]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final filters = [...data.mealTimeFilters]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final meals = _visibleMeals;
    final selectedPlan = plans
        .where((plan) => plan.code == _selectedPlanCode)
        .firstOrNull;
    final hero = selectedPlan == null
        ? data.hero
        : GuestHero(
            title: selectedPlan.name,
            subtitle: selectedPlan.description,
            bannerImageUrl: selectedPlan.imageUrl,
          );
    final width = MediaQuery.sizeOf(context).width;
    const columns = 2;
    final compactMealCards = width < 680;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.emeraldGreen,
          onRefresh: () => _load(force: true),
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
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _GuestLanguageSelector(
                        languageCode: _language ?? 'en',
                        onSelected: _changeLanguage,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _GuestMenuHeader(hero: hero),
                    if (_isRefreshing) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(
                        minHeight: 3,
                        color: AppColors.emeraldGreen,
                        backgroundColor: Color(0x1A00674E),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _SectionTitle(label: l10n.guestMealPlansTitle),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 108,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = (constraints.maxWidth * .36)
                              .clamp(120.0, 145.0)
                              .toDouble();
                          return ListView.separated(
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
                                width: cardWidth,
                                selected: plan.code == _selectedPlanCode,
                                onTap: () => _selectPlan(plan),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (_hasError) ...[
                      const SizedBox(height: 16),
                      _InlineError(
                        message: l10n.guestMenuLoadError,
                        retryLabel: l10n.retry,
                        onRetry: _load,
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
                  isDateAvailable: (date) =>
                      _isDateAvailable(data, _selectedPlanCode, date),
                  onDateSelected: _selectDate,
                  onFilterSelected: (filter, index) {
                    _selectMealTime(filter);
                    _keepFilterVisible(index);
                  },
                ),
              ),
              if (meals.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _GuestMenuEmpty(
                    title: l10n.noMealsAvailable,
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
                      mainAxisExtent: compactMealCards ? 315 : 365,
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
  const _GuestMenuHeader({required this.hero});

  final GuestHero hero;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(hero.bannerImageUrl);
    return Container(
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: _softShadow,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FractionallySizedBox(
                widthFactor: .58,
                heightFactor: 1,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [
                  Color(0xFFFEFEFB),
                  Color(0xFFF4FAEE),
                  Color(0x99F4FAEE),
                ],
                stops: [0, .52, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(width: 76),
                const Spacer(),
                if ((hero.title ?? '').isNotEmpty)
                  Text(
                    hero.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.7,
                    ),
                  ),
                if ((hero.subtitle ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    hero.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.emeraldGreen.withValues(alpha: .72),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

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
    required this.isDateAvailable,
    required this.onDateSelected,
    required this.onFilterSelected,
  });

  final String title;
  final GuestHomeData data;
  final List<GuestMealTimeFilter> filters;
  final String? selectedPlanCode;
  final DateTime? selectedDate;
  final String selectedMealTimeCode;
  final ScrollController dateScrollController;
  final ScrollController filterScrollController;
  final bool Function(DateTime? date) isDateAvailable;
  final ValueChanged<GuestCalendarDate> onDateSelected;
  final void Function(GuestMealTimeFilter filter, int index) onFilterSelected;

  @override
  double get minExtent => 138;

  @override
  double get maxExtent => 172;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final titleHeight = (maxExtent - shrinkOffset - minExtent).clamp(0.0, 34.0);
    return Material(
      color: const Color(0xFFF8F8F3),
      elevation: overlapsContent ? 3 : 0,
      shadowColor: const Color(0x240B3226),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          ClipRect(
            child: SizedBox(
              height: titleHeight,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 18,
                  ),
                  child: Opacity(
                    opacity: (titleHeight / 34).clamp(0.0, 1.0),
                    child: _SectionTitle(label: title),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 72,
            child: ListView.separated(
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
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              controller: filterScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 0),
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final filter = filters[index];
                return _GuestFilterChip(
                  key: ValueKey('guest-filter-${filter.code}'),
                  filter: filter,
                  selected:
                      _normalizeMealTimeCode(filter.code) ==
                      _normalizeMealTimeCode(selectedMealTimeCode),
                  onTap: () => onFilterSelected(filter, index),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
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
      oldDelegate.title != title;
}

class _GuestPlanCard extends StatelessWidget {
  const _GuestPlanCard({
    required this.plan,
    required this.width,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final GuestMealPlan plan;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(plan.imageUrl);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: width,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF0F8EB) : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.emeraldGreen
                  : AppColors.darkGreen.withValues(alpha: .08),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: _softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _NetworkMealImage(url: imageUrl, height: 50),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        plan.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 12.5,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (selected)
                      const Padding(
                        padding: EdgeInsetsDirectional.only(start: 3),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.emeraldGreen,
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

  final GuestMealTimeFilter filter;
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
      label: Text(filter.name),
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
                  PositionedDirectional(
                    start: 12,
                    top: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 7 : 10,
                        vertical: compact ? 5 : 6,
                      ),
                      constraints: BoxConstraints(maxWidth: compact ? 92 : 160),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        meal.mealTime.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.emeraldGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
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
                      Text(
                        meal.description ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.darkGreen.withValues(alpha: .60),
                          fontSize: compact ? 10.5 : 12,
                          height: 1.35,
                        ),
                      ),
                      const Spacer(),
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

String _normalizeMealTimeCode(String? value) {
  final code = value?.trim().toUpperCase() ?? '';
  return code == 'SNACK_DESSERT' ? 'SNACK' : code;
}

IconData _filterIcon(String code) {
  return switch (_normalizeMealTimeCode(code)) {
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

const _softShadow = [
  BoxShadow(color: Color(0x120B3226), blurRadius: 24, offset: Offset(0, 9)),
];
