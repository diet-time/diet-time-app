import 'package:diet_time/features/menu/data/guest_menu_repository.dart';
import 'package:diet_time/features/menu/domain/guest_home_models.dart';
import 'package:diet_time/features/menu/presentation/browse_menu_screen.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  testWidgets('guest menu renders the new nested meal-plan response', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(
      GuestHomeResponse.fromJson(_nestedFixtureJson()),
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

Map<String, dynamic> _nestedFixtureJson() {
  return {
    'data': {
      'mealPlans': [
        {
          'id': 'plan-1',
          'code': 'PLN_CLASSIC',
          'name': 'Balanced Living',
          'description': 'Fresh balanced meals for a healthy lifestyle.',
          'imageUrl': 'https://cdn.example.com/plan.png',
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
                  'imageUrl': 'https://cdn.example.com/meal.jpg',
                  'thumbnailUrl': 'https://cdn.example.com/meal-thumb.jpg',
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
