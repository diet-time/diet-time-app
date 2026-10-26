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
    return _profileFromEnvelope(result.body, fallback: profile) ??
        (throw const CustomerProfileException(statusCode: 502));
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
            ? errors.whereType<Map>().map((e) => e['code']).join(',')
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
  const CustomerProfileException({this.statusCode});

  final int? statusCode;
  String get message => switch (statusCode) {
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

class _ProfileHttpResult {
  const _ProfileHttpResult({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
}
