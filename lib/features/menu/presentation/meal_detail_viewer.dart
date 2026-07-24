import 'dart:ui';

import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/menu/data/guest_menu_repository.dart';
import 'package:diet_time/features/menu/data/meal_detail_repository.dart';
import 'package:diet_time/features/menu/domain/guest_home_models.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showMealDetailViewer({
  required BuildContext context,
  required List<GuestMeal> meals,
  required int initialIndex,
}) {
  if (meals.isEmpty || initialIndex < 0 || initialIndex >= meals.length) {
    return Future.value();
  }
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, _, _) =>
        MealDetailViewer(meals: meals, initialIndex: initialIndex),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: .97, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
  );
}

class MealDetailViewer extends ConsumerStatefulWidget {
  const MealDetailViewer({
    required this.meals,
    required this.initialIndex,
    super.key,
  });

  final List<GuestMeal> meals;
  final int initialIndex;

  @override
  ConsumerState<MealDetailViewer> createState() => _MealDetailViewerState();
}

class _MealDetailViewerState extends ConsumerState<MealDetailViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  final Map<int, MealDetailData?> _details = {};
  final Set<int> _loadingDetails = {};
  String? _language;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: widget.initialIndex,
      viewportFraction: .90,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_language == language) return;
    _language = language;
    _details.clear();
    _loadingDetails.clear();
    _loadDetail(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _close() {
    if (_isClosing) return;
    _isClosing = true;
    Navigator.of(context).pop();
  }

  Future<void> _loadDetail(int index) async {
    if (_details.containsKey(index) || !_loadingDetails.add(index)) return;
    final mealId = widget.meals[index].id;
    if (!_uuidPattern.hasMatch(mealId)) {
      _loadingDetails.remove(index);
      return;
    }
    try {
      final detail = await ref
          .read(mealDetailRepositoryProvider)
          .getMealDetail(mealId: mealId, language: _language ?? 'en');
      if (!mounted) return;
      setState(() {
        _details[index] = detail;
        _loadingDetails.remove(index);
      });
    } on Object {
      if (!mounted) return;
      setState(() => _loadingDetails.remove(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meals[_currentIndex];
    return Material(
      color: AppColors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
            child: ColoredBox(color: AppColors.black.withValues(alpha: .78)),
          ),
          SafeArea(
            child: Column(
              children: [
                _MealDetailHeader(
                  mealTimeName: meal.mealTime.name,
                  currentIndex: _currentIndex,
                  count: widget.meals.length,
                  onClose: _close,
                ),
                Expanded(
                  child: PageView.builder(
                    key: const ValueKey('mealDetailPageView'),
                    controller: _pageController,
                    itemCount: widget.meals.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                      _loadDetail(index);
                    },
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.fromLTRB(5, 8, 5, 16),
                      child: _MealDetailCard(
                        meal: widget.meals[index],
                        detail: _details[index],
                        detailLoading: _loadingDetails.contains(index),
                      ),
                    ),
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

class _MealDetailHeader extends StatelessWidget {
  const _MealDetailHeader({
    required this.mealTimeName,
    required this.currentIndex,
    required this.count,
    required this.onClose,
  });

  final String mealTimeName;
  final int currentIndex;
  final int count;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                mealTimeName.toUpperCase(),
                key: const ValueKey('mealDetailMealTime'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            _MealPageIndicator(current: currentIndex, count: count),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  key: const ValueKey('mealDetailClose'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: onClose,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: AppColors.white.withValues(alpha: .12),
                    foregroundColor: AppColors.white,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealPageIndicator extends StatelessWidget {
  const _MealPageIndicator({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count > 7) {
      return Text(
        '${current + 1} / $count',
        key: const ValueKey('mealDetailPageIndicator'),
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      );
    }
    return Semantics(
      key: const ValueKey('mealDetailPageIndicator'),
      label: '${current + 1} / $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          count,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: index == current ? 16 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: index == current
                  ? const Color(0xFF62CE55)
                  : AppColors.white.withValues(alpha: .30),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

class _MealDetailCard extends StatelessWidget {
  const _MealDetailCard({
    required this.meal,
    required this.detail,
    required this.detailLoading,
  });

  final GuestMeal meal;
  final MealDetailData? detail;
  final bool detailLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final imageUrl = resolveMediaUrl(
      (detail?.primaryImageUrl ?? '').isNotEmpty
          ? detail!.primaryImageUrl
          : (meal.imageUrl ?? '').isNotEmpty
          ? meal.imageUrl
          : meal.thumbnailUrl,
    );
    final compact = MediaQuery.sizeOf(context).height < 700;
    final fiber = detail?.fiberGrams ?? meal.nutrition.fiber;
    final sodium = detail?.sodiumMg;
    final ingredients =
        detail?.ingredients
            .where((item) => item.name.isNotEmpty)
            .toList(growable: false) ??
        const <MealDetailIngredient>[];
    final allergens = detail != null
        ? detail!.allergens
        : meal.allergens
              .map((item) => item.name?.trim() ?? '')
              .where((name) => name.isNotEmpty)
              .toList(growable: false);
    return Container(
      key: ValueKey('meal-detail-${meal.id}'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCF8),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: SingleChildScrollView(
        key: PageStorageKey('meal-detail-scroll-${meal.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (detailLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.emeraldGreen,
                backgroundColor: Color(0x1A00674E),
              ),
            _DetailMealImage(url: imageUrl, height: compact ? 220 : 290),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 18 : 22,
                18,
                compact ? 18 : 22,
                26,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.kcal(meal.nutrition.calories.round()).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.emeraldGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    meal.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 23,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if ((detail?.fullDescription ?? meal.description ?? '')
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Text(
                      detail?.fullDescription ?? meal.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.darkGreen.withValues(alpha: .64),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _MacroSummary(meal: meal),
                  if (ingredients.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _SectionTitle(label: l10n.mealIngredientsTitle),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ingredients
                          .map(
                            (ingredient) => Chip(
                              label: Text(_ingredientLabel(ingredient)),
                              backgroundColor: const Color(0xFFEAF4E8),
                              side: BorderSide.none,
                              labelStyle: const TextStyle(
                                color: AppColors.darkGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  if ((fiber != null && fiber > 0) ||
                      (sodium != null && sodium > 0)) ...[
                    const SizedBox(height: 22),
                    _SectionTitle(label: l10n.mealMicronutrientsTitle),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (fiber != null && fiber > 0)
                          _InformationChip(
                            label: l10n.fiberLabel,
                            value: _grams(l10n, fiber),
                          ),
                        if (sodium != null && sodium > 0)
                          _InformationChip(
                            label: l10n.sodiumLabel,
                            value: '${_number(sodium)} mg',
                          ),
                      ],
                    ),
                  ],
                  if (allergens.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _SectionTitle(label: l10n.mealAllergensTitle),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allergens
                          .map(
                            (name) => Chip(
                              avatar: const Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: AppColors.emeraldGreen,
                              ),
                              label: Text(name),
                              backgroundColor: const Color(0xFFEAF4E8),
                              side: BorderSide.none,
                              labelStyle: const TextStyle(
                                color: AppColors.darkGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroSummary extends StatelessWidget {
  const _MacroSummary({required this.meal});

  final GuestMeal meal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _MacroValue(
          label: l10n.proteinLabel,
          value: _grams(l10n, meal.nutrition.protein),
          color: const Color(0xFFFFC107),
        ),
        _MacroValue(
          label: l10n.carbsLabel,
          value: _grams(l10n, meal.nutrition.carbs),
          color: const Color(0xFF41B9D8),
        ),
        _MacroValue(
          label: l10n.fatLabel,
          value: _grams(l10n, meal.nutrition.fat),
          color: const Color(0xFFB66BD3),
        ),
      ],
    );
  }
}

class _MacroValue extends StatelessWidget {
  const _MacroValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .52),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 13,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.darkGreen,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: .5,
      ),
    );
  }
}

class _InformationChip extends StatelessWidget {
  const _InformationChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label  $value',
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailMealImage extends StatelessWidget {
  const _DetailMealImage({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      key: const ValueKey('mealDetailImagePlaceholder'),
      color: const Color(0xFFE7F1E4),
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 44,
          color: AppColors.emeraldGreen,
        ),
      ),
    );
    if (url.isEmpty) return SizedBox(height: height, child: placeholder);
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          placeholder,
          Image.network(
            url,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, _) => AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              child: child,
            ),
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

String _grams(AppLocalizations l10n, double value) {
  if (value <= 0) return '—';
  return l10n.gramsValue(_number(value));
}

String _ingredientLabel(MealDetailIngredient ingredient) {
  final quantity = ingredient.quantity;
  if (quantity == null || quantity <= 0) return ingredient.name;
  final unit = ingredient.unit?.trim() ?? '';
  return '${ingredient.name} · ${_number(quantity)}${unit.isEmpty ? '' : ' $unit'}';
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);
