import 'package:flutter/foundation.dart';
import 'customer_profile.dart';

/// Reapply only this customer's questionnaire edits onto the latest server row.
/// Concurrent edits to the same answer require review instead of an auto retry.
({CustomerProfile profile, bool hasConflicts}) mergeQuestionnaireAnswers(
  CustomerProfile baseline,
  CustomerProfile local,
  CustomerProfile remote,
) {
  var conflicts = false;
  T choose<T>(T before, T edited, T latest) {
    bool equal(Object? a, Object? b) =>
        a is Set<String> && b is Set<String> ? setEquals(a, b) : a == b;
    if (equal(before, edited)) return latest;
    if (!equal(before, latest) && !equal(edited, latest)) conflicts = true;
    return edited;
  }

  final profile = remote.copyWith(
    goalCode: choose(baseline.goalCode, local.goalCode, remote.goalCode),
    genderCode: choose(
      baseline.genderCode,
      local.genderCode,
      remote.genderCode,
    ),
    dateOfBirth: choose(
      baseline.dateOfBirth,
      local.dateOfBirth,
      remote.dateOfBirth,
    ),
    heightCm: choose(baseline.heightCm, local.heightCm, remote.heightCm),
    weightKg: choose(baseline.weightKg, local.weightKg, remote.weightKg),
    dailyRoutineCode: choose(
      baseline.dailyRoutineCode,
      local.dailyRoutineCode,
      remote.dailyRoutineCode,
    ),
    activityLevelCode: choose(
      baseline.activityLevelCode,
      local.activityLevelCode,
      remote.activityLevelCode,
    ),
    preferences: choose(
      baseline.preferences,
      local.preferences,
      remote.preferences,
    ),
    allergens: choose(baseline.allergens, local.allergens, remote.allergens),
    preferencesConfirmed: choose(
      baseline.preferencesConfirmed,
      local.preferencesConfirmed,
      remote.preferencesConfirmed,
    ),
    allergensConfirmed: choose(
      baseline.allergensConfirmed,
      local.allergensConfirmed,
      remote.allergensConfirmed,
    ),
  );
  return (profile: profile, hasConflicts: conflicts);
}
