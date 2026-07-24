import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mealDetailRepositoryProvider = Provider<MealDetailRepository>(
  (ref) => HttpMealDetailRepository(),
);

abstract interface class MealDetailRepository {
  Future<MealDetailData?> getMealDetail({
    required String mealId,
    required String language,
  });
}

class HttpMealDetailRepository implements MealDetailRepository {
  HttpMealDetailRepository({HttpClient Function()? clientFactory})
    : _clientFactory = clientFactory ?? HttpClient.new;

  final HttpClient Function() _clientFactory;
  final Map<String, Future<MealDetailData?>> _cache = {};

  @override
  Future<MealDetailData?> getMealDetail({
    required String mealId,
    required String language,
  }) {
    final key = '${language.toLowerCase()}:${mealId.toLowerCase()}';
    return _cache.putIfAbsent(key, () async {
      try {
        return await _fetch(mealId: mealId, language: language);
      } on Object {
        _cache.remove(key);
        rethrow;
      }
    });
  }

  Future<MealDetailData?> _fetch({
    required String mealId,
    required String language,
  }) async {
    final uri = Uri.parse(AppEnvironment.apiBaseUrl)
        .resolve(ApiEndpoints.mealDetails(mealId))
        .replace(queryParameters: {'language': language});
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
      if (response.statusCode == HttpStatus.notFound) return null;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const MealDetailException();
      }
      final body = await utf8.decoder.bind(response).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const MealDetailException();
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw const MealDetailException();
      }
      return MealDetailData.fromJson(data);
    } on MealDetailException {
      rethrow;
    } on Object {
      throw const MealDetailException();
    } finally {
      client.close(force: true);
    }
  }
}

class MealDetailException implements Exception {
  const MealDetailException();
}

class MealDetailData {
  const MealDetailData({
    required this.ingredients,
    required this.allergens,
    this.fullDescription,
    this.primaryImageUrl,
    this.fiberGrams,
    this.sodiumMg,
  });

  factory MealDetailData.fromJson(Map<String, dynamic> json) {
    final nutrition = _map(json['nutrition']);
    return MealDetailData(
      fullDescription: _string(json['fullDescription']),
      primaryImageUrl: _string(json['primaryImageUrl']),
      fiberGrams: _nullableDecimal(nutrition['fiberGrams']),
      sodiumMg: _nullableDecimal(nutrition['sodiumMg']),
      ingredients: _list(json['ingredients'])
          .map((item) => MealDetailIngredient.fromJson(_map(item)))
          .toList(growable: false),
      allergens: _list(json['allergens'])
          .map((item) => _string(_map(item)['name']))
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String? fullDescription;
  final String? primaryImageUrl;
  final double? fiberGrams;
  final double? sodiumMg;
  final List<MealDetailIngredient> ingredients;
  final List<String> allergens;
}

class MealDetailIngredient {
  const MealDetailIngredient({required this.name, this.quantity, this.unit});

  factory MealDetailIngredient.fromJson(Map<String, dynamic> json) =>
      MealDetailIngredient(
        name: _string(json['name']) ?? '',
        quantity: _nullableDecimal(json['quantity']),
        unit: _string(json['unit']),
      );

  final String name;
  final double? quantity;
  final String? unit;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

List<dynamic> _list(Object? value) => value is List ? value : const [];

String? _string(Object? value) {
  final result = value?.toString().trim();
  return result == null || result.isEmpty ? null : result;
}

double? _nullableDecimal(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
