class CustomerProfile {
  const CustomerProfile({
    this.genderCode = 'FEMALE',
    this.dateOfBirth = '1998-01-01',
    this.heightCm = 170,
    this.weightKg = 70,
    this.goalCode,
    this.dailyRoutineCode,
    this.activityLevelCode,
    this.preferredLanguage = 'en',
    this.onboardingStatus = 'IN_PROGRESS',
    this.preferences = const {},
    this.allergens = const {},
    this.bmi,
    this.nutritionTargets,
  });

  factory CustomerProfile.fromJson(
    Map<String, dynamic> json, {
    CustomerProfile fallback = const CustomerProfile(),
  }) {
    return CustomerProfile(
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
      onboardingStatus:
          _string(json['onboardingStatus']) ?? fallback.onboardingStatus,
      preferences: _stringSet(
        json['preferenceIds'] ?? json['preferences'],
        fallback.preferences,
      ),
      allergens: _stringSet(
        json['allergenIds'] ?? json['allergens'],
        fallback.allergens,
      ),
      bmi: _decimal(json['bmi']) ?? fallback.bmi,
      nutritionTargets: json['nutritionTargets'] is Map<String, dynamic>
          ? NutritionTargets.fromJson(
              json['nutritionTargets'] as Map<String, dynamic>,
            )
          : fallback.nutritionTargets,
    );
  }

  final String genderCode;
  final String dateOfBirth;
  final double heightCm;
  final double weightKg;
  final String? goalCode;
  final String? dailyRoutineCode;
  final String? activityLevelCode;
  final String preferredLanguage;
  final String onboardingStatus;
  final Set<String> preferences;
  final Set<String> allergens;
  final double? bmi;
  final NutritionTargets? nutritionTargets;

  bool get isCompleted => onboardingStatus == 'COMPLETED';
  String? get primaryGoal => goalCode;
  String get gender => genderCode;
  int get age {
    final birthDate = DateTime.tryParse(dateOfBirth);
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
    'genderCode': genderCode,
    'dateOfBirth': dateOfBirth,
    'heightCm': heightCm,
    'weightKg': weightKg,
    if (goalCode != null) 'goalCode': goalCode,
    if (dailyRoutineCode != null) 'dailyRoutineCode': dailyRoutineCode,
    if (activityLevelCode != null) 'activityLevelCode': activityLevelCode,
    'preferredLanguage': preferredLanguage,
    'onboardingStatus': onboardingStatus,
    'preferenceIds': preferences.toList(growable: false),
    'allergenIds': allergens
        .where((value) => value != 'NONE')
        .toList(growable: false),
  };

  CustomerProfile copyWith({
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
    NutritionTargets? nutritionTargets,
  }) {
    return CustomerProfile(
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
      nutritionTargets: nutritionTargets ?? this.nutritionTargets,
    );
  }
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

Set<String> _stringSet(Object? value, Set<String> fallback) {
  if (value is! List) return fallback;
  return value
      .map((item) {
        if (item is Map<String, dynamic>) {
          return _string(item['id'] ?? item['code']);
        }
        return _string(item);
      })
      .whereType<String>()
      .toSet();
}
