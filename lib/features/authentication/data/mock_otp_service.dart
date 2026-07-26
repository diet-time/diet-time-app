import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final otpServiceProvider = Provider<OtpService>((ref) {
  if (AppEnvironment.useMockOtp) return const MockOtpService();
  return const UnavailableOtpService();
});

class MockOtpService implements OtpService {
  const MockOtpService({
    this.requestDelay = const Duration(milliseconds: 700),
    this.verificationDelay = const Duration(milliseconds: 500),
  });

  static const developmentCode = '123456';

  final Duration requestDelay;
  final Duration verificationDelay;

  @override
  Future<OtpRequestResult> requestOtp({
    required String phoneNumber,
    required OtpChannel channel,
  }) async {
    await Future<void>.delayed(requestDelay);
    return OtpRequestResult(
      success: true,
      requestId: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      expiresInSeconds: 120,
    );
  }

  @override
  Future<OtpVerificationResult> verifyOtp({
    required String phoneNumber,
    required String code,
  }) async {
    await Future<void>.delayed(verificationDelay);
    return OtpVerificationResult(success: code == developmentCode);
  }
}

class UnavailableOtpService implements OtpService {
  const UnavailableOtpService();

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
