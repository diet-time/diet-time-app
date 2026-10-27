import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final upcomingMealsRepositoryProvider = Provider<UpcomingMealsRepository>((
  ref,
) {
  final storage = ref.watch(secureStorageServiceProvider);
  return UpcomingMealsRepository(
    ref.watch(apiClientProvider),
    () => storage.read(SecureStorageService.accessTokenKey),
  );
});

final upcomingMealDaysProvider = FutureProvider.autoDispose
    .family<List<UpcomingMealDay>, String>(
      (ref, orderId) =>
          ref.watch(upcomingMealsRepositoryProvider).getDays(orderId),
      retry: (_, _) => null,
    );

typedef DailyMenuRequest = ({String orderId, String dayId, String language});
final dailyMealMenuProvider = FutureProvider.autoDispose
    .family<DailyMealMenu, DailyMenuRequest>(
      (ref, request) =>
          ref.watch(upcomingMealsRepositoryProvider).getMenu(request),
      retry: (_, _) => null,
    );

class UpcomingMealsRepository {
  const UpcomingMealsRepository(this.api, this.accessToken);
  final ApiClient api;
  final Future<String?> Function() accessToken;

  String _base(String orderId) =>
      '/api/v1/orders/${Uri.encodeComponent(orderId)}';
  String _menuPath(DailyMenuRequest request) =>
      '${_base(request.orderId)}/service-days/${Uri.encodeComponent(request.dayId)}';

  Future<List<UpcomingMealDay>> getDays(String orderId) async {
    final data = await _request('GET', '${_base(orderId)}/upcoming-meals');
    if (data is! List) throw const ApiException(ApiFailure.invalidResponse);
    final days = data
        .map((j) => UpcomingMealDay.fromJson(j as Map<String, dynamic>))
        .toList();
    if (days.any((day) => day.orderId != null && day.orderId != orderId)) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return days;
  }

  Future<DailyMealMenu> getMenu(DailyMenuRequest request) async {
    final data = await _request(
      'GET',
      '${_menuPath(request)}/menu',
      language: request.language,
    );
    final menu = DailyMealMenu.fromJson(data as Map<String, dynamic>);
    if (menu.dayId != request.dayId ||
        (menu.orderId != null && menu.orderId != request.orderId)) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return menu;
  }

  Future<DailyMealMenu> replace(
    DailyMenuRequest request,
    AssignedDailyMeal selection,
    DailyMealItem replacement,
    int revision,
  ) async {
    final data = await _request(
      'PUT',
      '${_menuPath(request)}/meal-selections/${Uri.encodeComponent(selection.id)}',
      language: request.language,
      body: {
        'mealItemId': replacement.id,
        'slotOptionId': replacement.optionId,
        'expectedRevision': revision,
      },
    );
    final menu = DailyMealMenu.fromJson(data as Map<String, dynamic>);
    if (menu.dayId != request.dayId) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return menu;
  }

  Future<Object?> _request(
    String method,
    String path, {
    String? language,
    Map<String, dynamic>? body,
  }) async {
    final token = await accessToken();
    if (token?.trim().isNotEmpty != true) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    final response = await api.request(
      method: method,
      path: path,
      queryParameters: {'language': ?language},
      headers: {'Authorization': 'Bearer ${token!.trim()}'},
      body: body,
    );
    if (!response.isSuccess) throw ApiException.fromResponse(response);
    return response.body['data'];
  }
}
