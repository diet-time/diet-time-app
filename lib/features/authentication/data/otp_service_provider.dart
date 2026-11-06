import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';

final otpServiceProvider = Provider<OtpService>((ref) {
  return ApiOtpService(ref.read(apiClientProvider));
});

class ApiOtpService implements OtpService {
  const ApiOtpService(this._client);

  final ApiClient _client;

  @override
  Future<OtpRequestResult> requestOtp({
    required String phoneNumber,
    required OtpChannel channel,
  }) async {
    try {
      final response = await _client.request(
        method: 'POST',
        path: ApiEndpoints.requestPhoneOtp,
        body: {'phoneNumber': phoneNumber, 'channel': channel.name},
      );
      if (!response.isSuccess) {
        return OtpRequestResult(
          success: false,
          failure: response.statusCode == 429
              ? OtpFailure.tooManyAttempts
              : OtpFailure.unavailable,
        );
      }
      final data = response.body['data'];
      if (data is! Map<String, dynamic> ||
          data['requestId'] is! String ||
          (data['requestId'] as String).isEmpty ||
          data['expiresInSeconds'] is! int ||
          (data['expiresInSeconds'] as int) <= 0) {
        return const OtpRequestResult(
          success: false,
          failure: OtpFailure.unavailable,
        );
      }
      final cooldown = data['resendAfterSeconds'] ?? 60;
      if (cooldown is! int || cooldown < 60) {
        return const OtpRequestResult(
          success: false,
          failure: OtpFailure.unavailable,
        );
      }
      return OtpRequestResult(
        success: true,
        requestId: data['requestId'] as String,
        expiresInSeconds: data['expiresInSeconds'] as int,
        resendAfterSeconds: cooldown,
      );
    } on ApiException {
      return const OtpRequestResult(
        success: false,
        failure: OtpFailure.unavailable,
      );
    }
  }

  @override
  Future<OtpVerificationResult> verifyOtp({
    required String phoneNumber,
    required String code,
  }) async {
    return const OtpVerificationResult(
      success: false,
      failure: OtpFailure.unavailable,
    );
  }
}
