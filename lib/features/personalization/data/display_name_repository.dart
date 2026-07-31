import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/core/storage/shared_preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final displayNameRepositoryProvider = Provider<DisplayNameRepository>((ref) {
  return DisplayNameRepository(
    preferences: ref.watch(sharedPreferencesServiceProvider),
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});

class DisplayNameRepository {
  const DisplayNameRepository({
    required SharedPreferencesService preferences,
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  }) : _preferences = preferences,
       _apiClient = apiClient,
       _secureStorage = secureStorage;

  static const displayNameKey = 'profileDisplayName';
  static const capturedKey = 'profileDisplayNameCaptured';

  final SharedPreferencesService _preferences;
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  Future<String?> load() async {
    final headers = await _authorizationHeaders();
    if (headers.isEmpty) return _loadLocally();
    try {
      final response = await _apiClient.request(
        method: 'GET',
        path: ApiEndpoints.customerProfile,
        headers: headers,
      );
      if (response.statusCode == 404) return null;
      if (!response.isSuccess) throw ApiException.fromResponse(response);
      final data = response.body['data'];
      final name = data is Map<String, dynamic>
          ? data['preferredName']?.toString().trim()
          : null;
      if (name == null || name.isEmpty) return null;
      await _saveLocally(name);
      return name;
    } on ApiException {
      return _loadLocally();
    }
  }

  Future<void> save(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return;
    final headers = await _authorizationHeaders();
    if (headers.isEmpty) {
      await _saveLocally(normalized);
      return;
    }
    final response = await _apiClient.request(
      method: 'PATCH',
      path: '${ApiEndpoints.customerProfile}/preferred-name',
      headers: headers,
      body: {'preferredName': normalized},
    );
    if (!response.isSuccess) throw ApiException.fromResponse(response);
    await _saveLocally(normalized);
  }

  Future<Map<String, String>> _authorizationHeaders() async {
    final token = await _secureStorage.read(
      SecureStorageService.accessTokenKey,
    );
    if (token == null || token.trim().isEmpty) return const {};
    return {'Authorization': 'Bearer ${token.trim()}'};
  }

  Future<String?> _loadLocally() async {
    final captured = await _preferences.getBool(capturedKey) ?? false;
    if (!captured) return null;
    final name = (await _preferences.getString(displayNameKey))?.trim();
    return name == null || name.isEmpty ? null : name;
  }

  Future<void> _saveLocally(String normalized) async {
    await _preferences.setString(displayNameKey, normalized);
    await _preferences.setBool(capturedKey, true);
  }
}
