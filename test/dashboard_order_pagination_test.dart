import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'dashboard uses one summary request without history pagination',
    () async {
      final api = DashboardOrdersApi();
      final repository = OrdersRepository(
        apiClient: api,
        accessTokenProvider: () async => 'token',
      );
      final orders = await repository.getCustomerOrders(
        'profile',
        dashboard: true,
      );
      expect(orders.single.id, 'active');
      expect(api.paths, ['/api/v1/customer-profiles/profile/orders/dashboard']);
    },
  );
  test(
    'an older API without a dashboard route falls back to complete history',
    () async {
      final api = DashboardOrdersApi()..summaryStatus = 404;
      final repository = OrdersRepository(
        apiClient: api,
        accessTokenProvider: () async => 'token',
      );
      final orders = await repository.getCustomerOrders(
        'profile',
        dashboard: true,
      );
      expect(orders.single.id, 'active');
      expect(api.paths, [
        '/api/v1/customer-profiles/profile/orders/dashboard',
        '/api/v1/customer-profiles/profile/orders',
      ]);
    },
  );
  test(
    'summary authorization and server failures do not trigger history fallback',
    () async {
      for (final status in [401, 500]) {
        final api = DashboardOrdersApi()..summaryStatus = status;
        final repository = OrdersRepository(
          apiClient: api,
          accessTokenProvider: () async => 'token',
        );
        await expectLater(
          repository.getCustomerOrders('profile', dashboard: true),
          throwsA(isA<ApiException>()),
        );
        expect(api.paths.length, 1);
      }
    },
  );
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
  test(
    'pending activation orders await confirmation and are not current plans',
    () {
      expect(
        CustomerOrderSummary.fromJson(
          orderJson('pending', 'PENDING_ACTIVATION'),
        ).isCurrent,
        isFalse,
      );
    },
  );
}

class DashboardOrdersApi extends ApiClient {
  int summaryStatus = 200;
  final paths = <String>[];
  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    paths.add(path);
    return ApiResponse(
      statusCode: path.endsWith('/dashboard') ? summaryStatus : 200,
      body: {
        'items': [orderJson('active', 'ACTIVE')],
        'pageNumber': 1,
        'pageSize': 20,
        'totalCount': 1,
      },
    );
  }
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
