import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileLinkRepositoryProvider = Provider<ProfileLinkRepository>(
  (ref) => ProfileLinkRepository(
    apiClient: ref.watch(apiClientProvider),
    storage: ref.watch(secureStorageServiceProvider),
  ),
);

class ProfileLinkRepository {
  const ProfileLinkRepository({required this.apiClient, required this.storage});

  final ApiClient apiClient;
  final SecureStorageService storage;

  Future<CustomerProfile?> linkGuestProfile() async {
    final guestToken = await storage.read(SecureStorageService.guestTokenKey);
    if (guestToken == null || guestToken.trim().isEmpty) return null;
    final jwt = await storage.read(SecureStorageService.accessTokenKey);
    if (jwt == null || jwt.trim().isEmpty) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    final response = await apiClient.request(
      method: 'POST',
      path: ApiEndpoints.linkGuestProfile,
      headers: {'Authorization': 'Bearer ${jwt.trim()}'},
      body: {'guestToken': guestToken},
    );
    if (!response.isSuccess) throw ApiException.fromResponse(response);
    final data = response.body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return CustomerProfile.fromJson(data);
  }
}
