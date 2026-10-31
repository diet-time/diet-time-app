import 'package:diet_time/features/personalization/domain/customer_profile.dart';

enum CustomerJourneyIntent { normalLogin, startNewPlan }

enum CustomerOnboardingPhase {
  unauthenticated,
  loadingProfile,
  profileRequired,
  nameRequired,
  questionnaireRequired,
  ready,
  recoverableError,
}

/// The existing compiled questionnaire widgets, in their displayed order.
/// Welcome, BMI and success pages are not required questionnaire questions.
abstract final class CustomerQuestionnaire {
  static const steps = [
    (code: 'GOAL', page: 1),
    (code: 'BASIC_DETAILS', page: 2),
    (code: 'DAILY_ROUTINE', page: 3),
    (code: 'ACTIVITY_LEVEL', page: 4),
    (code: 'PREFERENCES', page: 5),
    (code: 'ALLERGENS', page: 6),
  ];

  static bool answered(CustomerProfile profile, String code) {
    bool text(String? value) => value?.trim().isNotEmpty == true;
    switch (code) {
      case 'GOAL':
        return text(profile.goalCode);
      case 'BASIC_DETAILS':
        final birth = DateTime.tryParse(profile.dateOfBirth ?? '');
        final today = DateTime.now();
        return text(profile.genderCode) &&
            birth != null &&
            !birth.isAfter(today) &&
            !birth.isBefore(
              DateTime(today.year - 120, today.month, today.day),
            ) &&
            profile.heightCm != null &&
            profile.heightCm! >= 50 &&
            profile.heightCm! <= 300 &&
            profile.weightKg != null &&
            profile.weightKg! >= 15 &&
            profile.weightKg! <= 500;
      case 'DAILY_ROUTINE':
        return text(profile.dailyRoutineCode);
      case 'ACTIVITY_LEVEL':
        return text(profile.activityLevelCode);
      case 'PREFERENCES':
        return profile.preferencesConfirmed;
      case 'ALLERGENS':
        return profile.allergensConfirmed;
      default:
        return false;
    }
  }

  static int firstIncompletePage(CustomerProfile profile) {
    for (final step in steps) {
      if (!answered(profile, step.code)) return step.page;
    }
    // Confirm/retry completion until the backend acknowledges completion.
    return steps.last.page;
  }

  static int progress(CustomerProfile? persisted) {
    if (persisted == null) return 0;
    if (persisted.isCompleted) return 100;
    var completed = 0;
    for (final step in steps) {
      if (!answered(persisted, step.code)) break;
      completed++;
    }
    return (completed.clamp(0, steps.length - 1) * 100 / steps.length).round();
  }

  static int? previousPage(int page) {
    final index = steps.indexWhere((step) => step.page == page);
    return index <= 0 ? null : steps[index - 1].page;
  }
}

abstract final class CustomerOnboardingPolicy {
  static bool validName(String? value) {
    final name = value?.trim() ?? '';
    return name.length >= 2 &&
        name.length <= 150 &&
        RegExp(r'\p{L}', unicode: true).hasMatch(name);
  }

  static CustomerOnboardingPhase phase(CustomerProfile? profile) {
    if (profile == null || profile.profileId == null) {
      return CustomerOnboardingPhase.profileRequired;
    }
    if (!validName(profile.preferredName)) {
      return CustomerOnboardingPhase.nameRequired;
    }
    return profile.isCompleted
        ? CustomerOnboardingPhase.ready
        : CustomerOnboardingPhase.questionnaireRequired;
  }

  static bool ready(CustomerProfile? profile) =>
      phase(profile) == CustomerOnboardingPhase.ready;
}
