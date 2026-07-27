import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Diet Time'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Fuel Right. Feel Light.'**
  String get tagline;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthy;

  /// No description provided for @journeyStartsHere.
  ///
  /// In en, this message translates to:
  /// **'Your journey starts here.'**
  String get journeyStartsHere;

  /// No description provided for @landingTitle.
  ///
  /// In en, this message translates to:
  /// **'Eat Well, Feel Great'**
  String get landingTitle;

  /// No description provided for @landingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover tailored meal plans designed for flavor and health. Build lasting habits, one delicious meal at a time.'**
  String get landingSubtitle;

  /// No description provided for @viewPlans.
  ///
  /// In en, this message translates to:
  /// **'The Plans'**
  String get viewPlans;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your healthy journey.'**
  String get loginSubtitle;

  /// No description provided for @emailOrMobile.
  ///
  /// In en, this message translates to:
  /// **'Email / Mobile'**
  String get emailOrMobile;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'OR CONTINUE WITH'**
  String get orContinueWith;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orSignInWith.
  ///
  /// In en, this message translates to:
  /// **'or sign in with'**
  String get orSignInWith;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidEmailOrMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address or mobile number'**
  String get invalidEmailOrMobile;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @homeScreen.
  ///
  /// In en, this message translates to:
  /// **'Home Screen'**
  String get homeScreen;

  /// No description provided for @postLoginWelcomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Diet Time'**
  String get postLoginWelcomeLabel;

  /// No description provided for @postLoginAccountReady.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready'**
  String get postLoginAccountReady;

  /// No description provided for @postLoginTitleLead.
  ///
  /// In en, this message translates to:
  /// **'Your plan starts'**
  String get postLoginTitleLead;

  /// No description provided for @postLoginTitleAccent.
  ///
  /// In en, this message translates to:
  /// **'with you'**
  String get postLoginTitleAccent;

  /// No description provided for @postLoginSupporting.
  ///
  /// In en, this message translates to:
  /// **'Tell us a little about your routine, goals, and food preferences.'**
  String get postLoginSupporting;

  /// No description provided for @postLoginSecondary.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use your answers to shape a plan that feels practical, balanced, and easy to follow.'**
  String get postLoginSecondary;

  /// No description provided for @postLoginCta.
  ///
  /// In en, this message translates to:
  /// **'Personalize My Plan'**
  String get postLoginCta;

  /// No description provided for @postLoginMealBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced meals'**
  String get postLoginMealBalanced;

  /// No description provided for @postLoginMealFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible choices'**
  String get postLoginMealFlexible;

  /// No description provided for @postLoginMealGoals.
  ///
  /// In en, this message translates to:
  /// **'Built around your goals'**
  String get postLoginMealGoals;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @onboardingHealthyMealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Healthy Meals,'**
  String get onboardingHealthyMealsTitle;

  /// No description provided for @onboardingHealthyMealsAccent.
  ///
  /// In en, this message translates to:
  /// **'Made Simple.'**
  String get onboardingHealthyMealsAccent;

  /// No description provided for @onboardingHealthyMealsDescription.
  ///
  /// In en, this message translates to:
  /// **'Delicious, balanced meals delivered daily to support your healthy lifestyle.'**
  String get onboardingHealthyMealsDescription;

  /// No description provided for @onboardingPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Plans That Fit'**
  String get onboardingPlansTitle;

  /// No description provided for @onboardingPlansAccent.
  ///
  /// In en, this message translates to:
  /// **'You Perfectly'**
  String get onboardingPlansAccent;

  /// No description provided for @onboardingPlansDescription.
  ///
  /// In en, this message translates to:
  /// **'Tell us your goals, we\'ll handle the rest with personalised plans just for you.'**
  String get onboardingPlansDescription;

  /// No description provided for @onboardingFreshTitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh. Clean.'**
  String get onboardingFreshTitle;

  /// No description provided for @onboardingFreshAccent.
  ///
  /// In en, this message translates to:
  /// **'Always.'**
  String get onboardingFreshAccent;

  /// No description provided for @onboardingFreshDescription.
  ///
  /// In en, this message translates to:
  /// **'We use real ingredients with no artificial colors, preservatives or unhealthy fillers.'**
  String get onboardingFreshDescription;

  /// No description provided for @onboardingTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Track. Improve.'**
  String get onboardingTrackTitle;

  /// No description provided for @onboardingTrackAccent.
  ///
  /// In en, this message translates to:
  /// **'Live Better.'**
  String get onboardingTrackAccent;

  /// No description provided for @onboardingTrackDescription.
  ///
  /// In en, this message translates to:
  /// **'Simple tracking helps you stay consistent and achieve your health goals.'**
  String get onboardingTrackDescription;

  /// No description provided for @onboardingBmiTitle.
  ///
  /// In en, this message translates to:
  /// **'Know Your BMI,'**
  String get onboardingBmiTitle;

  /// No description provided for @onboardingBmiAccent.
  ///
  /// In en, this message translates to:
  /// **'Build a Better Plan'**
  String get onboardingBmiAccent;

  /// No description provided for @onboardingBmiDescription.
  ///
  /// In en, this message translates to:
  /// **'Calculate your BMI and get a plan shaped around your body and goals.'**
  String get onboardingBmiDescription;

  /// No description provided for @onboardingTogetherTitle.
  ///
  /// In en, this message translates to:
  /// **'Better Together,'**
  String get onboardingTogetherTitle;

  /// No description provided for @onboardingTogetherAccent.
  ///
  /// In en, this message translates to:
  /// **'Stronger Together'**
  String get onboardingTogetherAccent;

  /// No description provided for @onboardingTogetherDescription.
  ///
  /// In en, this message translates to:
  /// **'Invite friends, share your journey and achieve more together.'**
  String get onboardingTogetherDescription;

  /// No description provided for @onboardingMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get onboardingMenu;

  /// No description provided for @onboardingStartPlan.
  ///
  /// In en, this message translates to:
  /// **'Start your Plan'**
  String get onboardingStartPlan;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your Language'**
  String get chooseLanguage;

  /// No description provided for @languageSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language to personalize your experience.'**
  String get languageSelectionSubtitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save language preference. Please try again.'**
  String get languageSaveError;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @pageProgress.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageProgress(int current, int total);

  /// No description provided for @browseMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh choices, made for you'**
  String get browseMenuTitle;

  /// No description provided for @browseMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore chef-crafted meals prepared with wholesome ingredients.'**
  String get browseMenuSubtitle;

  /// No description provided for @browseMenu.
  ///
  /// In en, this message translates to:
  /// **'Browse Menu'**
  String get browseMenu;

  /// No description provided for @popularMeals.
  ///
  /// In en, this message translates to:
  /// **'Popular meals'**
  String get popularMeals;

  /// No description provided for @mealGrilledChicken.
  ///
  /// In en, this message translates to:
  /// **'Herb Grilled Chicken'**
  String get mealGrilledChicken;

  /// No description provided for @mealGrilledChickenDetail.
  ///
  /// In en, this message translates to:
  /// **'Brown rice, greens & tahini'**
  String get mealGrilledChickenDetail;

  /// No description provided for @mealSalmon.
  ///
  /// In en, this message translates to:
  /// **'Citrus Salmon Bowl'**
  String get mealSalmon;

  /// No description provided for @mealSalmonDetail.
  ///
  /// In en, this message translates to:
  /// **'Quinoa, avocado & edamame'**
  String get mealSalmonDetail;

  /// No description provided for @mealKeto.
  ///
  /// In en, this message translates to:
  /// **'Keto Beef Garden'**
  String get mealKeto;

  /// No description provided for @mealKetoDetail.
  ///
  /// In en, this message translates to:
  /// **'Roasted vegetables & herbs'**
  String get mealKetoDetail;

  /// No description provided for @kcal.
  ///
  /// In en, this message translates to:
  /// **'{value} kcal'**
  String kcal(int value);

  /// No description provided for @choosePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Meal Plan'**
  String get choosePlanTitle;

  /// No description provided for @choosePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the plan that matches your goals. You can change it anytime.'**
  String get choosePlanSubtitle;

  /// No description provided for @weightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight Loss'**
  String get weightLoss;

  /// No description provided for @weightLossDescription.
  ///
  /// In en, this message translates to:
  /// **'Balanced portions designed for steady, sustainable progress.'**
  String get weightLossDescription;

  /// No description provided for @keto.
  ///
  /// In en, this message translates to:
  /// **'Keto'**
  String get keto;

  /// No description provided for @ketoDescription.
  ///
  /// In en, this message translates to:
  /// **'Low-carb favorites rich in healthy fats and fresh produce.'**
  String get ketoDescription;

  /// No description provided for @highProtein.
  ///
  /// In en, this message translates to:
  /// **'High Protein'**
  String get highProtein;

  /// No description provided for @highProteinDescription.
  ///
  /// In en, this message translates to:
  /// **'Protein-forward meals to support strength and recovery.'**
  String get highProteinDescription;

  /// No description provided for @balancedDiet.
  ///
  /// In en, this message translates to:
  /// **'Balanced Diet'**
  String get balancedDiet;

  /// No description provided for @balancedDietDescription.
  ///
  /// In en, this message translates to:
  /// **'Everyday nutrition with a delicious mix of all food groups.'**
  String get balancedDietDescription;

  /// No description provided for @dailyCalories.
  ///
  /// In en, this message translates to:
  /// **'{value} kcal / day'**
  String dailyCalories(int value);

  /// No description provided for @weeklyPrice.
  ///
  /// In en, this message translates to:
  /// **'QAR {value} / week'**
  String weeklyPrice(int value);

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @otpPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Get Started'**
  String get otpPhoneTitle;

  /// No description provided for @otpPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number to continue.'**
  String get otpPhoneSubtitle;

  /// No description provided for @otpPhoneHelper.
  ///
  /// In en, this message translates to:
  /// **'We will send you a 6-digit verification code.'**
  String get otpPhoneHelper;

  /// No description provided for @otpMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get otpMobileNumber;

  /// No description provided for @otpInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number.'**
  String get otpInvalidPhone;

  /// No description provided for @otpRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to send the verification code. Please try again.'**
  String get otpRequestFailed;

  /// No description provided for @otpCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the Code'**
  String get otpCodeTitle;

  /// No description provided for @otpCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A 6-digit verification code was sent to:'**
  String get otpCodeSubtitle;

  /// No description provided for @otpCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to'**
  String get otpCodeSentTo;

  /// No description provided for @otpCodeEntryHelper.
  ///
  /// In en, this message translates to:
  /// **'Please enter the code automatically detected or type it manually'**
  String get otpCodeEntryHelper;

  /// No description provided for @otpEditPhone.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get otpEditPhone;

  /// No description provided for @otpDidntGetCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get the code?'**
  String get otpDidntGetCode;

  /// No description provided for @otpVerifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get otpVerifyCode;

  /// No description provided for @otpResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResendCode;

  /// No description provided for @otpResendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String otpResendCountdown(String time);

  /// No description provided for @otpSendViaSms.
  ///
  /// In en, this message translates to:
  /// **'Send via SMS'**
  String get otpSendViaSms;

  /// No description provided for @otpSendViaWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Send via WhatsApp'**
  String get otpSendViaWhatsapp;

  /// No description provided for @otpResendViaWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Resend via WhatsApp'**
  String get otpResendViaWhatsapp;

  /// No description provided for @otpDevelopmentCode.
  ///
  /// In en, this message translates to:
  /// **'Development code: {code}'**
  String otpDevelopmentCode(String code);

  /// No description provided for @otpIncorrectCode.
  ///
  /// In en, this message translates to:
  /// **'The verification code is incorrect. Please try again.'**
  String get otpIncorrectCode;

  /// No description provided for @otpExpiredCode.
  ///
  /// In en, this message translates to:
  /// **'This verification code has expired. Request a new code.'**
  String get otpExpiredCode;

  /// No description provided for @otpTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get otpTooManyAttempts;

  /// No description provided for @otpResendUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Resend is temporarily unavailable. Please try again.'**
  String get otpResendUnavailable;

  /// No description provided for @otpResendConfirmation.
  ///
  /// In en, this message translates to:
  /// **'A new verification code has been sent.'**
  String get otpResendConfirmation;

  /// No description provided for @otpWhatsappTestGenerated.
  ///
  /// In en, this message translates to:
  /// **'Test code generated for WhatsApp verification.'**
  String get otpWhatsappTestGenerated;

  /// No description provided for @mealPlanHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Plan'**
  String get mealPlanHeaderTitle;

  /// No description provided for @mealPlanHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan that fits your lifestyle and goals.'**
  String get mealPlanHeaderSubtitle;

  /// No description provided for @planSwitchLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing your new plan'**
  String get planSwitchLoadingTitle;

  /// No description provided for @planSwitchLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re organizing the best meals for you...'**
  String get planSwitchLoadingSubtitle;

  /// No description provided for @mealContentLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cooking up something healthy!'**
  String get mealContentLoadingTitle;

  /// No description provided for @mealContentLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetching today\'s meals...'**
  String get mealContentLoadingSubtitle;

  /// No description provided for @guestMealPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your plan'**
  String get guestMealPlansTitle;

  /// No description provided for @selectMealPlanSemantics.
  ///
  /// In en, this message translates to:
  /// **'Select {planName} meal plan'**
  String selectMealPlanSemantics(String planName);

  /// No description provided for @guestWeeklyMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'This week\'s menu'**
  String get guestWeeklyMenuTitle;

  /// No description provided for @guestMenuLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the menu.'**
  String get guestMenuLoadError;

  /// No description provided for @guestPlanLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load this meal plan.'**
  String get guestPlanLoadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noMealsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No meals available for this selection.'**
  String get noMealsAvailable;

  /// No description provided for @noMealsAvailableForPlan.
  ///
  /// In en, this message translates to:
  /// **'No meals available for this plan.'**
  String get noMealsAvailableForPlan;

  /// No description provided for @tryAnotherMealFilter.
  ///
  /// In en, this message translates to:
  /// **'Try another date or meal category.'**
  String get tryAnotherMealFilter;

  /// No description provided for @caloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesLabel;

  /// No description provided for @proteinLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get proteinLabel;

  /// No description provided for @carbsLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbsLabel;

  /// No description provided for @fatLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fatLabel;

  /// No description provided for @mealIngredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get mealIngredientsTitle;

  /// No description provided for @mealAllergensTitle.
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get mealAllergensTitle;

  /// No description provided for @showAllIngredients.
  ///
  /// In en, this message translates to:
  /// **'Show all ingredients'**
  String get showAllIngredients;

  /// No description provided for @noAllergensListed.
  ///
  /// In en, this message translates to:
  /// **'No allergens listed'**
  String get noAllergensListed;

  /// No description provided for @allergenContains.
  ///
  /// In en, this message translates to:
  /// **'Contains {name}'**
  String allergenContains(String name);

  /// No description provided for @allergenMayContain.
  ///
  /// In en, this message translates to:
  /// **'May contain {name}'**
  String allergenMayContain(String name);

  /// No description provided for @allergenTraces.
  ///
  /// In en, this message translates to:
  /// **'Traces of {name}'**
  String allergenTraces(String name);

  /// No description provided for @nutritionItemSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label} {value}'**
  String nutritionItemSemantics(String label, String value);

  /// No description provided for @mealMicronutrientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Micronutrients'**
  String get mealMicronutrientsTitle;

  /// No description provided for @fiberLabel.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get fiberLabel;

  /// No description provided for @sodiumLabel.
  ///
  /// In en, this message translates to:
  /// **'Sodium'**
  String get sodiumLabel;

  /// No description provided for @gramsValue.
  ///
  /// In en, this message translates to:
  /// **'{value}g'**
  String gramsValue(String value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
