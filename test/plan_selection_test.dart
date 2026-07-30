import 'package:diet_time/features/personalization/domain/plan_recommendation.dart';
import 'package:diet_time/features/personalization/presentation/plan_selection_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selected plan details survive the authentication transition', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(planSelectionControllerProvider.notifier)
        .select(
          const PlanRecommendation(
            id: 'plan-id',
            code: 'BALANCED',
            name: 'Balanced Living',
            durationDays: 28,
          ),
          postLoginRoute: '/plans',
          pricingOption: 'MONTHLY',
          startDate: DateTime(2026, 8, 1),
        );

    final selection = container.read(planSelectionControllerProvider);
    expect(selection.planId, 'plan-id');
    expect(selection.planCode, 'BALANCED');
    expect(selection.pricingOption, 'MONTHLY');
    expect(selection.durationDays, 28);
    expect(selection.startDate, DateTime(2026, 8, 1));
    expect(selection.postLoginRoute, '/plans');
  });
}
