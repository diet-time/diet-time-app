import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final personalizationControllerProvider =
    NotifierProvider<PersonalizationController, CustomerProfile>(
      PersonalizationController.new,
    );

class PersonalizationController extends Notifier<CustomerProfile> {
  @override
  CustomerProfile build() => const CustomerProfile();

  void replace(CustomerProfile profile) => state = profile;

  void setGoal(String value) => state = state.copyWith(goalCode: value);

  void setGender(String value) => state = state.copyWith(genderCode: value);

  void setAge(int value) {
    if (value <= 0) return;
    final today = DateTime.now();
    final birthYear = today.year - value;
    state = state.copyWith(
      dateOfBirth:
          '$birthYear-${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}',
    );
  }

  void setHeight(double value) {
    if (value <= 0) return;
    state = state.copyWith(heightCm: value);
  }

  void setWeight(double value) {
    if (value <= 0) return;
    state = state.copyWith(weightKg: value);
  }

  void setActivity(String value) =>
      state = state.copyWith(activityLevelCode: value);

  void setRoutine(String value) =>
      state = state.copyWith(dailyRoutineCode: value);

  void setPreferredLanguage(String value) =>
      state = state.copyWith(preferredLanguage: value);

  void togglePreference(String value) {
    final values = {...state.preferences};
    if (!values.add(value)) values.remove(value);
    state = state.copyWith(preferences: values);
  }

  void toggleAllergy(String value) {
    final values = {...state.allergens};
    if (value.toUpperCase() == 'NONE') {
      values
        ..clear()
        ..add('NONE');
    } else {
      values.remove('NONE');
      if (!values.add(value)) values.remove(value);
    }
    state = state.copyWith(allergens: values);
  }

  void clear() => state = const CustomerProfile();
}
