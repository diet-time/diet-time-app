import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/dashboard/domain/customer_account_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerAccountProfileRepositoryProvider =
    Provider<CustomerAccountProfileRepository>((ref) {
      final storage = ref.watch(secureStorageServiceProvider);
      return ApiCustomerAccountProfileRepository(
        apiClient: ref.watch(apiClientProvider),
        accessTokenProvider: () =>
            storage.read(SecureStorageService.accessTokenKey),
      );
    });

abstract interface class CustomerAccountProfileRepository {
  Future<CustomerAccountProfile> getProfile();

  Future<CustomerAccountProfile> updateProfile(
    UpdateCustomerProfileRequest request,
  );
}

class ApiCustomerAccountProfileRepository
    implements CustomerAccountProfileRepository {
  const ApiCustomerAccountProfileRepository({
    required this.apiClient,
    required this.accessTokenProvider,
  });

  final ApiClient apiClient;
  final Future<String?> Function() accessTokenProvider;

  @override
  Future<CustomerAccountProfile> getProfile() async {
    final response = await _request(method: 'GET');
    return _profile(response);
  }

  @override
  Future<CustomerAccountProfile> updateProfile(
    UpdateCustomerProfileRequest request,
  ) async {
    final response = await _request(method: 'PUT', body: request.toJson());
    return _profile(response);
  }

  Future<ApiResponse> _request({
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final token = (await accessTokenProvider())?.trim();
    final response = await apiClient.request(
      method: method,
      path: ApiEndpoints.customerAccountProfile,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (!response.isSuccess) throw ApiException.fromResponse(response);
    return response;
  }

  CustomerAccountProfile _profile(ApiResponse response) {
    final rawData = response.body['data'] ?? response.body;
    if (rawData is! Map) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    final envelope = Map<String, dynamic>.from(rawData);
    final nested = envelope['customerProfile'] ?? envelope['profile'];
    final json = nested is Map
        ? (Map<String, dynamic>.from(nested)
            ..putIfAbsent('addresses', () => envelope['addresses']))
        : envelope;
    return CustomerAccountProfile.fromJson(json);
  }
}
