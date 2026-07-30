const goalLabels = <String, Map<String, String>>{
  'LOSE_WEIGHT': {'en': 'Lose Weight', 'ar': 'خسارة الوزن'},
  'MAINTAIN_WEIGHT': {'en': 'Maintain Weight', 'ar': 'الحفاظ على الوزن'},
  'GAIN_WEIGHT': {'en': 'Gain Weight', 'ar': 'زيادة الوزن'},
  'BUILD_MUSCLE': {'en': 'Build Muscle', 'ar': 'بناء العضلات'},
  'EAT_HEALTHIER': {'en': 'Eat Healthier', 'ar': 'تناول طعام صحي'},
};

const dailyRoutineLabels = <String, Map<String, String>>{
  'OFFICE_WORK': {'en': 'Office Work', 'ar': 'عمل مكتبي'},
  'WORK_FROM_HOME': {'en': 'Work From Home', 'ar': 'العمل من المنزل'},
  'STUDENT': {'en': 'Student', 'ar': 'طالب'},
  'ACTIVE_JOB': {'en': 'Active Job', 'ar': 'عمل نشط'},
  'SHIFT_WORKER': {'en': 'Shift Worker', 'ar': 'عامل بنظام الورديات'},
};

const activityLevelLabels = <String, Map<String, String>>{
  'MOSTLY_SITTING': {'en': 'Mostly Sitting', 'ar': 'الجلوس معظم الوقت'},
  'LIGHT_ACTIVITY': {'en': 'Light Activity', 'ar': 'نشاط خفيف'},
  'ACTIVE_LIFESTYLE': {'en': 'Active Lifestyle', 'ar': 'نمط حياة نشط'},
  'ATHLETE': {'en': 'Athlete', 'ar': 'رياضي'},
};

String personalizationOptionLabel(
  Map<String, Map<String, String>> labels,
  String code,
  String language,
) {
  final translations = labels[code];
  if (translations == null) return code;
  return translations[language] ?? translations['en'] ?? code;
}
