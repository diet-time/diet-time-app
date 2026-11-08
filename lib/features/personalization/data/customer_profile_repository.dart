import 'dart:convert';
import 'dart:io';

import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerProfileRepositoryProvider = Provider<CustomerProfileRepository>(
  (ref) => HttpCustomerProfileRepository(
    accessTokenProvider: () => ref
        .read(secureStorageServiceProvider)
        .read(SecureStorageService.accessTokenKey),
    temporaryPhoneProvider: () => ref
        .read(secureStorageServiceProvider)
        .read(SecureStorageService.temporaryCustomerPhoneKey),
  ),
);

abstract interface class CustomerProfileRepository {
  Future<CustomerProfile?> getProfile();

  Future<CustomerProfile> updateProfile(CustomerProfile profile);
}

class HttpCustomerProfileRepository implements CustomerProfileRepository {
  HttpCustomerProfileRepository({
    HttpClient Function()? clientFactory,
    Future<String?> Function()? accessTokenProvider,
    Future<String?> Function()? temporaryPhoneProvider,
  }) : _clientFactory = clientFactory ?? HttpClient.new,
       _accessTokenProvider = accessTokenProvider,
       _temporaryPhoneProvider = temporaryPhoneProvider;

  final HttpClient Function() _clientFactory;
  final Future<String?> Function()? _accessTokenProvider;
  final Future<String?> Function()? _temporaryPhoneProvider;
  CustomerProfile? _persistedProfile;

  @override
  Future<CustomerProfile?> getProfile() async {
    final result = await _request(method: 'GET');
    if (result.statusCode == HttpStatus.notFound &&
        _errorCode(result.body) == 'profile_not_found') {
      _persistedProfile = null;
      return null;
    }
    if (result.statusCode < 200 || result.statusCode >= 300) {
      throw CustomerProfileException(
        statusCode: result.statusCode,
        code: _errorCode(result.body),
      );
    }
    final profile = _profileFromEnvelope(result.body);
    if (profile == null || profile.profileId == null) {
      throw const CustomerProfileException(statusCode: 502);
    }
    _persistedProfile = profile;
    return profile;
  }

  @override
  Future<CustomerProfile> updateProfile(CustomerProfile profile) async {
    final body = {
      ...profile.toJson(),
      'preferredLanguage': profile.preferredLanguage,
      if (profile.profileId == null) 'createOnly': true,
    };
    final baseline = _persistedProfile;
    if (profile.profileId != null &&
        baseline != null &&
        baseline.profileId == profile.profileId) {
      // Omitted collections are preserved by the API. Do not revalidate or
      // replace saved allergies/preferences while editing another answer.
      if (setEquals(profile.allergens, baseline.allergens)) {
        body.remove('allergens');
      }
      if (setEquals(profile.preferences, baseline.preferences)) {
        body.remove('preferences');
      }
    }
    final result = await _request(method: 'PUT', body: body);
    if (result.statusCode < 200 || result.statusCode >= 300) {
      throw CustomerProfileException(
        statusCode: result.statusCode,
        code: _errorCode(result.body),
        validationFields: _validationFields(result.body),
      );
    }
    final saved = _profileFromEnvelope(
      result.body,
      fallback: profile.copyWith(
        onboardingStatus: 'IN_PROGRESS',
        nextStepCode: 'BASIC_DETAILS',
        shouldShowOnboarding: true,
      ),
    );
    if (saved == null || saved.profileId == null) {
      throw const CustomerProfileException(statusCode: 502);
    }
    _persistedProfile = saved;
    return saved;
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
      } else {
        final temporaryPhone = await _temporaryPhoneProvider?.call();
        if (temporaryPhone != null && temporaryPhone.trim().isNotEmpty) {
          request.headers.set(
            'X-Temporary-Customer-Phone',
            temporaryPhone.trim(),
          );
        }
      }
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 25),
      );
      final responseText = await utf8.decoder.bind(response).join();
      Map<String, dynamic> decoded = const {};
      if (responseText.trim().isNotEmpty) {
        try {
          final value = jsonDecode(responseText);
          if (value is Map<String, dynamic>) decoded = value;
        } on FormatException {
          // A proxy may return HTML on failure; retain its HTTP status.
          if (response.statusCode < 400) {
            throw const CustomerProfileException(statusCode: 502);
          }
        }
      }
      if (response.statusCode >= 400) {
        final errors = decoded['errors'];
        // Log field names/codes, never rejected values or questionnaire answers.
        final fields = errors is Map
            ? errors.keys.join(',')
            : errors is List
            ? errors
                  .whereType<Map>()
                  .map((e) => e['field'] ?? e['target'] ?? e['code'])
                  .join(',')
            : '';
        final correlation =
            response.headers.value('x-correlation-id') ?? decoded['traceId'];
        debugPrint(
          '[CustomerProfile] $method ${uri.path} status=${response.statusCode} validationFields=$fields correlation=$correlation',
        );
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
  final nested = data['customerProfile'] ?? data['profile'];
  final profileJson = nested is Map<String, dynamic> ? nested : data;
  return CustomerProfile.fromJson(profileJson, fallback: fallback);
}

class CustomerProfileException implements Exception {
  const CustomerProfileException({
    this.statusCode,
    this.code,
    this.validationFields = const {},
  });

  final int? statusCode;
  final String? code;
  final Set<String> validationFields;
  String get message {
    if (statusCode == 400 || statusCode == 422) {
      final sections = <String>{};
      for (final field in validationFields) {
        final name = field.toLowerCase().replaceFirst(RegExp(r'^\$\.'), '');
        for (final entry in const {
          'goal': 'goal',
          'gender': 'gender',
          'dateofbirth': 'date of birth',
          'height': 'height',
          'weight': 'weight',
          'dailyroutine': 'daily routine',
          'activitylevel': 'activity level',
          'preferences': 'food preferences',
          'allergens': 'allergy selections',
          'preferredlanguage': 'language',
        }.entries) {
          if (name.startsWith(entry.key)) sections.add(entry.value);
        }
      }
      if (code == 'invalid_allergen_id') sections.add('allergy selections');
      if (sections.isNotEmpty) {
        return 'Please review your ${sections.join(', ')} and retry saving.';
      }
    }
    return switch (statusCode) {
      400 || 422 =>
        'Some answers could not be accepted. Review your selections and retry.',
      401 || 403 =>
        'Your session has expired. Your answers are kept; sign in again to save.',
      409 =>
        'Your profile changed elsewhere. Your answers are kept; retry saving.',
      429 => 'Too many attempts. Please wait briefly and retry.',
      null =>
        'We could not reach the server. Your answers are kept; please retry.',
      _ =>
        'The server could not save your answers. Your answers are kept; please retry.',
    };
  }
}

Set<String> _validationFields(Map<String, dynamic> body) {
  final errors = body['errors'];
  if (errors is Map) return errors.keys.map((key) => key.toString()).toSet();
  if (errors is List) {
    return errors
        .whereType<Map>()
        .map((error) => error['field'] ?? error['target'])
        .whereType<String>()
        .toSet();
  }
  return const {};
}

String? _errorCode(Map<String, dynamic> body) {
  if (body['code'] is String) return body['code'] as String;
  final errors = body['errors'];
  if (errors is! List || errors.isEmpty || errors.first is! Map) return null;
  return (errors.first as Map)['code']?.toString();
}

class _ProfileHttpResult {
  const _ProfileHttpResult({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
}
