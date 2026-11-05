import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/authentication/data/otp_service_provider.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requests WhatsApp delivery and parses the challenge', () async {
    final client = _Client(
      const ApiResponse(
        statusCode: 200,
        body: {
          'data': {'requestId': 'verification-id', 'expiresInSeconds': 600},
        },
      ),
    );
    final result = await ApiOtpService(
      client,
    ).requestOtp(phoneNumber: '+97455555555', channel: OtpChannel.whatsapp);
    expect(client.path, '/api/v1/auth/phone-otp/request');
    expect(client.body, {'phoneNumber': '+97455555555', 'channel': 'whatsapp'});
    expect(result.success, isTrue);
    expect(result.requestId, 'verification-id');
    expect(result.expiresInSeconds, 600);
  });

  for (final status in [429, 503]) {
    test(
      'handles delivery HTTP $status without opening verification',
      () async {
        final result = await ApiOtpService(
          _Client(ApiResponse(statusCode: status, body: {})),
        ).requestOtp(phoneNumber: '+97455555555', channel: OtpChannel.whatsapp);
        expect(result.success, isFalse);
        expect(
          result.failure,
          status == 429 ? OtpFailure.tooManyAttempts : OtpFailure.unavailable,
        );
      },
    );
  }

  test('rejects an incomplete delivery response', () async {
    final result = await ApiOtpService(
      _Client(const ApiResponse(statusCode: 200, body: {'data': {}})),
    ).requestOtp(phoneNumber: '+97455555555', channel: OtpChannel.whatsapp);
    expect(result.success, isFalse);
  });
}

class _Client extends ApiClient {
  _Client(this.response);
  final ApiResponse response;
  String? path;
  Map<String, dynamic>? body;
  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    expect(method, 'POST');
    this.path = path;
    this.body = body;
    return response;
  }
}
