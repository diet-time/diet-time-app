import 'dart:convert';
import 'dart:io';

import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allergenRepositoryProvider = Provider<AllergenRepository>(
  (ref) => HttpAllergenRepository(),
);

final guestAllergensProvider =
    FutureProvider.family<List<GuestAllergen>, String>((ref, language) {
      return ref
          .watch(allergenRepositoryProvider)
          .getAllergens(language: language);
    });

abstract interface class AllergenRepository {
  Future<List<GuestAllergen>> getAllergens({required String language});
}

class HttpAllergenRepository implements AllergenRepository {
  HttpAllergenRepository({HttpClient Function()? clientFactory})
    : _clientFactory = clientFactory ?? HttpClient.new;

  final HttpClient Function() _clientFactory;

  @override
  Future<List<GuestAllergen>> getAllergens({required String language}) async {
    final uri = buildGuestAllergensUri(
      baseUrl: AppEnvironment.apiBaseUrl,
      language: language,
    );
    if (kDebugMode) {
      debugPrint('[Allergens] GET ${uri.path}?${uri.query}');
    }
    final client = _clientFactory()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 15));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const AllergenException();
      }
      final bodyText = await utf8.decoder.bind(response).join();
      final decoded = jsonDecode(bodyText);
      if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
        throw const AllergenException();
      }
      return (decoded['data'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(GuestAllergen.fromJson)
          .where(
            (allergen) =>
                allergen.id.isNotEmpty &&
                allergen.code.isNotEmpty &&
                allergen.name.isNotEmpty,
          )
          .toList(growable: false);
    } on AllergenException {
      rethrow;
    } on Object {
      throw const AllergenException();
    } finally {
      client.close(force: true);
    }
  }
}

class GuestAllergen {
  const GuestAllergen({
    required this.id,
    required this.code,
    required this.name,
  });

  factory GuestAllergen.fromJson(Map<String, dynamic> json) => GuestAllergen(
    id: json['id']?.toString().trim() ?? '',
    code: json['code']?.toString().trim() ?? '',
    name: json['name']?.toString().trim() ?? '',
  );

  final String id;
  final String code;
  final String name;
}

class AllergenException implements Exception {
  const AllergenException();
}

Uri buildGuestAllergensUri({
  required String baseUrl,
  required String language,
}) {
  return Uri.parse(baseUrl)
      .resolve(ApiEndpoints.guestAllergens)
      .replace(queryParameters: {'language': language});
}
