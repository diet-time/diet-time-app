import 'package:diet_time/features/personalization/domain/personalization_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final personalizationControllerProvider =
    NotifierProvider<PersonalizationController, PersonalizationDraft>(
      PersonalizationController.new,
    );

class PersonalizationController extends Notifier<PersonalizationDraft> {
  @override
  PersonalizationDraft build() => const PersonalizationDraft();

  void setGoal(String value) => state = state.copyWith(primaryGoal: value);

  void setGender(String value) => state = state.copyWith(gender: value);

  void setAge(int value) => state = state.copyWith(age: value);

  void setHeight(double value) {
    if (value <= 0) return;
    state = state.copyWith(
      heightCm: value,
      bmi: calculateBmi(weightKg: state.weightKg, heightCm: value),
    );
  }

  void setWeight(double value) {
    if (value <= 0) return;
    state = state.copyWith(
      weightKg: value,
      bmi: calculateBmi(weightKg: value, heightCm: state.heightCm),
    );
  }

  void setActivity(String value) =>
      state = state.copyWith(activityLevel: value);

  void setRoutine(String value) => state = state.copyWith(dailyRoutine: value);

  void togglePreference(String value) {
    final values = {...state.foodPreferenceIds};
    if (!values.add(value)) values.remove(value);
    state = state.copyWith(foodPreferenceIds: values);
  }

  void toggleAllergy(String value) {
    final values = {...state.allergenIds};
    if (value.toUpperCase() == 'NONE') {
      values
        ..clear()
        ..add('NONE');
    } else {
      values.remove('NONE');
      if (!values.add(value)) values.remove(value);
    }
    state = state.copyWith(allergenIds: values);
  }

  void clear() => state = const PersonalizationDraft();
}
