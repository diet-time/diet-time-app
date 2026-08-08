import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mealPlanRepositoryProvider = Provider<MealPlanRepository>(
  (ref) => MealPlanRepository(ref.watch(apiClientProvider)),
);

final mealPlansProvider = FutureProvider.family<List<MealPlanOption>, String>(
  (ref, language) =>
      ref.watch(mealPlanRepositoryProvider).getMealPlans(language: language),
);

typedef MealPlanDetailsRequest = ({MealPlanOption plan, String language});

final mealPlanConfigurationsProvider =
    FutureProvider.family<List<MealPlanConfiguration>, MealPlanDetailsRequest>((
      ref,
      request,
    ) async {
      return ref
          .watch(mealPlanRepositoryProvider)
          .getMealPlanConfigurations(
            mealPlanTemplateId: request.plan.id,
            language: request.language,
          );
    }, retry: (_, _) => null);

class MealPlanRepository {
  const MealPlanRepository(this.apiClient);

  final ApiClient apiClient;

  Future<List<MealPlanOption>> getMealPlans({required String language}) async {
    final response = await apiClient.request(
      method: 'GET',
      path: ApiEndpoints.mealPlans,
      queryParameters: {'language': language},
    );
    if (!response.isSuccess) throw ApiException.fromResponse(response);
    final data = response.body['data'];
    if (data is! List) throw const ApiException(ApiFailure.invalidResponse);
    return data
        .whereType<Map<String, dynamic>>()
        .map(MealPlanOption.fromJson)
        .where(
          (plan) =>
              plan.id.isNotEmpty &&
              plan.code.isNotEmpty &&
              plan.name.isNotEmpty,
        )
        .toList(growable: false);
  }

  Future<List<MealPlanConfiguration>> getMealPlanConfigurations({
    required String mealPlanTemplateId,
    required String language,
  }) async {
    final response = await apiClient.request(
      method: 'GET',
      path: ApiEndpoints.mealPlanDetails(mealPlanTemplateId),
      queryParameters: {'language': language},
    );
    if (!response.isSuccess) throw ApiException.fromResponse(response);
    final raw = response.body['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return parseMealPlanConfigurations(raw, language: language);
  }
}

List<MealPlanConfiguration> parseMealPlanConfigurations(
  Map<String, dynamic> raw, {
  required String language,
}) {
  final nested =
      raw['mealConfigurations'] ??
      raw['configurations'] ??
      raw['mealQuantityConfigurations'];
  if (nested is List) {
    return nested
        .whereType<Map<String, dynamic>>()
        .map(MealPlanConfiguration.fromJson)
        .where((item) => item.isValid)
        .toList(growable: false);
  }

  final prices = raw['prices'];
  if (prices is! List) throw const ApiException(ApiFailure.invalidResponse);
  final supportedMealTypes = raw['supportedMealTypes'] is List
      ? (raw['supportedMealTypes'] as List)
            .whereType<Map<String, dynamic>>()
            .toList(growable: false)
      : const <Map<String, dynamic>>[];
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final price in prices.whereType<Map<String, dynamic>>()) {
    final meals = _integer(price['mealsPerDay']);
    final snacks = _integer(price['snacksPerDay']) ?? 0;
    if (meals == null || meals <= 0 || snacks < 0) continue;
    grouped.putIfAbsent('$meals-$snacks', () => []).add(price);
  }

  return grouped.entries
      .map((entry) {
        final first = entry.value.first;
        final meals = _integer(first['mealsPerDay'])!;
        final snacks = _integer(first['snacksPerDay']) ?? 0;
        return MealPlanConfiguration(
          id: entry.key,
          name: _configurationName(
            meals: meals,
            snacks: snacks,
            language: language,
          ),
          description: _configurationDescription(
            supportedMealTypes,
            meals: meals,
            snacks: snacks,
            language: language,
          ),
          packages: entry.value
              .map(
                (price) => MealPlanPackage.fromJson({
                  ...price,
                  'serviceDays': price['serviceDays'] ?? price['durationDays'],
                  'totalPrice': price['totalPrice'] ?? price['amount'],
                }),
              )
              .where((item) => item.isValid)
              .toList(growable: false),
        );
      })
      .where((item) => item.isValid)
      .toList(growable: false);
}

String _configurationName({
  required int meals,
  required int snacks,
  required String language,
}) {
  if (language == 'ar') {
    final mealLabel = meals == 1 ? 'وجبة واحدة' : '$meals وجبات';
    if (snacks == 0) return mealLabel;
    final snackLabel = snacks == 1 ? 'وجبة خفيفة' : '$snacks وجبات خفيفة';
    return '$mealLabel + $snackLabel';
  }
  final mealLabel = '$meals ${meals == 1 ? 'Meal' : 'Meals'}';
  if (snacks == 0) return mealLabel;
  return '$mealLabel + $snacks ${snacks == 1 ? 'Snack' : 'Snacks'}';
}

String? _configurationDescription(
  List<Map<String, dynamic>> mealTypes, {
  required int meals,
  required int snacks,
  required String language,
}) {
  final regular = mealTypes
      .where((item) {
        final code = item['code']?.toString().toUpperCase() ?? '';
        return !code.contains('SNACK') && !code.contains('DESSERT');
      })
      .take(meals)
      .map((item) {
        final name = item['name']?.toString().trim() ?? '';
        return name.isEmpty ? '' : '1 $name';
      });
  final names = regular.where((name) => name.isNotEmpty).toList();
  if (snacks > 0) {
    names.add(
      language == 'ar'
          ? (snacks == 1 ? 'وجبة خفيفة' : '$snacks وجبات خفيفة')
          : '$snacks ${snacks == 1 ? 'Snack' : 'Snacks'}',
    );
  }
  return names.isEmpty ? null : names.join(' · ');
}

int? _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
