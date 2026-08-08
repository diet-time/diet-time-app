enum OtpChannel { sms, whatsapp }

enum OtpFailure { unavailable, expired, tooManyAttempts, resendUnavailable }

class OtpRequestResult {
  const OtpRequestResult({
    required this.success,
    this.requestId,
    this.expiresInSeconds = 120,
    this.failure,
  });

  final bool success;
  final String? requestId;
  final int expiresInSeconds;
  final OtpFailure? failure;
}

class OtpVerificationResult {
  const OtpVerificationResult({
    required this.success,
    this.failure,
    this.accessToken,
  });

  final bool success;
  final OtpFailure? failure;
  final String? accessToken;
}

abstract interface class OtpService {
  Future<OtpRequestResult> requestOtp({
    required String phoneNumber,
    required OtpChannel channel,
  });

  Future<OtpVerificationResult> verifyOtp({
    required String phoneNumber,
    required String code,
  });
}

class PendingAuthDestination {
  const PendingAuthDestination({
    required this.route,
    this.planCode,
    this.planName,
    this.selectedDate,
    this.mealTimePreference,
    this.mealPlanTemplateId,
    this.mealPlanPriceId,
  });

  final String route;
  final String? planCode;
  final String? planName;
  final DateTime? selectedDate;
  final String? mealTimePreference;
  final String? mealPlanTemplateId;
  final String? mealPlanPriceId;
}
