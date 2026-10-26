import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'an older active order on the second page remains visible to the dashboard',
    () async {
      final api = PagedOrdersApi();
      final repository = OrdersRepository(
        apiClient: api,
        accessTokenProvider: () async => 'token',
      );
      final orders = await repository.getCustomerOrders('profile', pageSize: 1);
      expect(api.pages, [1, 2]);
      expect(orders.where((o) => o.isCurrent).single.id, 'active');
    },
  );
  test(
    'an incomplete page is a request failure rather than an empty order list',
    () async {
      final repository = OrdersRepository(
        apiClient: PagedOrdersApi()..incomplete = true,
        accessTokenProvider: () async => 'token',
      );
      await expectLater(
        repository.getCustomerOrders('profile', pageSize: 1),
        throwsA(isA<ApiException>()),
      );
    },
  );
  test('pending activation orders are recognized as current plans', () {
    expect(
      CustomerOrderSummary.fromJson(
        orderJson('pending', 'PENDING_ACTIVATION'),
      ).isCurrent,
      isTrue,
    );
  });
}

Map<String, dynamic> orderJson(String id, String status) => {
  'id': id,
  'orderNumber': 'ORD-$id',
  'planName': 'Complete Balance',
  'status': status,
  'paymentStatus': 'PAID',
  'totalAmount': 500,
  'currencyCode': 'QAR',
  'startDate': '2026-10-27',
  'endDate': '2026-11-10',
  'placedAt': '2026-10-20T12:00:00Z',
};

class PagedOrdersApi extends ApiClient {
  bool incomplete = false;
  final pages = <int>[];
  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    final page = int.parse(queryParameters['pageNumber']!);
    pages.add(page);
    return ApiResponse(
      statusCode: 200,
      body: {
        'items': page == 1
            ? [orderJson('cancelled', 'CANCELLED')]
            : incomplete
            ? []
            : [orderJson('active', 'ACTIVE')],
        'pageNumber': page,
        'pageSize': 1,
        'totalCount': 2,
      },
    );
  }
}
