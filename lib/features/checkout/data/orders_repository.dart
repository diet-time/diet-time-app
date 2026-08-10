import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return OrdersRepository(
    apiClient: ref.watch(apiClientProvider),
    accessTokenProvider: () =>
        storage.read(SecureStorageService.accessTokenKey),
  );
});

class OrdersRepository {
  const OrdersRepository({
    required this.apiClient,
    required this.accessTokenProvider,
  });

  final ApiClient apiClient;
  final Future<String?> Function() accessTokenProvider;

  Future<OrderConfirmation> placeOrder(
    PlaceOrderRequest request,
    String idempotencyKey,
  ) async {
    final response = await _request(
      method: 'POST',
      path: ApiEndpoints.orders,
      headers: {'Idempotency-Key': idempotencyKey},
      body: request.toJson(),
    );
    if (response.statusCode != 201) {
      throw ApiException(
        ApiFailure.invalidResponse,
        statusCode: response.statusCode,
        message: 'The order service returned an unexpected response.',
      );
    }
    final confirmation = OrderConfirmation.fromJson(_orderFrom(response.body));
    if (!confirmation.isValid) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return confirmation;
  }

  Future<List<OrderConfirmation>> getCustomerOrders(String profileId) async {
    final response = await _request(
      method: 'GET',
      path: ApiEndpoints.customerOrders(profileId),
    );
    final raw = response.body['data'];
    Object? items = raw;
    if (raw is Map<String, dynamic>) items = raw['orders'] ?? raw['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(OrderConfirmation.fromJson)
        .where((order) => order.isValid)
        .toList(growable: false);
  }

  Future<OrderConfirmation> getOrder(String orderId) async {
    final response = await _request(
      method: 'GET',
      path: ApiEndpoints.order(orderId),
    );
    final order = OrderConfirmation.fromJson(_orderFrom(response.body));
    if (!order.isValid) throw const ApiException(ApiFailure.invalidResponse);
    return order;
  }

  Future<ApiResponse> _request({
    required String method,
    required String path,
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    final token = await accessTokenProvider();
    final response = await apiClient.request(
      method: method,
      path: path,
      headers: {
        if (token?.trim().isNotEmpty == true)
          'Authorization': 'Bearer ${token!.trim()}',
        ...headers,
      },
      body: body,
    );
    if (!response.isSuccess) throw ApiException.fromResponse(response);
    return response;
  }
}

Map<String, dynamic> _orderFrom(Map<String, dynamic> body) {
  final data = body['data'];
  if (data is Map<String, dynamic>) {
    final nested = data['order'];
    return nested is Map<String, dynamic> ? nested : data;
  }
  final order = body['order'];
  return order is Map<String, dynamic> ? order : body;
}
