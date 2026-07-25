import 'package:diet_time/features/menu/data/guest_menu_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home URI contains only the lightweight endpoint parameters', () {
    final uri = buildGuestHomeUri(
      baseUrl: 'https://api.example.com',
      language: 'en',
      date: DateTime(2026, 7, 23, 18, 45),
      planCode: 'CLASSIC',
    );

    expect(uri.path, '/api/v1/guest/home');
    expect(uri.queryParameters, {
      'language': 'en',
      'date': '2026-07-23',
      'planCode': 'CLASSIC',
    });
    expect(uri.queryParameters, isNot(contains('includeAll')));
    expect(uri.queryParameters, isNot(contains('mealTimeCode')));
    expect(uri.queryParameters, isNot(contains('page')));
    expect(uri.queryParameters, isNot(contains('pageSize')));
  });

  test('menu URI encodes plan code and formats date strictly', () {
    final uri = buildGuestMenuUri(
      baseUrl: 'https://api.example.com',
      planCode: 'CLASSIC / PLUS',
      date: DateTime(2026, 7, 3, 23, 59),
      language: 'ar',
    );

    expect(
      uri.toString(),
      'https://api.example.com/api/v1/guest/meal-plans/'
      'CLASSIC%20%2F%20PLUS/menu?date=2026-07-03&language=ar',
    );
  });
}
