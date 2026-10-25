import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/dashboard/data/upcoming_meals_repository.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const request = (orderId: 'order-1', dayId: 'day-1', language: 'en');

  test(
    'daily menu GET authenticates and uses the selected order and day',
    () async {
      final api = _Api();
      final menu = await UpcomingMealsRepository(
        api,
        () async => 'token',
      ).getMenu(request);
      expect(api.path, '/api/v1/orders/order-1/service-days/day-1/menu');
      expect(api.headers['Authorization'], 'Bearer token');
      expect(api.query, {'language': 'en'});
      expect(menu.dayId, 'day-1');
      expect(menu.revision, 7);
    },
  );

  test('missing authentication cannot issue a menu request', () async {
    final api = _Api();
    await expectLater(
      UpcomingMealsRepository(api, () async => null).getDays('order-1'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          ApiFailure.unauthorized,
        ),
      ),
    );
    expect(api.path, isNull);
  });

  test('a response for another service day is rejected', () async {
    final api = _Api()..dayId = 'another-day';
    await expectLater(
      UpcomingMealsRepository(api, () async => 'token').getMenu(request),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          ApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test(
    'replacement updates only the chosen selection with its expected revision',
    () async {
      final api = _Api();
      const meal = DailyMealItem(
        id: 'replacement',
        optionId: 'configured-option',
        name: 'Chicken',
        category: 'meal',
      );
      await UpcomingMealsRepository(api, () async => 'token').replace(
        request,
        const AssignedDailyMeal(
          id: 'selection-3',
          source: 'automatic',
          meal: meal,
        ),
        meal,
        7,
      );
      expect(api.method, 'PUT');
      expect(
        api.path,
        '/api/v1/orders/order-1/service-days/day-1/meal-selections/selection-3',
      );
      expect(api.body, {
        'mealItemId': 'replacement',
        'slotOptionId': 'configured-option',
        'expectedRevision': 7,
      });
    },
  );

  test('server conflicts retain status for refresh guidance', () async {
    final api = _Api()..status = 409;
    await expectLater(
      UpcomingMealsRepository(api, () async => 'token').getMenu(request),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
    );
  });
}

class _Api extends ApiClient {
  String? path;
  String? method;
  Map<String, String> headers = {};
  Map<String, String> query = {};
  Map<String, dynamic>? body;
  int status = 200;
  String dayId = 'day-1';

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    this.path = path;
    this.method = method;
    this.headers = headers;
    query = queryParameters;
    this.body = body;
    return ApiResponse(
      statusCode: status,
      body: {
        'data': {
          'subscriptionServiceDayId': dayId,
          'deliveryDate': '2030-10-27',
          'mealCount': 3,
          'snackCount': 1,
          'status': 'auto_selected',
          'canEdit': true,
          'revision': 7,
          'selectedMeals': [],
          'availableAlternatives': [],
        },
      },
    );
  }
}
