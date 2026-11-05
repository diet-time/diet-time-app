abstract final class AppEnvironment {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://diet-time-api-staging.up.railway.app',
  );

  /// Opt in for test builds; the server must separately enable test verification.
  static const useTestOtp =
      bool.fromEnvironment('USE_TEST_OTP', defaultValue: false) ||
      bool.fromEnvironment('ENABLE_TEST_OTP', defaultValue: false);

  /// Optional hint for testers. Verification always happens on the server.
  static const testOtp = String.fromEnvironment(
    'TEST_PHONE_OTP',
    defaultValue: '',
  );

  static const enableTestOtp = useTestOtp && testOtp.length == 6;

  /// Test APKs may skip delivery, including when compiled in release mode.
  static const enableRequestOtpApi =
      !useTestOtp &&
      bool.fromEnvironment('ENABLE_REQUEST_OTP_API', defaultValue: true);
}
