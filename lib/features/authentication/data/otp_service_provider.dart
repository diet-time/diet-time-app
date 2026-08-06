import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final otpServiceProvider = Provider<OtpService>((ref) {
  return const ApiOtpService();
});

/// Placeholder for the future send-OTP backend integration.
class ApiOtpService implements OtpService {
  const ApiOtpService();

  @override
  Future<OtpRequestResult> requestOtp({
    required String phoneNumber,
    required OtpChannel channel,
  }) async {
    return const OtpRequestResult(
      success: false,
      failure: OtpFailure.unavailable,
    );
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
