import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/dashboard/domain/tomorrow_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tomorrowMenuRepositoryProvider = Provider<TomorrowMenuRepository>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return TomorrowMenuRepository(
    ref.watch(apiClientProvider),
    () => storage.read(SecureStorageService.accessTokenKey),
  );
});

class TomorrowMenuRepository {
  const TomorrowMenuRepository(this.api, this.accessToken);
  final ApiClient api;
  final Future<String?> Function() accessToken;

  Future<TomorrowMenu> get(String orderId, String language) =>
      _request(orderId, language, 'GET', 'tomorrow-menu');

  Future<TomorrowMenu> confirm(
    String orderId,
    String dayId,
    String language,
    Set<String> meals,
    Set<String> snacks,
  ) => _request(
    orderId,
    language,
    'POST',
    'service-days/${Uri.encodeComponent(dayId)}/confirm-meals',
    body: {
      'mealMenuItemIds': meals.toList(growable: false),
      'snackMenuItemIds': snacks.toList(growable: false),
    },
    expectedDayId: dayId,
  );

  Future<TomorrowMenu> _request(
    String orderId,
    String language,
    String method,
    String suffix, {
    Map<String, dynamic>? body,
    String? expectedDayId,
  }) async {
    final token = await accessToken();
    if (token?.trim().isNotEmpty != true) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    final response = await api.request(
      method: method,
      path: '/api/v1/orders/${Uri.encodeComponent(orderId)}/$suffix',
      queryParameters: {'language': language},
      headers: {'Authorization': 'Bearer ${token!.trim()}'},
      body: body,
    );
    if (!response.isSuccess) throw ApiException.fromResponse(response);
    try {
      final menu = TomorrowMenu.fromJson(
        response.body['data'] as Map<String, dynamic>,
      );
      if (menu.subscriptionId != orderId ||
          (expectedDayId != null &&
              (menu.dayId != expectedDayId ||
                  menu.status != 'CUSTOMER_CONFIRMED' ||
                  !menu.locked))) {
        throw const FormatException('Unexpected confirmation response');
      }
      return menu;
    } on Object {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }
}
