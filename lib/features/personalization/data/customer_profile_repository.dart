import 'dart:convert';
import 'dart:io';

import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerProfileRepositoryProvider = Provider<CustomerProfileRepository>(
  (ref) => AppEnvironment.useMockOtp
      ? LocalCustomerProfileRepository()
      : HttpCustomerProfileRepository(
          accessTokenProvider: () => ref
              .read(secureStorageServiceProvider)
              .read(SecureStorageService.accessTokenKey),
        ),
);

abstract interface class CustomerProfileRepository {
  Future<CustomerProfile?> getProfile();

  Future<CustomerProfile> updateProfile(CustomerProfile profile);
}

class LocalCustomerProfileRepository implements CustomerProfileRepository {
  CustomerProfile? _profile;

  @override
  Future<CustomerProfile?> getProfile() async => _profile;

  @override
  Future<CustomerProfile> updateProfile(CustomerProfile profile) async {
    final isComplete = profile.onboardingStatus == 'COMPLETED';
    final bmi = _calculateBmi(profile.heightCm, profile.weightKg);
    _profile = profile.copyWith(
      bmi: bmi,
      bmiCategoryCode: _bmiCategory(bmi),
      nextStepCode: isComplete ? 'PROFILE_COMPLETED' : profile.nextStepCode,
      completionPercentage: isComplete ? 100 : profile.completionPercentage,
      shouldShowOnboarding: !isComplete,
      updatedAt: DateTime.now().toUtc(),
    );
    return _profile!;
  }
}

double? _calculateBmi(double? heightCm, double? weightKg) {
  if (heightCm == null || weightKg == null || heightCm <= 0 || weightKg <= 0) {
    return null;
  }
  final heightM = heightCm / 100;
  return weightKg / (heightM * heightM);
}

String? _bmiCategory(double? bmi) {
  if (bmi == null) return null;
  if (bmi < 18.5) return 'UNDERWEIGHT';
  if (bmi < 25) return 'NORMAL';
  if (bmi < 30) return 'OVERWEIGHT';
  return 'OBESE';
}

class HttpCustomerProfileRepository implements CustomerProfileRepository {
  HttpCustomerProfileRepository({
    HttpClient Function()? clientFactory,
    Future<String?> Function()? accessTokenProvider,
  }) : _clientFactory = clientFactory ?? HttpClient.new,
       _accessTokenProvider = accessTokenProvider;

  final HttpClient Function() _clientFactory;
  final Future<String?> Function()? _accessTokenProvider;

  @override
  Future<CustomerProfile?> getProfile() async {
    final result = await _request(method: 'GET');
    if (result.statusCode == HttpStatus.notFound) return null;
    if (result.statusCode < 200 || result.statusCode >= 300) {
      throw CustomerProfileException(statusCode: result.statusCode);
    }
    return _profileFromEnvelope(result.body);
  }

  @override
  Future<CustomerProfile> updateProfile(CustomerProfile profile) async {
    final result = await _request(method: 'PUT', body: profile.toJson());
    if (result.statusCode < 200 || result.statusCode >= 300) {
      throw CustomerProfileException(statusCode: result.statusCode);
    }
    return _profileFromEnvelope(result.body, fallback: profile) ?? profile;
  }

  Future<_ProfileHttpResult> _request({
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(
      AppEnvironment.apiBaseUrl,
    ).resolve(ApiEndpoints.customerProfile);
    if (kDebugMode) debugPrint('[CustomerProfile] $method ${uri.path}');
    final client = _clientFactory()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request =
          await (method == 'GET' ? client.getUrl(uri) : client.putUrl(uri))
              .timeout(const Duration(seconds: 15));
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..set(HttpHeaders.contentTypeHeader, 'application/json');
      final accessToken = await _accessTokenProvider?.call();
      if (accessToken != null && accessToken.trim().isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${accessToken.trim()}',
        );
      }
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 25),
      );
      final responseText = await utf8.decoder.bind(response).join();
      Map<String, dynamic> decoded = const {};
      if (responseText.trim().isNotEmpty) {
        final value = jsonDecode(responseText);
        if (value is Map<String, dynamic>) decoded = value;
      }
      return _ProfileHttpResult(statusCode: response.statusCode, body: decoded);
    } on CustomerProfileException {
      rethrow;
    } on Object {
      throw const CustomerProfileException();
    } finally {
      client.close(force: true);
    }
  }
}

CustomerProfile? _profileFromEnvelope(
  Map<String, dynamic> body, {
  CustomerProfile fallback = const CustomerProfile(),
}) {
  final data = body['data'];
  if (data == null) return null;
  if (data is! Map<String, dynamic>) {
    throw const CustomerProfileException();
  }
  return CustomerProfile.fromJson(data, fallback: fallback);
}

class CustomerProfileException implements Exception {
  const CustomerProfileException({this.statusCode});

  final int? statusCode;
}

class _ProfileHttpResult {
  const _ProfileHttpResult({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
}
