import 'package:diet_time/features/language/presentation/language_controller.dart';
import 'package:diet_time/features/menu/data/guest_menu_repository.dart';
import 'package:diet_time/features/menu/data/meal_detail_repository.dart';
import 'package:diet_time/features/menu/domain/guest_home_models.dart';
import 'package:diet_time/features/menu/presentation/browse_menu_screen.dart';
import 'package:diet_time/features/menu/presentation/meal_detail_viewer.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('models safely parse optional filter id and nutrition fiber', () {
    final response = GuestHomeResponse.fromJson(_fixtureJson());

    expect(response.data.mealTimeFilters.first.id, isNull);
    expect(response.data.meals.first.nutrition.fiber, isNull);
    expect(response.data.weeklyCalendar.first.date, DateTime(2026, 7, 25));
  });

  test('models parse meals nested inside the selected plan slots', () {
    final response = GuestHomeResponse.fromJson(_nestedFixtureJson());
    final data = response.data;

    expect(data.hero.title, 'Balanced Living');
    expect(data.hero.bannerImageUrl, 'https://cdn.example.com/plan.png');
    expect(data.mealPlans.single.slots.single.mealTime.code, 'BREAKFAST');
    expect(data.meals.single.name, 'Oatmeal Banana');
    expect(data.meals.single.mealTime.name, 'Breakfast');
    expect(data.meals.single.nutrition.calories, 522);
  });

  test('meal details parse optional ingredients and micronutrients', () {
    final detail = MealDetailData.fromJson({
      'fullDescription': 'Complete meal description.',
      'primaryImageUrl': 'https://cdn.example.com/detail.jpg',
      'nutrition': {'fiberGrams': 4, 'sodiumMg': 343},
      'ingredients': [
        {'name': 'Olive oil', 'quantity': 10, 'unit': 'ml'},
      ],
      'allergens': [
        {'code': 'EGG', 'name': 'Egg'},
      ],
    });

    expect(detail.ingredients.single.name, 'Olive oil');
    expect(detail.fiberGrams, 4);
    expect(detail.sodiumMg, 343);
    expect(detail.allergens, ['Egg']);
  });

  test('absolute media URLs are not prefixed', () {
    const url = 'https://cdn.example.com/meal.jpg';
    expect(resolveMediaUrl(url), url);
    expect(resolveMediaUrl('/media/meal.jpg'), contains('/media/meal.jpg'));
  });

  testWidgets('guest menu renders API hero, selectors, dates, and meals', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    expect(find.text('Classic'), findsWidgets);
    expect(find.text('PLN_CLASSIC'), findsWidgets);
    expect(find.text('Oatmeal Banana'), findsOneWidget);
    expect(find.text('Breakfast'), findsWidgets);
    expect(
      find.byKey(const ValueKey('guest-plan-PLN_CLASSIC')),
      findsOneWidget,
    );
    expect(repository.calls.single.language, 'en');
    expect(repository.calls.single.includeAll, isTrue);
  });

  testWidgets('plan cards stay compact and omit their descriptions', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    final size = tester.getSize(
      find.byKey(const ValueKey('guest-plan-PLN_CLASSIC')),
    );
    expect(size.width, inInclusiveRange(120, 145));
    expect(size.height, inInclusiveRange(95, 110));
    expect(find.text('PLN_CLASSIC'), findsOneWidget);
  });

  testWidgets('phone layout displays two meal cards in each row', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    final firstCard = find.byKey(const ValueKey('guest-meal-meal-1'));
    final secondCard = find.byKey(const ValueKey('guest-meal-meal-2'));
    expect(firstCard, findsOneWidget);
    expect(secondCard, findsOneWidget);
    expect(tester.getTopLeft(firstCard).dy, tester.getTopLeft(secondCard).dy);
    expect(
      tester.getTopLeft(firstCard).dx,
      lessThan(tester.getTopLeft(secondCard).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a meal opens details at the tapped meal', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    await tester.tap(find.byKey(const ValueKey('guest-meal-meal-2')));
    await tester.pumpAndSettle();

    expect(find.byType(MealDetailViewer), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-detail-meal-2')), findsOneWidget);
    expect(find.text('SNACK / DESSERT'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('mealDetailPageIndicator')))
          .label,
      '2 / 2',
    );
    expect(
      find.byKey(const ValueKey('mealDetailImagePlaceholder')),
      findsWidgets,
    );
    expect(find.text('ALLERGENS'), findsOneWidget);
    expect(find.text('Egg'), findsOneWidget);
    expect(find.text('MICRONUTRIENTS'), findsOneWidget);
    expect(repository.calls, hasLength(1));
  });

  testWidgets('meal detail swipes locally and closes without losing menu', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    await tester.tap(find.byKey(const ValueKey('guest-meal-meal-1')));
    await tester.pumpAndSettle();
    expect(find.text('BREAKFAST'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('mealDetailPageView')),
      const Offset(-650, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('SNACK / DESSERT'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('mealDetailPageIndicator')))
          .label,
      '2 / 2',
    );
    expect(repository.calls, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('mealDetailClose')));
    await tester.pumpAndSettle();
    expect(find.byType(MealDetailViewer), findsNothing);
    expect(find.byKey(const ValueKey('guest-filter-ALL')), findsOneWidget);
    expect(repository.calls, hasLength(1));
  });

  testWidgets('system back closes meal details and preserves menu state', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    await tester.tap(find.byKey(const ValueKey('guest-meal-meal-1')));
    await tester.pumpAndSettle();
    expect(find.byType(MealDetailViewer), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(MealDetailViewer), findsNothing);
    expect(find.byType(BrowseMenuScreen), findsOneWidget);
    expect(repository.calls, hasLength(1));
  });

  testWidgets('tapped meal opens at its index and close preserves menu state', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    final card = find.byKey(const ValueKey('guest-meal-meal-2'));
    await tester.ensureVisible(card);
    final scrollController = tester
        .widget<CustomScrollView>(find.byType(CustomScrollView))
        .controller!;
    final offsetBeforeOpen = scrollController.offset;
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.byType(MealDetailViewer), findsOneWidget);
    final viewer = tester.widget<MealDetailViewer>(
      find.byType(MealDetailViewer),
    );
    expect(viewer.initialIndex, 1);
    expect(viewer.meals, hasLength(2));
    expect(find.bySemanticsLabel('2 / 2'), findsOneWidget);
    expect(repository.calls, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('mealDetailClose')));
    await tester.pumpAndSettle();
    expect(find.byType(MealDetailViewer), findsNothing);
    expect(scrollController.offset, closeTo(offsetBeforeOpen, .1));
    expect(repository.calls, hasLength(1));
  });

  testWidgets('meal detail swipe updates the page without an API request', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    final card = find.byKey(const ValueKey('guest-meal-meal-1'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('1 / 2'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('2 / 2'), findsOneWidget);
    expect(find.text('Protein Bite'), findsWidgets);
    expect(repository.calls, hasLength(1));
  });

  testWidgets('meal detail hides missing sections and back closes it', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    final card = find.byKey(const ValueKey('guest-meal-meal-1'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mealDetailImagePlaceholder')),
      findsWidgets,
    );
    final firstDetail = find.byKey(const ValueKey('meal-detail-meal-1'));
    expect(
      find.descendant(of: firstDetail, matching: find.text('Ingredients')),
      findsNothing,
    );
    expect(
      find.descendant(of: firstDetail, matching: find.text('MICRONUTRIENTS')),
      findsNothing,
    );
    expect(
      find.descendant(of: firstDetail, matching: find.text('ALLERGENS')),
      findsNothing,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MealDetailViewer), findsNothing);
    expect(repository.calls, hasLength(1));
  });

  testWidgets('meal detail follows Arabic RTL direction', (tester) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(
      _app(repository: repository, locale: const Locale('ar')),
    );
    await _load(tester);

    final card = find.byKey(const ValueKey('guest-meal-meal-1'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(MealDetailViewer))),
      TextDirection.rtl,
    );
    expect(repository.calls, hasLength(1));
  });

  testWidgets('optional meal detail request is cached once per meal', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final detailRepository = _FakeMealDetailRepository();
    final meals = [
      _detailMeal(
        id: '11111111-1111-4111-8111-111111111111',
        name: 'First Meal',
        mealTime: 'Breakfast',
      ),
      _detailMeal(
        id: '22222222-2222-4222-8222-222222222222',
        name: 'Second Meal',
        mealTime: 'Lunch',
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealDetailRepositoryProvider.overrideWithValue(detailRepository),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MealDetailViewer(meals: meals, initialIndex: 0),
        ),
      ),
    );
    await _load(tester);
    expect(detailRepository.calls, [meals.first.id]);
    expect(find.text('INGREDIENTS'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('mealDetailPageView')),
      const Offset(-650, 0),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('mealDetailPageView')),
      const Offset(650, 0),
    );
    await tester.pumpAndSettle();

    expect(detailRepository.calls, [meals.first.id, meals.last.id]);
  });

  testWidgets('calendar and filters remain pinned while meals scroll', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 450));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    final allFilter = find.byKey(const ValueKey('guest-filter-ALL'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(allFilter, findsOneWidget);
    expect(tester.getTopLeft(allFilter).dy, lessThan(150));
    expect(repository.calls, hasLength(1));
  });

  testWidgets('guest menu renders the new nested meal-plan response', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(
      GuestHomeResponse.fromJson(_nestedFixtureJson(includeImages: false)),
    );
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    expect(find.text('Balanced Living'), findsWidgets);
    expect(find.text('Oatmeal Banana'), findsOneWidget);
    expect(find.text('Breakfast'), findsWidgets);
    expect(find.byKey(const ValueKey('guest-meal-meal-1')), findsOneWidget);
  });

  testWidgets('plan, date, and meal-time selections filter without API calls', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('guest-plan-PLN_KETO')),
    );
    await tester.tap(find.byKey(const ValueKey('guest-plan-PLN_KETO')));
    await _load(tester);
    expect(repository.calls, hasLength(1));
    expect(find.text('Keto Omelette'), findsOneWidget);
    expect(find.text('Oatmeal Banana'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('guest-date-2026-07-26T00:00:00.000')),
    );
    await tester.tap(
      find.byKey(const ValueKey('guest-date-2026-07-26T00:00:00.000')),
    );
    await _load(tester);
    expect(repository.calls, hasLength(1));
    expect(find.text('Keto Chicken'), findsOneWidget);
    expect(find.text('Keto Omelette'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('guest-filter-LUNCH')),
    );
    await tester.tap(find.byKey(const ValueKey('guest-filter-LUNCH')));
    await _load(tester);
    expect(repository.calls, hasLength(1));
    expect(find.text('Keto Chicken'), findsOneWidget);
  });

  testWidgets('snack filter includes SNACK_DESSERT meals locally', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('guest-filter-SNACK')),
    );
    await tester.tap(find.byKey(const ValueKey('guest-filter-SNACK')));
    await _load(tester);

    expect(repository.calls, hasLength(1));
    expect(find.text('Protein Bite'), findsOneWidget);
    expect(find.text('Oatmeal Banana'), findsNothing);
  });

  testWidgets('empty local selection displays localized empty state', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('guest-filter-LUNCH')),
    );
    await tester.tap(find.byKey(const ValueKey('guest-filter-LUNCH')));
    await _load(tester);

    expect(repository.calls, hasLength(1));
    expect(find.text('No meals available for this selection.'), findsOneWidget);
    expect(find.text('Try another date or meal category.'), findsOneWidget);
  });

  testWidgets('widget rebuild does not repeat the initial request', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.calls, hasLength(1));
  });

  testWidgets('manual pull-to-refresh makes exactly one additional request', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repository.calls, hasLength(2));
  });

  testWidgets('language change makes one request and preserves page state', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    await tester.pumpWidget(
      _app(repository: repository, locale: const Locale('ar')),
    );
    await _load(tester);

    expect(repository.calls, hasLength(2));
    expect(repository.calls.last.language, 'ar');
    expect(
      Directionality.of(tester.element(find.byType(BrowseMenuScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('top language selector changes locale and reloads API once', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(_languageAwareApp(repository: repository));
    await _load(tester);

    expect(find.byKey(const ValueKey('guestLanguageSelector')), findsOneWidget);
    expect(repository.calls, hasLength(1));
    expect(repository.calls.single.language, 'en');

    await tester.tap(find.byKey(const ValueKey('guestLanguageSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guest-language-ar')));
    await _load(tester);

    expect(repository.calls, hasLength(2));
    expect(repository.calls.last.language, 'ar');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('preferredLanguage'), 'ar');
    expect(
      Directionality.of(tester.element(find.byType(BrowseMenuScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('local filtering preserves source data and stable meal element', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final response = _response();
    final originalMenuCount = response.data.menus.length;
    final originalMealCount = response.data.menus.first.slots
        .expand((slot) => slot.meals)
        .length;
    final repository = _FakeGuestMenuRepository(response);
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);
    final originalElement = tester.element(
      find.byKey(const ValueKey('guest-meal-meal-1')),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('guest-filter-BREAKFAST')),
    );
    await tester.tap(find.byKey(const ValueKey('guest-filter-BREAKFAST')));
    await _load(tester);

    expect(repository.calls, hasLength(1));
    expect(
      tester.element(find.byKey(const ValueKey('guest-meal-meal-1'))),
      same(originalElement),
    );
    expect(response.data.menus, hasLength(originalMenuCount));
    expect(
      response.data.menus.first.slots.expand((slot) => slot.meals),
      hasLength(originalMealCount),
    );
  });

  testWidgets('API failure displays retry and retry repeats the request', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(
      _response(),
      failuresRemaining: 1,
    );
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);

    expect(find.text('Unable to load the menu.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await _load(tester);
    expect(repository.calls, hasLength(2));
    expect(find.text('Oatmeal Banana'), findsOneWidget);
  });

  testWidgets('Arabic mode requests Arabic and applies RTL', (tester) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response());
    await tester.pumpWidget(
      _app(repository: repository, locale: const Locale('ar')),
    );
    await _load(tester);

    expect(repository.calls.single.language, 'ar');
    expect(
      Directionality.of(tester.element(find.byType(BrowseMenuScreen))),
      TextDirection.rtl,
    );
    await tester.tap(find.byKey(const ValueKey('guest-meal-meal-1')));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(MealDetailViewer))),
      TextDirection.rtl,
    );
    expect(repository.calls, hasLength(1));
  });
}

Future<void> _load(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _app({
  required GuestMenuRepository repository,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [guestMenuRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const BrowseMenuScreen(),
    ),
  );
}

Widget _languageAwareApp({required GuestMenuRepository repository}) {
  return ProviderScope(
    overrides: [guestMenuRepositoryProvider.overrideWithValue(repository)],
    child: const _LanguageAwareTestApp(),
  );
}

class _LanguageAwareTestApp extends ConsumerWidget {
  const _LanguageAwareTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageControllerProvider);
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const BrowseMenuScreen(),
    );
  }
}

class _FakeMealDetailRepository implements MealDetailRepository {
  final calls = <String>[];

  @override
  Future<MealDetailData?> getMealDetail({
    required String mealId,
    required String language,
  }) async {
    calls.add(mealId);
    return const MealDetailData(
      fullDescription: 'Loaded detail description.',
      fiberGrams: 4,
      sodiumMg: 343,
      ingredients: [
        MealDetailIngredient(name: 'Olive oil', quantity: 10, unit: 'ml'),
      ],
      allergens: ['Egg'],
    );
  }
}

GuestMeal _detailMeal({
  required String id,
  required String name,
  required String mealTime,
}) {
  return GuestMeal.fromJson({
    'id': id,
    'code': id,
    'name': name,
    'description': '$name description.',
    'mealTime': {'code': mealTime.toUpperCase(), 'name': mealTime},
    'nutrition': {'calories': 400, 'protein': 25, 'carbs': 30, 'fat': 12},
    'tags': <dynamic>[],
    'allergens': <dynamic>[],
    'isAvailable': true,
    'displayOrder': 0,
  });
}

class _FakeGuestMenuRepository implements GuestMenuRepository {
  _FakeGuestMenuRepository(this.response, {this.failuresRemaining = 0});

  final GuestHomeResponse response;
  int failuresRemaining;
  final calls = <_Request>[];

  @override
  Future<GuestHomeResponse> getGuestHome({
    required String language,
    DateTime? date,
    String? planCode,
    String mealTimeCode = 'ALL',
    int page = 1,
    int pageSize = 20,
    bool includeAll = true,
  }) async {
    calls.add(
      _Request(
        language: language,
        date: date,
        planCode: planCode,
        mealTimeCode: mealTimeCode,
        includeAll: includeAll,
      ),
    );
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw const GuestMenuException();
    }
    return response;
  }
}

class _Request {
  const _Request({
    required this.language,
    required this.date,
    required this.planCode,
    required this.mealTimeCode,
    required this.includeAll,
  });

  final String language;
  final DateTime? date;
  final String? planCode;
  final String mealTimeCode;
  final bool includeAll;
}

GuestHomeResponse _response() => GuestHomeResponse.fromJson(_fixtureJson());

Map<String, dynamic> _fixtureJson() {
  return {
    'data': {
      'hero': {
        'title': 'Classic',
        'subtitle': 'PLN_CLASSIC',
        'bannerImageUrl': '',
      },
      'mealPlans': [
        {
          'id': 'plan-1',
          'code': 'PLN_CLASSIC',
          'name': 'Classic',
          'description': 'PLN_CLASSIC',
          'imageUrl': '',
          'displayOrder': 1,
          'isSelected': true,
        },
        {
          'id': 'plan-2',
          'code': 'PLN_KETO',
          'name': 'Keto',
          'description': 'PLN_KETO',
          'imageUrl': '',
          'displayOrder': 2,
          'isSelected': false,
        },
      ],
      'weeklyCalendar': [
        {
          'date': '2026-07-25',
          'dayNumber': 25,
          'dayName': 'Saturday',
          'shortDayName': 'Sat',
          'isToday': false,
          'isSelected': true,
          'isAvailable': true,
        },
        {
          'date': '2026-07-26',
          'dayNumber': 26,
          'dayName': 'Sunday',
          'shortDayName': 'Sun',
          'isToday': false,
          'isSelected': false,
          'isAvailable': true,
        },
      ],
      'mealTimeFilters': [
        {'code': 'ALL', 'name': 'All', 'displayOrder': 0, 'isSelected': true},
        {
          'id': 'filter-1',
          'code': 'BREAKFAST',
          'name': 'Breakfast',
          'displayOrder': 1,
          'isSelected': false,
        },
        {
          'id': 'filter-2',
          'code': 'LUNCH',
          'name': 'Lunch',
          'displayOrder': 2,
          'isSelected': false,
        },
        {
          'id': 'filter-3',
          'code': 'SNACK',
          'name': 'Snacks',
          'displayOrder': 3,
          'isSelected': false,
        },
      ],
      'meals': [
        {
          'id': 'meal-1',
          'code': 'DT-001',
          'name': 'Oatmeal Banana',
          'description': 'Creamy oatmeal with banana.',
          'imageUrl': '',
          'thumbnailUrl': '',
          'mealTime': {'code': 'BREAKFAST', 'name': 'Breakfast'},
          'nutrition': {
            'calories': 522.0,
            'protein': 22.5,
            'carbs': 82.2,
            'fat': 12.4,
          },
          'tags': <dynamic>[],
          'allergens': <dynamic>[],
          'isAvailable': true,
          'displayOrder': 0,
        },
      ],
      'menus': [
        {
          'planCode': 'PLN_CLASSIC',
          'date': '2026-07-25',
          'slots': [
            {
              'id': 'classic-breakfast',
              'mealTime': {'code': 'BREAKFAST', 'name': 'Breakfast'},
              'displayOrder': 1,
              'minimumSelection': 1,
              'maximumSelection': 1,
              'isRequired': true,
              'meals': [
                {
                  'id': 'meal-1',
                  'code': 'DT-001',
                  'name': 'Oatmeal Banana',
                  'description': 'Creamy oatmeal with banana.',
                  'imageUrl': '',
                  'thumbnailUrl': '',
                  'nutrition': {
                    'calories': 522.0,
                    'protein': 22.5,
                    'carbs': 82.2,
                    'fat': 12.4,
                  },
                  'tags': <dynamic>[],
                  'allergens': <dynamic>[],
                  'isAvailable': true,
                  'displayOrder': 0,
                },
              ],
            },
            {
              'id': 'classic-snack',
              'mealTime': {'code': 'SNACK_DESSERT', 'name': 'Snack / Dessert'},
              'displayOrder': 2,
              'minimumSelection': 1,
              'maximumSelection': 1,
              'isRequired': true,
              'meals': [
                {
                  'id': 'meal-2',
                  'code': 'DT-002',
                  'name': 'Protein Bite',
                  'description': 'A compact protein snack.',
                  'imageUrl': '',
                  'thumbnailUrl': '',
                  'nutrition': {
                    'calories': 180.0,
                    'protein': 12.0,
                    'carbs': 16.0,
                    'fat': 7.0,
                    'fiber': 4.0,
                  },
                  'tags': <dynamic>[],
                  'allergens': [
                    {'code': 'EGG', 'name': 'Egg'},
                  ],
                  'isAvailable': true,
                  'displayOrder': 0,
                },
              ],
            },
          ],
        },
        {
          'planCode': 'PLN_KETO',
          'date': '2026-07-25',
          'slots': [
            {
              'id': 'keto-breakfast',
              'mealTime': {'code': 'BREAKFAST', 'name': 'Breakfast'},
              'displayOrder': 1,
              'minimumSelection': 1,
              'maximumSelection': 1,
              'isRequired': true,
              'meals': [
                {
                  'id': 'meal-3',
                  'code': 'DT-003',
                  'name': 'Keto Omelette',
                  'description': 'Eggs, cheese, and greens.',
                  'imageUrl': '',
                  'thumbnailUrl': '',
                  'nutrition': {
                    'calories': 410.0,
                    'protein': 30.0,
                    'carbs': 8.0,
                    'fat': 28.0,
                  },
                  'tags': <dynamic>[],
                  'allergens': <dynamic>[],
                  'isAvailable': true,
                  'displayOrder': 0,
                },
              ],
            },
          ],
        },
        {
          'planCode': 'PLN_KETO',
          'date': '2026-07-26',
          'slots': [
            {
              'id': 'keto-lunch',
              'mealTime': {'code': 'LUNCH', 'name': 'Lunch'},
              'displayOrder': 1,
              'minimumSelection': 1,
              'maximumSelection': 1,
              'isRequired': true,
              'meals': [
                {
                  'id': 'meal-4',
                  'code': 'DT-004',
                  'name': 'Keto Chicken',
                  'description': 'Chicken with low-carb vegetables.',
                  'imageUrl': '',
                  'thumbnailUrl': '',
                  'nutrition': {
                    'calories': 560.0,
                    'protein': 42.0,
                    'carbs': 12.0,
                    'fat': 34.0,
                  },
                  'tags': <dynamic>[],
                  'allergens': <dynamic>[],
                  'isAvailable': true,
                  'displayOrder': 0,
                },
              ],
            },
          ],
        },
      ],
      'pagination': {
        'page': 1,
        'pageSize': 20,
        'totalRecords': 1,
        'totalPages': 1,
        'hasNextPage': false,
        'hasPreviousPage': false,
      },
    },
    'errors': <dynamic>[],
  };
}

Map<String, dynamic> _nestedFixtureJson({bool includeImages = true}) {
  return {
    'data': {
      'mealPlans': [
        {
          'id': 'plan-1',
          'code': 'PLN_CLASSIC',
          'name': 'Balanced Living',
          'description': 'Fresh balanced meals for a healthy lifestyle.',
          'imageUrl': includeImages ? 'https://cdn.example.com/plan.png' : '',
          'displayOrder': 1,
          'isSelected': true,
          'slots': [
            {
              'id': 'slot-1',
              'mealTime': {
                'id': 'meal-time-1',
                'code': 'BREAKFAST',
                'name': 'Breakfast',
                'displayOrder': 5,
              },
              'displayOrder': 0,
              'minimumSelection': 1,
              'maximumSelection': 1,
              'isRequired': true,
              'meals': [
                {
                  'id': 'meal-1',
                  'code': 'DT-IMP-0001',
                  'name': 'Oatmeal Banana',
                  'description': 'Creamy oatmeal with banana.',
                  'imageUrl': includeImages
                      ? 'https://cdn.example.com/meal.jpg'
                      : '',
                  'thumbnailUrl': includeImages
                      ? 'https://cdn.example.com/meal-thumb.jpg'
                      : '',
                  'nutrition': {
                    'calories': 522.0,
                    'protein': 22.5,
                    'carbs': 82.2,
                    'fat': 12.4,
                    'fiber': 0.0,
                  },
                  'tags': <dynamic>[],
                  'allergens': <dynamic>[],
                  'isAvailable': true,
                  'displayOrder': 0,
                },
              ],
            },
          ],
        },
      ],
      'weeklyCalendar': [
        {
          'date': '2026-07-25',
          'dayNumber': 25,
          'dayName': 'Saturday',
          'shortDayName': 'Sat',
          'isToday': false,
          'isSelected': true,
          'isAvailable': true,
        },
      ],
      'mealTimeFilters': [
        {'code': 'ALL', 'name': 'All', 'displayOrder': 0, 'isSelected': true},
        {
          'id': 'meal-time-1',
          'code': 'BREAKFAST',
          'name': 'Breakfast',
          'displayOrder': 5,
          'isSelected': false,
        },
      ],
      'pagination': {
        'page': 1,
        'pageSize': 20,
        'totalRecords': 1,
        'totalPages': 1,
        'hasNextPage': false,
        'hasPreviousPage': false,
      },
    },
    'errors': <dynamic>[],
  };
}
