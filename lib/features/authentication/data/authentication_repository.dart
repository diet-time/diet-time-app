import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/features/authentication/domain/auth_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authenticationRepositoryProvider = Provider<AuthenticationRepository>(
  (ref) => ApiAuthenticationRepository(ref.read(apiClientProvider)),
);

abstract interface class AuthenticationRepository {
  Future<AuthSession> verifyPhoneOtp(PhoneOtpLoginRequest request);
}

abstract interface class SessionRefreshRepository {
  Future<RefreshedAuthTokens> refreshSession({
    required String refreshToken,
    required DateTime refreshTokenExpiresAt,
  });
}

enum PhoneOtpFailure {
  validation,
  invalidOtp,
  accountConflict,
  tooManyAttempts,
  unavailable,
  connection,
  server,
  invalidResponse,
}

class PhoneOtpException implements Exception {
  const PhoneOtpException(this.failure, {this.message});

  final PhoneOtpFailure failure;
  final String? message;
}

class ApiAuthenticationRepository
    implements AuthenticationRepository, SessionRefreshRepository {
  const ApiAuthenticationRepository(this._client);

  final ApiClient _client;

  @override
  Future<AuthSession> verifyPhoneOtp(PhoneOtpLoginRequest request) async {
    try {
      final response = await _client.request(
        method: 'POST',
        path: ApiEndpoints.phoneOtp,
        body: request.toJson(),
      );
      if (!response.isSuccess) throw _exceptionFor(response);
      final data = response.body['data'];
      if (data is! Map<String, dynamic>) {
        throw const PhoneOtpException(PhoneOtpFailure.invalidResponse);
      }
      try {
        return AuthSession.fromJson(data);
      } on FormatException {
        throw const PhoneOtpException(PhoneOtpFailure.invalidResponse);
      }
    } on ApiException catch (error) {
      final failure = switch (error.failure) {
        ApiFailure.network || ApiFailure.timeout => PhoneOtpFailure.connection,
        _ => PhoneOtpFailure.invalidResponse,
      };
      throw PhoneOtpException(failure, message: error.message);
    }
  }

  @override
  Future<RefreshedAuthTokens> refreshSession({
    required String refreshToken,
    required DateTime refreshTokenExpiresAt,
  }) async {
    try {
      final response = await _client.request(
        method: 'POST',
        path: ApiEndpoints.refreshSession,
        body: {'refreshToken': refreshToken},
      );
      if (!response.isSuccess) throw _exceptionFor(response);
      final data = response.body['data'];
      if (data is! Map<String, dynamic>) {
        throw const PhoneOtpException(PhoneOtpFailure.invalidResponse);
      }
      try {
        return RefreshedAuthTokens.fromJson(
          data,
          currentRefreshToken: refreshToken,
          currentRefreshTokenExpiresAt: refreshTokenExpiresAt,
        );
      } on FormatException {
        throw const PhoneOtpException(PhoneOtpFailure.invalidResponse);
      }
    } on ApiException catch (error) {
      final failure = switch (error.failure) {
        ApiFailure.network || ApiFailure.timeout => PhoneOtpFailure.connection,
        _ => PhoneOtpFailure.invalidResponse,
      };
      throw PhoneOtpException(failure, message: error.message);
    }
  }

  PhoneOtpException _exceptionFor(ApiResponse response) {
    final message = _errorMessage(response.body);
    final failure = switch (response.statusCode) {
      400 => PhoneOtpFailure.validation,
      401 => PhoneOtpFailure.invalidOtp,
      409 => PhoneOtpFailure.accountConflict,
      429 => PhoneOtpFailure.tooManyAttempts,
      503 => PhoneOtpFailure.unavailable,
      >= 500 => PhoneOtpFailure.server,
      _ => PhoneOtpFailure.invalidResponse,
    };
    return PhoneOtpException(failure, message: message);
  }

  String? _errorMessage(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors is! List || errors.isEmpty) return null;
    final first = errors.first;
    if (first is String && first.trim().isNotEmpty) return first.trim();
    if (first is Map) {
      final message = first['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }
    return null;
  }
}
