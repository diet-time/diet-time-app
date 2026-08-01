import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/authentication/data/mock_otp_session_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('registers the verified phone and stores its API tokens', () async {
    final api = _AuthApiClient();
    final storage = SecureStorageService();
    final repository = MockOtpSessionRepository(
      apiClient: api,
      secureStorage: storage,
    );

    expect(await repository.createSession('+974 5555 1234'), 'access-token');
    expect(api.paths, [ApiEndpoints.authRegister]);
    expect(api.lastCredentials?['email'], 'mobile+97455551234@diettime.local');
    expect(
      await storage.read(SecureStorageService.refreshTokenKey),
      'refresh-token',
    );
  });

  test('logs in with the stored credential when the account exists', () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureStorageService.mockAuthPhoneKey: '97455551234',
      SecureStorageService.mockAuthPasswordKey: 'Dt1!StoredPasswordValue',
    });
    final api = _AuthApiClient(registrationConflict: true);
    final repository = MockOtpSessionRepository(
      apiClient: api,
      secureStorage: SecureStorageService(),
    );

    expect(await repository.createSession('+97455551234'), 'access-token');
    expect(api.paths, [ApiEndpoints.authRegister, ApiEndpoints.authLogin]);
    expect(api.lastCredentials?['password'], 'Dt1!StoredPasswordValue');
  });
}

class _AuthApiClient extends ApiClient {
  _AuthApiClient({this.registrationConflict = false});

  final bool registrationConflict;
  final List<String> paths = [];
  Map<String, dynamic>? lastCredentials;

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    expect(method, 'POST');
    paths.add(path);
    lastCredentials = body;
    if (path == ApiEndpoints.authRegister && registrationConflict) {
      return const ApiResponse(statusCode: 409, body: {});
    }
    return const ApiResponse(
      statusCode: 200,
      body: {
        'data': {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
        },
      },
    );
  }
}
