import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/app_logo.dart';
import 'package:diet_time/features/menu/data/guest_menu_repository.dart';
import 'package:diet_time/features/menu/domain/guest_home_models.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BrowseMenuScreen extends ConsumerStatefulWidget {
  const BrowseMenuScreen({super.key});

  @override
  ConsumerState<BrowseMenuScreen> createState() => _BrowseMenuScreenState();
}

class _BrowseMenuScreenState extends ConsumerState<BrowseMenuScreen> {
  GuestHomeData? _data;
  String? _language;
  String? _selectedPlanCode;
  DateTime? _selectedDate;
  String _selectedMealTimeCode = 'ALL';
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasError = false;
  int _requestId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_language == language) return;
    _language = language;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(resetSelections: _data == null);
    });
  }

  Future<void> _load({bool resetSelections = false}) async {
    final requestId = ++_requestId;
    setState(() {
      _hasError = false;
      if (_data == null) {
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
            date: resetSelections ? null : _selectedDate,
            planCode: resetSelections ? null : _selectedPlanCode,
            mealTimeCode: resetSelections ? 'ALL' : _selectedMealTimeCode,
          );
      if (!mounted || requestId != _requestId) return;
      final data = response.data;
      setState(() {
        _data = data;
        _selectedPlanCode = _resolvePlan(data);
        _selectedDate = _resolveDate(data);
        _selectedMealTimeCode = _resolveMealTime(data);
        _isLoading = false;
        _isRefreshing = false;
      });
    } on Object {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _hasError = true;
      });
    }
  }

  String? _resolvePlan(GuestHomeData data) {
    if (_selectedPlanCode != null &&
        data.mealPlans.any((plan) => plan.code == _selectedPlanCode)) {
      return _selectedPlanCode;
    }
    return _firstSelected(data.mealPlans, (plan) => plan.isSelected)?.code ??
        data.mealPlans.firstOrNull?.code;
  }

  DateTime? _resolveDate(GuestHomeData data) {
    if (_selectedDate != null &&
        data.weeklyCalendar.any(
          (item) => _sameDate(item.date, _selectedDate),
        )) {
      return _selectedDate;
    }
    return _firstSelected(
          data.weeklyCalendar,
          (item) => item.isSelected && item.isAvailable,
        )?.date ??
        data.weeklyCalendar.where((item) => item.isAvailable).firstOrNull?.date;
  }

  String _resolveMealTime(GuestHomeData data) {
    if (data.mealTimeFilters.any(
      (filter) => filter.code == _selectedMealTimeCode,
    )) {
      return _selectedMealTimeCode;
    }
    return _firstSelected(
          data.mealTimeFilters,
          (filter) => filter.isSelected,
        )?.code ??
        data.mealTimeFilters.firstOrNull?.code ??
        'ALL';
  }

  void _selectPlan(GuestMealPlan plan) {
    if (plan.code == _selectedPlanCode || _isRefreshing) return;
    setState(() => _selectedPlanCode = plan.code);
    _load();
  }

  void _selectDate(GuestCalendarDate date) {
    if (!date.isAvailable ||
        _sameDate(date.date, _selectedDate) ||
        _isRefreshing) {
      return;
    }
    setState(() => _selectedDate = date.date);
    _load();
  }

  void _selectMealTime(GuestMealTimeFilter filter) {
    if (filter.code == _selectedMealTimeCode || _isRefreshing) return;
    setState(() => _selectedMealTimeCode = filter.code);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F8F3),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.emeraldGreen),
        ),
      );
    }
    if (_data == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F8F3),
        body: _GuestMenuError(
          message: l10n.guestMenuLoadError,
          retryLabel: l10n.retry,
          onRetry: _load,
        ),
      );
    }

    final data = _data!;
    final plans = [...data.mealPlans]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final filters = [...data.mealTimeFilters]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final meals = [...data.meals]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 980 ? 3 : (width >= 680 ? 2 : 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.emeraldGreen,
          onRefresh: _load,
          child: CustomScrollView(
            key: const PageStorageKey('guestMenuScroll'),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                sliver: SliverList.list(
                  children: [
                    _GuestMenuHeader(hero: data.hero),
                    if (_isRefreshing) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(
                        minHeight: 3,
                        color: AppColors.emeraldGreen,
                        backgroundColor: Color(0x1A00674E),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _SectionTitle(label: l10n.guestMealPlansTitle),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 142,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: plans.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final plan = plans[index];
                          return _GuestPlanCard(
                            key: ValueKey('guest-plan-${plan.code}'),
                            plan: plan,
                            selected: plan.code == _selectedPlanCode,
                            onTap: () => _selectPlan(plan),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SectionTitle(label: l10n.guestWeeklyMenuTitle),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 78,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.weeklyCalendar.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final date = data.weeklyCalendar[index];
                          return _GuestDateCard(
                            key: ValueKey(
                              'guest-date-${date.date?.toIso8601String()}',
                            ),
                            date: date,
                            selected: _sameDate(date.date, _selectedDate),
                            onTap: () => _selectDate(date),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 46,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 9),
                        itemBuilder: (context, index) {
                          final filter = filters[index];
                          return _GuestFilterChip(
                            key: ValueKey('guest-filter-${filter.code}'),
                            filter: filter,
                            selected: filter.code == _selectedMealTimeCode,
                            onTap: () => _selectMealTime(filter),
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
                    const SizedBox(height: 20),
                  ],
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
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 390,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: meals.length,
                      (context, index) => _GuestMealCard(
                        key: ValueKey('guest-meal-${meals[index].id}'),
                        meal: meals[index],
                        l10n: l10n,
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

class _GuestMenuHeader extends StatelessWidget {
  const _GuestMenuHeader({required this.hero});

  final GuestHero hero;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(hero.bannerImageUrl);
    return Container(
      height: 220,
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(width: 92),
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
    final imageUrl = resolveMediaUrl(plan.imageUrl);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 156,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF0F8EB) : AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? AppColors.emeraldGreen
                  : AppColors.darkGreen.withValues(alpha: .08),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: _softShadow,
          ),
          child: Row(
            children: [
              ClipOval(
                child: _NetworkMealImage(url: imageUrl, width: 52, height: 52),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if ((plan.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        plan.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.darkGreen.withValues(alpha: .55),
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (selected) ...[
                      const SizedBox(height: 7),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: AppColors.emeraldGreen,
                      ),
                    ],
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
    required this.onTap,
    super.key,
  });

  final GuestCalendarDate date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.white : AppColors.darkGreen;
    return Opacity(
      opacity: date.isAvailable ? 1 : .38,
      child: InkWell(
        onTap: date.isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 68,
          decoration: BoxDecoration(
            color: selected ? AppColors.emeraldGreen : AppColors.white,
            borderRadius: BorderRadius.circular(20),
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
        size: 18,
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
  const _GuestMealCard({required this.meal, required this.l10n, super.key});

  final GuestMeal meal;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(
      (meal.thumbnailUrl ?? '').isNotEmpty ? meal.thumbnailUrl : meal.imageUrl,
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: _softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              _NetworkMealImage(url: imageUrl, height: 190),
              PositionedDirectional(
                start: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    meal.mealTime.name,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meal.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.darkGreen.withValues(alpha: .60),
                      fontSize: 12,
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
                      ),
                      _NutritionValue(
                        value: l10n.gramsValue(
                          _nutrition(meal.nutrition.carbs),
                        ),
                        label: l10n.carbsLabel,
                      ),
                      _NutritionValue(
                        value: l10n.gramsValue(_nutrition(meal.nutrition.fat)),
                        label: l10n.fatLabel,
                      ),
                    ],
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

class _NutritionValue extends StatelessWidget {
  const _NutritionValue({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.emeraldGreen,
              fontSize: 14,
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
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkMealImage extends StatelessWidget {
  const _NetworkMealImage({
    required this.url,
    this.width,
    required this.height,
  });

  final String url;
  final double? width;
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
      return SizedBox(width: width, height: height, child: placeholder);
    }
    return Image.network(
      url,
      width: width ?? double.infinity,
      height: height,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, _) =>
          frame == null ? placeholder : child,
      errorBuilder: (_, _, _) => placeholder,
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

IconData _filterIcon(String code) {
  return switch (code) {
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
