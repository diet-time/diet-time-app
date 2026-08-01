import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/authentication/data/mock_otp_session_repository.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final otpServiceProvider = Provider<OtpService>((ref) {
  final sessionRepository = MockOtpSessionRepository(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
  final service = createOtpService(
    mockSessionCreator: sessionRepository.createSession,
  );
  debugPrint('Using ${service.runtimeType}');
  return service;
});

OtpService createOtpService({
  bool? useMockOtp,
  Future<String?> Function(String phoneNumber)? mockSessionCreator,
}) {
  if (useMockOtp ?? AppEnvironment.useMockOtp) {
    return MockOtpService(sessionCreator: mockSessionCreator);
  }
  return const ApiOtpService();
}

class MockOtpService implements OtpService {
  const MockOtpService({
    this.requestDelay = const Duration(milliseconds: 700),
    this.verificationDelay = const Duration(milliseconds: 500),
    this.sessionCreator,
  });

  static const developmentCode = '123456';

  final Duration requestDelay;
  final Duration verificationDelay;
  final Future<String?> Function(String phoneNumber)? sessionCreator;

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
    if (code != developmentCode) {
      return const OtpVerificationResult(success: false);
    }
    final createSession = sessionCreator;
    if (createSession == null) {
      return const OtpVerificationResult(success: true);
    }
    try {
      final accessToken = await createSession(phoneNumber);
      return OtpVerificationResult(
        success: accessToken != null && accessToken.isNotEmpty,
        accessToken: accessToken,
        failure: accessToken == null ? OtpFailure.unavailable : null,
      );
    } on Object {
      return const OtpVerificationResult(
        success: false,
        failure: OtpFailure.unavailable,
      );
    }
  }
}

/// Placeholder for the backend implementation.
///
/// This performs no network requests until the Diet Time OTP endpoints are
/// available. Replacing its method bodies later does not require UI changes.
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
