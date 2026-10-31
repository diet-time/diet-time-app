import 'package:flutter/widgets.dart';

// Tour-only localization catalogue; follows the app's currently selected locale/RTL.
String tourCopy(BuildContext context, String key) {
  final arabic = Localizations.localeOf(context).languageCode == 'ar';
  return (arabic ? tourArabic : tourEnglish)[key] ?? tourEnglish[key] ?? key;
}

const tourEnglish = <String, String>{
  'progress': 'Tour progress',
  'menuButton.title': 'Menu button',
  'menuButton':
      'Use Menu to browse dishes, dates and nutrition before choosing a plan. It opens the same menu you can return to from Home.',
  'menuButton.hint': 'Next opens the Menu screen.',
  'viewDetails.title': 'View Details',
  'viewDetails':
      'This button opens the full order for this plan: approval status, payment, service dates and takeaway or delivery information.',
  'viewDetails.hint': 'Next opens your order details.',
  'newPlan.title': 'Choose or add a plan',
  'newPlan':
      'Choose Plan starts your first plan. Order Another Plan lets you add a new one. You can review packages and dates before placing an order.',
  'newPlan.hint': 'Next opens the plan list.',
  'chooseMeals.title': 'Choose tomorrow’s meals',
  'chooseMeals':
      'When selection is open, this button lets you review or change tomorrow’s assigned dishes. Review your choices before confirming them.',
  'profileTab.title': 'Profile button',
  'profileTab':
      'Use this bottom button for personal information, Adjust My Plan, saved addresses and the app-tour setting.',
  'enable': 'Enable App Tour',
  'description': 'Explore the app with a guided walkthrough.',
  'next': 'Next',
  'previous': 'Previous',
  'skip': 'Skip Tour',
  'finish': 'Finish',
  'of': 'of',
  'detail': 'Include detailed guidance',
  'retry': 'Retry',
  'failed': 'Tour preference was not saved. Please retry.',
  'enabled': 'Tour enabled. Return to Home to start.',
  'loading': 'Finding this feature…',
  'confirmation.title': 'Confirm your meals',
  'confirmation':
      'When confirmation is available, review all your choices here before confirming. Confirmation can lock the choices for that service day. This tour never confirms meals for you.',
  'welcome.title': 'Welcome to Diet Time',
  'welcome':
      'We’ll highlight the buttons you use most. Next explores the next feature, Previous takes you back, and Skip Tour returns to Home.',
  'plans.title': 'My Plans',
  'plans':
      'Your plans appear here. Pending orders await staff approval; confirmed and active plans show their actual status. View Details opens the full order.',
  'tomorrow.title': 'Tomorrow’s meals',
  'tomorrow':
      'See your next meals and their service status here. Open a meal to review its details.',
  'navigation.title': 'Home button',
  'navigation':
      'Tap Home to return to your dashboard, current plans and tomorrow’s meals from any dashboard tab.',
  'orders.title': 'Orders button',
  'orders':
      'Tap Orders to see your purchases and filter them by status. Open an order to review it; approval and payment are shown separately.',
  'calendar.title': 'Calendar button',
  'calendar':
      'Tap Calendar for service dates. Choose a day to see its orders and meals below the calendar.',
  'profile.title': 'Your profile',
  'profile':
      'Open Customer Profile to review or update your personal information.',
  'questionnaire.title': 'Adjust My Plan',
  'questionnaire':
      'Open Adjust My Plan to update your goals, routine, dietary preferences and allergens.',
  'addresses.title': 'Saved addresses',
  'addresses':
      'Add or edit addresses here. Home Delivery needs an address; Takeaway uses your selected branch.',
  'language.title': 'Choose your language',
  'language':
      'Use the globe menu to switch between English and Arabic. Your saved preference applies across the app.',
  'menu.title': 'Browse the menu',
  'menu':
      'Explore the existing weekly menu, meal categories and dish nutrition. Menu availability follows the published schedule.',
  'choosePlan.title': 'Start your plan',
  'choosePlan':
      'Choose a plan and package, then continue through the existing start-date and checkout steps. Review fulfillment and payment before placing an order. This tour does not submit anything.',
  'settings.title': 'Replay whenever you like',
  'settings':
      'Enable App Tour in Profile to replay. Finish or Skip turns this preference off after it is saved.',
  'orderDetails.title': 'Order details',
  'orderDetails':
      'Find your package, service dates, fulfillment, approval and payment details in this existing order screen.',
  'calendarNavigation.title': 'Change the month',
  'calendarNavigation':
      'Use the month arrows to browse the available service period.',
  'calendarIndicators.title': 'Calendar indicators',
  'calendarIndicators':
      'These indicators explain service-day statuses. Counts show how many orders are scheduled on a date.',
  'calendarDetails.title': 'Selected-day details',
  'calendarDetails':
      'Orders below the calendar belong to the selected date. Open their details to review fulfillment and meals.',
  'assigned.title': 'Assigned meals',
  'assigned':
      'Your automatically assigned meals appear here. Review the current choice and its selection status.',
  'customize.title': 'Customize a meal',
  'customize':
      'When changes are available, Change Meal opens the permitted alternatives. Select a replacement, review it and use Save Changes to confirm. This tour keeps your current meals unchanged.',
  'nutrition.title': 'Meal nutrition',
  'nutrition':
      'Review the displayed calories and protein, carbohydrate and fat totals for these meals.',
  'menuDates.title': 'Browse service dates',
  'menuDates':
      'Choose a date in the week to see its published menu. Unavailable days remain unavailable.',
  'menuFilters.title': 'Meal categories',
  'menuFilters':
      'Use the existing category controls to browse the meals you want to explore.',
  'menuNutrition.title': 'Dish nutrition',
  'menuNutrition':
      'Each dish shows its nutrition. Open a dish after the tour for the full details.',
};
const tourArabic = <String, String>{
  'progress': 'تقدم الجولة',
  'menuButton.title': 'زر القائمة',
  'menuButton':
      'استخدم القائمة لاستعراض الأطباق والتواريخ والقيم الغذائية قبل اختيار خطة. يمكنك العودة إليها من الرئيسية في أي وقت.',
  'menuButton.hint': 'التالي يفتح شاشة القائمة.',
  'viewDetails.title': 'عرض التفاصيل',
  'viewDetails':
      'يفتح هذا الزر الطلب الكامل لهذه الخطة، بما في ذلك الموافقة والدفع وتواريخ الخدمة ومعلومات الاستلام أو التوصيل.',
  'viewDetails.hint': 'التالي يفتح تفاصيل طلبك.',
  'newPlan.title': 'اختيار خطة أو إضافة خطة',
  'newPlan':
      'اختر خطة لبدء خطتك الأولى، أو اطلب خطة أخرى لإضافة خطة جديدة. يمكنك مراجعة الباقات والتواريخ قبل تقديم الطلب.',
  'newPlan.hint': 'التالي يفتح قائمة الخطط.',
  'chooseMeals.title': 'اختيار وجبات الغد',
  'chooseMeals':
      'عندما يكون الاختيار متاحاً، يتيح هذا الزر مراجعة وجبات الغد المخصصة أو تغييرها. راجع اختياراتك قبل تأكيدها.',
  'profileTab.title': 'زر الملف الشخصي',
  'profileTab':
      'استخدم هذا الزر السفلي للوصول إلى المعلومات الشخصية وعدّل خطتي والعناوين المحفوظة وإعداد جولة التطبيق.',
  'enable': 'تفعيل جولة التطبيق',
  'description': 'استكشف التطبيق من خلال جولة إرشادية.',
  'next': 'التالي',
  'previous': 'السابق',
  'skip': 'تخطي الجولة',
  'finish': 'إنهاء',
  'of': 'من',
  'detail': 'تضمين إرشادات تفصيلية',
  'retry': 'إعادة المحاولة',
  'failed': 'لم يتم حفظ تفضيل الجولة. يرجى إعادة المحاولة.',
  'enabled': 'تم تفعيل الجولة. ارجع إلى الرئيسية للبدء.',
  'loading': 'جارٍ العثور على الميزة…',
  'confirmation.title': 'تأكيد وجباتك',
  'confirmation':
      'عند إتاحة التأكيد، راجع جميع اختياراتك هنا أولاً. قد يؤدي التأكيد إلى قفل اختيارات يوم الخدمة. الجولة لا تؤكد الوجبات نيابة عنك.',
  'welcome.title': 'مرحباً بك في دايت تايم',
  'welcome':
      'سنوضح الأزرار الأكثر استخداماً. التالي يستعرض الميزة التالية، والسابق يعيدك إلى الخطوة الماضية، وتخطي الجولة يعيدك إلى الرئيسية.',
  'plans.title': 'خططي',
  'plans':
      'تظهر خططك هنا. الطلبات المعلقة تنتظر موافقة الفريق، وتظهر الخطط المؤكدة والنشطة بحالتها الفعلية. افتح التفاصيل للاطلاع على الطلب.',
  'tomorrow.title': 'وجبات الغد',
  'tomorrow':
      'اطلع على وجباتك القادمة وحالة الخدمة هنا. افتح الوجبة لمراجعة تفاصيلها.',
  'navigation.title': 'زر الرئيسية',
  'navigation':
      'اضغط الرئيسية للعودة إلى لوحة التحكم وخططك الحالية ووجبات الغد من أي تبويب.',
  'orders.title': 'زر الطلبات',
  'orders':
      'اضغط الطلبات لرؤية مشترياتك وتصفيتها حسب الحالة. افتح طلباً لمراجعته؛ تظهر الموافقة والدفع بشكل منفصل.',
  'calendar.title': 'زر التقويم',
  'calendar':
      'اضغط التقويم لرؤية تواريخ الخدمة. اختر يوماً لعرض طلباته ووجباته أسفل التقويم.',
  'profile.title': 'ملفك الشخصي',
  'profile': 'افتح ملف العميل لمراجعة معلوماتك الشخصية أو تحديثها.',
  'questionnaire.title': 'عدّل خطتي',
  'questionnaire':
      'افتح عدّل خطتي لتحديث أهدافك وروتينك وتفضيلاتك الغذائية والحساسيات.',
  'addresses.title': 'العناوين المحفوظة',
  'addresses':
      'أضف العناوين أو عدّلها هنا. التوصيل المنزلي يحتاج عنواناً، والاستلام يستخدم الفرع المختار.',
  'language.title': 'اختر لغتك',
  'language':
      'استخدم قائمة الكرة الأرضية للتبديل بين العربية والإنجليزية. يسري تفضيلك المحفوظ على التطبيق كله.',
  'menu.title': 'استعرض القائمة',
  'menu':
      'استكشف القائمة الأسبوعية وفئات الوجبات وقيمها الغذائية. التوفر يتبع الجدول المنشور.',
  'choosePlan.title': 'ابدأ خطتك',
  'choosePlan':
      'اختر الخطة والباقة ثم تابع خطوات تاريخ البدء وإتمام الطلب الحالية. راجع طريقة الاستلام والدفع قبل الطلب. الجولة لا ترسل أي طلب.',
  'settings.title': 'أعد الجولة متى شئت',
  'settings':
      'فعّل جولة التطبيق من الملف الشخصي لإعادتها. الإنهاء أو التخطي يعطّل هذا التفضيل بعد حفظه.',
  'orderDetails.title': 'تفاصيل الطلب',
  'orderDetails':
      'راجع الباقة وتواريخ الخدمة والاستلام والموافقة والدفع في شاشة الطلب الحالية.',
  'calendarNavigation.title': 'تغيير الشهر',
  'calendarNavigation': 'استخدم أسهم الشهر لاستعراض فترة الخدمة المتاحة.',
  'calendarIndicators.title': 'مؤشرات التقويم',
  'calendarIndicators':
      'تشرح المؤشرات حالات أيام الخدمة. توضح الأعداد عدد الطلبات المجدولة في التاريخ.',
  'calendarDetails.title': 'تفاصيل اليوم المختار',
  'calendarDetails':
      'الطلبات أسفل التقويم تخص اليوم المختار. افتح تفاصيلها لمراجعة الاستلام والوجبات.',
  'assigned.title': 'الوجبات المخصصة',
  'assigned': 'تظهر وجباتك المخصصة تلقائياً هنا. راجع الاختيار الحالي وحالته.',
  'customize.title': 'تخصيص الوجبة',
  'customize':
      'عند إتاحة التغيير، يفتح تغيير الوجبة البدائل المسموحة. اختر البديل وراجعه ثم احفظ التغييرات للتأكيد. الجولة تحافظ على اختياراتك الحالية.',
  'nutrition.title': 'القيم الغذائية',
  'nutrition':
      'راجع السعرات الحرارية وإجمالي البروتين والكربوهيدرات والدهون لهذه الوجبات.',
  'menuDates.title': 'تواريخ القائمة',
  'menuDates':
      'اختر تاريخاً من الأسبوع لرؤية قائمته المنشورة. تبقى الأيام غير المتاحة غير متاحة.',
  'menuFilters.title': 'فئات الوجبات',
  'menuFilters': 'استخدم أدوات الفئات الحالية لاستعراض الوجبات التي تهمك.',
  'menuNutrition.title': 'القيم الغذائية للطبق',
  'menuNutrition':
      'يعرض كل طبق قيمه الغذائية. افتح الطبق بعد الجولة للتفاصيل الكاملة.',
};
