abstract final class AppEnvironment {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://diet-time-api-staging.up.railway.app',
  );

  static const useMockOtp = bool.fromEnvironment(
    'USE_MOCK_OTP',
    defaultValue: false,
  );
}
