import 'dart:ui';

import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
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

class _MealDetailCard extends StatefulWidget {
  const _MealDetailCard({
    required this.meal,
    required this.detail,
    required this.detailLoading,
  });

  final GuestMeal meal;
  final MealDetailData? detail;
  final bool detailLoading;

  @override
  State<_MealDetailCard> createState() => _MealDetailCardState();
}

class _MealDetailCardState extends State<_MealDetailCard> {
  bool _showAllIngredients = false;
  bool _ingredientsExpanded = true;
  bool _allergensExpanded = true;
  bool _descriptionExpanded = false;

  GuestMeal get meal => widget.meal;
  MealDetailData? get detail => widget.detail;
  bool get detailLoading => widget.detailLoading;

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
              .map(
                (name) => _AllergenDisplay(
                  name: name,
                  level: detail!.allergenLevels[name],
                ),
              )
              .toList(growable: false)
        : meal.allergens
              .where((item) => (item.name ?? '').trim().isNotEmpty)
              .map(
                (item) => _AllergenDisplay(
                  name: item.name!.trim(),
                  level: item.level,
                ),
              )
              .toList(growable: false);
    final visibleIngredients = _showAllIngredients
        ? ingredients
        : ingredients.take(8).toList(growable: false);
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
                  if (meal.mealTime.name.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(meal.mealTime.name),
                        backgroundColor: const Color(0xFFEAF4E8),
                        side: BorderSide.none,
                        labelStyle: const TextStyle(
                          color: AppColors.emeraldGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _NutritionSummary(meal: meal),
                  if ((fiber != null && fiber > 0) ||
                      (sodium != null && sodium > 0)) ...[
                    const SizedBox(height: 12),
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
                  if ((detail?.fullDescription ?? meal.description ?? '')
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _ExpandableDescription(
                      text: detail?.fullDescription ?? meal.description!,
                      expanded: _descriptionExpanded,
                      onToggle: () => setState(
                        () => _descriptionExpanded = !_descriptionExpanded,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _CollapsibleSection(
                    key: const ValueKey('ingredientsSection'),
                    title: l10n.mealIngredientsTitle,
                    expanded: _ingredientsExpanded,
                    onToggle: () => setState(
                      () => _ingredientsExpanded = !_ingredientsExpanded,
                    ),
                    child: ingredients.isEmpty
                        ? _EmptyInformationState(
                            label: l10n.noIngredientsAvailable,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AnimatedIngredientWrap(
                                ingredients: visibleIngredients,
                              ),
                              if (!_showAllIngredients &&
                                  ingredients.length > 8)
                                TextButton.icon(
                                  key: const ValueKey('showAllIngredients'),
                                  onPressed: () => setState(
                                    () => _showAllIngredients = true,
                                  ),
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 18,
                                  ),
                                  label: Text('+ ${l10n.showAllIngredients}'),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),
                  _CollapsibleSection(
                    key: const ValueKey('allergensSection'),
                    title: l10n.mealAllergensTitle,
                    expanded: _allergensExpanded,
                    onToggle: () => setState(
                      () => _allergensExpanded = !_allergensExpanded,
                    ),
                    child: allergens.isEmpty
                        ? _EmptyInformationState(label: l10n.noAllergensListed)
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: allergens
                                .map(
                                  (allergen) =>
                                      _AllergenChip(allergen: allergen),
                                )
                                .toList(growable: false),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableDescription extends StatelessWidget {
  const _ExpandableDescription({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.darkGreen.withValues(alpha: .64),
      fontSize: 13,
      height: 1.45,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 3,
        )..layout(maxWidth: constraints.maxWidth);
        final canExpand = painter.didExceedMaxLines;
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: AlignmentDirectional.topStart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                key: const ValueKey('mealDescription'),
                maxLines: expanded ? null : 3,
                overflow: expanded ? TextOverflow.visible : TextOverflow.fade,
                style: style,
              ),
              if (canExpand || expanded)
                TextButton(
                  key: const ValueKey('mealDescriptionToggle'),
                  onPressed: onToggle,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.emeraldGreen,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: const Size(44, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    expanded
                        ? AppLocalizations.of(context).showLess
                        : AppLocalizations.of(context).readMore,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
    super.key,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.emeraldGreen.withValues(alpha: .08),
        ),
      ),
      child: Column(
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0 : -.25,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.emeraldGreen,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: AlignmentDirectional.topStart,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: SizedBox(width: double.infinity, child: child),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedIngredientWrap extends StatelessWidget {
  const _AnimatedIngredientWrap({required this.ingredients});

  final List<MealDetailIngredient> ingredients;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('ingredient-count-${ingredients.length}'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ingredients
            .map((ingredient) => _IngredientChip(name: ingredient.name))
            .toList(growable: false),
      ),
    );
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: Chip(
        key: ValueKey('ingredient-$name'),
        label: Text(name),
        backgroundColor: const Color(0xFFEAF4E8),
        side: BorderSide(color: AppColors.emeraldGreen.withValues(alpha: .16)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelStyle: const TextStyle(
          color: AppColors.darkGreen,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyInformationState extends StatelessWidget {
  const _EmptyInformationState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F1EA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: Color(0xFF66736A),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF526159),
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

class _NutritionSummary extends StatelessWidget {
  const _NutritionSummary({required this.meal});

  final GuestMeal meal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final values = [
      (
        l10n.caloriesLabel,
        l10n.kcal(meal.nutrition.calories.round()),
        AppColors.emeraldGreen,
      ),
      (
        l10n.proteinLabel,
        _grams(l10n, meal.nutrition.protein),
        const Color(0xFFFFA000),
      ),
      (
        l10n.carbsLabel,
        _grams(l10n, meal.nutrition.carbs),
        const Color(0xFF258AA5),
      ),
      (
        l10n.fatLabel,
        _grams(l10n, meal.nutrition.fat),
        const Color(0xFF9858B4),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 240),
          builder: (context, value, child) =>
              Opacity(opacity: value, child: child),
          child: Wrap(
            key: const ValueKey('mealNutritionGrid'),
            spacing: 12,
            runSpacing: 10,
            children: values
                .map(
                  (item) => SizedBox(
                    width: itemWidth,
                    child: _MacroValue(
                      label: item.$1,
                      value: item.$2,
                      color: item.$3,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
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
    final semantics = AppLocalizations.of(
      context,
    ).nutritionItemSemantics(label, value);
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
        ),
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
      ),
    );
  }
}

enum _AllergenLevel { contains, mayContain, traces }

class _AllergenDisplay {
  const _AllergenDisplay({required this.name, this.level});

  final String name;
  final String? level;

  _AllergenLevel get normalizedLevel {
    final normalized = (level ?? '').trim().toUpperCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );
    if (normalized == 'MAY_CONTAIN' || normalized == 'MAYCONTAIN') {
      return _AllergenLevel.mayContain;
    }
    if (normalized == 'TRACES' || normalized == 'TRACE') {
      return _AllergenLevel.traces;
    }
    return _AllergenLevel.contains;
  }
}

class _AllergenChip extends StatelessWidget {
  const _AllergenChip({required this.allergen});

  final _AllergenDisplay allergen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (
      label,
      background,
      foreground,
      icon,
    ) = switch (allergen.normalizedLevel) {
      _AllergenLevel.contains => (
        l10n.allergenContains(allergen.name),
        const Color(0xFFFFE5DF),
        const Color(0xFF9B2C20),
        Icons.warning_amber_rounded,
      ),
      _AllergenLevel.mayContain => (
        l10n.allergenMayContain(allergen.name),
        const Color(0xFFFFF1CF),
        const Color(0xFF8A5A00),
        Icons.info_outline_rounded,
      ),
      _AllergenLevel.traces => (
        l10n.allergenTraces(allergen.name),
        const Color(0xFFFFEADB),
        const Color(0xFF8A431D),
        Icons.grain_rounded,
      ),
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .94, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: Chip(
          key: ValueKey(
            'allergen-${allergen.normalizedLevel.name}-${allergen.name}',
          ),
          avatar: Icon(icon, size: 17, color: foreground),
          label: Text(label),
          backgroundColor: background,
          side: BorderSide(color: foreground.withValues(alpha: .16)),
          labelStyle: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
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
    if (url.isEmpty) {
      return SizedBox(
        key: const ValueKey('mealDetailHeroImage'),
        height: height,
        child: placeholder,
      );
    }
    return SizedBox(
      key: const ValueKey('mealDetailHeroImage'),
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

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);
