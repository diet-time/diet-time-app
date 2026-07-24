// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'دايت تايم';

  @override
  String get tagline => 'غذاء أفضل. شعور أخف.';

  @override
  String get healthy => 'صحي';

  @override
  String get journeyStartsHere => 'رحلتك تبدأ هنا.';

  @override
  String get landingTitle => 'كل جيد، اشعر رائع';

  @override
  String get landingSubtitle =>
      'اكتشف خطط وجبات مخصصة للمذاق والصحة. ابنِ عادات تدوم، وجبة لذيذة في كل مرة.';

  @override
  String get viewPlans => 'الخطط';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get loginSubtitle => 'سجّل الدخول لمواصلة رحلتك الصحية.';

  @override
  String get emailOrMobile => 'البريد الإلكتروني / الجوال';

  @override
  String get password => 'كلمة المرور';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get orContinueWith => 'أو تابع باستخدام';

  @override
  String get continueWithApple => 'المتابعة باستخدام Apple';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get invalidEmailOrMobile =>
      'أدخل بريداً إلكترونياً أو رقم جوال صالحاً';

  @override
  String get passwordTooShort => 'يجب ألا تقل كلمة المرور عن 8 أحرف';

  @override
  String get homeScreen => 'الشاشة الرئيسية';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get onboardingHealthyMealsTitle => 'وجبات صحية،';

  @override
  String get onboardingHealthyMealsAccent => 'بكل بساطة.';

  @override
  String get onboardingHealthyMealsDescription =>
      'وجبات لذيذة ومتوازنة تُوصّل يومياً لدعم نمط حياتك الصحي.';

  @override
  String get onboardingPlansTitle => 'خطط تناسبك';

  @override
  String get onboardingPlansAccent => 'تماماً';

  @override
  String get onboardingPlansDescription =>
      'أخبرنا بأهدافك، وسنتولى الباقي بخطط مخصصة لك.';

  @override
  String get onboardingFreshTitle => 'طازج. نقي.';

  @override
  String get onboardingFreshAccent => 'دائماً.';

  @override
  String get onboardingFreshDescription =>
      'نستخدم مكونات طبيعية دون ألوان صناعية أو مواد حافظة أو إضافات غير صحية.';

  @override
  String get onboardingTrackTitle => 'تابع. تطوّر.';

  @override
  String get onboardingTrackAccent => 'عش أفضل.';

  @override
  String get onboardingTrackDescription =>
      'تساعدك المتابعة البسيطة على الاستمرار وتحقيق أهدافك الصحية.';

  @override
  String get onboardingBmiTitle => 'اعرف مؤشر كتلة جسمك،';

  @override
  String get onboardingBmiAccent => 'وابنِ خطة أفضل';

  @override
  String get onboardingBmiDescription =>
      'احسب مؤشر كتلة جسمك واحصل على خطة مصممة وفقاً لجسمك وأهدافك.';

  @override
  String get onboardingTogetherTitle => 'معاً أفضل،';

  @override
  String get onboardingTogetherAccent => 'معاً أقوى';

  @override
  String get onboardingTogetherDescription =>
      'ادعُ أصدقاءك، وشارك رحلتك، وحققوا المزيد معاً.';

  @override
  String get onboardingMenu => 'القائمة';

  @override
  String get onboardingStartPlan => 'ابدأ خطتك';

  @override
  String get chooseLanguage => 'اختر لغتك';

  @override
  String get languageSelectionSubtitle => 'اختر لغتك المفضلة لتخصيص تجربتك.';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get languageSaveError =>
      'تعذر حفظ تفضيل اللغة. يرجى المحاولة مرة أخرى.';

  @override
  String get loading => 'جارٍ التحميل';

  @override
  String pageProgress(int current, int total) {
    return 'الصفحة $current من $total';
  }

  @override
  String get browseMenuTitle => 'خيارات طازجة، صُنعت من أجلك';

  @override
  String get browseMenuSubtitle =>
      'اكتشف وجبات أعدها الطهاة بمكونات صحية وطازجة.';

  @override
  String get browseMenu => 'تصفح القائمة';

  @override
  String get popularMeals => 'الوجبات الأكثر طلباً';

  @override
  String get mealGrilledChicken => 'دجاج مشوي بالأعشاب';

  @override
  String get mealGrilledChickenDetail => 'أرز بني، خضروات وطحينة';

  @override
  String get mealSalmon => 'طبق السلمون بالحمضيات';

  @override
  String get mealSalmonDetail => 'كينوا، أفوكادو وإدامامي';

  @override
  String get mealKeto => 'لحم كيتو بالخضروات';

  @override
  String get mealKetoDetail => 'خضروات مشوية وأعشاب';

  @override
  String kcal(int value) {
    return '$value سعرة';
  }

  @override
  String get choosePlanTitle => 'اختر خطة وجباتك';

  @override
  String get choosePlanSubtitle =>
      'اختر الخطة التي تناسب أهدافك. يمكنك تغييرها في أي وقت.';

  @override
  String get weightLoss => 'خسارة الوزن';

  @override
  String get weightLossDescription => 'حصص متوازنة مصممة لتقدم ثابت ومستدام.';

  @override
  String get keto => 'كيتو';

  @override
  String get ketoDescription =>
      'وجبات منخفضة الكربوهيدرات غنية بالدهون الصحية والخضروات.';

  @override
  String get highProtein => 'عالي البروتين';

  @override
  String get highProteinDescription =>
      'وجبات غنية بالبروتين لدعم القوة والتعافي.';

  @override
  String get balancedDiet => 'نظام متوازن';

  @override
  String get balancedDietDescription =>
      'تغذية يومية شهية تجمع كل المجموعات الغذائية.';

  @override
  String dailyCalories(int value) {
    return '$value سعرة / يوم';
  }

  @override
  String weeklyPrice(int value) {
    return '$value ر.ق / أسبوع';
  }

  @override
  String get continueLabel => 'متابعة';

  @override
  String get guestMealPlansTitle => 'اختر خطة نمط حياتك';

  @override
  String get guestWeeklyMenuTitle => 'قائمة هذا الأسبوع';

  @override
  String get guestMenuLoadError => 'تعذر تحميل قائمة الوجبات.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noMealsAvailable => 'لا توجد وجبات متاحة.';

  @override
  String get tryAnotherMealFilter => 'جرّب تاريخاً أو فئة وجبات مختلفة.';

  @override
  String get caloriesLabel => 'السعرات';

  @override
  String get proteinLabel => 'البروتين';

  @override
  String get carbsLabel => 'الكربوهيدرات';

  @override
  String get fatLabel => 'الدهون';

  @override
  String gramsValue(String value) {
    return '$valueغ';
  }
}
