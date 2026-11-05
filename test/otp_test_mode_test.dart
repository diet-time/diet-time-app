import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/features/authentication/data/authentication_repository.dart';
import 'package:diet_time/features/authentication/data/otp_service_provider.dart';
import 'package:diet_time/features/authentication/domain/auth_models.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'test mode skips delivery but still verifies the entered code on the server',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final sender = _Sender();
      final verifier = _Verifier();
      final container = ProviderContainer(
        overrides: [
          otpServiceProvider.overrideWithValue(sender),
          authenticationRepositoryProvider.overrideWithValue(verifier),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(otpAuthControllerProvider.notifier);
      await controller.restoreSession();
      controller.setPhoneNumber('+97455555555');
      expect(await controller.requestOtp(), isTrue);
      expect(sender.sends, AppEnvironment.enableRequestOtpApi ? 1 : 0);
      controller.setOtpCode('654321');
      expect(await controller.verifyOtp(), isFalse);
      expect(verifier.calls, 1);
      expect(verifier.request?.otp, '654321');
      expect(
        container.read(otpAuthControllerProvider).isAuthenticated,
        isFalse,
      );
      expect(
        container.read(otpAuthControllerProvider).verificationError,
        OtpUiError.incorrectCode,
      );
    },
  );
}

class _Sender implements OtpService {
  int sends = 0;
  @override
  Future<OtpRequestResult> requestOtp({
    required String phoneNumber,
    required OtpChannel channel,
  }) async {
    sends++;
    return const OtpRequestResult(success: true, requestId: 'challenge');
  }

  @override
  Future<OtpVerificationResult> verifyOtp({
    required String phoneNumber,
    required String code,
  }) => throw UnimplementedError();
}

class _Verifier implements AuthenticationRepository {
  int calls = 0;
  PhoneOtpLoginRequest? request;
  @override
  Future<AuthSession> verifyPhoneOtp(PhoneOtpLoginRequest request) async {
    calls++;
    this.request = request;
    throw const PhoneOtpException(PhoneOtpFailure.invalidOtp);
  }
}
