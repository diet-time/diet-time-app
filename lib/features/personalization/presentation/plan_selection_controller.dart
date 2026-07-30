import 'package:diet_time/features/personalization/domain/plan_recommendation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlanSelectionState {
  const PlanSelectionState({
    this.planId,
    this.planCode,
    this.planName,
    this.pricingOption,
    this.durationDays,
    this.startDate,
    this.postLoginRoute,
  });

  final String? planId;
  final String? planCode;
  final String? planName;
  final String? pricingOption;
  final int? durationDays;
  final DateTime? startDate;
  final String? postLoginRoute;
}

final planSelectionControllerProvider =
    NotifierProvider<PlanSelectionController, PlanSelectionState>(
      PlanSelectionController.new,
    );

class PlanSelectionController extends Notifier<PlanSelectionState> {
  @override
  PlanSelectionState build() => const PlanSelectionState();

  void select(
    PlanRecommendation plan, {
    required String postLoginRoute,
    String? pricingOption,
    DateTime? startDate,
  }) {
    state = PlanSelectionState(
      planId: plan.id,
      planCode: plan.code,
      planName: plan.name,
      pricingOption: pricingOption,
      durationDays: plan.durationDays,
      startDate: startDate,
      postLoginRoute: postLoginRoute,
    );
  }

  void clear() => state = const PlanSelectionState();
}
