import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/checkout_repository.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';

void main() {
  for (final slotsFirst in [false, true]) {
    test(
      'saved slot restores and edits without a false validation error, slotsFirst=$slotsFirst',
      () async {
        final api = _CheckoutApiClient();
        final container = ProviderContainer(
          overrides: [
            checkoutRepositoryProvider.overrideWithValue(
              CheckoutRepository(
                apiClient: api,
                accessTokenProvider: () async => 'token',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(checkoutControllerProvider.notifier);
        if (slotsFirst) await controller.loadDeliveryTimeSlots();
        await controller.loadAddressesForProfile('profile-id');
        if (!slotsFirst) await controller.loadDeliveryTimeSlots();
        var state = container.read(checkoutControllerProvider);
        expect(state.selectedDeliveryTimeSlot!.id, 'morning-id');
        expect(
          await controller.saveAddress(state.selectedAddress!, editing: true),
          true,
        );
        state = container.read(checkoutControllerProvider);
        expect(state.saveAddressError, isNull);
        expect(state.selectedAddress!.deliveryTimeSlotId, 'morning-id');
        expect(api.requests.last.body!['deliveryTimeSlotId'], 'morning-id');
      },
    );
  }

  test('loads addresses and delivery slots from required endpoints', () async {
    final api = _CheckoutApiClient();
    final repository = CheckoutRepository(
      apiClient: api,
      accessTokenProvider: () async => 'access-token',
    );

    final addresses = await repository.getAddresses('profile 1');
    final slots = await repository.getDeliveryTimeSlots();

    expect(
      api.requests[0].path,
      '/api/v1/customer-profiles/profile%201/addresses',
    );
    expect(api.requests[0].headers['Authorization'], 'Bearer access-token');
    expect(api.requests[1].path, '/api/v1/delivery-time-slots');
    expect(addresses.single.displayName, 'Home');
    expect(addresses.single.streetLine, 'Building 126, Street 960, Zone 91');
    expect(slots.single.id, 'morning-id');
    expect(slots.single.timeRange, '09:00 - 11:00');
  });

  test('creates and edits addresses without creating on edit', () async {
    final api = _CheckoutApiClient();
    final repository = CheckoutRepository(
      apiClient: api,
      accessTokenProvider: () async => null,
    );
    const newAddress = CustomerDeliveryAddress(
      id: '',
      addressName: 'Home',
      addressType: DeliveryAddressType.home,
      buildingNo: '126',
      streetNo: '960',
      zoneNo: '91',
      area: 'Al Wakrah',
      latitude: 25.1712345,
      longitude: 51.6034567,
      formattedAddress: 'Zone 91, Al Wakrah, Qatar',
      directions: 'Call me when you arrive',
      isDefault: true,
      deliveryTimeSlotId: 'morning-id',
    );

    final created = await repository.createAddress('profile-id', newAddress);
    await repository.updateAddress('profile-id', created);

    expect(api.requests[0].method, 'POST');
    expect(
      api.requests[0].path,
      '/api/v1/customer-profiles/profile-id/addresses',
    );
    expect(api.requests[0].body!['unitNumber'], isNull);
    expect(api.requests[0].body!['addressType'], 'HOME');
    expect(created.id, 'saved-address-id');
    expect(created.deliveryTimeSlotId, 'morning-id');
    expect(api.requests[0].body!['deliveryTimeSlotId'], 'morning-id');
    expect(api.requests[1].method, 'PUT');
    expect(
      api.requests[1].path,
      '/api/v1/customer-profiles/profile-id/addresses/saved-address-id',
    );
  });
}

class _CheckoutApiClient extends ApiClient {
  final requests = <_Request>[];

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    requests.add(
      _Request(method: method, path: path, headers: headers, body: body),
    );
    if (path == '/api/v1/delivery-time-slots') {
      return const ApiResponse(
        statusCode: 200,
        body: {
          'data': {
            'timeSlots': [
              {
                'id': 'morning-id',
                'name': 'Morning',
                'startTime': '09:00',
                'endTime': '11:00',
              },
            ],
          },
        },
      );
    }
    if (method == 'GET') {
      return const ApiResponse(
        statusCode: 200,
        body: {
          'data': {
            'addresses': [
              {
                'id': 'address-id',
                'deliveryTimeSlotId': 'morning-id',
                'addressName': 'Home',
                'addressType': 'HOME',
                'buildingNo': '126',
                'streetNo': '960',
                'zoneNo': '91',
                'area': 'Al Wakrah',
                'latitude': 25.17,
                'longitude': 51.60,
                'formattedAddress': 'Zone 91, Al Wakrah, Qatar',
              },
            ],
          },
        },
      );
    }
    return ApiResponse(
      statusCode: 200,
      body: {
        'data': {...?body, 'id': body?['id'] ?? 'saved-address-id'},
      },
    );
  }
}

class _Request {
  const _Request({
    required this.method,
    required this.path,
    required this.headers,
    required this.body,
  });
  final String method;
  final String path;
  final Map<String, String> headers;
  final Map<String, dynamic>? body;
}
