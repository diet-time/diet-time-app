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
    required DateTime date,
    String? planCode,
    String mealTimeCode = 'ALL',
    int page = 1,
    int pageSize = 20,
    bool includeAll = false,
  });
}

class HttpGuestMenuRepository implements GuestMenuRepository {
  HttpGuestMenuRepository({HttpClient Function()? clientFactory})
    : _clientFactory = clientFactory ?? HttpClient.new;

  final HttpClient Function() _clientFactory;

  @override
  Future<GuestHomeResponse> getGuestHome({
    required String language,
    required DateTime date,
    String? planCode,
    String mealTimeCode = 'ALL',
    int page = 1,
    int pageSize = 20,
    bool includeAll = false,
  }) async {
    final base = Uri.parse(AppEnvironment.apiBaseUrl);
    final uri = base
        .resolve(ApiEndpoints.guestHome)
        .replace(
          queryParameters: {
            'language': language,
            'date': _date(date),
            if (planCode != null && planCode.trim().isNotEmpty)
              'planCode': planCode,
            'mealTimeCode': mealTimeCode,
            'page': '$page',
            'pageSize': '$pageSize',
            'includeAll': '$includeAll',
          },
        );
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
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const GuestMenuException();
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const GuestMenuException();
      }
      return GuestHomeResponse.fromJson(decoded);
    } on GuestMenuException {
      rethrow;
    } on Object {
      throw const GuestMenuException();
    } finally {
      client.close(force: true);
    }
  }
}

class GuestMenuException implements Exception {
  const GuestMenuException();
}

String resolveMediaUrl(String? value) {
  final candidate = value?.trim() ?? '';
  if (candidate.isEmpty) return '';
  final parsed = Uri.tryParse(candidate);
  if (parsed != null && parsed.hasScheme) return candidate;
  return Uri.parse(AppEnvironment.apiBaseUrl).resolve(candidate).toString();
}

String _date(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
