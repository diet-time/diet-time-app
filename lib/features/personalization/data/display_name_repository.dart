import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/domain/customer_onboarding.dart';

final displayNameRepositoryProvider = Provider<DisplayNameRepository>((ref) {
  return DisplayNameRepository(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});

class DisplayNameRepository {
  const DisplayNameRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage;

  static const displayNameKey = 'profileDisplayName';
  static const capturedKey = 'profileDisplayNameCaptured';

  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  /// Onboarding uses the authenticated API response, never the device-wide cache.
  Future<CustomerProfile> saveAuthenticatedProfileName(String name) async {
    if (!CustomerOnboardingPolicy.validName(name)) {
      throw const CustomerProfileException(statusCode: 422);
    }
    final token = await _secureStorage.read(
      SecureStorageService.accessTokenKey,
    );
    if (token == null || token.trim().isEmpty) {
      throw const CustomerProfileException(statusCode: 401);
    }
    final response = await _apiClient.request(
      method: 'PATCH',
      path: '${ApiEndpoints.customerProfile}/preferred-name',
      headers: {'Authorization': 'Bearer ${token.trim()}'},
      body: {'preferredName': name.trim()},
    );
    if (!response.isSuccess) {
      throw CustomerProfileException(statusCode: response.statusCode);
    }
    final data = response.body['data'];
    if (data is! Map<String, dynamic>) {
      throw const CustomerProfileException(statusCode: 502);
    }
    final profile = CustomerProfile.fromJson(data);
    if (profile.profileId == null ||
        !CustomerOnboardingPolicy.validName(profile.preferredName)) {
      throw const CustomerProfileException(statusCode: 502);
    }
    return profile;
  }

}
