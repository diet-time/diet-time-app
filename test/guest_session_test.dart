import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/personalization/data/guest_session_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('first launch creates and securely stores a guest session', () async {
    final api = _FakeApiClient();
    final storage = SecureStorageService();
    final repository = GuestSessionRepository(apiClient: api, storage: storage);

    final session = await repository.ensureSession();

    expect(session.token, 'guest-token-1');
    expect(api.createCalls, 1);
    expect(
      await storage.read(SecureStorageService.guestTokenKey),
      'guest-token-1',
    );
  });

  test('an existing valid guest token is reused', () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureStorageService.guestTokenKey: 'existing-token',
      SecureStorageService.guestTokenExpiryKey: DateTime.now()
          .add(const Duration(hours: 2))
          .toUtc()
          .toIso8601String(),
    });
    final api = _FakeApiClient();
    final repository = GuestSessionRepository(
      apiClient: api,
      storage: SecureStorageService(),
    );

    final session = await repository.ensureSession();

    expect(session.token, 'existing-token');
    expect(api.createCalls, 0);
  });

  test('an expired guest token is cleared and replaced', () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureStorageService.guestTokenKey: 'expired-token',
      SecureStorageService.guestTokenExpiryKey: DateTime.now()
          .subtract(const Duration(minutes: 1))
          .toUtc()
          .toIso8601String(),
    });
    final api = _FakeApiClient();
    final repository = GuestSessionRepository(
      apiClient: api,
      storage: SecureStorageService(),
    );

    final session = await repository.ensureSession();

    expect(session.token, 'guest-token-1');
    expect(api.createCalls, 1);
  });
}

class _FakeApiClient extends ApiClient {
  int createCalls = 0;

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    createCalls++;
    return ApiResponse(
      statusCode: 201,
      body: {
        'data': {
          'guestToken': 'guest-token-$createCalls',
          'expiresAt': DateTime.now()
              .add(const Duration(days: 1))
              .toUtc()
              .toIso8601String(),
        },
        'errors': const [],
      },
    );
  }
}
