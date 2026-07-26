import 'package:flutter/foundation.dart';

abstract final class AppEnvironment {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://diet-time-api-staging.up.railway.app',
  );

  static const useMockOtp =
      kDebugMode && bool.fromEnvironment('USE_MOCK_OTP', defaultValue: true);
}
