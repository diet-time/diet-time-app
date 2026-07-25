import 'package:diet_time/features/menu/domain/guest_home_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home parses metadata-only plans without meals', () {
    final response = GuestHomeResponse.fromJson({
      'data': {
        'mealPlans': [
          {
            'id': 'plan-1',
            'code': 'CLASSIC',
            'name': 'Classic',
            'description': 'Balanced meals.',
            'imageUrl': 'https://cdn.example.com/plan.jpg',
            'iconUrl': null,
            'displayOrder': 2,
            'isSelected': true,
            'slots': [
              {
                'id': 'slot-1',
                'mealTime': {
                  'id': 'time-1',
                  'code': 'BREAKFAST',
                  'name': 'Breakfast',
                  'displayOrder': 1,
                },
                'displayOrder': 1,
                'minimumSelection': 1,
                'maximumSelection': 1,
                'isRequired': true,
              },
            ],
          },
        ],
        'weeklyCalendar': [
          {
            'date': '2026-07-23',
            'dayNumber': 23,
            'dayName': 'Thursday',
            'shortDayName': 'Thu',
            'isToday': false,
            'isSelected': true,
            'isAvailable': true,
          },
        ],
      },
      'errors': <dynamic>[],
    });

    expect(response.data.mealPlans.single.code, 'CLASSIC');
    expect(
      response.data.mealPlans.single.slots.single.mealTime.code,
      'BREAKFAST',
    );
    expect(response.data.weeklyCalendar.single.date, DateTime(2026, 7, 23));
  });

  test('menu parses and sorts slots and meals', () {
    final response = GuestMenuResponse.fromJson({
      'data': {
        'planId': 'plan-1',
        'planCode': 'CLASSIC',
        'date': '2026-07-23',
        'slots': [
          {
            'id': 'slot-2',
            'mealTime': {'code': 'LUNCH', 'name': 'Lunch', 'displayOrder': 2},
            'displayOrder': 2,
            'minimumSelection': 1,
            'maximumSelection': 1,
            'isRequired': true,
            'meals': [
              {
                'id': 'meal-2',
                'code': 'DT-2',
                'name': 'Second',
                'nutrition': {
                  'calories': 420,
                  'protein': 35,
                  'carbs': 40,
                  'fat': 12,
                  'fiber': null,
                },
                'tags': <dynamic>[],
                'allergens': <dynamic>[],
                'isAvailable': true,
                'displayOrder': 2,
              },
              {
                'id': 'meal-1',
                'code': 'DT-1',
                'name': 'First',
                'nutrition': {
                  'calories': 400,
                  'protein': 30,
                  'carbs': 38,
                  'fat': 10,
                },
                'tags': <dynamic>[],
                'allergens': [
                  {'code': 'MILK', 'name': 'Milk'},
                ],
                'isAvailable': true,
                'displayOrder': 1,
              },
            ],
          },
        ],
      },
      'errors': <dynamic>[],
    });

    expect(response.data.planCode, 'CLASSIC');
    expect(response.data.date, DateTime(2026, 7, 23));
    expect(response.data.meals.map((meal) => meal.name), ['First', 'Second']);
    expect(response.data.meals.first.mealTime.name, 'Lunch');
    expect(response.data.meals.first.allergens.single.name, 'Milk');
  });
}
