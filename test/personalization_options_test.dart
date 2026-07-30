import 'package:diet_time/features/personalization/domain/personalization_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('goal codes have English and Arabic labels', () {
    expect(goalLabels.keys.toSet(), {
      'LOSE_WEIGHT',
      'MAINTAIN_WEIGHT',
      'GAIN_WEIGHT',
      'BUILD_MUSCLE',
      'EAT_HEALTHIER',
    });
    expect(goalLabels['LOSE_WEIGHT']?['en'], 'Lose Weight');
    expect(goalLabels['LOSE_WEIGHT']?['ar'], 'خسارة الوزن');
  });

  test('daily routine codes match the API contract', () {
    expect(dailyRoutineLabels.keys.toSet(), {
      'OFFICE_WORK',
      'WORK_FROM_HOME',
      'STUDENT',
      'ACTIVE_JOB',
      'SHIFT_WORKER',
    });
  });

  test('activity level codes match the API contract', () {
    expect(activityLevelLabels.keys.toSet(), {
      'MOSTLY_SITTING',
      'LIGHT_ACTIVITY',
      'ACTIVE_LIFESTYLE',
      'ATHLETE',
    });
    expect(
      personalizationOptionLabel(activityLevelLabels, 'ACTIVE_LIFESTYLE', 'ar'),
      'نمط حياة نشط',
    );
  });
}
