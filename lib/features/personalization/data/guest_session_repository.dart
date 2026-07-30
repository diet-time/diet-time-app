import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/personalization/domain/guest_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final guestSessionRepositoryProvider = Provider<GuestSessionRepository>(
  (ref) => GuestSessionRepository(
    apiClient: ref.watch(apiClientProvider),
    storage: ref.watch(secureStorageServiceProvider),
  ),
);

class GuestSessionRepository {
  const GuestSessionRepository({
    required this.apiClient,
    required this.storage,
  });

  final ApiClient apiClient;
  final SecureStorageService storage;

  Future<GuestSession?> readValidSession() async {
    final token = await storage.read(SecureStorageService.guestTokenKey);
    final expiryText = await storage.read(
      SecureStorageService.guestTokenExpiryKey,
    );
    final expiry = DateTime.tryParse(expiryText ?? '');
    if (token == null || token.trim().isEmpty || expiry == null) return null;
    final session = GuestSession(token: token, expiresAt: expiry);
    if (session.isExpired) {
      await clear();
      return null;
    }
    return session;
  }

  Future<GuestSession> createSession() async {
    final response = await apiClient.request(
      method: 'POST',
      path: ApiEndpoints.guestSession,
    );
    if (!response.isSuccess) throw ApiException.fromResponse(response);
    final data = response.body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    final session = GuestSession.fromJson(data);
    await storage.write(SecureStorageService.guestTokenKey, session.token);
    await storage.write(
      SecureStorageService.guestTokenExpiryKey,
      session.expiresAt.toUtc().toIso8601String(),
    );
    return session;
  }

  Future<GuestSession> ensureSession() async {
    return await readValidSession() ?? createSession();
  }

  Future<void> clear() async {
    await storage.delete(SecureStorageService.guestTokenKey);
    await storage.delete(SecureStorageService.guestTokenExpiryKey);
  }
}
