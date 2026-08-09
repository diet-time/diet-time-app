class CustomerProfile {
  const CustomerProfile({
    this.profileId,
    this.preferredName,
    this.genderCode,
    this.dateOfBirth,
    this.heightCm,
    this.weightKg,
    this.goalCode,
    this.dailyRoutineCode,
    this.activityLevelCode,
    this.preferredLanguage = 'en',
    this.onboardingStatus = 'IN_PROGRESS',
    this.preferences = const {},
    this.allergens = const {},
    this.bmi,
    this.bmiCategoryCode,
    this.nutritionTargets,
    this.allergensConfirmed = false,
    this.preferencesConfirmed = false,
    this.nextStepCode = 'BASIC_DETAILS',
    this.completionPercentage = 0,
    this.shouldShowOnboarding = true,
    this.updatedAt,
    this.rowVersion,
  });

  factory CustomerProfile.fromJson(
    Map<String, dynamic> json, {
    CustomerProfile fallback = const CustomerProfile(),
  }) {
    final nutritionJson = json['nutritionTarget'] ?? json['nutritionTargets'];
    final onboardingStatus =
        _string(json['onboardingStatus']) ?? fallback.onboardingStatus;
    final statusIsComplete =
        onboardingStatus == 'COMPLETED' ||
        onboardingStatus == 'PROFILE_COMPLETED';
    final nextStepCode =
        _string(json['nextStepCode']) ??
        (statusIsComplete ? 'PROFILE_COMPLETED' : fallback.nextStepCode);
    return CustomerProfile(
      profileId:
          _string(
            json['profileId'] ?? json['customerProfileId'] ?? json['id'],
          ) ??
          fallback.profileId,
      preferredName: _string(json['preferredName']) ?? fallback.preferredName,
      genderCode: _string(json['genderCode']) ?? fallback.genderCode,
      dateOfBirth: _string(json['dateOfBirth']) ?? fallback.dateOfBirth,
      heightCm: _decimal(json['heightCm']) ?? fallback.heightCm,
      weightKg: _decimal(json['weightKg']) ?? fallback.weightKg,
      goalCode: _string(json['goalCode']) ?? fallback.goalCode,
      dailyRoutineCode:
          _string(json['dailyRoutineCode']) ?? fallback.dailyRoutineCode,
      activityLevelCode:
          _string(json['activityLevelCode']) ?? fallback.activityLevelCode,
      preferredLanguage:
          _string(json['preferredLanguage']) ?? fallback.preferredLanguage,
      onboardingStatus: onboardingStatus,
      preferences: _stringSet(
        json['preferenceIds'] ?? json['preferences'],
        fallback.preferences,
      ),
      allergens: _stringSet(
        json['allergenIds'] ?? json['allergens'],
        fallback.allergens,
      ),
      bmi: _decimal(json['bmi']) ?? fallback.bmi,
      bmiCategoryCode:
          _string(json['bmiCategoryCode']) ?? fallback.bmiCategoryCode,
      nutritionTargets: nutritionJson is Map<String, dynamic>
          ? NutritionTargets.fromJson(nutritionJson)
          : fallback.nutritionTargets,
      allergensConfirmed: json.containsKey('allergensConfirmed')
          ? json['allergensConfirmed'] == true
          : fallback.allergensConfirmed,
      preferencesConfirmed: json.containsKey('preferencesConfirmed')
          ? json['preferencesConfirmed'] == true
          : fallback.preferencesConfirmed,
      nextStepCode: nextStepCode,
      completionPercentage:
          _integer(json['completionPercentage']) ??
          fallback.completionPercentage,
      shouldShowOnboarding: json.containsKey('shouldShowOnboarding')
          ? json['shouldShowOnboarding'] == true
          : statusIsComplete
          ? false
          : fallback.shouldShowOnboarding,
      updatedAt: _dateTime(json['updatedAt']) ?? fallback.updatedAt,
      rowVersion: _integer(json['rowVersion']) ?? fallback.rowVersion,
    );
  }

  final String? profileId;
  final String? preferredName;
  final String? genderCode;
  final String? dateOfBirth;
  final double? heightCm;
  final double? weightKg;
  final String? goalCode;
  final String? dailyRoutineCode;
  final String? activityLevelCode;
  final String preferredLanguage;
  final String onboardingStatus;
  final Set<String> preferences;
  final Set<String> allergens;
  final double? bmi;
  final String? bmiCategoryCode;
  final NutritionTargets? nutritionTargets;
  final bool allergensConfirmed;
  final bool preferencesConfirmed;
  final String nextStepCode;
  final int completionPercentage;
  final bool shouldShowOnboarding;
  final DateTime? updatedAt;
  final int? rowVersion;

  bool get isCompleted =>
      !shouldShowOnboarding || nextStepCode == 'PROFILE_COMPLETED';
  bool get hasCapturedQuestionnaire =>
      genderCode != null &&
      dateOfBirth != null &&
      heightCm != null &&
      weightKg != null &&
      goalCode != null &&
      dailyRoutineCode != null &&
      activityLevelCode != null &&
      preferencesConfirmed &&
      allergensConfirmed;
  String? get primaryGoal => goalCode;
  String get gender => genderCode ?? '';
  int get age {
    final birthDate = DateTime.tryParse(dateOfBirth ?? '');
    if (birthDate == null) return 0;
    final today = DateTime.now();
    var result = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      result--;
    }
    return result;
  }

  String? get activityLevel => activityLevelCode;
  String? get dailyRoutine => dailyRoutineCode;
  Set<String> get foodPreferenceIds => preferences;
  Set<String> get allergenIds => allergens;

  Map<String, dynamic> toJson() => {
    if (genderCode != null) 'genderCode': genderCode,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
    if (heightCm != null) 'heightCm': heightCm,
    if (weightKg != null) 'weightKg': weightKg,
    if (goalCode != null) 'goalCode': goalCode,
    if (dailyRoutineCode != null) 'dailyRoutineCode': dailyRoutineCode,
    if (activityLevelCode != null) 'activityLevelCode': activityLevelCode,
    'onboardingStatus': onboardingStatus,
    'preferencesConfirmed': preferencesConfirmed,
    'allergensConfirmed': allergensConfirmed,
    'preferences': [
      for (final code in preferences.where((value) => value != 'NONE'))
        CustomerPreference(
          preferenceCode: code,
          preferenceType: 'DIET_STYLE',
          preferencePriority: 5,
        ).toJson(),
    ],
    'allergens': [
      for (final id in allergens.where(
        (value) => value != 'NONE' && value != 'none',
      ))
        CustomerAllergen(allergenId: id).toJson(),
    ],
    if (rowVersion != null) 'rowVersion': rowVersion,
  };

  CustomerProfile copyWith({
    String? profileId,
    String? preferredName,
    String? genderCode,
    String? dateOfBirth,
    double? heightCm,
    double? weightKg,
    String? goalCode,
    String? dailyRoutineCode,
    String? activityLevelCode,
    String? preferredLanguage,
    String? onboardingStatus,
    Set<String>? preferences,
    Set<String>? allergens,
    double? bmi,
    String? bmiCategoryCode,
    NutritionTargets? nutritionTargets,
    bool? allergensConfirmed,
    bool? preferencesConfirmed,
    String? nextStepCode,
    int? completionPercentage,
    bool? shouldShowOnboarding,
    DateTime? updatedAt,
    int? rowVersion,
  }) {
    return CustomerProfile(
      profileId: profileId ?? this.profileId,
      preferredName: preferredName ?? this.preferredName,
      genderCode: genderCode ?? this.genderCode,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goalCode: goalCode ?? this.goalCode,
      dailyRoutineCode: dailyRoutineCode ?? this.dailyRoutineCode,
      activityLevelCode: activityLevelCode ?? this.activityLevelCode,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      preferences: preferences ?? this.preferences,
      allergens: allergens ?? this.allergens,
      bmi: bmi ?? this.bmi,
      bmiCategoryCode: bmiCategoryCode ?? this.bmiCategoryCode,
      nutritionTargets: nutritionTargets ?? this.nutritionTargets,
      allergensConfirmed: allergensConfirmed ?? this.allergensConfirmed,
      preferencesConfirmed: preferencesConfirmed ?? this.preferencesConfirmed,
      nextStepCode: nextStepCode ?? this.nextStepCode,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      shouldShowOnboarding: shouldShowOnboarding ?? this.shouldShowOnboarding,
      updatedAt: updatedAt ?? this.updatedAt,
      rowVersion: rowVersion ?? this.rowVersion,
    );
  }
}

class CustomerPreference {
  const CustomerPreference({
    required this.preferenceCode,
    required this.preferenceType,
    required this.preferencePriority,
  });

  final String preferenceCode;
  final String preferenceType;
  final int preferencePriority;

  Map<String, dynamic> toJson() => {
    'preferenceCode': preferenceCode,
    'preferenceType': preferenceType,
    'preferencePriority': preferencePriority,
  };
}

class CustomerAllergen {
  const CustomerAllergen({
    required this.allergenId,
    this.severityCode,
    this.medicallyConfirmed = false,
    this.notes,
  });

  final String allergenId;
  final String? severityCode;
  final bool medicallyConfirmed;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'allergenId': allergenId,
    if (severityCode != null) 'severityCode': severityCode,
    'medicallyConfirmed': medicallyConfirmed,
    'notes': notes,
  };
}

class NutritionTargets {
  const NutritionTargets({
    this.calories,
    this.proteinGrams,
    this.carbsGrams,
    this.fatGrams,
    this.waterMl,
  });

  factory NutritionTargets.fromJson(Map<String, dynamic> json) {
    return NutritionTargets(
      calories: _decimal(json['calories'] ?? json['caloriesKcal']),
      proteinGrams: _decimal(json['proteinGrams'] ?? json['protein']),
      carbsGrams: _decimal(json['carbsGrams'] ?? json['carbs']),
      fatGrams: _decimal(json['fatGrams'] ?? json['fat']),
      waterMl: _decimal(json['waterMl'] ?? json['water']),
    );
  }

  final double? calories;
  final double? proteinGrams;
  final double? carbsGrams;
  final double? fatGrams;
  final double? waterMl;
}

String? _string(Object? value) {
  final result = value?.toString().trim();
  return result == null || result.isEmpty ? null : result;
}

double? _decimal(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

int? _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

DateTime? _dateTime(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '');

Set<String> _stringSet(Object? value, Set<String> fallback) {
  if (value is! List) return fallback;
  return value
      .map((item) {
        if (item is Map<String, dynamic>) {
          return _string(
            item['allergenId'] ??
                item['preferenceCode'] ??
                item['id'] ??
                item['code'],
          );
        }
        return _string(item);
      })
      .whereType<String>()
      .toSet();
}
