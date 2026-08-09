import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/authentication/data/authentication_repository.dart';
import 'package:diet_time/features/authentication/domain/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testOtp = List.generate(6, (index) => (index + 1).toString()).join();
  final request = PhoneOtpLoginRequest(
    phoneNumber: '+97455555555',
    otp: testOtp,
  );

  test('PhoneOtpLoginRequest omits blank optional names', () {
    expect(request.toJson(), {'phoneNumber': '+97455555555', 'otp': testOtp});
  });

  test('parses a successful authentication session', () async {
    final client = _FakeApiClient(_successResponse());
    final session = await ApiAuthenticationRepository(
      client,
    ).verifyPhoneOtp(request);

    expect(client.lastPath, '/api/v1/auth/phone-otp');
    expect(client.lastBody, request.toJson());
    expect(session.accessToken, 'access-token');
    expect(session.refreshToken, 'refresh-token');
    expect(session.accessTokenExpiresAt, DateTime.utc(2026, 8, 6, 20));
    expect(session.user.id, 'user-1');
    expect(session.user.phoneNumber, '+97455555555');
    expect(session.user.roles, ['customer']);
  });

  test('rejects malformed success responses', () async {
    final repository = ApiAuthenticationRepository(
      _FakeApiClient(const ApiResponse(statusCode: 200, body: {'data': {}})),
    );

    await expectLater(
      repository.verifyPhoneOtp(request),
      throwsA(
        isA<PhoneOtpException>().having(
          (error) => error.failure,
          'failure',
          PhoneOtpFailure.invalidResponse,
        ),
      ),
    );
  });

  test(
    'refreshes an expired access token with the stored refresh token',
    () async {
      final response = ApiResponse(
        statusCode: 200,
        body: {
          'data': {
            'accessToken': 'renewed-access-token',
            'accessTokenExpiresAt': DateTime.now()
                .toUtc()
                .add(const Duration(minutes: 15))
                .toIso8601String(),
          },
        },
      );
      final client = _FakeApiClient(response);
      final refreshExpiry = DateTime.now().toUtc().add(
        const Duration(days: 30),
      );

      final tokens = await ApiAuthenticationRepository(client).refreshSession(
        refreshToken: 'stored-refresh-token',
        refreshTokenExpiresAt: refreshExpiry,
      );

      expect(client.lastPath, '/api/v1/auth/refresh');
      expect(client.lastBody, {'refreshToken': 'stored-refresh-token'});
      expect(tokens.accessToken, 'renewed-access-token');
      expect(tokens.refreshToken, 'stored-refresh-token');
      expect(tokens.refreshTokenExpiresAt, refreshExpiry);
    },
  );

  for (final entry in {
    400: PhoneOtpFailure.validation,
    401: PhoneOtpFailure.invalidOtp,
    409: PhoneOtpFailure.accountConflict,
    429: PhoneOtpFailure.tooManyAttempts,
    503: PhoneOtpFailure.unavailable,
    500: PhoneOtpFailure.server,
  }.entries) {
    test('maps HTTP ${entry.key} to ${entry.value.name}', () async {
      final repository = ApiAuthenticationRepository(
        _FakeApiClient(
          ApiResponse(
            statusCode: entry.key,
            body: const {
              'errors': [
                {'message': 'Backend validation message'},
              ],
            },
          ),
        ),
      );

      await expectLater(
        repository.verifyPhoneOtp(request),
        throwsA(
          isA<PhoneOtpException>()
              .having((error) => error.failure, 'failure', entry.value)
              .having(
                (error) => error.message,
                'message',
                'Backend validation message',
              ),
        ),
      );
    });
  }

  test('maps network failures to a retryable connection failure', () async {
    final repository = ApiAuthenticationRepository(
      _FakeApiClient(const ApiException(ApiFailure.network)),
    );

    await expectLater(
      repository.verifyPhoneOtp(request),
      throwsA(
        isA<PhoneOtpException>().having(
          (error) => error.failure,
          'failure',
          PhoneOtpFailure.connection,
        ),
      ),
    );
  });
}

ApiResponse _successResponse() => const ApiResponse(
  statusCode: 200,
  body: {
    'data': {
      'accessToken': 'access-token',
      'accessTokenExpiresAt': '2026-08-06T20:00:00.000Z',
      'refreshToken': 'refresh-token',
      'refreshTokenExpiresAt': '2026-09-06T20:00:00.000Z',
      'user': {
        'id': 'user-1',
        'email': '',
        'name': 'Test User',
        'roles': ['customer'],
        'phoneNumber': '+97455555555',
      },
    },
    'errors': [],
  },
);

class _FakeApiClient implements ApiClient {
  _FakeApiClient(this.result);

  final Object result;
  String? lastPath;
  Map<String, dynamic>? lastBody;

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    lastPath = path;
    lastBody = body;
    if (result is ApiException) throw result as ApiException;
    return result as ApiResponse;
  }
}
