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
      if (request.plan.mealConfigurations.isNotEmpty) {
        return request.plan.mealConfigurations;
      }
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
    final value =
        raw['mealConfigurations'] ??
        raw['configurations'] ??
        raw['mealQuantityConfigurations'];
    if (value is! List) throw const ApiException(ApiFailure.invalidResponse);
    return value
        .whereType<Map<String, dynamic>>()
        .map(MealPlanConfiguration.fromJson)
        .where((item) => item.isValid)
        .toList(growable: false);
  }
}
