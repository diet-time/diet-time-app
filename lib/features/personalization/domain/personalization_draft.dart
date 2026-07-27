class PersonalizationDraft {
  const PersonalizationDraft({
    this.primaryGoal,
    this.gender = 'FEMALE',
    this.age = 28,
    this.heightCm = 170,
    this.weightKg = 70,
    this.bmi = 24.2,
    this.activityLevel,
    this.dailyRoutine,
    this.foodPreferenceIds = const {},
    this.allergenIds = const {},
  });

  final String? primaryGoal;
  final String gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final double bmi;
  final String? activityLevel;
  final String? dailyRoutine;
  final Set<String> foodPreferenceIds;
  final Set<String> allergenIds;

  PersonalizationDraft copyWith({
    String? primaryGoal,
    String? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    double? bmi,
    String? activityLevel,
    String? dailyRoutine,
    Set<String>? foodPreferenceIds,
    Set<String>? allergenIds,
  }) {
    return PersonalizationDraft(
      primaryGoal: primaryGoal ?? this.primaryGoal,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bmi: bmi ?? this.bmi,
      activityLevel: activityLevel ?? this.activityLevel,
      dailyRoutine: dailyRoutine ?? this.dailyRoutine,
      foodPreferenceIds: foodPreferenceIds ?? this.foodPreferenceIds,
      allergenIds: allergenIds ?? this.allergenIds,
    );
  }
}

double calculateBmi({required double weightKg, required double heightCm}) {
  if (weightKg <= 0 || heightCm <= 0) {
    throw ArgumentError('Height and weight must be greater than zero.');
  }
  final heightMeters = heightCm / 100;
  return weightKg / (heightMeters * heightMeters);
}
