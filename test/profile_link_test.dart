import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/personalization/data/profile_link_repository.dart';
import 'package:diet_time/features/personalization/presentation/profile_link_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      SecureStorageService.guestTokenKey: 'guest-token',
      SecureStorageService.guestTokenExpiryKey: DateTime.now()
          .add(const Duration(hours: 1))
          .toUtc()
          .toIso8601String(),
      SecureStorageService.accessTokenKey: 'jwt-token',
    });
  });

  test(
    'successful linking clears guest credentials after the response',
    () async {
      final storage = SecureStorageService();
      final repository = ProfileLinkRepository(
        apiClient: _LinkApiClient(succeeds: true),
        storage: storage,
      );
      final container = ProviderContainer(
        overrides: [
          profileLinkRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final linked = await container
          .read(profileLinkControllerProvider.notifier)
          .link();

      expect(linked, isTrue);
      expect(await storage.read(SecureStorageService.guestTokenKey), isNull);
    },
  );

  test('link failure preserves the guest token for retry', () async {
    final storage = SecureStorageService();
    final repository = ProfileLinkRepository(
      apiClient: _LinkApiClient(succeeds: false),
      storage: storage,
    );
    final container = ProviderContainer(
      overrides: [profileLinkRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final linked = await container
        .read(profileLinkControllerProvider.notifier)
        .link();

    expect(linked, isFalse);
    expect(
      await storage.read(SecureStorageService.guestTokenKey),
      'guest-token',
    );
    expect(
      container.read(profileLinkControllerProvider).errorMessage,
      isNotNull,
    );
  });
}

class _LinkApiClient extends ApiClient {
  _LinkApiClient({required this.succeeds});

  final bool succeeds;

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    if (!succeeds) {
      return const ApiResponse(statusCode: 409, body: {});
    }
    expect(headers['Authorization'], 'Bearer jwt-token');
    expect(body, {'guestToken': 'guest-token'});
    return const ApiResponse(
      statusCode: 200,
      body: {
        'data': {
          'genderCode': 'FEMALE',
          'dateOfBirth': '1998-01-01',
          'heightCm': 170,
          'weightKg': 70,
          'onboardingStatus': 'COMPLETED',
        },
      },
    );
  }
}
