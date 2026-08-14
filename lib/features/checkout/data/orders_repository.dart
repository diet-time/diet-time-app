import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

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
      throw const ApiException(
        ApiFailure.invalidResponse,
        message: 'The order confirmation response was incomplete.',
      );
    }
    return confirmation;
  }

  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
  }) async {
    final page = await getCustomerOrdersPage(
      profileId,
      pageNumber: 1,
      pageSize: pageSize,
    );
    return page.items;
  }

  Future<CustomerOrdersPage> getCustomerOrdersPage(
    String profileId, {
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final path = ApiEndpoints.customerOrders(profileId);
    final query = {'pageNumber': '$pageNumber', 'pageSize': '$pageSize'};
    _logOrders('GET $path?pageNumber=$pageNumber&pageSize=$pageSize');
    final response = await _request(
      method: 'GET',
      path: path,
      queryParameters: query,
    );
    try {
      final page = CustomerOrdersPage.fromJson(response.body);
      _logOrders(
        'Parsed ${page.items.length} items; totalCount=${page.totalCount}',
      );
      return page;
    } on Object catch (error) {
      _logOrders('Parsing failed: ${error.runtimeType}');
      throw const ApiException(
        ApiFailure.invalidResponse,
        message: 'The customer orders response was invalid.',
      );
    }
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
    Map<String, String> queryParameters = const {},
    Map<String, dynamic>? body,
  }) async {
    final token = await accessTokenProvider();
    final response = await apiClient.request(
      method: method,
      path: path,
      queryParameters: queryParameters,
      headers: {
        if (token?.trim().isNotEmpty == true)
          'Authorization': 'Bearer ${token!.trim()}',
        ...headers,
      },
      body: body,
    );
    if (path.contains('/customer-profiles/') && path.endsWith('/orders')) {
      _logOrders('HTTP ${response.statusCode}');
    }
    if (!response.isSuccess) throw ApiException.fromResponse(response);
    return response;
  }
}

void _logOrders(String message) {
  if (kDebugMode) debugPrint('[CustomerOrders] $message');
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
