abstract final class AppEnvironment {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://diet-time-api-staging.up.railway.app',
  );

  /// Shows development-only OTP guidance. This is false in release builds.
  static const testOtp = String.fromEnvironment(
    'TEST_PHONE_OTP',
    defaultValue: '',
  );

  static const enableTestOtp =
      bool.fromEnvironment('ENABLE_TEST_OTP', defaultValue: false) &&
      testOtp.length == 6;

  /// Enable after a send-OTP endpoint is available.
  static const enableRequestOtpApi = bool.fromEnvironment(
    'ENABLE_REQUEST_OTP_API',
    defaultValue: false,
  );
}
