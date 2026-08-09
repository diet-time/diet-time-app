import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return CheckoutRepository(
    apiClient: ref.watch(apiClientProvider),
    accessTokenProvider: () =>
        storage.read(SecureStorageService.accessTokenKey),
  );
});

class CheckoutRepository {
  const CheckoutRepository({
    required this.apiClient,
    required this.accessTokenProvider,
  });

  final ApiClient apiClient;
  final Future<String?> Function() accessTokenProvider;

  Future<List<CustomerDeliveryAddress>> getAddresses(String profileId) async {
    final response = await _request(
      method: 'GET',
      path: ApiEndpoints.customerAddresses(profileId),
    );
    final items = _listFrom(response.body, keys: const ['addresses', 'items']);
    return items.map(CustomerDeliveryAddress.fromJson).toList(growable: false);
  }

  Future<List<DeliveryTimeSlot>> getDeliveryTimeSlots() async {
    final response = await _request(
      method: 'GET',
      path: ApiEndpoints.deliveryTimeSlots,
    );
    final items = _listFrom(
      response.body,
      keys: const ['timeSlots', 'slots', 'items'],
    );
    return items
        .map(DeliveryTimeSlot.fromJson)
        .where((slot) => slot.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<CustomerDeliveryAddress> createAddress(
    String profileId,
    CustomerDeliveryAddress address,
  ) => _saveAddress(
    method: 'POST',
    path: ApiEndpoints.customerAddresses(profileId),
    address: address,
  );

  Future<CustomerDeliveryAddress> updateAddress(
    String profileId,
    CustomerDeliveryAddress address,
  ) => _saveAddress(
    method: 'PUT',
    path: ApiEndpoints.customerAddress(profileId, address.id),
    address: address,
  );

  Future<CustomerDeliveryAddress> _saveAddress({
    required String method,
    required String path,
    required CustomerDeliveryAddress address,
  }) async {
    final response = await _request(
      method: method,
      path: path,
      body: address.toRequestJson(),
    );
    final data = _mapFrom(response.body);
    return data.isEmpty
        ? address
        : CustomerDeliveryAddress.fromJson(data).copyWith(
            id: _text(data['id'] ?? data['addressId']).isEmpty
                ? address.id
                : null,
          );
  }

  Future<ApiResponse> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final token = await accessTokenProvider();
    final response = await apiClient.request(
      method: method,
      path: path,
      headers: {
        if (token?.trim().isNotEmpty == true)
          'Authorization': 'Bearer ${token!.trim()}',
      },
      body: body,
    );
    if (!response.isSuccess) throw ApiException.fromResponse(response);
    return response;
  }
}

List<Map<String, dynamic>> _listFrom(
  Map<String, dynamic> body, {
  required List<String> keys,
}) {
  Object? value = body['data'];
  if (value is Map<String, dynamic>) {
    final envelope = value;
    for (final key in keys) {
      if (envelope[key] is List) {
        value = envelope[key];
        break;
      }
    }
  }
  if (value is! List) {
    for (final key in keys) {
      if (body[key] is List) {
        value = body[key];
        break;
      }
    }
  }
  return value is List
      ? value.whereType<Map<String, dynamic>>().toList(growable: false)
      : const [];
}

Map<String, dynamic> _mapFrom(Map<String, dynamic> body) {
  final data = body['data'];
  if (data is Map<String, dynamic>) {
    final nested = data['address'];
    return nested is Map<String, dynamic> ? nested : data;
  }
  final address = body['address'];
  return address is Map<String, dynamic> ? address : const {};
}

String _text(Object? value) => value?.toString().trim() ?? '';
