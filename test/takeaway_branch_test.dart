import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/checkout_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'branch API loads backend names and configured addresses with authentication, then clears a removed selection',
    () async {
      final api = _BranchApi();
      final repository = CheckoutRepository(
        apiClient: api,
        accessTokenProvider: () async => 'token',
      );
      final container = ProviderContainer(
        overrides: [checkoutRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final checkout = container.read(checkoutControllerProvider.notifier);
      await checkout.loadBranches();
      final branches = container.read(checkoutControllerProvider).branches;
      expect(branches, hasLength(2));
      expect(branches.first.name, 'Diet Time – Izghawa Branch');
      expect(branches.first.address, isNull);
      expect(branches.last.address, 'Administrator configured address');
      checkout.selectBranch(branches.first);
      expect(
        container.read(checkoutControllerProvider).selectedBranch?.id,
        'izghawa',
      );
      api.removeIzghawa = true;
      await checkout.loadBranches();
      expect(container.read(checkoutControllerProvider).selectedBranch, isNull);
      expect(
        container.read(checkoutControllerProvider).branches.single.id,
        'azizia',
      );
    },
  );

  test(
    'order summary and confirmation parse the saved branch and preserve historical missing branches',
    () {
      final json = <String, dynamic>{
        'fulfillmentMethod': 'TAKEAWAY',
        'takeawayBranch': {
          'id': 'branch',
          'name': 'Saved branch',
          'address': 'Saved address',
        },
      };
      expect(
        OrderConfirmation.fromJson(json).takeawayBranch?.address,
        'Saved address',
      );
      expect(
        CustomerOrderSummary.fromJson(json).takeawayBranch?.name,
        'Saved branch',
      );
      expect(
        OrderConfirmation.fromJson({
          'fulfillmentMethod': 'TAKEAWAY',
        }).takeawayBranch,
        isNull,
      );
    },
  );
}

class _BranchApi extends ApiClient {
  bool removeIzghawa = false;
  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    expect(method, 'GET');
    expect(path, '/api/v1/takeaway-branches');
    expect(headers['Authorization'], 'Bearer token');
    return ApiResponse(
      statusCode: 200,
      body: {
        'items': [
          if (!removeIzghawa)
            {
              'id': 'izghawa',
              'name': 'Diet Time – Izghawa Branch',
              'address': null,
            },
          {
            'id': 'azizia',
            'name': 'Diet Time – Azizia Branch',
            'address': 'Administrator configured address',
          },
        ],
      },
    );
  }
}
