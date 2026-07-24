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

  testWidgets('plan, date, and meal-time selections reload with query values', (
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
    expect(repository.calls.last.planCode, 'PLN_KETO');

    await tester.ensureVisible(
      find.byKey(const ValueKey('guest-date-2026-07-26T00:00:00.000')),
    );
    await tester.tap(
      find.byKey(const ValueKey('guest-date-2026-07-26T00:00:00.000')),
    );
    await _load(tester);
    expect(repository.calls.last.date, DateTime(2026, 7, 26));

    await tester.ensureVisible(
      find.byKey(const ValueKey('guest-filter-BREAKFAST')),
    );
    await tester.tap(find.byKey(const ValueKey('guest-filter-BREAKFAST')));
    await _load(tester);
    expect(repository.calls.last.mealTimeCode, 'BREAKFAST');
  });

  testWidgets('empty API meal list displays localized empty state', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakeGuestMenuRepository(_response(meals: const []));
    await tester.pumpWidget(_app(repository: repository));
    await _load(tester);
    expect(find.text('No meals available.'), findsOneWidget);
    expect(find.text('Try another date or meal category.'), findsOneWidget);
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
  }) async {
    calls.add(
      _Request(
        language: language,
        date: date,
        planCode: planCode,
        mealTimeCode: mealTimeCode,
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
  });

  final String language;
  final DateTime? date;
  final String? planCode;
  final String mealTimeCode;
}

GuestHomeResponse _response({List<GuestMeal>? meals}) {
  final json = _fixtureJson();
  if (meals != null) {
    final data = Map<String, dynamic>.from(
      json['data']! as Map<String, dynamic>,
    );
    data['meals'] = meals
        .map(
          (meal) => {
            'id': meal.id,
            'code': meal.code,
            'name': meal.name,
            'description': meal.description,
            'imageUrl': meal.imageUrl,
            'thumbnailUrl': meal.thumbnailUrl,
            'mealTime': {
              'code': meal.mealTime.code,
              'name': meal.mealTime.name,
            },
            'nutrition': {
              'calories': meal.nutrition.calories,
              'protein': meal.nutrition.protein,
              'carbs': meal.nutrition.carbs,
              'fat': meal.nutrition.fat,
            },
            'tags': <dynamic>[],
            'allergens': <dynamic>[],
            'isAvailable': meal.isAvailable,
            'displayOrder': meal.displayOrder,
          },
        )
        .toList();
    json['data'] = data;
  }
  return GuestHomeResponse.fromJson(json);
}

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
