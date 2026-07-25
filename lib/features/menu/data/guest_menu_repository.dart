import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/features/menu/domain/guest_home_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final guestMenuRepositoryProvider = Provider<GuestMenuRepository>(
  (ref) => HttpGuestMenuRepository(),
);

abstract interface class GuestMenuRepository {
  Future<GuestHomeResponse> getGuestHome({
    required String language,
    DateTime? date,
    String? planCode,
  });

  Future<GuestMenuResponse> getGuestMenu({
    required String planCode,
    required DateTime date,
    required String language,
  });
}

class HttpGuestMenuRepository implements GuestMenuRepository {
  HttpGuestMenuRepository({HttpClient Function()? clientFactory})
    : _clientFactory = clientFactory ?? HttpClient.new;

  final HttpClient Function() _clientFactory;

  @override
  Future<GuestHomeResponse> getGuestHome({
    required String language,
    DateTime? date,
    String? planCode,
  }) async {
    final uri = buildGuestHomeUri(
      baseUrl: AppEnvironment.apiBaseUrl,
      language: language,
      date: date,
      planCode: planCode,
    );
    final result = await _get(uri);
    if (result.statusCode == HttpStatus.badRequest) {
      throw const GuestMenuException(GuestMenuFailure.invalidRequest);
    }
    if (result.statusCode < 200 || result.statusCode >= 300) {
      throw const GuestMenuException();
    }
    return GuestHomeResponse.fromJson(result.body);
  }

  @override
  Future<GuestMenuResponse> getGuestMenu({
    required String planCode,
    required DateTime date,
    required String language,
  }) async {
    final uri = buildGuestMenuUri(
      baseUrl: AppEnvironment.apiBaseUrl,
      planCode: planCode,
      date: date,
      language: language,
    );
    final result = await _get(uri);
    if (result.statusCode == HttpStatus.notFound) {
      return GuestMenuResponse.empty(planCode: planCode, date: date);
    }
    if (result.statusCode == HttpStatus.badRequest) {
      throw const GuestMenuException(GuestMenuFailure.invalidRequest);
    }
    if (result.statusCode < 200 || result.statusCode >= 300) {
      throw const GuestMenuException();
    }
    return GuestMenuResponse.fromJson(result.body);
  }

  Future<_HttpResult> _get(Uri uri) async {
    if (kDebugMode) {
      debugPrint('[GuestMenu] GET ${uri.path}?${uri.query}');
    }
    final client = _clientFactory()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 20));
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..set(HttpHeaders.contentTypeHeader, 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final bodyText = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _HttpResult(statusCode: response.statusCode, body: const {});
      }
      Map<String, dynamic> body = const {};
      if (bodyText.trim().isNotEmpty) {
        final decoded = jsonDecode(bodyText);
        if (decoded is! Map<String, dynamic>) {
          throw const GuestMenuException();
        }
        body = decoded;
      }
      return _HttpResult(statusCode: response.statusCode, body: body);
    } on GuestMenuException {
      rethrow;
    } on Object {
      throw const GuestMenuException();
    } finally {
      client.close(force: true);
    }
  }
}

Uri buildGuestHomeUri({
  required String baseUrl,
  required String language,
  DateTime? date,
  String? planCode,
}) {
  return Uri.parse(baseUrl)
      .resolve(ApiEndpoints.guestHome)
      .replace(
        queryParameters: {
          'language': language,
          if (date != null) 'date': formatGuestDate(date),
          if (planCode != null && planCode.trim().isNotEmpty)
            'planCode': planCode,
        },
      );
}

Uri buildGuestMenuUri({
  required String baseUrl,
  required String planCode,
  required DateTime date,
  required String language,
}) {
  return Uri.parse(baseUrl)
      .resolve(ApiEndpoints.guestMealPlanMenu(planCode))
      .replace(
        queryParameters: {'date': formatGuestDate(date), 'language': language},
      );
}

enum GuestMenuFailure { network, invalidRequest }

class GuestMenuException implements Exception {
  const GuestMenuException([this.failure = GuestMenuFailure.network]);

  final GuestMenuFailure failure;
}

String resolveMediaUrl(String? value) {
  final candidate = value?.trim() ?? '';
  if (candidate.isEmpty) return '';
  final parsed = Uri.tryParse(candidate);
  if (parsed != null && parsed.hasScheme) return candidate;
  return Uri.parse(AppEnvironment.apiBaseUrl).resolve(candidate).toString();
}

String formatGuestDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

class _HttpResult {
  const _HttpResult({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
}
