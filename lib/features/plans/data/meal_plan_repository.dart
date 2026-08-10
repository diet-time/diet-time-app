import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return MealPlanRepository(
    ref.watch(apiClientProvider),
    accessTokenProvider: () =>
        storage.read(SecureStorageService.accessTokenKey),
  );
});

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
  const MealPlanRepository(
    this.apiClient, {
    this.accessTokenProvider = _noAccessToken,
  });

  final ApiClient apiClient;
  final Future<String?> Function() accessTokenProvider;

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

  Future<List<MealPlanConfiguration>> getPurchaseOptions({
    required String mealPlanCode,
    required String language,
  }) async {
    final token = await accessTokenProvider();
    final response = await apiClient.request(
      method: 'GET',
      path: ApiEndpoints.mealPlanPurchaseOptions(mealPlanCode),
      queryParameters: {'language': language},
      headers: {
        if (token?.trim().isNotEmpty == true)
          'Authorization': 'Bearer ${token!.trim()}',
      },
    );
    if (!response.isSuccess) throw ApiException.fromResponse(response);
    final data = response.body['data'];
    if (data is! Map<String, dynamic> || data['mealConfigurations'] is! List) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return (data['mealConfigurations'] as List)
        .whereType<Map<String, dynamic>>()
        .map(MealPlanConfiguration.fromJson)
        .where((configuration) => configuration.isValid)
        .toList(growable: false);
  }
}

Future<String?> _noAccessToken() async => null;

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
          selectedMeals: _mealSelections(
            supportedMealTypes,
            meals: meals,
            snacks: snacks,
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

List<MealPlanMealSelection> _mealSelections(
  List<Map<String, dynamic>> mealTypes, {
  required int meals,
  required int snacks,
}) {
  bool isSnack(Map<String, dynamic> item) {
    final code = item['code']?.toString().toUpperCase() ?? '';
    return code.contains('SNACK') || code.contains('DESSERT');
  }

  MealPlanMealSelection selection(
    Map<String, dynamic> item, {
    int quantity = 1,
  }) => MealPlanMealSelection(
    mealTypeId: (item['mealTypeId'] ?? item['id'])?.toString().trim() ?? '',
    name: (item['name'] ?? item['mealTypeName'])?.toString().trim() ?? 'Meal',
    quantity: quantity,
  );

  final selected = mealTypes
      .where((item) => !isSnack(item))
      .take(meals)
      .map(selection)
      .where((item) => item.isValid)
      .toList();
  if (snacks > 0) {
    final snackTypes = mealTypes.where(isSnack);
    if (snackTypes.isNotEmpty) {
      final snack = selection(snackTypes.first, quantity: snacks);
      if (snack.isValid) selected.add(snack);
    }
  }
  return List.unmodifiable(selected);
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
