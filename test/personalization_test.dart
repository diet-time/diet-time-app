import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Riverpod profile preserves answers without calculating BMI', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      personalizationControllerProvider.notifier,
    );

    controller.setGoal('LOSE_WEIGHT');
    controller.setHeight(176);
    controller.setWeight(80);
    controller.setRoutine('SHIFT_WORKER');
    controller.setActivity('ACTIVE_LIFESTYLE');

    final draft = container.read(personalizationControllerProvider);
    expect(draft.primaryGoal, 'LOSE_WEIGHT');
    expect(draft.dailyRoutine, 'SHIFT_WORKER');
    expect(draft.activityLevel, 'ACTIVE_LIFESTYLE');
    expect(draft.heightCm, 176);
    expect(draft.weightKg, 80);
    expect(draft.bmi, isNull);
  });
}
