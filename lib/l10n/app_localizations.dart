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

  /// No description provided for @guestMealPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your lifestyle plan'**
  String get guestMealPlansTitle;

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

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noMealsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No meals available.'**
  String get noMealsAvailable;

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
