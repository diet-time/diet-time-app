// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get deliveriesTitle => 'توصيلات الغد';

  @override
  String deliveriesScheduled(int count) {
    return '$count طلبات مجدولة';
  }

  @override
  String deliveriesOrder(String reference) {
    return 'الطلب: $reference';
  }

  @override
  String get deliveriesConfirmed => 'مؤكد';

  @override
  String get deliveriesPending => 'بانتظار الاختيار';

  @override
  String get deliveriesReady => 'جاهز للتأكيد';

  @override
  String get deliveriesAutomatic => 'تم الاختيار تلقائيًا';

  @override
  String get deliveriesLocked => 'مقفل';

  @override
  String get deliveriesReviewConfirm => 'مراجعة وتأكيد';

  @override
  String get deliveriesViewConfirmed => 'عرض الوجبات المؤكدة';

  @override
  String get deliveriesViewSelected => 'عرض الوجبات المختارة';

  @override
  String get deliveriesViewMenu => 'عرض القائمة';

  @override
  String get deliveriesUnavailable => 'تعذر تحميل جميع التوصيلات';

  @override
  String get deliveriesActionNeeded => 'يتطلب إجراء';

  @override
  String get deliveriesWaiting => 'تحديث التوصيل';

  @override
  String deliveriesPackage(int meals, int snacks) {
    return '$meals وجبات + $snacks وجبات خفيفة';
  }

  @override
  String deliveriesAllConfirmed(int count) {
    return 'تم تأكيد جميع الأطباق ($count)';
  }

  @override
  String get deliveriesViewDishes => 'عرض أطباقك';

  @override
  String get deliveriesHideDishes => 'إخفاء أطباقك';

  @override
  String deliveriesProgress(int selected, int total) {
    return 'تم اختيار $selected من $total';
  }

  @override
  String get deliveriesDeadline => 'اختر قبل الساعة 9:00 مساءً';

  @override
  String get deliveriesChoose => 'اختر وجباتك';

  @override
  String get deliveriesRefresh => 'تحديث القائمة';

  @override
  String get deliveriesLoading => 'جارٍ تحميل التوصيلات…';

  @override
  String get deliveriesMeal => 'وجبة';

  @override
  String get deliveriesSnack => 'وجبة خفيفة';

  @override
  String get deliveriesViewDetails => 'عرض التفاصيل';

  @override
  String deliveriesFirstDelivery(String date) {
    return 'أول توصيل: $date';
  }

  @override
  String deliveriesStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'NO_ORDER': 'لا يوجد طلب مرتبط بحسابك.',
      'PENDING_ACTIVATION': 'تم حفظ طلبك وهو بانتظار التفعيل.',
      'NOT_STARTED':
          'تبدأ خطتك قريبًا. يفتح الاختيار في اليوم السابق لأول توصيل.',
      'NO_DELIVERY': 'لا توجد توصيلات مجدولة للغد.',
      'SERVICE_DAYS_MISSING':
          'تم حفظ طلبك ويحتاج فريقنا إلى إعداد جدول التوصيل.',
      'SERVICE_DAY_INCOMPLETE': 'تحتاج تفاصيل التوصيل إلى مراجعة فريقنا.',
      'SCHEDULE_NOT_CONFIGURED': 'تحتاج أيام توصيل طلبك إلى مراجعة فريقنا.',
      'MENU_NOT_CONFIGURED': 'تم حفظ طلبك. لم يتم إعداد أطباق الغد بعد.',
      'SELECTION_NOT_OPEN': 'يفتح الاختيار في اليوم السابق للتوصيل.',
      'FINALIZATION_PENDING':
          'انتهت مهلة الاختيار في الساعة 9:00 مساءً. يجري تأكيد وجباتك تلقائيًا.',
      'INACTIVE_ORDER': 'هذا الطلب غير نشط لاختيار الوجبات.',
      'LOCKED': 'تم قفل اختياراتك لبدء التحضير.',
      'NEEDS_REVIEW': 'يحتاج فريقنا إلى مراجعة الأطباق المناسبة لباقتك.',
      'other': 'يرجى اختيار وجبات الغد.',
    });
    return '$_temp0';
  }

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
  String get orSignInWith => 'أو سجل الدخول باستخدام';

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
  String get postLoginWelcomeLabel => 'مرحباً بك في دايت تايم';

  @override
  String get postLoginAccountReady => 'حسابك جاهز';

  @override
  String get postLoginTitleLead => 'خطتك تبدأ';

  @override
  String get postLoginTitleAccent => 'منك';

  @override
  String get postLoginSupporting =>
      'أخبرنا قليلاً عن روتينك وأهدافك وتفضيلاتك الغذائية.';

  @override
  String get postLoginSecondary =>
      'سنستخدم إجاباتك لبناء خطة عملية ومتوازنة وسهلة الاتباع.';

  @override
  String get postLoginCta => 'خصّص خطتي';

  @override
  String get postLoginMealBalanced => 'وجبات متوازنة';

  @override
  String get postLoginMealFlexible => 'خيارات مرنة';

  @override
  String get postLoginMealGoals => 'مصممة حول أهدافك';

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
  String get onboardingMenu => 'عرض القائمة';

  @override
  String get onboardingStartPlan => 'ابدأ خطتك';

  @override
  String get onboardingBrand => 'دايت تايم';

  @override
  String get onboardingWelcomeTitle => 'مرحباً بك في دايت تايم';

  @override
  String get onboardingWelcomeSubtitle =>
      'الأكل الصحي أصبح أسهل.\nلنصمم خطة وجبات تناسبك أنت.';

  @override
  String get onboardingStartJourney => 'ابدأ رحلتي';

  @override
  String get onboardingContinue => 'متابعة';

  @override
  String get onboardingPrevious => 'السابق';

  @override
  String get onboardingGoalTitle => 'ما الهدف الذي ترغب في تحقيقه؟';

  @override
  String get onboardingGoalSubtitle => 'سنخصص وجباتك بما يناسب هدفك.';

  @override
  String get onboardingLoseWeight => 'خسارة الوزن';

  @override
  String get onboardingLoseWeightDescription =>
      'اخسر الدهون مع وجبات مشبعة ولذيذة.';

  @override
  String get onboardingBuildMuscle => 'بناء العضلات';

  @override
  String get onboardingBuildMuscleDescription =>
      'وجبات غنية بالبروتين لدعم القوة.';

  @override
  String get onboardingStayHealthy => 'الحفاظ على الصحة';

  @override
  String get onboardingStayHealthyDescription =>
      'تغذية متوازنة لصحة يومية أفضل.';

  @override
  String get onboardingImproveFitness => 'تحسين اللياقة';

  @override
  String get onboardingImproveFitnessDescription =>
      'غذاء يمنح جسمك طاقة لنمط حياة نشط.';

  @override
  String get onboardingProfileTitle => 'لنتعرف عليك أكثر';

  @override
  String get onboardingProfileSubtitle =>
      'بعض التفاصيل تساعدنا في تخصيص كل وجبة لك.';

  @override
  String get onboardingGender => 'الجنس';

  @override
  String get onboardingAge => 'العمر';

  @override
  String get onboardingHeight => 'الطول';

  @override
  String get onboardingWeight => 'الوزن';

  @override
  String get onboardingMale => 'ذكر';

  @override
  String get onboardingFemale => 'أنثى';

  @override
  String get onboardingPreferNotToSay => 'أفضل عدم الإجابة';

  @override
  String get onboardingLifestyleTitle => 'أخبرنا عن روتينك اليومي';

  @override
  String get onboardingLifestyleSubtitle => 'اختر الوصف الأقرب ليومك.';

  @override
  String get onboardingOfficeWork => 'عمل مكتبي';

  @override
  String get onboardingWorkFromHome => 'العمل من المنزل';

  @override
  String get onboardingStudent => 'طالب';

  @override
  String get onboardingActiveJob => 'عمل يتطلب الحركة';

  @override
  String get onboardingShiftWorker => 'عمل بنظام المناوبات';

  @override
  String get onboardingActivityTitle => 'ما مستوى نشاطك؟';

  @override
  String get onboardingActivitySubtitle =>
      'سنوازن وجباتك وفق احتياجاتك من الطاقة.';

  @override
  String get onboardingMostlySitting => 'الجلوس غالباً';

  @override
  String get onboardingLightActivity => 'نشاط خفيف';

  @override
  String get onboardingActiveLifestyle => 'نمط حياة نشط';

  @override
  String get onboardingAthlete => 'رياضي';

  @override
  String get onboardingPreferencesTitle => 'ما الأطعمة التي تستمتع بها؟';

  @override
  String get onboardingPreferencesSubtitle => 'اختر كل ما تفضله.';

  @override
  String get onboardingHighProtein => 'عالي البروتين';

  @override
  String get onboardingLowCarb => 'قليل الكربوهيدرات';

  @override
  String get onboardingVegetarian => 'نباتي';

  @override
  String get onboardingVegan => 'نباتي صرف';

  @override
  String get onboardingSeafood => 'مأكولات بحرية';

  @override
  String get onboardingChicken => 'دجاج';

  @override
  String get onboardingBeef => 'لحم بقري';

  @override
  String get onboardingArabicCuisine => 'مطبخ عربي';

  @override
  String get onboardingInternational => 'مطبخ عالمي';

  @override
  String get onboardingMediterranean => 'مطبخ متوسطي';

  @override
  String get onboardingHealthySnacks => 'وجبات خفيفة صحية';

  @override
  String get onboardingBreakfastLover => 'محب للإفطار';

  @override
  String get onboardingAllergiesTitle => 'هل لديك حساسية من أي طعام؟';

  @override
  String get onboardingAllergiesSubtitle =>
      'اختر كل ما يجب أن نأخذه في الاعتبار.';

  @override
  String get onboardingMilk => 'الحليب';

  @override
  String get onboardingEgg => 'البيض';

  @override
  String get onboardingFish => 'السمك';

  @override
  String get onboardingShellfish => 'المحار';

  @override
  String get onboardingTreeNuts => 'المكسرات';

  @override
  String get onboardingPeanuts => 'الفول السوداني';

  @override
  String get onboardingSoy => 'الصويا';

  @override
  String get onboardingSesame => 'السمسم';

  @override
  String get onboardingGluten => 'الغلوتين';

  @override
  String get onboardingNoAllergies => 'لا توجد حساسية';

  @override
  String get onboardingBuildingTitle => 'جارٍ إنشاء خطة وجباتك المخصصة';

  @override
  String get onboardingBuildingSubtitle =>
      'نجهز وجبات تناسب أهدافك ونمط حياتك وتفضيلاتك.';

  @override
  String get onboardingReadyAction => 'عرض خياراتي';

  @override
  String get personalizationIntroTitle => 'لنصمم خطتك';

  @override
  String get personalizationIntroSubtitle =>
      'أجب عن بعض الأسئلة البسيطة لنقترح وجبات تناسب أهدافك وروتينك وتفضيلاتك.';

  @override
  String get personalizationBegin => 'ابدأ';

  @override
  String get personalizationNotNow => 'ليس الآن';

  @override
  String get personalizationSelectOption => 'اختر أحد الخيارات للمتابعة.';

  @override
  String get onboardingMaintainWeight => 'الحفاظ على الوزن';

  @override
  String get onboardingMaintainWeightDescription =>
      'وجبات متوازنة تدعم روتينك الحالي.';

  @override
  String get onboardingGainWeight => 'زيادة الوزن';

  @override
  String get onboardingGainWeightDescription =>
      'وجبات مغذية توفر الطاقة التي تحتاجها أهدافك.';

  @override
  String get onboardingEatHealthier => 'تناول طعام صحي';

  @override
  String get onboardingEatHealthierDescription =>
      'اجعل الخيارات الصحية اليومية أسهل.';

  @override
  String get bmiSummaryTitle => 'لمحة عن عافيتك';

  @override
  String get bmiCalculatedLabel => 'مؤشر كتلة الجسم المحسوب';

  @override
  String get bmiDisclaimer =>
      'مؤشر كتلة الجسم مقياس عام ولا يأخذ في الاعتبار الكتلة العضلية أو تكوين الجسم أو العمر أو الظروف الصحية الفردية.';

  @override
  String get bmiYouthNote =>
      'يحتاج الأطفال والمراهقون إلى تقييم خاص بالعمر والجنس.';

  @override
  String get bmiBelowRange => 'أقل من النطاق القياسي';

  @override
  String get bmiWithinRange => 'ضمن النطاق القياسي';

  @override
  String get bmiAboveRange => 'أعلى من النطاق القياسي';

  @override
  String get bmiWellAboveRange => 'أعلى بكثير من النطاق القياسي';

  @override
  String get allergySafetyNote =>
      'سنستخدم هذه المعلومات لإبراز الوجبات التي قد لا تناسبك. راجع دائماً تفاصيل المكونات ومسببات الحساسية قبل الطلب.';

  @override
  String get recommendationTitle => 'خطة تناسب روتينك';

  @override
  String get recommendationReasonGoal => 'تتناسب مع هدفك الأساسي';

  @override
  String get recommendationReasonActivity => 'تناسب مستوى نشاطك';

  @override
  String get recommendationReasonPreferences =>
      'تتضمن أنماط الوجبات التي تفضلها';

  @override
  String get recommendationReasonAllergens =>
      'تأخذ مسببات الحساسية المسجلة في الاعتبار';

  @override
  String get viewRecommendedPlan => 'عرض الخطة المقترحة';

  @override
  String get compareAllPlans => 'مقارنة جميع الخطط';

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
  String dailyPlanPrice(String currency, String amount) {
    return '$currency $amount / يوم';
  }

  @override
  String get dailyPriceLabel => 'السعر اليومي';

  @override
  String get dailyPriceUnavailable => 'السعر اليومي غير متاح';

  @override
  String weeklyPrice(int value) {
    return '$value ر.ق / أسبوع';
  }

  @override
  String get continueLabel => 'متابعة';

  @override
  String get otpPhoneTitle => 'لنبدأ';

  @override
  String get otpPhoneSubtitle => 'أدخل رقم هاتفك للمتابعة.';

  @override
  String get otpPhoneHelper => 'سنرسل إليك رمز تحقق مكوّناً من 6 أرقام.';

  @override
  String get otpMobileNumber => 'رقم الجوال';

  @override
  String get otpInvalidPhone => 'أدخل رقم جوال صالحاً.';

  @override
  String get otpRequestFailed =>
      'تعذّر إرسال رمز التحقق. يرجى المحاولة مرة أخرى.';

  @override
  String get otpCodeTitle => 'أدخل الرمز';

  @override
  String get otpCodeSubtitle => 'تم إرسال رمز تحقق مكوّن من 6 أرقام إلى:';

  @override
  String get otpCodeSentTo => 'تم إرسال الرمز إلى';

  @override
  String get otpCodeEntryHelper =>
      'أدخل الرمز المكتشف تلقائياً أو اكتبه يدوياً';

  @override
  String get otpEditPhone => 'تعديل';

  @override
  String get otpDidntGetCode => 'لم يصلك الرمز؟';

  @override
  String get otpVerifyCode => 'تحقق من الرمز';

  @override
  String get otpResendCode => 'إعادة إرسال الرمز';

  @override
  String otpResendCountdown(String time) {
    return 'إعادة إرسال الرمز خلال $time';
  }

  @override
  String get otpSendViaSms => 'الإرسال عبر رسالة نصية';

  @override
  String get otpSendViaWhatsapp => 'الإرسال عبر واتساب';

  @override
  String get otpResendViaWhatsapp => 'إعادة الإرسال عبر واتساب';

  @override
  String otpDevelopmentCode(String code) {
    return 'رمز التطوير: $code';
  }

  @override
  String get otpIncorrectCode => 'رمز التحقق غير صحيح. يرجى المحاولة مرة أخرى.';

  @override
  String get otpExpiredCode => 'انتهت صلاحية رمز التحقق. اطلب رمزاً جديداً.';

  @override
  String get otpTooManyAttempts => 'عدد محاولات كبير. يرجى المحاولة لاحقاً.';

  @override
  String get otpResendUnavailable =>
      'إعادة الإرسال غير متاحة مؤقتاً. يرجى المحاولة مرة أخرى.';

  @override
  String get otpResendConfirmation => 'تم إرسال رمز تحقق جديد.';

  @override
  String get otpWhatsappTestGenerated =>
      'تم إنشاء رمز تجريبي للتحقق عبر واتساب.';

  @override
  String get mealPlanHeaderTitle => 'خطة الوجبات';

  @override
  String get mealPlanHeaderSubtitle => 'اختر خطة تناسب نمط حياتك وأهدافك.';

  @override
  String get planSwitchLoadingTitle => 'نُحضّر خطتك الجديدة';

  @override
  String get planSwitchLoadingSubtitle => 'نرتّب لك أفضل الوجبات...';

  @override
  String get mealContentLoadingTitle => 'نحضّر لك شيئاً صحياً!';

  @override
  String get mealContentLoadingSubtitle => 'جارٍ تحميل وجبات اليوم...';

  @override
  String get guestMealPlansTitle => 'اختر خطتك';

  @override
  String selectMealPlanSemantics(String planName) {
    return 'اختر خطة وجبات $planName';
  }

  @override
  String get guestWeeklyMenuTitle => 'قائمة هذا الأسبوع';

  @override
  String get guestMenuLoadError => 'تعذر تحميل قائمة الوجبات.';

  @override
  String get guestPlanLoadError => 'تعذر تحميل خطة الوجبات هذه.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noMealsAvailable => 'لا توجد وجبات متاحة لهذا الاختيار.';

  @override
  String get noMealsAvailableForPlan => 'لا توجد وجبات متاحة لهذه الخطة.';

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
  String get mealIngredientsTitle => 'المكونات';

  @override
  String get mealAllergensTitle => 'مسببات الحساسية';

  @override
  String get showAllIngredients => 'عرض الكل';

  @override
  String get noIngredientsAvailable => 'لا تتوفر معلومات عن المكونات.';

  @override
  String get noAllergensListed => 'لا توجد مسببات حساسية مسجلة.';

  @override
  String get readMore => 'قراءة المزيد';

  @override
  String get showLess => 'عرض أقل';

  @override
  String allergenContains(String name) {
    return 'يحتوي على $name';
  }

  @override
  String allergenMayContain(String name) {
    return 'قد يحتوي على $name';
  }

  @override
  String allergenTraces(String name) {
    return 'آثار من $name';
  }

  @override
  String nutritionItemSemantics(String label, String value) {
    return '$label $value';
  }

  @override
  String get mealMicronutrientsTitle => 'العناصر الغذائية الدقيقة';

  @override
  String get fiberLabel => 'الألياف';

  @override
  String get sodiumLabel => 'الصوديوم';

  @override
  String gramsValue(String value) {
    return '$valueغ';
  }

  @override
  String get otpInvalidCode => 'رمز التحقق غير صحيح. يرجى المحاولة مرة أخرى.';

  @override
  String get otpAccountConflict => 'تعذر إنشاء هذا الحساب أو الوصول إليه.';

  @override
  String get otpPhoneLoginUnavailable =>
      'تسجيل الدخول بالهاتف غير متاح حالياً.';

  @override
  String get otpConnectionError =>
      'تعذر الاتصال. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get otpServerError => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get otpResendTestUnavailable =>
      'إعادة الإرسال غير متاحة في وضع الاختبار';

  @override
  String get exploreMenu => 'استكشف القائمة';

  @override
  String get backToDashboard => 'العودة إلى لوحة التحكم';

  @override
  String get dailyNutritionTotal => 'إجمالي التغذية اليومي';

  @override
  String get nutritionUnavailable => 'المعلومات الغذائية غير متاحة';

  @override
  String get nutritionTotalsIncomplete =>
      'لا يمكن حساب إجمالي القيم الغذائية غير المتاحة.';

  @override
  String get sugarLabel => 'السكر';

  @override
  String get saturatedFatLabel => 'الدهون المشبعة';

  @override
  String get transFatLabel => 'الدهون المتحولة';

  @override
  String get cholesterolLabel => 'الكوليسترول';

  @override
  String nutritionServing(String portion) {
    return 'لكل حصة: $portion';
  }

  @override
  String get customerUnableToSignIn => 'تعذر تسجيل الدخول';

  @override
  String get customerWeCouldNotLoadTakeawayBranchesPleaseTryAgain =>
      'تعذر تحميل فروع الاستلام. يرجى المحاولة مرة أخرى.';

  @override
  String get customerChooseAFutureDeliveryStartDateTodayAndFriday =>
      'اختر تاريخ بدء لاحقاً؛ اليوم والجمعة غير متاحين.';

  @override
  String get customerTheSelectedMealConfigurationIsNoLongerAvailable =>
      'خيارات الوجبات المحددة لم تعد متاحة.';

  @override
  String get customerTheSelectedPlanDurationIsNoLongerAvailable =>
      'مدة الباقة المحددة لم تعد متاحة.';

  @override
  String get customerWeCouldNotVerifyTheSelectedPlanPleaseTry =>
      'تعذر التحقق من الباقة المحددة. يرجى المحاولة مرة أخرى.';

  @override
  String get customerDeliveryTimesCouldNotBeLoadedPleaseTryAgain =>
      'تعذر تحميل أوقات التوصيل. يرجى المحاولة مرة أخرى.';

  @override
  String get customerWeCouldNotLoadYourCustomerProfilePleaseSign =>
      'تعذر تحميل ملفك. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get customerSavedAddressesCouldNotBeLoadedPleaseTryAgain =>
      'تعذر تحميل العناوين المحفوظة. يرجى المحاولة مرة أخرى.';

  @override
  String get customerYourCustomerProfileIsUnavailablePleaseSignInAgain =>
      'ملفك غير متاح. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get customerSelectAnActiveDeliveryTimeSlotBeforeSaving =>
      'اختر وقت توصيل متاحاً قبل الحفظ.';

  @override
  String get customerYourAddressCouldNotBeSavedPleaseTryAgain =>
      'تعذر حفظ عنوانك. يرجى المحاولة مرة أخرى.';

  @override
  String get customerWeCouldntPlaceYourOrderPleaseTryAgain =>
      'تعذر إرسال طلبك. يرجى المحاولة مرة أخرى.';

  @override
  String get customerPleaseCheckYourConnectionAndTryAgain =>
      'يرجى التحقق من الاتصال والمحاولة مرة أخرى.';

  @override
  String get customerThePlanPriceHasChangedPleaseReviewTheUpdated =>
      'تغير سعر الباقة. يرجى مراجعة الإجمالي المحدث قبل إرسال الطلب.';

  @override
  String get customerThisOrderIsAlreadyBeingProcessedPleaseTryAgain =>
      'هذا الطلب قيد المعالجة بالفعل. يرجى المحاولة مرة أخرى.';

  @override
  String get customerTheSelectedPlanIsNoLongerAvailablePleaseChoose =>
      'الباقة المحددة لم تعد متاحة. يرجى اختيار باقة أخرى.';

  @override
  String get customerTheSelectedDeliveryAddressIsNoLongerAvailable =>
      'عنوان التوصيل المحدد لم يعد متاحاً.';

  @override
  String get customerTheSelectedDeliveryTimeIsNoLongerAvailable =>
      'وقت التوصيل المحدد لم يعد متاحاً.';

  @override
  String get customerASelectedCheckoutOptionIsNoLongerAvailablePlease =>
      'أحد الخيارات المحددة لم يعد متاحاً. يرجى مراجعة طلبك.';

  @override
  String get customerPleaseReviewYourSelectedMeals =>
      'يرجى مراجعة الوجبات المحددة.';

  @override
  String get customerPleaseReviewYourSelectedServiceDays =>
      'يرجى مراجعة أيام الخدمة المحددة.';

  @override
  String get customerPleaseSelectAnotherPlanStartDate =>
      'يرجى اختيار تاريخ بدء آخر للباقة.';

  @override
  String get customerCouponCodesAreNotSupportedYetRemoveTheCoupon =>
      'رموز الخصم غير مدعومة حالياً. احذف الرمز وحاول مرة أخرى.';

  @override
  String get customerYourOrderResponseCouldNotBeConfirmedPleaseCheck =>
      'تعذر التحقق من نتيجة الطلب. يرجى مراجعة طلباتك قبل المحاولة مرة أخرى.';

  @override
  String get customerSomeAddressInformationWasNotAcceptedPleaseReviewIt =>
      'لم يتم قبول بعض بيانات العنوان. يرجى مراجعتها.';

  @override
  String get customerYourSessionExpiredPleaseSignInAgain =>
      'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get customerWeCouldNotLoadYourProfile => 'تعذر تحميل ملفك.';

  @override
  String get customerTRYAGAIN => 'حاول مرة أخرى';

  @override
  String get customerBrowsePlans => 'تصفح الباقات';

  @override
  String get customerDohaQatar => 'الدوحة، قطر';

  @override
  String get customerCustomerAddress => 'عنوان العميل';

  @override
  String get customerDeliveryAddress => 'عنوان التوصيل';

  @override
  String get customerChooseDeliveryAddress => 'اختر عنوان التوصيل';

  @override
  String get customerSelectWhereYouWouldLikeYourMealsDelivered =>
      'حدد المكان الذي ترغب في توصيل وجباتك إليه.';

  @override
  String get customerLoadingSavedAddresses => 'جارٍ تحميل العناوين المحفوظة...';

  @override
  String get customerAddAnotherAddress => 'إضافة عنوان آخر';

  @override
  String get customerUseThisAddress => 'استخدام هذا العنوان';

  @override
  String get customerAddressDetails => 'تفاصيل العنوان';

  @override
  String get customerSavedAddresses => 'العناوين المحفوظة';

  @override
  String get customerSAVEASundefined => 'حفظ باسم *';

  @override
  String get customerBuildingNoundefined => 'رقم المبنى *';

  @override
  String get customerStreetundefined => 'الشارع *';

  @override
  String get customerUnitNumber => 'رقم الوحدة';

  @override
  String get customerZoneNoundefined => 'رقم المنطقة *';

  @override
  String get customerAreaundefined => 'المنطقة *';

  @override
  String get customerDirectionsToReach => 'إرشادات الوصول';

  @override
  String get customerCallMeWhenYouArrive => 'اتصل بي عند الوصول';

  @override
  String get customerSavingAddress => 'جارٍ حفظ العنوان...';

  @override
  String get customerSaveAddress => 'حفظ العنوان';

  @override
  String get customerPinnedLocationQatar => 'الموقع المحدد، قطر';

  @override
  String get customerSelectAnAddressTypeBeforeSaving =>
      'اختر نوع العنوان قبل الحفظ.';

  @override
  String get customerCompleteAllRequiredAddressFields =>
      'أكمل جميع حقول العنوان المطلوبة.';

  @override
  String get customerSelectADeliveryTimeSlotBeforeSaving =>
      'اختر وقت التوصيل قبل الحفظ.';

  @override
  String get customerSelectADeliveryAddressOrAddANewOne =>
      'اختر عنوان توصيل أو أضف عنواناً جديداً.';

  @override
  String get customerSelectADeliveryTimeSlot => 'اختر وقت التوصيل.';

  @override
  String get customerEnterAZoneOrAreaToSearch => 'أدخل منطقة للبحث.';

  @override
  String get customerNoMatchingLocationWasFound =>
      'لم يتم العثور على موقع مطابق.';

  @override
  String get customerLocationSearchIsUnavailableTryAgainOrMoveThe =>
      'البحث عن الموقع غير متاح. حاول مرة أخرى أو حرك العلامة.';

  @override
  String get customerTurnOnLocationServicesToContinue =>
      'فعّل خدمات الموقع للمتابعة.';

  @override
  String get customerLocationAccessIsBlockedEnableItInDeviceSettings =>
      'الوصول إلى الموقع محظور. فعّله من إعدادات الجهاز.';

  @override
  String get customerLocationPermissionIsNeededToFindYourCurrentAddress =>
      'يلزم إذن الموقع لتحديد عنوانك الحالي.';

  @override
  String get customerFindingYourCurrentLocation => 'جارٍ تحديد موقعك الحالي...';

  @override
  String get customerCouldNotDetermineYourLocationTryAgainOrMove =>
      'تعذر تحديد موقعك. حاول مرة أخرى أو حرك العلامة.';

  @override
  String get customerPinnedLocation => 'الموقع المحدد';

  @override
  String get customerSearchAZone => 'ابحث عن منطقة';

  @override
  String get customerCurrentAddress => 'العنوان الحالي';

  @override
  String get customerGoogleMapsIsNotConfiguredForThisIOSBuild =>
      'خرائط Google غير مهيأة في هذا الإصدار لنظام iOS.';

  @override
  String get customerAddTheIOSAPIKeyThenCleanAndRebuild =>
      'أضف مفتاح iOS ثم أعد بناء التطبيق.';

  @override
  String get customerDELIVERYTIMEundefined => 'وقت التوصيل *';

  @override
  String get customerLoadingDeliveryTimes => 'جارٍ تحميل أوقات التوصيل...';

  @override
  String get customerNoDeliveryTimeSlotsAreCurrentlyAvailable =>
      'لا توجد أوقات توصيل متاحة حالياً.';

  @override
  String get customerDEFAULT => 'الافتراضي';

  @override
  String get customerNoSavedAddressesYet => 'لا توجد عناوين محفوظة بعد';

  @override
  String get customerAddAnAddressForYourMealDeliveries =>
      'أضف عنواناً لتوصيل وجباتك.';

  @override
  String get customerAddAddress => 'إضافة عنوان';

  @override
  String get customerOrderSubmitted => 'تم إرسال الطلب';

  @override
  String get customerOrderConfirmed => 'تم تأكيد الطلب!';

  @override
  String get customerYourOrderHasBeenReceivedAndIsAwaitingConfirmation =>
      'استلمنا طلبك وهو بانتظار تأكيد دايت تايم. سنخطرك بعد مراجعته.';

  @override
  String get customerGOTODASHBOARD => 'الانتقال إلى لوحة التحكم';

  @override
  String get customerORDERNUMBER => 'رقم الطلب';

  @override
  String get customerPLAN => 'الباقة';

  @override
  String get customerPAYMENT => 'الدفع';

  @override
  String get customerPACKAGE => 'الاشتراك';

  @override
  String get customerFULFILLMENT => 'طريقة الاستلام';

  @override
  String get customerTakeaway => 'استلام من الفرع';

  @override
  String get customerPLANPERIOD => 'فترة الباقة';

  @override
  String get customerFIRSTCOLLECTION => 'أول استلام';

  @override
  String get customerFIRSTDELIVERY => 'أول توصيل';

  @override
  String get customerDELIVERYTO => 'التوصيل إلى';

  @override
  String get customerTOTAL => 'الإجمالي';

  @override
  String get customerSTATUS => 'الحالة';

  @override
  String get customerOrderConfirmationIsUnavailable => 'تأكيد الطلب غير متاح.';

  @override
  String get customerVerifyingYourSelectedPlan =>
      'جارٍ التحقق من الباقة المحددة...';

  @override
  String get customerYourPlanDetails => 'تفاصيل باقتك';

  @override
  String get customerThisPackageIsAvailableForTakeawayOnly =>
      'هذه الباقة متاحة للاستلام من الفرع فقط.';

  @override
  String get customerHomeDelivery => 'توصيل إلى المنزل';

  @override
  String get customerCOLLECTIONBRANCH => 'فرع الاستلام';

  @override
  String get customerNoTakeawayBranchesAreCurrentlyAvailable =>
      'لا توجد فروع استلام متاحة حالياً.';

  @override
  String get customerDELIVERYADDRESSTIMESLOT => 'عنوان ووقت التوصيل';

  @override
  String get customerStartDate => 'تاريخ البدء';

  @override
  String get customerSelectYourServiceDates => 'اختر تواريخ الخدمة';

  @override
  String get customerOrderTotal => 'إجمالي الطلب';

  @override
  String get customerPLACEORDER => 'إرسال الطلب';

  @override
  String get customerPLACINGORDER => 'جارٍ إرسال الطلب...';

  @override
  String get customerPREPARINGORDER => 'جارٍ تجهيز الطلب...';

  @override
  String get customerNoDeliveryAddressSelected => 'لم يتم اختيار عنوان توصيل';

  @override
  String get customerAddDeliveryAddress => 'إضافة عنوان توصيل';

  @override
  String get customerChange => 'تغيير';

  @override
  String get customerSelectADeliveryTimeSlot2 => 'اختر وقت التوصيل';

  @override
  String get customerChooseAMealPlanBeforeReviewingYourSummary =>
      'اختر باقة وجبات قبل مراجعة الملخص.';

  @override
  String get customerBrowsePlans2 => 'تصفح الباقات';

  @override
  String get customerWeCouldNotLoadYourDashboardPleaseTryAgain =>
      'تعذر تحميل لوحة التحكم. يرجى المحاولة مرة أخرى.';

  @override
  String get customerWeCouldNotLoadYourOrdersPleaseTryAgain =>
      'تعذر تحميل طلباتك. يرجى المحاولة مرة أخرى.';

  @override
  String get customerHOME => 'الرئيسية';

  @override
  String get customerORDERS => 'الطلبات';

  @override
  String get customerCALENDAR => 'التقويم';

  @override
  String get customerPROFILE => 'الملف الشخصي';

  @override
  String get customerProfileUpdatedSuccessfully => 'تم تحديث الملف بنجاح';

  @override
  String get customerUnableToLoadYourProfile => 'تعذر تحميل ملفك.';

  @override
  String get customerQuestionnaireUpdatedSuccessfully =>
      'تم تحديث الاستبيان بنجاح';

  @override
  String get customerLogout => 'تسجيل الخروج';

  @override
  String get customerAreYouSureYouWantToLogout => 'هل تريد تسجيل الخروج؟';

  @override
  String get customerCancel => 'إلغاء';

  @override
  String get customerYourSessionHasExpiredPleaseSignInAgain =>
      'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get customerSIGNIN => 'تسجيل الدخول';

  @override
  String get customerYourCustomerProfileCouldNotBeFound =>
      'تعذر العثور على ملفك.';

  @override
  String get customerYOURACTIVEPLAN => 'باقتك الحالية';

  @override
  String get customerMYACTIVEPLANS => 'باقاتي الحالية';

  @override
  String get customerORDERANOTHERPLAN => 'طلب باقة أخرى';

  @override
  String get customerQUICKACTIONS => 'إجراءات سريعة';

  @override
  String get customerPREVIOUSORDERS => 'الطلبات السابقة';

  @override
  String get customerMYORDERS => 'طلباتي';

  @override
  String get customerVIEWALL => 'عرض الكل';

  @override
  String get customerNOACTIVEPLAN => 'لا توجد باقة نشطة';

  @override
  String get customerYouDontHaveAnActiveMealPlanRightNow =>
      'ليس لديك باقة وجبات نشطة حالياً.';

  @override
  String get customerCHOOSEAPLAN => 'اختر باقة';

  @override
  String get customerScheduleReady => 'الجدول جاهز';

  @override
  String get customerCollectFromDietTime => 'استلم من دايت تايم';

  @override
  String get customerVIEWPLAN => 'عرض الباقة';

  @override
  String get customerDETAILS => 'التفاصيل';

  @override
  String get customerMyPlan => 'باقتي';

  @override
  String get customerOrders => 'الطلبات';

  @override
  String get customerNewPlan => 'باقة جديدة';

  @override
  String get customerSupport => 'الدعم';

  @override
  String get customerSupportWillBeAvailableSoon => 'سيتوفر الدعم قريباً.';

  @override
  String get customerDeliveryCalendar => 'تقويم التوصيل';

  @override
  String get customerNoActiveDeliveryCalendar => 'لا يوجد جدول توصيل نشط';

  @override
  String get customerYourDeliveryDatesWillAppearHereWhenAMeal =>
      'ستظهر تواريخ التوصيل هنا عند تفعيل باقة الوجبات.';

  @override
  String get customerALL => 'الكل';

  @override
  String get customerMyOrders => 'طلباتي';

  @override
  String get customerAllYourMealOrdersInOnePlace =>
      'جميع طلبات وجباتك في مكان واحد';

  @override
  String get customerAllOrders => 'جميع الطلبات';

  @override
  String get customerPendingConfirmation => 'بانتظار التأكيد';

  @override
  String get customerOnHold => 'معلق';

  @override
  String get customerRejected => 'مرفوض';

  @override
  String get customerPending => 'قيد الانتظار';

  @override
  String get customerCancelled => 'ملغى';

  @override
  String get customerNoOrdersFoundForThisStatus => 'لا توجد طلبات بهذه الحالة.';

  @override
  String get customerOrderPlaced => 'تم إرسال الطلب';

  @override
  String get customerViewDetailsundefined => 'عرض التفاصيل ←';

  @override
  String get customerGoodMorning => 'صباح الخير';

  @override
  String get customerGoodAfternoon => 'مساء الخير';

  @override
  String get customerGoodEvening => 'مساء الخير';

  @override
  String get customerYourMealPlanIsActive => 'باقة وجباتك نشطة';

  @override
  String get customerReadyWhenYouAre => 'نحن مستعدون عندما تكون جاهزاً';

  @override
  String get customerYourMealPlansAtAGlance => 'نظرة على باقات وجباتك';

  @override
  String get customerMon => 'الاثنين';

  @override
  String get customerTue => 'الثلاثاء';

  @override
  String get customerWed => 'الأربعاء';

  @override
  String get customerThu => 'الخميس';

  @override
  String get customerFri => 'الجمعة';

  @override
  String get customerSat => 'السبت';

  @override
  String get customerSun => 'الأحد';

  @override
  String get customerWeCouldntLoadAllYourDeliveryOrders =>
      'تعذر تحميل جميع طلبات التوصيل.';

  @override
  String get customerUnableToUpdateProfilePleaseTryAgain =>
      'تعذر تحديث الملف. يرجى المحاولة مرة أخرى.';

  @override
  String get customerProfile => 'الملف الشخصي';

  @override
  String get customerCustomerProfile => 'ملف العميل';

  @override
  String get customerViewOrUpdateYourPersonalInformation =>
      'عرض بياناتك الشخصية أو تحديثها';

  @override
  String get customerQuestionnaire => 'الاستبيان';

  @override
  String get customerCaptureYourGoalsAndFoodPreferences =>
      'أدخل أهدافك وتفضيلاتك الغذائية';

  @override
  String get customerAddOrEditYourDeliveryAddress =>
      'أضف عنوان التوصيل أو عدله';

  @override
  String get customerPleaseSignInAgainToViewYourMeals =>
      'يرجى تسجيل الدخول مرة أخرى لعرض وجباتك.';

  @override
  String get customerWeCouldntLoadYourMealsForThisDayPlease =>
      'تعذر تحميل وجبات هذا اليوم. يرجى المحاولة مرة أخرى.';

  @override
  String get customerTheMenuForThisDateCouldNotBeConfirmed =>
      'تعذر التحقق من قائمة هذا التاريخ.';

  @override
  String get customerWeveSelectedYourMealsForThisDayYouCan =>
      'اخترنا وجباتك لهذا اليوم. يمكنك تغييرها قبل موعد إغلاق الاختيار.';

  @override
  String get customerTheSelectionDeadlineHasPassedYourMealsAreLocked =>
      'انتهى وقت الاختيار. وجباتك مقفلة لتجهيزها في المطبخ.';

  @override
  String get customerYourMealsAreReadonlyForThisDay =>
      'وجبات هذا اليوم متاحة للعرض فقط.';

  @override
  String get customerYourMealsForThisDay => 'وجباتك لهذا اليوم';

  @override
  String get customerYourMealsAreBeingReviewedByOurTeamPlease =>
      'فريقنا يراجع وجباتك. يرجى العودة قريباً.';

  @override
  String get customerSelectedForYou => 'تم اختيارها لك';

  @override
  String get customerYourChoice => 'اختيارك';

  @override
  String get customerYourMealChangeHasBeenSaved => 'تم حفظ تغيير الوجبة.';

  @override
  String get customerTheSelectionDeadlineHasPassedCloseThisSheetTo =>
      'انتهى وقت الاختيار. أغلق النافذة لعرض وجباتك المحفوظة.';

  @override
  String get customerYourChoicesOrSelectionDeadlineHaveChangedCloseThis =>
      'تغيرت خياراتك أو موعد الإغلاق. أغلق النافذة وحدّث اليوم.';

  @override
  String get customerThatMealIsNoLongerAvailablePleaseChooseAnother =>
      'هذه الوجبة لم تعد متاحة. اختر بديلاً أو حدّث اليوم.';

  @override
  String get customerWeCouldntSaveThisChangeYourSavedMealsAre =>
      'تعذر حفظ التغيير. وجباتك المحفوظة لم تتغير. يرجى المحاولة مرة أخرى.';

  @override
  String get customerChangeMeal => 'تغيير الوجبة';

  @override
  String get customerClose => 'إغلاق';

  @override
  String get customerThereAreNoOtherEligibleDishesForThisSelection =>
      'لا توجد أطباق بديلة متاحة لهذا الاختيار في هذا اليوم.';

  @override
  String get customerSelectedReplacement => 'البديل المحدد';

  @override
  String get customerAvailableForThisDay => 'متاح لهذا اليوم';

  @override
  String get customerSavingChanges => 'جارٍ حفظ التغييرات…';

  @override
  String get customerSaveChanges => 'حفظ التغييرات';

  @override
  String get customerChangeMeal2 => 'تغيير الوجبة';

  @override
  String get customerLoadingMealsForTheSelectedDay =>
      'جارٍ تحميل وجبات اليوم المحدد';

  @override
  String get customerAutomaticallySelected => 'تم الاختيار تلقائياً';

  @override
  String get customerCustomized => 'مخصص';

  @override
  String get customerDelivered => 'تم التوصيل';

  @override
  String get customerOurTeamIsReviewingThisDay => 'فريقنا يراجع هذا اليوم';

  @override
  String get customerEditProfile => 'تعديل الملف';

  @override
  String get customerFullNameIsRequired => 'الاسم الكامل مطلوب.';

  @override
  String get customerFullNameMustBeAtLeast2Characters =>
      'يجب أن يتكون الاسم الكامل من حرفين على الأقل.';

  @override
  String get customerFullNameMustBe150CharactersOrFewer =>
      'يجب ألا يتجاوز الاسم الكامل 150 حرفاً.';

  @override
  String get customerFullName => 'الاسم الكامل';

  @override
  String get customerMobileNumber => 'رقم الهاتف';

  @override
  String get customerContactSupportOrUseChangeMobileNumberToUpdate =>
      'تواصل مع الدعم أو استخدم تغيير رقم الهاتف لتحديث رقم الدخول.';

  @override
  String get customerDateOfBirth => 'تاريخ الميلاد';

  @override
  String get customerSaving => 'جارٍ الحفظ...';

  @override
  String get customerDiscardChanges => 'تجاهل التغييرات؟';

  @override
  String get customerYouHaveUnsavedChangesAreYouSureYouWant =>
      'لديك تغييرات غير محفوظة. هل تريد المغادرة؟';

  @override
  String get customerKeepEditing => 'متابعة التعديل';

  @override
  String get customerDiscard => 'تجاهل';

  @override
  String get customerBack => 'رجوع';

  @override
  String get customerOrderDetails => 'تفاصيل الطلب';

  @override
  String get customerRequestCancellation => 'طلب الإلغاء';

  @override
  String get customerTheOrderCouldNotBeCancelledRefreshTheOrder =>
      'تعذر إلغاء الطلب. حدّثه أو تواصل مع دايت تايم.';

  @override
  String get customerMEALSINCLUDED => 'الوجبات المشمولة';

  @override
  String get customerCOLLECTIONDAYS => 'أيام الاستلام';

  @override
  String get customerDELIVERYDAYS => 'أيام التوصيل';

  @override
  String get customerDELIVERYADDRESS => 'عنوان التوصيل';

  @override
  String get customerDELIVERYTIME => 'وقت التوصيل';

  @override
  String get customerPRICING => 'الأسعار';

  @override
  String get customerPAYMENTSTATUS => 'حالة الدفع';

  @override
  String get customerThankYouForYourOrder => 'شكراً لطلبك!';

  @override
  String get customerYourPlanAndDeliveryScheduleAreConfirmedAbove =>
      'تفاصيل باقتك وجدول التوصيل المؤكدة أعلاه.';

  @override
  String get customerNeedHelp => 'هل تحتاج مساعدة؟';

  @override
  String get customerContactSupport => 'تواصل مع الدعم';

  @override
  String get customerWeCouldntLoadThisOrder => 'تعذر تحميل هذا الطلب.';

  @override
  String get customerCancelThisOrder => 'إلغاء هذا الطلب؟';

  @override
  String get customerReason => 'السبب';

  @override
  String get customerKeepOrder => 'الإبقاء على الطلب';

  @override
  String get customerConfirmCancellation => 'تأكيد الإلغاء';

  @override
  String get customerThisOrderCouldNotBeLoadedForYourAccount =>
      'تعذر تحميل هذا الطلب لحسابك. حدّث لوحة التحكم أو تواصل مع فريقنا برقم الطلب.';

  @override
  String get customerWeCouldNotConnectToLoadYourMenuCheck =>
      'تعذر الاتصال لتحميل القائمة. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get customerTheMenuServiceCouldNotLoadYourOrdersDishes =>
      'تعذر تحميل أطباق طلبك. يرجى التحديث أو التواصل مع فريقنا.';

  @override
  String get customerConfirmYourMeals => 'تأكيد وجباتك';

  @override
  String get customerYourSelectionsCannotBeChangedAfterConfirmation =>
      'لا يمكن تغيير اختياراتك بعد التأكيد.';

  @override
  String get customerConfirm => 'تأكيد';

  @override
  String get customerThe900PMDeadlineHasPassedYourAutomaticMeals =>
      'انتهى موعد الاختيار في التاسعة مساءً. جارٍ تثبيت وجباتك التلقائية.';

  @override
  String get customerYourMealsHaveAlreadyBeenFinalizedHereAreYour =>
      'تم تثبيت وجباتك بالفعل. هذه أطباقك المحفوظة.';

  @override
  String get customerYourSubscriptionIsNoLongerActiveForThisDelivery =>
      'اشتراكك لم يعد نشطاً لهذا التوصيل.';

  @override
  String get customerADishIsNoLongerAvailablePleaseReviewThe =>
      'أحد الأطباق لم يعد متاحاً. يرجى مراجعة القائمة المحدثة.';

  @override
  String get customerWeCouldNotVerifyYourConfirmationPleaseCheckYour =>
      'تعذر التحقق من التأكيد. تحقق من الاتصال وحدّث قبل المحاولة مرة أخرى.';

  @override
  String get customerUnableToConfirmYourMealsPleaseTryAgain =>
      'تعذر تأكيد وجباتك. يرجى المحاولة مرة أخرى.';

  @override
  String get customerTomorrowsMenu => 'قائمة الغد';

  @override
  String get customerAutomaticallyFinalized => 'تم التثبيت تلقائياً';

  @override
  String get customerHideConfirmedMeals => 'إخفاء الوجبات المؤكدة';

  @override
  String get customerSelectionClosesTodayAt900PMQatarTime =>
      'ينتهي الاختيار اليوم الساعة التاسعة مساءً بتوقيت قطر.';

  @override
  String get customerMeals => 'الوجبات';

  @override
  String get customerSnacks => 'الوجبات الخفيفة';

  @override
  String get customerConfirmMyMeals => 'تأكيد وجباتي';

  @override
  String get customerReplaceAMeal => 'استبدال وجبة';

  @override
  String get customerReplaceASnack => 'استبدال وجبة خفيفة';

  @override
  String get customerNoEligibleDishesAreCurrentlyConfiguredOurTeamWill =>
      'لا توجد أطباق متاحة حالياً. سيراجع فريقنا هذا التوصيل.';

  @override
  String get customerUpcomingMeals => 'الوجبات القادمة';

  @override
  String get customerWeCouldntLoadAllYourDeliveryMeals =>
      'تعذر تحميل جميع وجبات التوصيل.';

  @override
  String get customerMealsHaveNotBeenAssignedToThisDeliveryYet =>
      'لم يتم تعيين وجبات لهذا التوصيل بعد. سيراجعه فريقنا.';

  @override
  String get customerMealsChosenForYou => 'وجبات مختارة لك';

  @override
  String get customerYourChoicesConfirmed => 'تم تأكيد اختياراتك';

  @override
  String get customerServiceDay => 'يوم خدمة';

  @override
  String get customerNonserviceDay => 'يوم بلا خدمة';

  @override
  String get customerNonservice => 'بلا خدمة';

  @override
  String get customerAutoselected => 'مختار تلقائياً';

  @override
  String get customerDelivery => 'التوصيل';

  @override
  String get customerScheduled => 'مجدول';

  @override
  String get customerNoUpcomingDeliveriesAreScheduled =>
      'لا توجد توصيلات قادمة مجدولة.';

  @override
  String get customerServiceRunsSaturdayToThursdayFridayIsANonservice =>
      'الخدمة من السبت إلى الخميس. الجمعة يوم بلا خدمة.';

  @override
  String get customerBeingPrepared => 'قيد التجهيز';

  @override
  String get customerOnTheWay => 'في الطريق';

  @override
  String get customerSkipped => 'تم التخطي';

  @override
  String get customerChooseYourLanguage => 'اختر لغتك';

  @override
  String get customerAll => 'الكل';

  @override
  String get customerYourDraftCouldNotBeSavedPleaseTryAgain =>
      'تعذر حفظ المسودة. يرجى المحاولة مرة أخرى.';

  @override
  String get customerUnableToLoadYourSavedProfile => 'تعذر تحميل ملفك المحفوظ.';

  @override
  String get customerYourProfileChangedElsewhereWeReloadedItPleaseReview =>
      'تم تعديل ملفك من مكان آخر. أعدنا تحميله؛ يرجى المراجعة والمحاولة مرة أخرى.';

  @override
  String get customerCouldNotSaveYourProgressCheckYourConnection =>
      'تعذر حفظ تقدمك. تحقق من الاتصال.';

  @override
  String get customerSelect => 'اختر';

  @override
  String get customerNoFoodPreferences => 'لا توجد تفضيلات غذائية';

  @override
  String get customerSearchAllergies => 'ابحث عن الحساسية...';

  @override
  String get customerPersonalized => 'مخصص لك';

  @override
  String get customerBalanced => 'متوازن';

  @override
  String get customerMadeForYou => 'صُنع لك';

  @override
  String get customerUnableToLoadAllergens => 'تعذر تحميل مسببات الحساسية.';

  @override
  String get customerWellAlwaysHighlightMealsThatAreSafeForYou =>
      'سنوضح دائماً الوجبات الآمنة لك.';

  @override
  String get customerNoAllergiesFound => 'لم يتم العثور على أنواع حساسية.';

  @override
  String get customerHeresAQuickOverviewOfYou => 'إليك نظرة سريعة على بياناتك.';

  @override
  String get customerGoal => 'الهدف';

  @override
  String get customerActivityLevel => 'مستوى النشاط';

  @override
  String get customerNotCalculatedYet => 'لم يُحسب بعد';

  @override
  String get customerProteinTarget => 'هدف البروتين';

  @override
  String get customerPersonalizeYourDietTimeExperience =>
      'لتخصيص تجربتك مع دايت تايم.';

  @override
  String get customerYourGoals => 'أهدافك';

  @override
  String get customerYourProfile => 'ملفك';

  @override
  String get customerYourLifestyle => 'نمط حياتك';

  @override
  String get customerYourFoodPreferences => 'تفضيلاتك الغذائية';

  @override
  String get customerYourHealthAllergies => 'صحتك والحساسية';

  @override
  String get customerYoureAllSet => 'أنت جاهز!';

  @override
  String get customerYouCanNowExploreTheDietTimeMenu =>
      'يمكنك الآن تصفح قائمة دايت تايم.';

  @override
  String get customerWeCouldntLoadYourProfile => 'تعذر تحميل ملفك.';

  @override
  String get customerWhatShouldWeCallYou => 'بماذا نناديك؟';

  @override
  String get customerYourName => 'اسمك';

  @override
  String get customerUnableToSaveYourNamePleaseTryAgain =>
      'تعذر حفظ اسمك. يرجى المحاولة مرة أخرى.';

  @override
  String get customerYourAnswersAreKeptOnThisPhonePleaseRetry =>
      'إجاباتك محفوظة على هذا الهاتف. يرجى محاولة الحفظ مجدداً.';

  @override
  String get customerPickHowManyMealsYoudLikeEachDay =>
      'اختر عدد الوجبات التي ترغب بها يومياً.';

  @override
  String get customerSwipeToExploreMealPackagesundefined =>
      'اسحب لاستعراض باقات الوجبات ←';

  @override
  String get customerChooseYourDuration => 'اختر المدة';

  @override
  String get customerCurrentlyUnavailable => 'غير متاح حالياً';

  @override
  String get customerSwipeToExplorePackageDurationsundefined =>
      'اسحب لاستعراض مدد الباقات ←';

  @override
  String get customerPricingUnavailable => 'الأسعار غير متاحة';

  @override
  String get customerYourAllergenPreferencesAreSaved =>
      'تم حفظ معلومات الحساسية';

  @override
  String
  get customerWellUseYourRecordedAllergenInformationWhenShowingSuitable =>
      'سنستخدم معلومات الحساسية المسجلة لعرض الوجبات المناسبة. يرجى مراجعة تفاصيل حساسية كل وجبة قبل الطلب.';

  @override
  String get customerPricingIsTemporarilyUnavailable =>
      'الأسعار غير متاحة مؤقتاً.';

  @override
  String get customerNoPackagesAreCurrentlyAvailableForThisMealPlan =>
      'لا توجد باقات متاحة حالياً لخطة الوجبات هذه.';

  @override
  String get customerTryAnotherPlanToFindYourDailyMealRoutine =>
      'جرب باقة أخرى لتجد نظام وجباتك اليومي.';

  @override
  String get customerChooseAnotherPlan => 'اختر باقة أخرى';

  @override
  String get customerNoMealPlansAreAvailableYet =>
      'لا توجد باقات وجبات متاحة بعد.';

  @override
  String get customerUnableToLoadMealPlans => 'تعذر تحميل باقات الوجبات.';

  @override
  String get customerChooseANewDeliveryStartDateDeliveryCanStart =>
      'اختر تاريخ بدء جديداً. يمكن أن يبدأ التوصيل غداً أو لاحقاً.';

  @override
  String get customerChooseYourStartDate => 'اختر تاريخ البدء';

  @override
  String get customerTapToChooseAnAvailableServiceDay =>
      'اضغط لاختيار يوم خدمة متاح.';

  @override
  String get customerTapToChooseADifferentServiceDay =>
      'اضغط لاختيار يوم خدمة آخر.';

  @override
  String get customerContinueundefined => 'متابعة ←';

  @override
  String get customerStartDate2 => 'تاريخ البدء';

  @override
  String get customerSelectADate => 'اختر تاريخاً';

  @override
  String get customerEndDate => 'تاريخ الانتهاء';

  @override
  String get customerCalculatedAutomatically => 'يُحسب تلقائياً';

  @override
  String get customerSelectYourStartDate => 'اختر تاريخ البدء';

  @override
  String get customerSelectedStartDate => 'تاريخ البدء المحدد';

  @override
  String get customerPlanEndDate => 'تاريخ انتهاء الباقة';

  @override
  String get customerPlanServiceDay => 'يوم خدمة الباقة';

  @override
  String get customerFridayUnavailable => 'الجمعة غير متاح';

  @override
  String get customerSelectAStartDate => 'اختر تاريخ بدء';

  @override
  String get customerConfirmDates => 'تأكيد التواريخ';

  @override
  String get customerYourSubscription => 'اشتراكك';

  @override
  String get customerActive => 'نشط';

  @override
  String get customerCompleted => 'مكتمل';

  @override
  String get customerPaused => 'متوقف مؤقتاً';

  @override
  String get customerAwaitingActivation => 'بانتظار التفعيل';

  @override
  String get customerUnderReview => 'قيد المراجعة';

  @override
  String get customerUnpaid => 'غير مدفوع';

  @override
  String get customerPaymentPending => 'بانتظار الدفع';

  @override
  String get customerPaid => 'مدفوع';

  @override
  String get customerPaymentFailed => 'فشل الدفع';

  @override
  String get customerRefundUnderReview => 'استرداد المبلغ قيد المراجعة';

  @override
  String get customerRefunded => 'تم الاسترداد';

  @override
  String get customerPartiallyRefunded => 'تم استرداد جزء من المبلغ';

  @override
  String get customerPaymentUnderReview => 'الدفع قيد المراجعة';

  @override
  String get customerDietTimeIsReviewingYourOrder => 'دايت تايم تراجع طلبك.';

  @override
  String get customerDietTimeWillReviewYourOrderAndNotifyYou =>
      'ستراجع دايت تايم طلبك وتخطرك بعد تأكيده.';

  @override
  String customerDaysPerWeek(int count) {
    return '$count أيام في الأسبوع';
  }

  @override
  String customerActivePlans(int count) {
    return 'لديك $count باقات وجبات نشطة';
  }

  @override
  String customerOrderReference(String reference) {
    return 'يرجى ذكر رقم الطلب $reference.';
  }

  @override
  String get customerSelectionDeadline => 'موعد إغلاق الاختيار';

  @override
  String get customerQatarTime => 'بتوقيت قطر';

  @override
  String get customerOrderStatus => 'حالة الطلب';

  @override
  String get customerSelected => 'محدد';

  @override
  String get customerYourOrderIsConfirmedAndAwaitingTheRequiredPayment =>
      'طلبك مؤكد وبانتظار الدفع المطلوب.';

  @override
  String get addressHomeLabel => 'المنزل';

  @override
  String get addressApartmentLabel => 'الشقة';

  @override
  String get addressOfficeLabel => 'المكتب';

  @override
  String get addressOtherLabel => 'آخر';

  @override
  String get reviewPackage => 'مراجعة الباقة';

  @override
  String get packageUnavailable =>
      'باقة الوجبات المحددة غير متاحة. يرجى مراجعة باقتك.';

  @override
  String get durationPricingUnavailable =>
      'السعر غير متاح لهذه المدة. يرجى مراجعة باقتك.';

  @override
  String get planPricingMismatch =>
      'الباقة والسعر المحددان غير متطابقين. يرجى مراجعة باقتك.';

  @override
  String get planNotFound =>
      'لم يتم العثور على باقة الوجبات هذه. يرجى اختيار باقة أخرى.';

  @override
  String get planUnavailable =>
      'باقة الوجبات هذه لم تعد متاحة. يرجى اختيار باقة أخرى.';

  @override
  String get availabilityRetry =>
      'تعذر التحقق من هذه الباقة. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get saveOrderRetry =>
      'تعذر حفظ طلبك. يرجى المحاولة مرة أخرى أو التواصل مع دايت تايم.';

  @override
  String get menuButton => 'القائمة';

  @override
  String get dashboardMyPlans => 'خططي';

  @override
  String get dashboardPendingApproval => 'بانتظار الموافقة';

  @override
  String get dashboardAwaitingConfirmation => 'بانتظار تأكيد دايت تايم';

  @override
  String dashboardPlanCount(int count) {
    return '$count خطط';
  }
}
