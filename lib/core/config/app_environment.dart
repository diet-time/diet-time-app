import 'package:flutter/foundation.dart';

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
      kDebugMode &&
      bool.fromEnvironment('ENABLE_TEST_OTP', defaultValue: false) &&
      testOtp.length == 6;

  /// Disable only for local development against the legacy test-code backend.
  static const enableRequestOtpApi =
      !kDebugMode ||
      bool.fromEnvironment('ENABLE_REQUEST_OTP_API', defaultValue: true);
}
