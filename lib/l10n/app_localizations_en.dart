// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get deliveriesTitle => 'Tomorrow’s Deliveries';

  @override
  String deliveriesScheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'orders',
      one: 'order',
    );
    return '$count scheduled $_temp0';
  }

  @override
  String deliveriesOrder(String reference) {
    return 'Order: $reference';
  }

  @override
  String get deliveriesConfirmed => 'Confirmed';

  @override
  String get deliveriesPending => 'Selection pending';

  @override
  String get deliveriesReady => 'Ready to confirm';

  @override
  String get deliveriesAutomatic => 'Automatically selected';

  @override
  String get deliveriesLocked => 'Locked';

  @override
  String get deliveriesReviewConfirm => 'Review & confirm';

  @override
  String get deliveriesViewConfirmed => 'View confirmed meals';

  @override
  String get deliveriesViewSelected => 'View selected meals';

  @override
  String get deliveriesViewMenu => 'View menu';

  @override
  String get deliveriesUnavailable => 'Unable to load all deliveries';

  @override
  String get deliveriesActionNeeded => 'Action needed';

  @override
  String get deliveriesWaiting => 'Delivery update';

  @override
  String deliveriesPackage(int meals, int snacks) {
    String _temp0 = intl.Intl.pluralLogic(
      snacks,
      locale: localeName,
      other: 'Snacks',
      one: 'Snack',
    );
    return '$meals Meals + $snacks $_temp0';
  }

  @override
  String deliveriesAllConfirmed(int count) {
    return 'All $count dishes confirmed';
  }

  @override
  String get deliveriesViewDishes => 'View your dishes';

  @override
  String get deliveriesHideDishes => 'Hide your dishes';

  @override
  String deliveriesProgress(int selected, int total) {
    return '$selected of $total selected';
  }

  @override
  String get deliveriesDeadline => 'Choose before 9:00 PM';

  @override
  String get deliveriesChoose => 'Choose your meals';

  @override
  String get deliveriesRefresh => 'Refresh menu';

  @override
  String get deliveriesLoading => 'Loading deliveries…';

  @override
  String get deliveriesMeal => 'Meal';

  @override
  String get deliveriesSnack => 'Snack';

  @override
  String get deliveriesViewDetails => 'View Details';

  @override
  String deliveriesFirstDelivery(String date) {
    return 'First delivery: $date';
  }

  @override
  String deliveriesStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'NO_ORDER': 'No order is linked to your account.',
      'PENDING_ACTIVATION':
          'Your order is saved and is waiting for activation.',
      'NOT_STARTED':
          'Your plan starts soon. Selection opens the day before your first delivery.',
      'NO_DELIVERY': 'No delivery is scheduled for tomorrow.',
      'SERVICE_DAYS_MISSING':
          'Your order is saved, but its delivery schedule needs to be initialized by our team.',
      'SERVICE_DAY_INCOMPLETE':
          'Your delivery details need review by our team.',
      'SCHEDULE_NOT_CONFIGURED':
          'Your order’s delivery weekdays need review by our team.',
      'MENU_NOT_CONFIGURED':
          'Your order is saved. Tomorrow’s dishes have not been configured yet.',
      'SELECTION_NOT_OPEN': 'Selection opens the day before your delivery.',
      'FINALIZATION_PENDING':
          'The 9:00 PM selection window has closed. Your automatic meals are being finalized.',
      'INACTIVE_ORDER': 'This order is not active for meal selection.',
      'LOCKED': 'Your meal selections are locked for preparation.',
      'NEEDS_REVIEW':
          'Our team needs to review suitable dishes for your package.',
      'other': 'Please choose your meals for tomorrow.',
    });
    return '$_temp0';
  }

  @override
  String get appName => 'Diet Time';

  @override
  String get tagline => 'Fuel Right. Feel Light.';

  @override
  String get healthy => 'Healthy';

  @override
  String get journeyStartsHere => 'Your journey starts here.';

  @override
  String get landingTitle => 'Eat Well, Feel Great';

  @override
  String get landingSubtitle =>
      'Discover tailored meal plans designed for flavor and health. Build lasting habits, one delicious meal at a time.';

  @override
  String get viewPlans => 'The Plans';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to continue your healthy journey.';

  @override
  String get emailOrMobile => 'Email / Mobile';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get orContinueWith => 'OR CONTINUE WITH';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orSignInWith => 'or sign in with';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get createAccount => 'Create Account';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidEmailOrMobile =>
      'Enter a valid email address or mobile number';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get homeScreen => 'Home Screen';

  @override
  String get postLoginWelcomeLabel => 'Welcome to Diet Time';

  @override
  String get postLoginAccountReady => 'Your account is ready';

  @override
  String get postLoginTitleLead => 'Your plan starts';

  @override
  String get postLoginTitleAccent => 'with you';

  @override
  String get postLoginSupporting =>
      'Tell us a little about your routine, goals, and food preferences.';

  @override
  String get postLoginSecondary =>
      'We\'ll use your answers to shape a plan that feels practical, balanced, and easy to follow.';

  @override
  String get postLoginCta => 'Personalize My Plan';

  @override
  String get postLoginMealBalanced => 'Balanced meals';

  @override
  String get postLoginMealFlexible => 'Flexible choices';

  @override
  String get postLoginMealGoals => 'Built around your goals';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get onboardingHealthyMealsTitle => 'Healthy Meals,';

  @override
  String get onboardingHealthyMealsAccent => 'Made Simple.';

  @override
  String get onboardingHealthyMealsDescription =>
      'Delicious, balanced meals delivered daily to support your healthy lifestyle.';

  @override
  String get onboardingPlansTitle => 'Plans That Fit';

  @override
  String get onboardingPlansAccent => 'You Perfectly';

  @override
  String get onboardingPlansDescription =>
      'Tell us your goals, we\'ll handle the rest with personalised plans just for you.';

  @override
  String get onboardingFreshTitle => 'Fresh. Clean.';

  @override
  String get onboardingFreshAccent => 'Always.';

  @override
  String get onboardingFreshDescription =>
      'We use real ingredients with no artificial colors, preservatives or unhealthy fillers.';

  @override
  String get onboardingTrackTitle => 'Track. Improve.';

  @override
  String get onboardingTrackAccent => 'Live Better.';

  @override
  String get onboardingTrackDescription =>
      'Simple tracking helps you stay consistent and achieve your health goals.';

  @override
  String get onboardingBmiTitle => 'Know Your BMI,';

  @override
  String get onboardingBmiAccent => 'Build a Better Plan';

  @override
  String get onboardingBmiDescription =>
      'Calculate your BMI and get a plan shaped around your body and goals.';

  @override
  String get onboardingTogetherTitle => 'Better Together,';

  @override
  String get onboardingTogetherAccent => 'Stronger Together';

  @override
  String get onboardingTogetherDescription =>
      'Invite friends, share your journey and achieve more together.';

  @override
  String get onboardingMenu => 'View Menu';

  @override
  String get onboardingStartPlan => 'Start your Plan';

  @override
  String get onboardingBrand => 'Diet Time';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Diet Time';

  @override
  String get onboardingWelcomeSubtitle =>
      'Healthy eating made simple.\nLet\'s build a meal plan designed just for you.';

  @override
  String get onboardingStartJourney => 'Start My Journey';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingPrevious => 'Previous';

  @override
  String get onboardingGoalTitle => 'What would you like to achieve?';

  @override
  String get onboardingGoalSubtitle =>
      'We\'ll personalize your meals around your goal.';

  @override
  String get onboardingLoseWeight => 'Lose Weight';

  @override
  String get onboardingLoseWeightDescription =>
      'Burn fat while enjoying satisfying meals.';

  @override
  String get onboardingBuildMuscle => 'Build Muscle';

  @override
  String get onboardingBuildMuscleDescription =>
      'Protein-focused meals to support strength.';

  @override
  String get onboardingStayHealthy => 'Stay Healthy';

  @override
  String get onboardingStayHealthyDescription =>
      'Balanced nutrition for everyday wellness.';

  @override
  String get onboardingImproveFitness => 'Improve Fitness';

  @override
  String get onboardingImproveFitnessDescription =>
      'Fuel your body for an active lifestyle.';

  @override
  String get onboardingProfileTitle => 'Let\'s get to know you';

  @override
  String get onboardingProfileSubtitle =>
      'A few details help us tailor every meal to you.';

  @override
  String get onboardingGender => 'Gender';

  @override
  String get onboardingAge => 'Age';

  @override
  String get onboardingHeight => 'Height';

  @override
  String get onboardingWeight => 'Weight';

  @override
  String get onboardingMale => 'Male';

  @override
  String get onboardingFemale => 'Female';

  @override
  String get onboardingPreferNotToSay => 'Prefer not to say';

  @override
  String get onboardingLifestyleTitle => 'Tell us about your daily routine';

  @override
  String get onboardingLifestyleSubtitle =>
      'Choose the option that feels most like your day.';

  @override
  String get onboardingOfficeWork => 'Office Work';

  @override
  String get onboardingWorkFromHome => 'Work From Home';

  @override
  String get onboardingStudent => 'Student';

  @override
  String get onboardingActiveJob => 'Active Job';

  @override
  String get onboardingShiftWorker => 'Shift Worker';

  @override
  String get onboardingActivityTitle => 'How active are you?';

  @override
  String get onboardingActivitySubtitle =>
      'We\'ll balance your meals around your energy needs.';

  @override
  String get onboardingMostlySitting => 'Mostly Sitting';

  @override
  String get onboardingLightActivity => 'Light Activity';

  @override
  String get onboardingActiveLifestyle => 'Active Lifestyle';

  @override
  String get onboardingAthlete => 'Athlete';

  @override
  String get onboardingPreferencesTitle => 'What do you enjoy eating?';

  @override
  String get onboardingPreferencesSubtitle => 'Select as many as you like.';

  @override
  String get onboardingHighProtein => 'High Protein';

  @override
  String get onboardingLowCarb => 'Low Carb';

  @override
  String get onboardingVegetarian => 'Vegetarian';

  @override
  String get onboardingVegan => 'Vegan';

  @override
  String get onboardingSeafood => 'Seafood';

  @override
  String get onboardingChicken => 'Chicken';

  @override
  String get onboardingBeef => 'Beef';

  @override
  String get onboardingArabicCuisine => 'Arabic Cuisine';

  @override
  String get onboardingInternational => 'International';

  @override
  String get onboardingMediterranean => 'Mediterranean';

  @override
  String get onboardingHealthySnacks => 'Healthy Snacks';

  @override
  String get onboardingBreakfastLover => 'Breakfast Lover';

  @override
  String get onboardingAllergiesTitle => 'Any food allergies?';

  @override
  String get onboardingAllergiesSubtitle =>
      'Select everything we should keep in mind.';

  @override
  String get onboardingMilk => 'Milk';

  @override
  String get onboardingEgg => 'Egg';

  @override
  String get onboardingFish => 'Fish';

  @override
  String get onboardingShellfish => 'Shellfish';

  @override
  String get onboardingTreeNuts => 'Tree Nuts';

  @override
  String get onboardingPeanuts => 'Peanuts';

  @override
  String get onboardingSoy => 'Soy';

  @override
  String get onboardingSesame => 'Sesame';

  @override
  String get onboardingGluten => 'Gluten';

  @override
  String get onboardingNoAllergies => 'No Allergies';

  @override
  String get onboardingBuildingTitle => 'Creating your personalized meal plan';

  @override
  String get onboardingBuildingSubtitle =>
      'We\'re preparing meals that match your goals, lifestyle and preferences.';

  @override
  String get onboardingReadyAction => 'View My Options';

  @override
  String get personalizationIntroTitle => 'Let\'s shape your plan';

  @override
  String get personalizationIntroSubtitle =>
      'Answer a few simple questions so we can recommend meals that suit your goals, routine, and preferences.';

  @override
  String get personalizationBegin => 'Begin';

  @override
  String get personalizationNotNow => 'Not now';

  @override
  String get personalizationSelectOption => 'Choose an option to continue.';

  @override
  String get onboardingMaintainWeight => 'Maintain Weight';

  @override
  String get onboardingMaintainWeightDescription =>
      'Balanced meals that support your current routine.';

  @override
  String get onboardingGainWeight => 'Gain Weight';

  @override
  String get onboardingGainWeightDescription =>
      'Nourishing meals with the energy your goals need.';

  @override
  String get onboardingEatHealthier => 'Eat Healthier';

  @override
  String get onboardingEatHealthierDescription =>
      'Make wholesome everyday choices easier.';

  @override
  String get bmiSummaryTitle => 'Your wellness snapshot';

  @override
  String get bmiCalculatedLabel => 'Your calculated BMI';

  @override
  String get bmiDisclaimer =>
      'BMI is a general screening measure and does not account for muscle mass, body composition, age, or individual health conditions.';

  @override
  String get bmiYouthNote =>
      'Children and teenagers require age- and sex-specific assessment.';

  @override
  String get bmiBelowRange => 'Below standard range';

  @override
  String get bmiWithinRange => 'Within standard range';

  @override
  String get bmiAboveRange => 'Above standard range';

  @override
  String get bmiWellAboveRange => 'Well above standard range';

  @override
  String get allergySafetyNote =>
      'We\'ll use this information to highlight meals that may not be suitable for you. Always review the meal\'s ingredient and allergen details before ordering.';

  @override
  String get recommendationTitle => 'A plan that fits your routine';

  @override
  String get recommendationReasonGoal => 'Matches your primary goal';

  @override
  String get recommendationReasonActivity => 'Fits your activity level';

  @override
  String get recommendationReasonPreferences =>
      'Includes your preferred meal styles';

  @override
  String get recommendationReasonAllergens =>
      'Considers your recorded allergens';

  @override
  String get viewRecommendedPlan => 'View Recommended Plan';

  @override
  String get compareAllPlans => 'Compare All Plans';

  @override
  String get chooseLanguage => 'Choose your Language';

  @override
  String get languageSelectionSubtitle =>
      'Select your preferred language to personalize your experience.';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSaveError =>
      'Unable to save language preference. Please try again.';

  @override
  String get loading => 'Loading';

  @override
  String pageProgress(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get browseMenuTitle => 'Fresh choices, made for you';

  @override
  String get browseMenuSubtitle =>
      'Explore chef-crafted meals prepared with wholesome ingredients.';

  @override
  String get browseMenu => 'Browse Menu';

  @override
  String get popularMeals => 'Popular meals';

  @override
  String get mealGrilledChicken => 'Herb Grilled Chicken';

  @override
  String get mealGrilledChickenDetail => 'Brown rice, greens & tahini';

  @override
  String get mealSalmon => 'Citrus Salmon Bowl';

  @override
  String get mealSalmonDetail => 'Quinoa, avocado & edamame';

  @override
  String get mealKeto => 'Keto Beef Garden';

  @override
  String get mealKetoDetail => 'Roasted vegetables & herbs';

  @override
  String kcal(int value) {
    return '$value kcal';
  }

  @override
  String get choosePlanTitle => 'Choose Your Meal Plan';

  @override
  String get choosePlanSubtitle =>
      'Pick the plan that matches your goals. You can change it anytime.';

  @override
  String get weightLoss => 'Weight Loss';

  @override
  String get weightLossDescription =>
      'Balanced portions designed for steady, sustainable progress.';

  @override
  String get keto => 'Keto';

  @override
  String get ketoDescription =>
      'Low-carb favorites rich in healthy fats and fresh produce.';

  @override
  String get highProtein => 'High Protein';

  @override
  String get highProteinDescription =>
      'Protein-forward meals to support strength and recovery.';

  @override
  String get balancedDiet => 'Balanced Diet';

  @override
  String get balancedDietDescription =>
      'Everyday nutrition with a delicious mix of all food groups.';

  @override
  String dailyCalories(int value) {
    return '$value kcal / day';
  }

  @override
  String dailyPlanPrice(String currency, String amount) {
    return '$currency $amount / day';
  }

  @override
  String get dailyPriceLabel => 'Daily price';

  @override
  String get dailyPriceUnavailable => 'Daily price unavailable';

  @override
  String weeklyPrice(int value) {
    return 'QAR $value / week';
  }

  @override
  String get continueLabel => 'Continue';

  @override
  String get otpPhoneTitle => 'Let\'s Get Started';

  @override
  String get otpPhoneSubtitle => 'Enter your mobile number to continue.';

  @override
  String get otpPhoneHelper => 'We will send you a 6-digit verification code.';

  @override
  String get otpMobileNumber => 'Mobile number';

  @override
  String get otpInvalidPhone => 'Enter a valid mobile number.';

  @override
  String get otpRequestFailed =>
      'Unable to send the verification code. Please try again.';

  @override
  String get otpCodeTitle => 'Enter the Code';

  @override
  String get otpCodeSubtitle => 'A 6-digit verification code was sent to:';

  @override
  String get otpCodeSentTo => 'Code sent to';

  @override
  String get otpCodeEntryHelper =>
      'Please enter the code automatically detected or type it manually';

  @override
  String get otpEditPhone => 'Edit';

  @override
  String get otpDidntGetCode => 'Didn\'t get the code?';

  @override
  String get otpVerifyCode => 'Verify Code';

  @override
  String get otpResendCode => 'Resend code';

  @override
  String otpResendCountdown(String time) {
    return 'Resend code in $time';
  }

  @override
  String get otpSendViaSms => 'Send via SMS';

  @override
  String get otpSendViaWhatsapp => 'Send via WhatsApp';

  @override
  String get otpResendViaWhatsapp => 'Resend via WhatsApp';

  @override
  String otpDevelopmentCode(String code) {
    return 'Development code: $code';
  }

  @override
  String get otpIncorrectCode =>
      'The verification code is incorrect. Please try again.';

  @override
  String get otpExpiredCode =>
      'This verification code has expired. Request a new code.';

  @override
  String get otpTooManyAttempts => 'Too many attempts. Please try again later.';

  @override
  String get otpResendUnavailable =>
      'Resend is temporarily unavailable. Please try again.';

  @override
  String get otpResendConfirmation => 'A new verification code has been sent.';

  @override
  String get otpWhatsappTestGenerated =>
      'Test code generated for WhatsApp verification.';

  @override
  String get mealPlanHeaderTitle => 'Meal Plan';

  @override
  String get mealPlanHeaderSubtitle =>
      'Choose a plan that fits your lifestyle and goals.';

  @override
  String get planSwitchLoadingTitle => 'Preparing your new plan';

  @override
  String get planSwitchLoadingSubtitle =>
      'We\'re organizing the best meals for you...';

  @override
  String get mealContentLoadingTitle => 'Cooking up something healthy!';

  @override
  String get mealContentLoadingSubtitle => 'Fetching today\'s meals...';

  @override
  String get guestMealPlansTitle => 'Choose your plan';

  @override
  String selectMealPlanSemantics(String planName) {
    return 'Select $planName meal plan';
  }

  @override
  String get guestWeeklyMenuTitle => 'This week\'s menu';

  @override
  String get guestMenuLoadError => 'Unable to load the menu.';

  @override
  String get guestPlanLoadError => 'Unable to load this meal plan.';

  @override
  String get retry => 'Retry';

  @override
  String get noMealsAvailable => 'No meals available for this selection.';

  @override
  String get noMealsAvailableForPlan => 'No meals available for this plan.';

  @override
  String get tryAnotherMealFilter => 'Try another date or meal category.';

  @override
  String get caloriesLabel => 'Calories';

  @override
  String get proteinLabel => 'Protein';

  @override
  String get carbsLabel => 'Carbs';

  @override
  String get fatLabel => 'Fat';

  @override
  String get mealIngredientsTitle => 'Ingredients';

  @override
  String get mealAllergensTitle => 'Allergens';

  @override
  String get showAllIngredients => 'Show all';

  @override
  String get noIngredientsAvailable => 'No ingredient information available.';

  @override
  String get noAllergensListed => 'No allergens recorded.';

  @override
  String get readMore => 'Read more';

  @override
  String get showLess => 'Show less';

  @override
  String allergenContains(String name) {
    return 'Contains $name';
  }

  @override
  String allergenMayContain(String name) {
    return 'May contain $name';
  }

  @override
  String allergenTraces(String name) {
    return 'Traces of $name';
  }

  @override
  String nutritionItemSemantics(String label, String value) {
    return '$label $value';
  }

  @override
  String get mealMicronutrientsTitle => 'Micronutrients';

  @override
  String get fiberLabel => 'Fiber';

  @override
  String get sodiumLabel => 'Sodium';

  @override
  String gramsValue(String value) {
    return '${value}g';
  }

  @override
  String get otpInvalidCode => 'Invalid OTP. Please try again.';

  @override
  String get otpAccountConflict => 'Unable to create or access this account.';

  @override
  String get otpPhoneLoginUnavailable =>
      'Phone login is currently unavailable.';

  @override
  String get otpConnectionError =>
      'Could not connect. Check your connection and try again.';

  @override
  String get otpServerError => 'Something went wrong. Please try again.';

  @override
  String get otpResendTestUnavailable => 'Resend unavailable in test mode';

  @override
  String get exploreMenu => 'Explore Menu';

  @override
  String get backToDashboard => 'Back to Dashboard';

  @override
  String get dailyNutritionTotal => 'Daily nutrition total';

  @override
  String get nutritionUnavailable => 'Nutrition information unavailable';

  @override
  String get nutritionTotalsIncomplete =>
      'Totals unavailable for missing nutritional values.';

  @override
  String get sugarLabel => 'Sugar';

  @override
  String get saturatedFatLabel => 'Saturated fat';

  @override
  String get transFatLabel => 'Trans fat';

  @override
  String get cholesterolLabel => 'Cholesterol';

  @override
  String nutritionServing(String portion) {
    return 'Per serving: $portion';
  }

  @override
  String get customerUnableToSignIn => 'Unable to sign in';

  @override
  String get customerWeCouldNotLoadTakeawayBranchesPleaseTryAgain =>
      'We could not load takeaway branches. Please try again.';

  @override
  String get customerChooseAFutureDeliveryStartDateTodayAndFriday =>
      'Choose a future delivery start date; today and Friday are unavailable.';

  @override
  String get customerTheSelectedMealConfigurationIsNoLongerAvailable =>
      'The selected meal configuration is no longer available.';

  @override
  String get customerTheSelectedPlanDurationIsNoLongerAvailable =>
      'The selected plan duration is no longer available.';

  @override
  String get customerWeCouldNotVerifyTheSelectedPlanPleaseTry =>
      'We could not verify the selected plan. Please try again.';

  @override
  String get customerDeliveryTimesCouldNotBeLoadedPleaseTryAgain =>
      'Delivery times could not be loaded. Please try again.';

  @override
  String get customerWeCouldNotLoadYourCustomerProfilePleaseSign =>
      'We could not load your customer profile. Please sign in again.';

  @override
  String get customerSavedAddressesCouldNotBeLoadedPleaseTryAgain =>
      'Saved addresses could not be loaded. Please try again.';

  @override
  String get customerYourCustomerProfileIsUnavailablePleaseSignInAgain =>
      'Your customer profile is unavailable. Please sign in again.';

  @override
  String get customerSelectAnActiveDeliveryTimeSlotBeforeSaving =>
      'Select an active delivery time slot before saving.';

  @override
  String get customerYourAddressCouldNotBeSavedPleaseTryAgain =>
      'Your address could not be saved. Please try again.';

  @override
  String get customerWeCouldntPlaceYourOrderPleaseTryAgain =>
      'We couldn\'t place your order. Please try again.';

  @override
  String get customerPleaseCheckYourConnectionAndTryAgain =>
      'Please check your connection and try again.';

  @override
  String get customerThePlanPriceHasChangedPleaseReviewTheUpdated =>
      'The plan price has changed. Please review the updated total before placing your order.';

  @override
  String get customerThisOrderIsAlreadyBeingProcessedPleaseTryAgain =>
      'This order is already being processed. Please try again.';

  @override
  String get customerTheSelectedPlanIsNoLongerAvailablePleaseChoose =>
      'The selected plan is no longer available. Please choose another plan.';

  @override
  String get customerTheSelectedDeliveryAddressIsNoLongerAvailable =>
      'The selected delivery address is no longer available.';

  @override
  String get customerTheSelectedDeliveryTimeIsNoLongerAvailable =>
      'The selected delivery time is no longer available.';

  @override
  String get customerASelectedCheckoutOptionIsNoLongerAvailablePlease =>
      'A selected checkout option is no longer available. Please review your order.';

  @override
  String get customerPleaseReviewYourSelectedMeals =>
      'Please review your selected meals.';

  @override
  String get customerPleaseReviewYourSelectedServiceDays =>
      'Please review your selected service days.';

  @override
  String get customerPleaseSelectAnotherPlanStartDate =>
      'Please select another plan start date.';

  @override
  String get customerCouponCodesAreNotSupportedYetRemoveTheCoupon =>
      'Coupon codes are not supported yet. Remove the coupon and try again.';

  @override
  String get customerYourOrderResponseCouldNotBeConfirmedPleaseCheck =>
      'Your order response could not be confirmed. Please check your orders before trying again.';

  @override
  String get customerSomeAddressInformationWasNotAcceptedPleaseReviewIt =>
      'Some address information was not accepted. Please review it.';

  @override
  String get customerYourSessionExpiredPleaseSignInAgain =>
      'Your session expired. Please sign in again.';

  @override
  String get customerWeCouldNotLoadYourProfile =>
      'We could not load your profile.';

  @override
  String get customerTRYAGAIN => 'TRY AGAIN';

  @override
  String get customerBrowsePlans => 'Browse plans';

  @override
  String get customerDohaQatar => 'Doha, Qatar';

  @override
  String get customerCustomerAddress => 'Customer Address';

  @override
  String get customerDeliveryAddress => 'Delivery Address';

  @override
  String get customerChooseDeliveryAddress => 'Choose Delivery Address';

  @override
  String get customerSelectWhereYouWouldLikeYourMealsDelivered =>
      'Select where you would like your meals delivered.';

  @override
  String get customerLoadingSavedAddresses => 'Loading saved addresses...';

  @override
  String get customerAddAnotherAddress => 'Add Another Address';

  @override
  String get customerUseThisAddress => 'Use This Address';

  @override
  String get customerAddressDetails => 'Address Details';

  @override
  String get customerSavedAddresses => 'Saved addresses';

  @override
  String get customerSAVEASundefined => 'SAVE AS *';

  @override
  String get customerBuildingNoundefined => 'Building No *';

  @override
  String get customerStreetundefined => 'Street *';

  @override
  String get customerUnitNumber => 'Unit Number';

  @override
  String get customerZoneNoundefined => 'Zone No *';

  @override
  String get customerAreaundefined => 'Area *';

  @override
  String get customerDirectionsToReach => 'Directions To Reach';

  @override
  String get customerCallMeWhenYouArrive => 'Call me when you arrive';

  @override
  String get customerSavingAddress => 'Saving Address...';

  @override
  String get customerSaveAddress => 'Save Address';

  @override
  String get customerPinnedLocationQatar => 'Pinned location, Qatar';

  @override
  String get customerSelectAnAddressTypeBeforeSaving =>
      'Select an address type before saving.';

  @override
  String get customerCompleteAllRequiredAddressFields =>
      'Complete all required address fields.';

  @override
  String get customerSelectADeliveryTimeSlotBeforeSaving =>
      'Select a delivery time slot before saving.';

  @override
  String get customerSelectADeliveryAddressOrAddANewOne =>
      'Select a delivery address or add a new one.';

  @override
  String get customerSelectADeliveryTimeSlot => 'Select a delivery time slot.';

  @override
  String get customerEnterAZoneOrAreaToSearch =>
      'Enter a zone or area to search.';

  @override
  String get customerNoMatchingLocationWasFound =>
      'No matching location was found.';

  @override
  String get customerLocationSearchIsUnavailableTryAgainOrMoveThe =>
      'Location search is unavailable. Try again or move the pin.';

  @override
  String get customerTurnOnLocationServicesToContinue =>
      'Turn on location services to continue.';

  @override
  String get customerLocationAccessIsBlockedEnableItInDeviceSettings =>
      'Location access is blocked. Enable it in device settings.';

  @override
  String get customerLocationPermissionIsNeededToFindYourCurrentAddress =>
      'Location permission is needed to find your current address.';

  @override
  String get customerFindingYourCurrentLocation =>
      'Finding your current location...';

  @override
  String get customerCouldNotDetermineYourLocationTryAgainOrMove =>
      'Could not determine your location. Try again or move the pin.';

  @override
  String get customerPinnedLocation => 'Pinned location';

  @override
  String get customerSearchAZone => 'Search a Zone';

  @override
  String get customerCurrentAddress => 'Current Address';

  @override
  String get customerGoogleMapsIsNotConfiguredForThisIOSBuild =>
      'Google Maps is not configured for this iOS build.';

  @override
  String get customerAddTheIOSAPIKeyThenCleanAndRebuild =>
      'Add the iOS API key, then clean and rebuild the app.';

  @override
  String get customerDELIVERYTIMEundefined => 'DELIVERY TIME *';

  @override
  String get customerLoadingDeliveryTimes => 'Loading delivery times...';

  @override
  String get customerNoDeliveryTimeSlotsAreCurrentlyAvailable =>
      'No delivery time slots are currently available.';

  @override
  String get customerDEFAULT => 'DEFAULT';

  @override
  String get customerNoSavedAddressesYet => 'No saved addresses yet';

  @override
  String get customerAddAnAddressForYourMealDeliveries =>
      'Add an address for your meal deliveries.';

  @override
  String get customerAddAddress => 'Add Address';

  @override
  String get customerOrderSubmitted => 'Order Submitted';

  @override
  String get customerOrderConfirmed => 'Order Confirmed!';

  @override
  String get customerYourOrderHasBeenReceivedAndIsAwaitingConfirmation =>
      'Your order has been received and is awaiting confirmation from Diet Time. We\'ll notify you once it\'s reviewed.';

  @override
  String get customerGOTODASHBOARD => 'GO TO DASHBOARD';

  @override
  String get customerORDERNUMBER => 'ORDER NUMBER';

  @override
  String get customerPLAN => 'PLAN';

  @override
  String get customerPAYMENT => 'PAYMENT';

  @override
  String get customerPACKAGE => 'PACKAGE';

  @override
  String get customerFULFILLMENT => 'FULFILLMENT';

  @override
  String get customerTakeaway => 'Takeaway';

  @override
  String get customerPLANPERIOD => 'PLAN PERIOD';

  @override
  String get customerFIRSTCOLLECTION => 'FIRST COLLECTION';

  @override
  String get customerFIRSTDELIVERY => 'FIRST DELIVERY';

  @override
  String get customerDELIVERYTO => 'DELIVERY TO';

  @override
  String get customerTOTAL => 'TOTAL';

  @override
  String get customerSTATUS => 'STATUS';

  @override
  String get customerOrderConfirmationIsUnavailable =>
      'Order confirmation is unavailable.';

  @override
  String get customerVerifyingYourSelectedPlan =>
      'Verifying your selected plan...';

  @override
  String get customerYourPlanDetails => 'Your Plan Details';

  @override
  String get customerThisPackageIsAvailableForTakeawayOnly =>
      'This package is available for takeaway only.';

  @override
  String get customerHomeDelivery => 'Home Delivery';

  @override
  String get customerCOLLECTIONBRANCH => 'COLLECTION BRANCH';

  @override
  String get customerNoTakeawayBranchesAreCurrentlyAvailable =>
      'No takeaway branches are currently available.';

  @override
  String get customerDELIVERYADDRESSTIMESLOT => 'DELIVERY ADDRESS & TIME SLOT';

  @override
  String get customerStartDate => 'Start Date';

  @override
  String get customerSelectYourServiceDates => 'Select your service dates';

  @override
  String get customerOrderTotal => 'Order Total';

  @override
  String get customerPLACEORDER => 'PLACE ORDER';

  @override
  String get customerPLACINGORDER => 'PLACING ORDER...';

  @override
  String get customerPREPARINGORDER => 'PREPARING ORDER...';

  @override
  String get customerNoDeliveryAddressSelected =>
      'No delivery address selected';

  @override
  String get customerAddDeliveryAddress => 'Add Delivery Address';

  @override
  String get customerChange => 'Change';

  @override
  String get customerSelectADeliveryTimeSlot2 => 'Select a delivery time slot';

  @override
  String get customerChooseAMealPlanBeforeReviewingYourSummary =>
      'Choose a meal plan before reviewing your summary.';

  @override
  String get customerBrowsePlans2 => 'Browse Plans';

  @override
  String get customerWeCouldNotLoadYourDashboardPleaseTryAgain =>
      'We could not load your dashboard. Please try again.';

  @override
  String get customerWeCouldNotLoadYourOrdersPleaseTryAgain =>
      'We could not load your orders. Please try again.';

  @override
  String get customerHOME => 'HOME';

  @override
  String get customerORDERS => 'ORDERS';

  @override
  String get customerCALENDAR => 'CALENDAR';

  @override
  String get customerPROFILE => 'PROFILE';

  @override
  String get customerProfileUpdatedSuccessfully =>
      'Profile updated successfully';

  @override
  String get customerUnableToLoadYourProfile => 'Unable to load your profile.';

  @override
  String get customerQuestionnaireUpdatedSuccessfully =>
      'Questionnaire updated successfully';

  @override
  String get customerLogout => 'Logout';

  @override
  String get customerAreYouSureYouWantToLogout =>
      'Are you sure you want to logout?';

  @override
  String get customerCancel => 'Cancel';

  @override
  String get customerYourSessionHasExpiredPleaseSignInAgain =>
      'Your session has expired. Please sign in again.';

  @override
  String get customerSIGNIN => 'SIGN IN';

  @override
  String get customerYourCustomerProfileCouldNotBeFound =>
      'Your customer profile could not be found.';

  @override
  String get customerYOURACTIVEPLAN => 'YOUR ACTIVE PLAN';

  @override
  String get customerMYACTIVEPLANS => 'MY ACTIVE PLANS';

  @override
  String get customerORDERANOTHERPLAN => 'ORDER ANOTHER PLAN';

  @override
  String get customerQUICKACTIONS => 'QUICK ACTIONS';

  @override
  String get customerPREVIOUSORDERS => 'PREVIOUS ORDERS';

  @override
  String get customerMYORDERS => 'MY ORDERS';

  @override
  String get customerVIEWALL => 'VIEW ALL';

  @override
  String get customerNOACTIVEPLAN => 'NO ACTIVE PLAN';

  @override
  String get customerYouDontHaveAnActiveMealPlanRightNow =>
      'You don\'t have an active meal plan right now.';

  @override
  String get customerCHOOSEAPLAN => 'CHOOSE A PLAN';

  @override
  String get customerScheduleReady => 'Schedule ready';

  @override
  String get customerCollectFromDietTime => 'Collect from Diet Time';

  @override
  String get customerVIEWPLAN => 'VIEW PLAN';

  @override
  String get customerDETAILS => 'DETAILS';

  @override
  String get customerMyPlan => 'My Plan';

  @override
  String get customerOrders => 'Orders';

  @override
  String get customerNewPlan => 'New Plan';

  @override
  String get customerSupport => 'Support';

  @override
  String get customerSupportWillBeAvailableSoon =>
      'Support will be available soon.';

  @override
  String get customerDeliveryCalendar => 'Delivery Calendar';

  @override
  String get customerNoActiveDeliveryCalendar => 'No active delivery calendar';

  @override
  String get customerYourDeliveryDatesWillAppearHereWhenAMeal =>
      'Your delivery dates will appear here when a meal plan is active.';

  @override
  String get customerALL => 'ALL';

  @override
  String get customerMyOrders => 'My Orders';

  @override
  String get customerAllYourMealOrdersInOnePlace =>
      'All your meal orders in one place';

  @override
  String get customerAllOrders => 'All Orders';

  @override
  String get customerPendingConfirmation => 'Pending Confirmation';

  @override
  String get customerOnHold => 'On Hold';

  @override
  String get customerRejected => 'Rejected';

  @override
  String get customerPending => 'Pending';

  @override
  String get customerCancelled => 'Cancelled';

  @override
  String get customerNoOrdersFoundForThisStatus =>
      'No orders found for this status.';

  @override
  String get customerOrderPlaced => 'Order placed';

  @override
  String get customerViewDetailsundefined => 'View Details  →';

  @override
  String get customerGoodMorning => 'Good morning';

  @override
  String get customerGoodAfternoon => 'Good afternoon';

  @override
  String get customerGoodEvening => 'Good evening';

  @override
  String get customerYourMealPlanIsActive => 'Your meal plan is active';

  @override
  String get customerReadyWhenYouAre => 'Ready when you are';

  @override
  String get customerYourMealPlansAtAGlance => 'Your meal plans at a glance';

  @override
  String get customerMon => 'Mon';

  @override
  String get customerTue => 'Tue';

  @override
  String get customerWed => 'Wed';

  @override
  String get customerThu => 'Thu';

  @override
  String get customerFri => 'Fri';

  @override
  String get customerSat => 'Sat';

  @override
  String get customerSun => 'Sun';

  @override
  String get customerWeCouldntLoadAllYourDeliveryOrders =>
      'We couldn’t load all your delivery orders.';

  @override
  String get customerUnableToUpdateProfilePleaseTryAgain =>
      'Unable to update profile. Please try again.';

  @override
  String get customerProfile => 'Profile';

  @override
  String get customerCustomerProfile => 'Customer Profile';

  @override
  String get customerViewOrUpdateYourPersonalInformation =>
      'View or update your personal information';

  @override
  String get customerQuestionnaire => 'Questionnaire';

  @override
  String get customerCaptureYourGoalsAndFoodPreferences =>
      'Capture your goals and food preferences';

  @override
  String get customerAddOrEditYourDeliveryAddress =>
      'Add or edit your delivery address';

  @override
  String get customerPleaseSignInAgainToViewYourMeals =>
      'Please sign in again to view your meals.';

  @override
  String get customerWeCouldntLoadYourMealsForThisDayPlease =>
      'We couldn’t load your meals for this day. Please try again.';

  @override
  String get customerTheMenuForThisDateCouldNotBeConfirmed =>
      'The menu for this date could not be confirmed.';

  @override
  String get customerWeveSelectedYourMealsForThisDayYouCan =>
      'We’ve selected your meals for this day. You can change them before the selection deadline.';

  @override
  String get customerTheSelectionDeadlineHasPassedYourMealsAreLocked =>
      'The selection deadline has passed. Your meals are locked for kitchen preparation.';

  @override
  String get customerYourMealsAreReadonlyForThisDay =>
      'Your meals are read-only for this day.';

  @override
  String get customerYourMealsForThisDay => 'Your meals for this day';

  @override
  String get customerYourMealsAreBeingReviewedByOurTeamPlease =>
      'Your meals are being reviewed by our team. Please check back shortly.';

  @override
  String get customerSelectedForYou => 'Selected for you';

  @override
  String get customerYourChoice => 'Your choice';

  @override
  String get customerYourMealChangeHasBeenSaved =>
      'Your meal change has been saved.';

  @override
  String get customerTheSelectionDeadlineHasPassedCloseThisSheetTo =>
      'The selection deadline has passed. Close this sheet to view your saved meals.';

  @override
  String get customerYourChoicesOrSelectionDeadlineHaveChangedCloseThis =>
      'Your choices or selection deadline have changed. Close this sheet and refresh the day.';

  @override
  String get customerThatMealIsNoLongerAvailablePleaseChooseAnother =>
      'That meal is no longer available. Please choose another option or refresh the day.';

  @override
  String get customerWeCouldntSaveThisChangeYourSavedMealsAre =>
      'We couldn’t save this change. Your saved meals are unchanged. Please try again.';

  @override
  String get customerChangeMeal => 'Change meal';

  @override
  String get customerClose => 'Close';

  @override
  String get customerThereAreNoOtherEligibleDishesForThisSelection =>
      'There are no other eligible dishes for this selection on this day.';

  @override
  String get customerSelectedReplacement => 'Selected replacement';

  @override
  String get customerAvailableForThisDay => 'Available for this day';

  @override
  String get customerSavingChanges => 'Saving changes…';

  @override
  String get customerSaveChanges => 'Save Changes';

  @override
  String get customerChangeMeal2 => 'Change Meal';

  @override
  String get customerLoadingMealsForTheSelectedDay =>
      'Loading meals for the selected day';

  @override
  String get customerAutomaticallySelected => 'Automatically Selected';

  @override
  String get customerCustomized => 'Customized';

  @override
  String get customerDelivered => 'Delivered';

  @override
  String get customerOurTeamIsReviewingThisDay =>
      'Our team is reviewing this day';

  @override
  String get customerEditProfile => 'Edit Profile';

  @override
  String get customerFullNameIsRequired => 'Full Name is required.';

  @override
  String get customerFullNameMustBeAtLeast2Characters =>
      'Full Name must be at least 2 characters.';

  @override
  String get customerFullNameMustBe150CharactersOrFewer =>
      'Full Name must be 150 characters or fewer.';

  @override
  String get customerFullName => 'Full Name';

  @override
  String get customerMobileNumber => 'Mobile Number';

  @override
  String get customerContactSupportOrUseChangeMobileNumberToUpdate =>
      'Contact support or use Change Mobile Number to update your login number.';

  @override
  String get customerDateOfBirth => 'Date of Birth';

  @override
  String get customerSaving => 'Saving...';

  @override
  String get customerDiscardChanges => 'Discard changes?';

  @override
  String get customerYouHaveUnsavedChangesAreYouSureYouWant =>
      'You have unsaved changes. Are you sure you want to leave?';

  @override
  String get customerKeepEditing => 'Keep Editing';

  @override
  String get customerDiscard => 'Discard';

  @override
  String get customerBack => 'Back';

  @override
  String get customerOrderDetails => 'Order Details';

  @override
  String get customerRequestCancellation => 'Request cancellation';

  @override
  String get customerTheOrderCouldNotBeCancelledRefreshTheOrder =>
      'The order could not be cancelled. Refresh the order or contact Diet Time.';

  @override
  String get customerMEALSINCLUDED => 'MEALS INCLUDED';

  @override
  String get customerCOLLECTIONDAYS => 'COLLECTION DAYS';

  @override
  String get customerDELIVERYDAYS => 'DELIVERY DAYS';

  @override
  String get customerDELIVERYADDRESS => 'DELIVERY ADDRESS';

  @override
  String get customerDELIVERYTIME => 'DELIVERY TIME';

  @override
  String get customerPRICING => 'PRICING';

  @override
  String get customerPAYMENTSTATUS => 'PAYMENT STATUS';

  @override
  String get customerThankYouForYourOrder => 'Thank you for your order!';

  @override
  String get customerYourPlanAndDeliveryScheduleAreConfirmedAbove =>
      'Your plan and delivery schedule are confirmed above.';

  @override
  String get customerNeedHelp => 'Need Help?';

  @override
  String get customerContactSupport => 'Contact Support';

  @override
  String get customerWeCouldntLoadThisOrder => 'We couldn\'t load this order.';

  @override
  String get customerCancelThisOrder => 'Cancel this order?';

  @override
  String get customerReason => 'Reason';

  @override
  String get customerKeepOrder => 'Keep order';

  @override
  String get customerConfirmCancellation => 'Confirm cancellation';

  @override
  String get customerThisOrderCouldNotBeLoadedForYourAccount =>
      'This order could not be loaded for your account. Refresh your dashboard or contact our team with your order reference.';

  @override
  String get customerWeCouldNotConnectToLoadYourMenuCheck =>
      'We could not connect to load your menu. Check your connection and try again.';

  @override
  String get customerTheMenuServiceCouldNotLoadYourOrdersDishes =>
      'The menu service could not load your order’s dishes. Please refresh or contact our team.';

  @override
  String get customerConfirmYourMeals => 'Confirm your meals';

  @override
  String get customerYourSelectionsCannotBeChangedAfterConfirmation =>
      'Your selections cannot be changed after confirmation.';

  @override
  String get customerConfirm => 'Confirm';

  @override
  String get customerThe900PMDeadlineHasPassedYourAutomaticMeals =>
      'The 9:00 PM deadline has passed. Your automatic meals are being finalized.';

  @override
  String get customerYourMealsHaveAlreadyBeenFinalizedHereAreYour =>
      'Your meals have already been finalized. Here are your saved dishes.';

  @override
  String get customerYourSubscriptionIsNoLongerActiveForThisDelivery =>
      'Your subscription is no longer active for this delivery.';

  @override
  String get customerADishIsNoLongerAvailablePleaseReviewThe =>
      'A dish is no longer available. Please review the refreshed menu.';

  @override
  String get customerWeCouldNotVerifyYourConfirmationPleaseCheckYour =>
      'We could not verify your confirmation. Please check your connection and refresh before trying again.';

  @override
  String get customerUnableToConfirmYourMealsPleaseTryAgain =>
      'Unable to confirm your meals. Please try again.';

  @override
  String get customerTomorrowsMenu => 'Tomorrow’s Menu';

  @override
  String get customerAutomaticallyFinalized => 'Automatically finalized';

  @override
  String get customerHideConfirmedMeals => 'Hide confirmed meals';

  @override
  String get customerSelectionClosesTodayAt900PMQatarTime =>
      'Selection closes today at 9:00 PM Qatar time.';

  @override
  String get customerMeals => 'Meals';

  @override
  String get customerSnacks => 'Snacks';

  @override
  String get customerConfirmMyMeals => 'Confirm My Meals';

  @override
  String get customerReplaceAMeal => 'Replace a meal';

  @override
  String get customerReplaceASnack => 'Replace a snack';

  @override
  String get customerNoEligibleDishesAreCurrentlyConfiguredOurTeamWill =>
      'No eligible dishes are currently configured. Our team will review this delivery.';

  @override
  String get customerUpcomingMeals => 'Upcoming Meals';

  @override
  String get customerWeCouldntLoadAllYourDeliveryMeals =>
      'We couldn’t load all your delivery meals.';

  @override
  String get customerMealsHaveNotBeenAssignedToThisDeliveryYet =>
      'Meals have not been assigned to this delivery yet. Our team will review it.';

  @override
  String get customerMealsChosenForYou => 'Meals chosen for you';

  @override
  String get customerYourChoicesConfirmed => 'Your choices confirmed';

  @override
  String get customerServiceDay => 'Service day';

  @override
  String get customerNonserviceDay => 'Non-service day';

  @override
  String get customerNonservice => 'Non-service';

  @override
  String get customerAutoselected => 'Auto-selected';

  @override
  String get customerDelivery => 'Delivery';

  @override
  String get customerScheduled => 'Scheduled';

  @override
  String get customerNoUpcomingDeliveriesAreScheduled =>
      'No upcoming deliveries are scheduled.';

  @override
  String get customerServiceRunsSaturdayToThursdayFridayIsANonservice =>
      'Service runs Saturday to Thursday. Friday is a non-service day.';

  @override
  String get customerBeingPrepared => 'Being prepared';

  @override
  String get customerOnTheWay => 'On the way';

  @override
  String get customerSkipped => 'Skipped';

  @override
  String get customerChooseYourLanguage => 'Choose your language';

  @override
  String get customerAll => 'All';

  @override
  String get customerYourDraftCouldNotBeSavedPleaseTryAgain =>
      'Your draft could not be saved. Please try again.';

  @override
  String get customerUnableToLoadYourSavedProfile =>
      'Unable to load your saved profile.';

  @override
  String get customerYourProfileChangedElsewhereWeReloadedItPleaseReview =>
      'Your profile changed elsewhere. We reloaded it; please review and retry.';

  @override
  String get customerCouldNotSaveYourProgressCheckYourConnection =>
      'Could not save your progress. Check your connection.';

  @override
  String get customerSelect => 'Select';

  @override
  String get customerNoFoodPreferences => 'No food preferences';

  @override
  String get customerSearchAllergies => 'Search allergies...';

  @override
  String get customerPersonalized => 'Personalized';

  @override
  String get customerBalanced => 'Balanced';

  @override
  String get customerMadeForYou => 'Made for you';

  @override
  String get customerUnableToLoadAllergens => 'Unable to load allergens.';

  @override
  String get customerWellAlwaysHighlightMealsThatAreSafeForYou =>
      'We\'ll always highlight meals that are safe for you.';

  @override
  String get customerNoAllergiesFound => 'No allergies found.';

  @override
  String get customerHeresAQuickOverviewOfYou =>
      'Here\'s a quick overview of you.';

  @override
  String get customerGoal => 'Goal';

  @override
  String get customerActivityLevel => 'Activity Level';

  @override
  String get customerNotCalculatedYet => 'Not calculated yet';

  @override
  String get customerProteinTarget => 'Protein target';

  @override
  String get customerPersonalizeYourDietTimeExperience =>
      'personalize your Diet Time experience.';

  @override
  String get customerYourGoals => 'Your goals';

  @override
  String get customerYourProfile => 'Your profile';

  @override
  String get customerYourLifestyle => 'Your lifestyle';

  @override
  String get customerYourFoodPreferences => 'Your food preferences';

  @override
  String get customerYourHealthAllergies => 'Your health & allergies';

  @override
  String get customerYoureAllSet => 'You\'re all set!';

  @override
  String get customerYouCanNowExploreTheDietTimeMenu =>
      'You can now explore the Diet Time menu.';

  @override
  String get customerWeCouldntLoadYourProfile =>
      'We couldn\'t load your profile.';

  @override
  String get customerWhatShouldWeCallYou => 'What should we call you?';

  @override
  String get customerYourName => 'Your name';

  @override
  String get customerUnableToSaveYourNamePleaseTryAgain =>
      'Unable to save your name. Please try again.';

  @override
  String get customerYourAnswersAreKeptOnThisPhonePleaseRetry =>
      'Your answers are kept on this phone. Please retry saving.';

  @override
  String get customerPickHowManyMealsYoudLikeEachDay =>
      'Pick how many meals you\'d like each day.';

  @override
  String get customerSwipeToExploreMealPackagesundefined =>
      'Swipe to explore meal packages →';

  @override
  String get customerChooseYourDuration => 'Choose your duration';

  @override
  String get customerCurrentlyUnavailable => 'Currently unavailable';

  @override
  String get customerSwipeToExplorePackageDurationsundefined =>
      'Swipe to explore package durations →';

  @override
  String get customerPricingUnavailable => 'Pricing unavailable';

  @override
  String get customerYourAllergenPreferencesAreSaved =>
      'Your allergen preferences are saved';

  @override
  String
  get customerWellUseYourRecordedAllergenInformationWhenShowingSuitable =>
      'We’ll use your recorded allergen information when showing suitable meal choices. Please review each meal’s allergen details before ordering.';

  @override
  String get customerPricingIsTemporarilyUnavailable =>
      'Pricing is temporarily unavailable.';

  @override
  String get customerNoPackagesAreCurrentlyAvailableForThisMealPlan =>
      'No packages are currently available for this meal plan.';

  @override
  String get customerTryAnotherPlanToFindYourDailyMealRoutine =>
      'Try another plan to find your daily meal routine.';

  @override
  String get customerChooseAnotherPlan => 'Choose another plan';

  @override
  String get customerNoMealPlansAreAvailableYet =>
      'No meal plans are available yet.';

  @override
  String get customerUnableToLoadMealPlans => 'Unable to load meal plans.';

  @override
  String get customerChooseANewDeliveryStartDateDeliveryCanStart =>
      'Choose a new delivery start date. Delivery can start tomorrow or later.';

  @override
  String get customerChooseYourStartDate => 'Choose your start date';

  @override
  String get customerTapToChooseAnAvailableServiceDay =>
      'Tap to choose an available service day.';

  @override
  String get customerTapToChooseADifferentServiceDay =>
      'Tap to choose a different service day.';

  @override
  String get customerContinueundefined => 'Continue →';

  @override
  String get customerStartDate2 => 'Start date';

  @override
  String get customerSelectADate => 'Select a date';

  @override
  String get customerEndDate => 'End date';

  @override
  String get customerCalculatedAutomatically => 'Calculated automatically';

  @override
  String get customerSelectYourStartDate => 'Select your start date';

  @override
  String get customerSelectedStartDate => 'Selected start date';

  @override
  String get customerPlanEndDate => 'Plan end date';

  @override
  String get customerPlanServiceDay => 'Plan service day';

  @override
  String get customerFridayUnavailable => 'Friday unavailable';

  @override
  String get customerSelectAStartDate => 'Select a start date';

  @override
  String get customerConfirmDates => 'Confirm Dates';

  @override
  String get customerYourSubscription => 'Your subscription';

  @override
  String get customerActive => 'Active';

  @override
  String get customerCompleted => 'Completed';

  @override
  String get customerPaused => 'Paused';

  @override
  String get customerAwaitingActivation => 'Awaiting Activation';

  @override
  String get customerUnderReview => 'Under Review';

  @override
  String get customerUnpaid => 'Unpaid';

  @override
  String get customerPaymentPending => 'Payment Pending';

  @override
  String get customerPaid => 'Paid';

  @override
  String get customerPaymentFailed => 'Payment Failed';

  @override
  String get customerRefundUnderReview => 'Refund Under Review';

  @override
  String get customerRefunded => 'Refunded';

  @override
  String get customerPartiallyRefunded => 'Partially Refunded';

  @override
  String get customerPaymentUnderReview => 'Payment Under Review';

  @override
  String get customerDietTimeIsReviewingYourOrder =>
      'Diet Time is reviewing your order.';

  @override
  String get customerDietTimeWillReviewYourOrderAndNotifyYou =>
      'Diet Time will review your order and notify you once it is confirmed.';

  @override
  String customerDaysPerWeek(int count) {
    return '$count Days / Week';
  }

  @override
  String customerActivePlans(int count) {
    return 'You have $count active meal plans';
  }

  @override
  String customerOrderReference(String reference) {
    return 'Please reference order $reference.';
  }

  @override
  String get customerSelectionDeadline => 'Selection deadline';

  @override
  String get customerQatarTime => 'Qatar time';

  @override
  String get customerOrderStatus => 'Order status';

  @override
  String get customerSelected => 'selected';

  @override
  String get customerYourOrderIsConfirmedAndAwaitingTheRequiredPayment =>
      'Your order is confirmed and awaiting the required payment.';

  @override
  String get addressHomeLabel => 'Home';

  @override
  String get addressApartmentLabel => 'Apartment';

  @override
  String get addressOfficeLabel => 'Office';

  @override
  String get addressOtherLabel => 'Other';

  @override
  String get reviewPackage => 'Review package';

  @override
  String get packageUnavailable =>
      'The selected meal package is unavailable. Please review your package.';

  @override
  String get durationPricingUnavailable =>
      'Pricing is unavailable for this duration. Please review your package.';

  @override
  String get planPricingMismatch =>
      'The selected plan and pricing do not match. Please review your package.';

  @override
  String get planNotFound =>
      'This meal plan was not found. Please choose another plan.';

  @override
  String get planUnavailable =>
      'This meal plan is no longer available. Please choose another plan.';

  @override
  String get availabilityRetry =>
      'We could not verify this package. Check your connection and retry.';

  @override
  String get saveOrderRetry =>
      'Your order could not be saved. Please retry or contact Diet Time.';

  @override
  String get menuButton => 'Menu';

  @override
  String get dashboardMyPlans => 'My Plans';

  @override
  String get dashboardPendingApproval => 'Pending Approval';

  @override
  String get dashboardAwaitingConfirmation => 'Awaiting Diet Time confirmation';

  @override
  String dashboardPlanCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PLANS',
      one: '1 PLAN',
    );
    return '$_temp0';
  }
}
