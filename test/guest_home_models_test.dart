import 'package:diet_time/features/menu/domain/guest_home_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses day-specific menu entries from meal plan menus when top-level menus are absent', () {
    final data = GuestHomeData.fromJson({
      'hero': <String, dynamic>{},
      'mealPlans': [
        {
          'id': 'plan-1',
          'code': 'PLN_CLASSIC',
          'name': 'Balanced Living',
          'description': 'Balanced meals',
          'imageUrl': 'https://example.com/plan.png',
          'displayOrder': 1,
          'isSelected': true,
          'slots': <Map<String, dynamic>>[],
          'menus': [
            {
              'planCode': 'PLN_CLASSIC',
              'date': '2026-07-25',
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
                      'description': 'A wholesome breakfast',
                      'imageUrl': 'https://example.com/meal.png',
                      'thumbnailUrl': 'https://example.com/meal-thumb.png',
                      'nutrition': {
                        'calories': 522,
                        'protein': 22.5,
                        'carbs': 82.2,
                        'fat': 12.4,
                      },
                      'tags': [],
                      'allergens': [],
                      'isAvailable': true,
                      'displayOrder': 0,
                    },
                  ],
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
        {
          'code': 'ALL',
          'name': 'All',
          'displayOrder': 0,
          'isSelected': true,
        },
      ],
      'menus': null,
      'pagination': {
        'page': 1,
        'pageSize': 20,
        'totalRecords': 1,
        'totalPages': 1,
        'hasNextPage': false,
        'hasPreviousPage': false,
      },
    });

    expect(data.menus, hasLength(1));
    expect(data.menus.single.date, DateTime(2026, 7, 25));
    expect(data.menus.single.slots.single.meals.single.name, 'Oatmeal Banana');
  });
}
