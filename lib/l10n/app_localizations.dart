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
  /// **'View Menu'**
  String get onboardingMenu;

  /// No description provided for @onboardingStartPlan.
  ///
  /// In en, this message translates to:
  /// **'Start your Plan'**
  String get onboardingStartPlan;

  /// No description provided for @onboardingBrand.
  ///
  /// In en, this message translates to:
  /// **'Diet Time'**
  String get onboardingBrand;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Diet Time'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Healthy eating made simple.\nLet\'s build a meal plan designed just for you.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingStartJourney.
  ///
  /// In en, this message translates to:
  /// **'Start My Journey'**
  String get onboardingStartJourney;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get onboardingPrevious;

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to achieve?'**
  String get onboardingGoalTitle;

  /// No description provided for @onboardingGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll personalize your meals around your goal.'**
  String get onboardingGoalSubtitle;

  /// No description provided for @onboardingLoseWeight.
  ///
  /// In en, this message translates to:
  /// **'Lose Weight'**
  String get onboardingLoseWeight;

  /// No description provided for @onboardingLoseWeightDescription.
  ///
  /// In en, this message translates to:
  /// **'Burn fat while enjoying satisfying meals.'**
  String get onboardingLoseWeightDescription;

  /// No description provided for @onboardingBuildMuscle.
  ///
  /// In en, this message translates to:
  /// **'Build Muscle'**
  String get onboardingBuildMuscle;

  /// No description provided for @onboardingBuildMuscleDescription.
  ///
  /// In en, this message translates to:
  /// **'Protein-focused meals to support strength.'**
  String get onboardingBuildMuscleDescription;

  /// No description provided for @onboardingStayHealthy.
  ///
  /// In en, this message translates to:
  /// **'Stay Healthy'**
  String get onboardingStayHealthy;

  /// No description provided for @onboardingStayHealthyDescription.
  ///
  /// In en, this message translates to:
  /// **'Balanced nutrition for everyday wellness.'**
  String get onboardingStayHealthyDescription;

  /// No description provided for @onboardingImproveFitness.
  ///
  /// In en, this message translates to:
  /// **'Improve Fitness'**
  String get onboardingImproveFitness;

  /// No description provided for @onboardingImproveFitnessDescription.
  ///
  /// In en, this message translates to:
  /// **'Fuel your body for an active lifestyle.'**
  String get onboardingImproveFitnessDescription;

  /// No description provided for @onboardingProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get to know you'**
  String get onboardingProfileTitle;

  /// No description provided for @onboardingProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A few details help us tailor every meal to you.'**
  String get onboardingProfileSubtitle;

  /// No description provided for @onboardingGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get onboardingGender;

  /// No description provided for @onboardingAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get onboardingAge;

  /// No description provided for @onboardingHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get onboardingHeight;

  /// No description provided for @onboardingWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get onboardingWeight;

  /// No description provided for @onboardingMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get onboardingMale;

  /// No description provided for @onboardingFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get onboardingFemale;

  /// No description provided for @onboardingPreferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get onboardingPreferNotToSay;

  /// No description provided for @onboardingLifestyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your daily routine'**
  String get onboardingLifestyleTitle;

  /// No description provided for @onboardingLifestyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the option that feels most like your day.'**
  String get onboardingLifestyleSubtitle;

  /// No description provided for @onboardingOfficeWork.
  ///
  /// In en, this message translates to:
  /// **'Office Work'**
  String get onboardingOfficeWork;

  /// No description provided for @onboardingWorkFromHome.
  ///
  /// In en, this message translates to:
  /// **'Work From Home'**
  String get onboardingWorkFromHome;

  /// No description provided for @onboardingStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get onboardingStudent;

  /// No description provided for @onboardingActiveJob.
  ///
  /// In en, this message translates to:
  /// **'Active Job'**
  String get onboardingActiveJob;

  /// No description provided for @onboardingShiftWorker.
  ///
  /// In en, this message translates to:
  /// **'Shift Worker'**
  String get onboardingShiftWorker;

  /// No description provided for @onboardingActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'How active are you?'**
  String get onboardingActivityTitle;

  /// No description provided for @onboardingActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll balance your meals around your energy needs.'**
  String get onboardingActivitySubtitle;

  /// No description provided for @onboardingMostlySitting.
  ///
  /// In en, this message translates to:
  /// **'Mostly Sitting'**
  String get onboardingMostlySitting;

  /// No description provided for @onboardingLightActivity.
  ///
  /// In en, this message translates to:
  /// **'Light Activity'**
  String get onboardingLightActivity;

  /// No description provided for @onboardingActiveLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Active Lifestyle'**
  String get onboardingActiveLifestyle;

  /// No description provided for @onboardingAthlete.
  ///
  /// In en, this message translates to:
  /// **'Athlete'**
  String get onboardingAthlete;

  /// No description provided for @onboardingPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you enjoy eating?'**
  String get onboardingPreferencesTitle;

  /// No description provided for @onboardingPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select as many as you like.'**
  String get onboardingPreferencesSubtitle;

  /// No description provided for @onboardingHighProtein.
  ///
  /// In en, this message translates to:
  /// **'High Protein'**
  String get onboardingHighProtein;

  /// No description provided for @onboardingLowCarb.
  ///
  /// In en, this message translates to:
  /// **'Low Carb'**
  String get onboardingLowCarb;

  /// No description provided for @onboardingVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get onboardingVegetarian;

  /// No description provided for @onboardingVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get onboardingVegan;

  /// No description provided for @onboardingSeafood.
  ///
  /// In en, this message translates to:
  /// **'Seafood'**
  String get onboardingSeafood;

  /// No description provided for @onboardingChicken.
  ///
  /// In en, this message translates to:
  /// **'Chicken'**
  String get onboardingChicken;

  /// No description provided for @onboardingBeef.
  ///
  /// In en, this message translates to:
  /// **'Beef'**
  String get onboardingBeef;

  /// No description provided for @onboardingArabicCuisine.
  ///
  /// In en, this message translates to:
  /// **'Arabic Cuisine'**
  String get onboardingArabicCuisine;

  /// No description provided for @onboardingInternational.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get onboardingInternational;

  /// No description provided for @onboardingMediterranean.
  ///
  /// In en, this message translates to:
  /// **'Mediterranean'**
  String get onboardingMediterranean;

  /// No description provided for @onboardingHealthySnacks.
  ///
  /// In en, this message translates to:
  /// **'Healthy Snacks'**
  String get onboardingHealthySnacks;

  /// No description provided for @onboardingBreakfastLover.
  ///
  /// In en, this message translates to:
  /// **'Breakfast Lover'**
  String get onboardingBreakfastLover;

  /// No description provided for @onboardingAllergiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Any food allergies?'**
  String get onboardingAllergiesTitle;

  /// No description provided for @onboardingAllergiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select everything we should keep in mind.'**
  String get onboardingAllergiesSubtitle;

  /// No description provided for @onboardingMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get onboardingMilk;

  /// No description provided for @onboardingEgg.
  ///
  /// In en, this message translates to:
  /// **'Egg'**
  String get onboardingEgg;

  /// No description provided for @onboardingFish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get onboardingFish;

  /// No description provided for @onboardingShellfish.
  ///
  /// In en, this message translates to:
  /// **'Shellfish'**
  String get onboardingShellfish;

  /// No description provided for @onboardingTreeNuts.
  ///
  /// In en, this message translates to:
  /// **'Tree Nuts'**
  String get onboardingTreeNuts;

  /// No description provided for @onboardingPeanuts.
  ///
  /// In en, this message translates to:
  /// **'Peanuts'**
  String get onboardingPeanuts;

  /// No description provided for @onboardingSoy.
  ///
  /// In en, this message translates to:
  /// **'Soy'**
  String get onboardingSoy;

  /// No description provided for @onboardingSesame.
  ///
  /// In en, this message translates to:
  /// **'Sesame'**
  String get onboardingSesame;

  /// No description provided for @onboardingGluten.
  ///
  /// In en, this message translates to:
  /// **'Gluten'**
  String get onboardingGluten;

  /// No description provided for @onboardingNoAllergies.
  ///
  /// In en, this message translates to:
  /// **'No Allergies'**
  String get onboardingNoAllergies;

  /// No description provided for @onboardingBuildingTitle.
  ///
  /// In en, this message translates to:
  /// **'Creating your personalized meal plan'**
  String get onboardingBuildingTitle;

  /// No description provided for @onboardingBuildingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re preparing meals that match your goals, lifestyle and preferences.'**
  String get onboardingBuildingSubtitle;

  /// No description provided for @onboardingReadyAction.
  ///
  /// In en, this message translates to:
  /// **'View My Options'**
  String get onboardingReadyAction;

  /// No description provided for @personalizationIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s shape your plan'**
  String get personalizationIntroTitle;

  /// No description provided for @personalizationIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answer a few simple questions so we can recommend meals that suit your goals, routine, and preferences.'**
  String get personalizationIntroSubtitle;

  /// No description provided for @personalizationBegin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get personalizationBegin;

  /// No description provided for @personalizationNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get personalizationNotNow;

  /// No description provided for @personalizationSelectOption.
  ///
  /// In en, this message translates to:
  /// **'Choose an option to continue.'**
  String get personalizationSelectOption;

  /// No description provided for @onboardingMaintainWeight.
  ///
  /// In en, this message translates to:
  /// **'Maintain Weight'**
  String get onboardingMaintainWeight;

  /// No description provided for @onboardingMaintainWeightDescription.
  ///
  /// In en, this message translates to:
  /// **'Balanced meals that support your current routine.'**
  String get onboardingMaintainWeightDescription;

  /// No description provided for @onboardingGainWeight.
  ///
  /// In en, this message translates to:
  /// **'Gain Weight'**
  String get onboardingGainWeight;

  /// No description provided for @onboardingGainWeightDescription.
  ///
  /// In en, this message translates to:
  /// **'Nourishing meals with the energy your goals need.'**
  String get onboardingGainWeightDescription;

  /// No description provided for @onboardingEatHealthier.
  ///
  /// In en, this message translates to:
  /// **'Eat Healthier'**
  String get onboardingEatHealthier;

  /// No description provided for @onboardingEatHealthierDescription.
  ///
  /// In en, this message translates to:
  /// **'Make wholesome everyday choices easier.'**
  String get onboardingEatHealthierDescription;

  /// No description provided for @bmiSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your wellness snapshot'**
  String get bmiSummaryTitle;

  /// No description provided for @bmiCalculatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Your calculated BMI'**
  String get bmiCalculatedLabel;

  /// No description provided for @bmiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'BMI is a general screening measure and does not account for muscle mass, body composition, age, or individual health conditions.'**
  String get bmiDisclaimer;

  /// No description provided for @bmiYouthNote.
  ///
  /// In en, this message translates to:
  /// **'Children and teenagers require age- and sex-specific assessment.'**
  String get bmiYouthNote;

  /// No description provided for @bmiBelowRange.
  ///
  /// In en, this message translates to:
  /// **'Below standard range'**
  String get bmiBelowRange;

  /// No description provided for @bmiWithinRange.
  ///
  /// In en, this message translates to:
  /// **'Within standard range'**
  String get bmiWithinRange;

  /// No description provided for @bmiAboveRange.
  ///
  /// In en, this message translates to:
  /// **'Above standard range'**
  String get bmiAboveRange;

  /// No description provided for @bmiWellAboveRange.
  ///
  /// In en, this message translates to:
  /// **'Well above standard range'**
  String get bmiWellAboveRange;

  /// No description provided for @allergySafetyNote.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use this information to highlight meals that may not be suitable for you. Always review the meal\'s ingredient and allergen details before ordering.'**
  String get allergySafetyNote;

  /// No description provided for @recommendationTitle.
  ///
  /// In en, this message translates to:
  /// **'A plan that fits your routine'**
  String get recommendationTitle;

  /// No description provided for @recommendationReasonGoal.
  ///
  /// In en, this message translates to:
  /// **'Matches your primary goal'**
  String get recommendationReasonGoal;

  /// No description provided for @recommendationReasonActivity.
  ///
  /// In en, this message translates to:
  /// **'Fits your activity level'**
  String get recommendationReasonActivity;

  /// No description provided for @recommendationReasonPreferences.
  ///
  /// In en, this message translates to:
  /// **'Includes your preferred meal styles'**
  String get recommendationReasonPreferences;

  /// No description provided for @recommendationReasonAllergens.
  ///
  /// In en, this message translates to:
  /// **'Considers your recorded allergens'**
  String get recommendationReasonAllergens;

  /// No description provided for @viewRecommendedPlan.
  ///
  /// In en, this message translates to:
  /// **'View Recommended Plan'**
  String get viewRecommendedPlan;

  /// No description provided for @compareAllPlans.
  ///
  /// In en, this message translates to:
  /// **'Compare All Plans'**
  String get compareAllPlans;

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

  /// No description provided for @dailyPlanPrice.
  ///
  /// In en, this message translates to:
  /// **'{currency} {amount} / day'**
  String dailyPlanPrice(String currency, String amount);

  /// No description provided for @dailyPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily price'**
  String get dailyPriceLabel;

  /// No description provided for @dailyPriceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Daily price unavailable'**
  String get dailyPriceUnavailable;

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
  /// **'Show all'**
  String get showAllIngredients;

  /// No description provided for @noIngredientsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No ingredient information available.'**
  String get noIngredientsAvailable;

  /// No description provided for @noAllergensListed.
  ///
  /// In en, this message translates to:
  /// **'No allergens recorded.'**
  String get noAllergensListed;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

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

  String get otpInvalidCode;
  String get otpAccountConflict;
  String get otpPhoneLoginUnavailable;
  String get otpConnectionError;
  String get otpServerError;
  String get otpResendTestUnavailable;
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
