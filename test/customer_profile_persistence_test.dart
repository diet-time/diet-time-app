import 'dart:async';

import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile JSON excludes the locally stored language selection', () {
    final profile = const CustomerProfile().copyWith(
      genderCode: 'FEMALE',
      dateOfBirth: '1998-01-01',
      heightCm: 170,
      weightKg: 70,
      goalCode: 'LOSE_WEIGHT',
      dailyRoutineCode: 'OFFICE_WORK',
      activityLevelCode: 'MOSTLY_SITTING',
      preferredLanguage: 'ar',
      preferences: {'HIGH_PROTEIN'},
      allergens: {'allergen-id'},
    );

    expect(profile.toJson(), {
      'genderCode': 'FEMALE',
      'dateOfBirth': '1998-01-01',
      'heightCm': 170.0,
      'weightKg': 70.0,
      'goalCode': 'LOSE_WEIGHT',
      'dailyRoutineCode': 'OFFICE_WORK',
      'activityLevelCode': 'MOSTLY_SITTING',
      'onboardingStatus': 'IN_PROGRESS',
      'preferencesConfirmed': false,
      'allergensConfirmed': false,
      'preferences': [
        {
          'preferenceCode': 'HIGH_PROTEIN',
          'preferenceType': 'DIET_STYLE',
          'preferencePriority': 5,
        },
      ],
      'allergens': [
        {
          'allergenId': 'allergen-id',
          'medicallyConfirmed': false,
          'notes': null,
        },
      ],
    });
    expect(profile.toJson(), isNot(contains('preferredLanguage')));
  });

  test('backend BMI and nutrition targets populate the shared profile', () {
    final profile = CustomerProfile.fromJson(const {
      'preferredName': 'Noor',
      'genderCode': 'MALE',
      'dateOfBirth': '1990-04-10',
      'heightCm': 180,
      'weightKg': 82,
      'bmi': 25.3,
      'nutritionTargets': {
        'calories': 2300,
        'proteinGrams': 155,
        'carbsGrams': 240,
        'fatGrams': 75,
        'waterMl': 2800,
      },
    });

    expect(profile.preferredName, 'Noor');
    expect(profile.bmi, 25.3);
    expect(profile.nutritionTargets?.calories, 2300);
    expect(profile.nutritionTargets?.proteinGrams, 155);
  });

  test(
    'save prevents duplicate requests and keeps returned backend state',
    () async {
      final repository = _BlockingProfileRepository();
      final container = ProviderContainer(
        overrides: [
          customerProfileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(personalizationControllerProvider.notifier)
          .setGoal('LOSE_WEIGHT');

      final controller = container.read(
        profilePersistenceControllerProvider.notifier,
      );
      await controller.load(authenticated: true);
      final firstSave = controller.save(complete: false);
      final duplicateSave = await controller.save(complete: false);

      expect(duplicateSave, isFalse);
      expect(repository.updateCalls, 1);

      repository.complete();
      expect(await firstSave, isTrue);
      expect(container.read(personalizationControllerProvider).bmi, 24.2);
    },
  );

  test('resume chooses the first incomplete required step', () {
    expect(resumeStepFor(const CustomerProfile()), 2);
    expect(resumeStepFor(const CustomerProfile(nextStepCode: 'ALLERGENS')), 6);
    expect(
      resumeStepFor(const CustomerProfile(nextStepCode: 'PREFERENCES')),
      5,
    );
  });

  test('server completion fields are authoritative', () {
    expect(
      const CustomerProfile(
        onboardingStatus: 'IN_PROGRESS',
        nextStepCode: 'PROFILE_COMPLETED',
      ).isCompleted,
      isTrue,
    );
    expect(
      const CustomerProfile(
        onboardingStatus: 'PROFILE_COMPLETED',
        nextStepCode: 'GOAL',
        shouldShowOnboarding: true,
      ).isCompleted,
      isFalse,
    );
  });

  test('captured questionnaire requires every accumulated section', () {
    const captured = CustomerProfile(
      genderCode: 'FEMALE',
      dateOfBirth: '1998-01-01',
      heightCm: 170,
      weightKg: 70,
      goalCode: 'LOSE_WEIGHT',
      dailyRoutineCode: 'OFFICE_WORK',
      activityLevelCode: 'MOSTLY_SITTING',
      preferencesConfirmed: true,
      allergensConfirmed: true,
    );

    expect(captured.hasCapturedQuestionnaire, isTrue);
    expect(
      captured.copyWith(allergensConfirmed: false).hasCapturedQuestionnaire,
      isFalse,
    );
  });

  test('empty optional selections remain distinct from confirmation', () {
    const incomplete = CustomerProfile(
      nextStepCode: 'ALLERGENS',
      allergens: {},
      allergensConfirmed: false,
    );
    const confirmedEmpty = CustomerProfile(
      nextStepCode: 'PREFERENCES',
      allergens: {},
      allergensConfirmed: true,
    );

    expect(resumeStepFor(incomplete), 6);
    expect(resumeStepFor(confirmedEmpty), 5);
    expect(confirmedEmpty.toJson()['allergens'], isEmpty);
  });
}

class _BlockingProfileRepository implements CustomerProfileRepository {
  final _completer = Completer<void>();
  int updateCalls = 0;

  void complete() => _completer.complete();

  @override
  Future<CustomerProfile?> getProfile() async => null;

  @override
  Future<CustomerProfile> updateProfile(CustomerProfile profile) async {
    updateCalls++;
    await _completer.future;
    return profile.copyWith(
      bmi: 24.2,
      nutritionTargets: const NutritionTargets(calories: 2200),
    );
  }
}
