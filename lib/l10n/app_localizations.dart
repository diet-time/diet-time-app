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

  /// No description provided for @deliveriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow’s Deliveries'**
  String get deliveriesTitle;

  /// No description provided for @deliveriesScheduled.
  ///
  /// In en, this message translates to:
  /// **'{count} scheduled {count, plural, =1{order} other{orders}}'**
  String deliveriesScheduled(int count);

  /// No description provided for @deliveriesOrder.
  ///
  /// In en, this message translates to:
  /// **'Order: {reference}'**
  String deliveriesOrder(String reference);

  /// No description provided for @deliveriesConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get deliveriesConfirmed;

  /// No description provided for @deliveriesPending.
  ///
  /// In en, this message translates to:
  /// **'Selection pending'**
  String get deliveriesPending;

  /// No description provided for @deliveriesReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to confirm'**
  String get deliveriesReady;

  /// No description provided for @deliveriesAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatically selected'**
  String get deliveriesAutomatic;

  /// No description provided for @deliveriesLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get deliveriesLocked;

  /// No description provided for @deliveriesReviewConfirm.
  ///
  /// In en, this message translates to:
  /// **'Review & confirm'**
  String get deliveriesReviewConfirm;

  /// No description provided for @deliveriesViewConfirmed.
  ///
  /// In en, this message translates to:
  /// **'View confirmed meals'**
  String get deliveriesViewConfirmed;

  /// No description provided for @deliveriesViewSelected.
  ///
  /// In en, this message translates to:
  /// **'View selected meals'**
  String get deliveriesViewSelected;

  /// No description provided for @deliveriesViewMenu.
  ///
  /// In en, this message translates to:
  /// **'View menu'**
  String get deliveriesViewMenu;

  /// No description provided for @deliveriesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to load all deliveries'**
  String get deliveriesUnavailable;

  /// No description provided for @deliveriesActionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Action needed'**
  String get deliveriesActionNeeded;

  /// No description provided for @deliveriesWaiting.
  ///
  /// In en, this message translates to:
  /// **'Delivery update'**
  String get deliveriesWaiting;

  /// No description provided for @deliveriesPackage.
  ///
  /// In en, this message translates to:
  /// **'{meals} Meals + {snacks} {snacks, plural, =1{Snack} other{Snacks}}'**
  String deliveriesPackage(int meals, int snacks);

  /// No description provided for @deliveriesAllConfirmed.
  ///
  /// In en, this message translates to:
  /// **'All {count} dishes confirmed'**
  String deliveriesAllConfirmed(int count);

  /// No description provided for @deliveriesViewDishes.
  ///
  /// In en, this message translates to:
  /// **'View your dishes'**
  String get deliveriesViewDishes;

  /// No description provided for @deliveriesHideDishes.
  ///
  /// In en, this message translates to:
  /// **'Hide your dishes'**
  String get deliveriesHideDishes;

  /// No description provided for @deliveriesProgress.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total} selected'**
  String deliveriesProgress(int selected, int total);

  /// No description provided for @deliveriesDeadline.
  ///
  /// In en, this message translates to:
  /// **'Choose before 9:00 PM'**
  String get deliveriesDeadline;

  /// No description provided for @deliveriesChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose your meals'**
  String get deliveriesChoose;

  /// No description provided for @deliveriesRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh menu'**
  String get deliveriesRefresh;

  /// No description provided for @deliveriesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading deliveries…'**
  String get deliveriesLoading;

  /// No description provided for @deliveriesMeal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get deliveriesMeal;

  /// No description provided for @deliveriesSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get deliveriesSnack;

  /// No description provided for @deliveriesViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get deliveriesViewDetails;

  /// No description provided for @deliveriesFirstDelivery.
  ///
  /// In en, this message translates to:
  /// **'First delivery: {date}'**
  String deliveriesFirstDelivery(String date);

  /// No description provided for @deliveriesStatus.
  ///
  /// In en, this message translates to:
  /// **'{status, select, NO_ORDER{No order is linked to your account.} PENDING_ACTIVATION{Your order is saved and is waiting for activation.} NOT_STARTED{Your plan starts soon. Selection opens the day before your first delivery.} NO_DELIVERY{No delivery is scheduled for tomorrow.} SERVICE_DAYS_MISSING{Your order is saved, but its delivery schedule needs to be initialized by our team.} SERVICE_DAY_INCOMPLETE{Your delivery details need review by our team.} SCHEDULE_NOT_CONFIGURED{Your order’s delivery weekdays need review by our team.} MENU_NOT_CONFIGURED{Your order is saved. Tomorrow’s dishes have not been configured yet.} SELECTION_NOT_OPEN{Selection opens the day before your delivery.} FINALIZATION_PENDING{The 9:00 PM selection window has closed. Your automatic meals are being finalized.} INACTIVE_ORDER{This order is not active for meal selection.} LOCKED{Your meal selections are locked for preparation.} NEEDS_REVIEW{Our team needs to review suitable dishes for your package.} other{Please choose your meals for tomorrow.}}'**
  String deliveriesStatus(String status);

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

  /// No description provided for @otpInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Please try again.'**
  String get otpInvalidCode;

  /// No description provided for @otpAccountConflict.
  ///
  /// In en, this message translates to:
  /// **'Unable to create or access this account.'**
  String get otpAccountConflict;

  /// No description provided for @otpPhoneLoginUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Phone login is currently unavailable.'**
  String get otpPhoneLoginUnavailable;

  /// No description provided for @otpConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check your connection and try again.'**
  String get otpConnectionError;

  /// No description provided for @otpServerError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get otpServerError;

  /// No description provided for @otpResendTestUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Resend unavailable in test mode'**
  String get otpResendTestUnavailable;

  /// No description provided for @exploreMenu.
  ///
  /// In en, this message translates to:
  /// **'Explore Menu'**
  String get exploreMenu;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @dailyNutritionTotal.
  ///
  /// In en, this message translates to:
  /// **'Daily nutrition total'**
  String get dailyNutritionTotal;

  /// No description provided for @nutritionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Nutrition information unavailable'**
  String get nutritionUnavailable;

  /// No description provided for @nutritionTotalsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Totals unavailable for missing nutritional values.'**
  String get nutritionTotalsIncomplete;

  /// No description provided for @sugarLabel.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get sugarLabel;

  /// No description provided for @saturatedFatLabel.
  ///
  /// In en, this message translates to:
  /// **'Saturated fat'**
  String get saturatedFatLabel;

  /// No description provided for @transFatLabel.
  ///
  /// In en, this message translates to:
  /// **'Trans fat'**
  String get transFatLabel;

  /// No description provided for @cholesterolLabel.
  ///
  /// In en, this message translates to:
  /// **'Cholesterol'**
  String get cholesterolLabel;

  /// No description provided for @nutritionServing.
  ///
  /// In en, this message translates to:
  /// **'Per serving: {portion}'**
  String nutritionServing(String portion);

  /// No description provided for @customerUnableToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in'**
  String get customerUnableToSignIn;

  /// No description provided for @customerWeCouldNotLoadTakeawayBranchesPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'We could not load takeaway branches. Please try again.'**
  String get customerWeCouldNotLoadTakeawayBranchesPleaseTryAgain;

  /// No description provided for @customerChooseAFutureDeliveryStartDateTodayAndFriday.
  ///
  /// In en, this message translates to:
  /// **'Choose a future delivery start date; today and Friday are unavailable.'**
  String get customerChooseAFutureDeliveryStartDateTodayAndFriday;

  /// No description provided for @customerTheSelectedMealConfigurationIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'The selected meal configuration is no longer available.'**
  String get customerTheSelectedMealConfigurationIsNoLongerAvailable;

  /// No description provided for @customerTheSelectedPlanDurationIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'The selected plan duration is no longer available.'**
  String get customerTheSelectedPlanDurationIsNoLongerAvailable;

  /// No description provided for @customerWeCouldNotVerifyTheSelectedPlanPleaseTry.
  ///
  /// In en, this message translates to:
  /// **'We could not verify the selected plan. Please try again.'**
  String get customerWeCouldNotVerifyTheSelectedPlanPleaseTry;

  /// No description provided for @customerDeliveryTimesCouldNotBeLoadedPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Delivery times could not be loaded. Please try again.'**
  String get customerDeliveryTimesCouldNotBeLoadedPleaseTryAgain;

  /// No description provided for @customerWeCouldNotLoadYourCustomerProfilePleaseSign.
  ///
  /// In en, this message translates to:
  /// **'We could not load your customer profile. Please sign in again.'**
  String get customerWeCouldNotLoadYourCustomerProfilePleaseSign;

  /// No description provided for @customerSavedAddressesCouldNotBeLoadedPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses could not be loaded. Please try again.'**
  String get customerSavedAddressesCouldNotBeLoadedPleaseTryAgain;

  /// No description provided for @customerYourCustomerProfileIsUnavailablePleaseSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Your customer profile is unavailable. Please sign in again.'**
  String get customerYourCustomerProfileIsUnavailablePleaseSignInAgain;

  /// No description provided for @customerSelectAnActiveDeliveryTimeSlotBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Select an active delivery time slot before saving.'**
  String get customerSelectAnActiveDeliveryTimeSlotBeforeSaving;

  /// No description provided for @customerYourAddressCouldNotBeSavedPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Your address could not be saved. Please try again.'**
  String get customerYourAddressCouldNotBeSavedPleaseTryAgain;

  /// No description provided for @customerWeCouldntPlaceYourOrderPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t place your order. Please try again.'**
  String get customerWeCouldntPlaceYourOrderPleaseTryAgain;

  /// No description provided for @customerPleaseCheckYourConnectionAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get customerPleaseCheckYourConnectionAndTryAgain;

  /// No description provided for @customerThePlanPriceHasChangedPleaseReviewTheUpdated.
  ///
  /// In en, this message translates to:
  /// **'The plan price has changed. Please review the updated total before placing your order.'**
  String get customerThePlanPriceHasChangedPleaseReviewTheUpdated;

  /// No description provided for @customerThisOrderIsAlreadyBeingProcessedPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'This order is already being processed. Please try again.'**
  String get customerThisOrderIsAlreadyBeingProcessedPleaseTryAgain;

  /// No description provided for @customerTheSelectedPlanIsNoLongerAvailablePleaseChoose.
  ///
  /// In en, this message translates to:
  /// **'The selected plan is no longer available. Please choose another plan.'**
  String get customerTheSelectedPlanIsNoLongerAvailablePleaseChoose;

  /// No description provided for @customerTheSelectedDeliveryAddressIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'The selected delivery address is no longer available.'**
  String get customerTheSelectedDeliveryAddressIsNoLongerAvailable;

  /// No description provided for @customerTheSelectedDeliveryTimeIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'The selected delivery time is no longer available.'**
  String get customerTheSelectedDeliveryTimeIsNoLongerAvailable;

  /// No description provided for @customerASelectedCheckoutOptionIsNoLongerAvailablePlease.
  ///
  /// In en, this message translates to:
  /// **'A selected checkout option is no longer available. Please review your order.'**
  String get customerASelectedCheckoutOptionIsNoLongerAvailablePlease;

  /// No description provided for @customerPleaseReviewYourSelectedMeals.
  ///
  /// In en, this message translates to:
  /// **'Please review your selected meals.'**
  String get customerPleaseReviewYourSelectedMeals;

  /// No description provided for @customerPleaseReviewYourSelectedServiceDays.
  ///
  /// In en, this message translates to:
  /// **'Please review your selected service days.'**
  String get customerPleaseReviewYourSelectedServiceDays;

  /// No description provided for @customerPleaseSelectAnotherPlanStartDate.
  ///
  /// In en, this message translates to:
  /// **'Please select another plan start date.'**
  String get customerPleaseSelectAnotherPlanStartDate;

  /// No description provided for @customerCouponCodesAreNotSupportedYetRemoveTheCoupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon codes are not supported yet. Remove the coupon and try again.'**
  String get customerCouponCodesAreNotSupportedYetRemoveTheCoupon;

  /// No description provided for @customerYourOrderResponseCouldNotBeConfirmedPleaseCheck.
  ///
  /// In en, this message translates to:
  /// **'Your order response could not be confirmed. Please check your orders before trying again.'**
  String get customerYourOrderResponseCouldNotBeConfirmedPleaseCheck;

  /// No description provided for @customerSomeAddressInformationWasNotAcceptedPleaseReviewIt.
  ///
  /// In en, this message translates to:
  /// **'Some address information was not accepted. Please review it.'**
  String get customerSomeAddressInformationWasNotAcceptedPleaseReviewIt;

  /// No description provided for @customerYourSessionExpiredPleaseSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get customerYourSessionExpiredPleaseSignInAgain;

  /// No description provided for @customerWeCouldNotLoadYourProfile.
  ///
  /// In en, this message translates to:
  /// **'We could not load your profile.'**
  String get customerWeCouldNotLoadYourProfile;

  /// No description provided for @customerTRYAGAIN.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get customerTRYAGAIN;

  /// No description provided for @customerBrowsePlans.
  ///
  /// In en, this message translates to:
  /// **'Browse plans'**
  String get customerBrowsePlans;

  /// No description provided for @customerDohaQatar.
  ///
  /// In en, this message translates to:
  /// **'Doha, Qatar'**
  String get customerDohaQatar;

  /// No description provided for @customerCustomerAddress.
  ///
  /// In en, this message translates to:
  /// **'Customer Address'**
  String get customerCustomerAddress;

  /// No description provided for @customerDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get customerDeliveryAddress;

  /// No description provided for @customerChooseDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Choose Delivery Address'**
  String get customerChooseDeliveryAddress;

  /// No description provided for @customerSelectWhereYouWouldLikeYourMealsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Select where you would like your meals delivered.'**
  String get customerSelectWhereYouWouldLikeYourMealsDelivered;

  /// No description provided for @customerLoadingSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Loading saved addresses...'**
  String get customerLoadingSavedAddresses;

  /// No description provided for @customerAddAnotherAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Another Address'**
  String get customerAddAnotherAddress;

  /// No description provided for @customerUseThisAddress.
  ///
  /// In en, this message translates to:
  /// **'Use This Address'**
  String get customerUseThisAddress;

  /// No description provided for @customerAddressDetails.
  ///
  /// In en, this message translates to:
  /// **'Address Details'**
  String get customerAddressDetails;

  /// No description provided for @customerSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get customerSavedAddresses;

  /// No description provided for @customerSAVEASundefined.
  ///
  /// In en, this message translates to:
  /// **'SAVE AS *'**
  String get customerSAVEASundefined;

  /// No description provided for @customerBuildingNoundefined.
  ///
  /// In en, this message translates to:
  /// **'Building No *'**
  String get customerBuildingNoundefined;

  /// No description provided for @customerStreetundefined.
  ///
  /// In en, this message translates to:
  /// **'Street *'**
  String get customerStreetundefined;

  /// No description provided for @customerUnitNumber.
  ///
  /// In en, this message translates to:
  /// **'Unit Number'**
  String get customerUnitNumber;

  /// No description provided for @customerZoneNoundefined.
  ///
  /// In en, this message translates to:
  /// **'Zone No *'**
  String get customerZoneNoundefined;

  /// No description provided for @customerAreaundefined.
  ///
  /// In en, this message translates to:
  /// **'Area *'**
  String get customerAreaundefined;

  /// No description provided for @customerDirectionsToReach.
  ///
  /// In en, this message translates to:
  /// **'Directions To Reach'**
  String get customerDirectionsToReach;

  /// No description provided for @customerCallMeWhenYouArrive.
  ///
  /// In en, this message translates to:
  /// **'Call me when you arrive'**
  String get customerCallMeWhenYouArrive;

  /// No description provided for @customerSavingAddress.
  ///
  /// In en, this message translates to:
  /// **'Saving Address...'**
  String get customerSavingAddress;

  /// No description provided for @customerSaveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get customerSaveAddress;

  /// No description provided for @customerPinnedLocationQatar.
  ///
  /// In en, this message translates to:
  /// **'Pinned location, Qatar'**
  String get customerPinnedLocationQatar;

  /// No description provided for @customerSelectAnAddressTypeBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Select an address type before saving.'**
  String get customerSelectAnAddressTypeBeforeSaving;

  /// No description provided for @customerCompleteAllRequiredAddressFields.
  ///
  /// In en, this message translates to:
  /// **'Complete all required address fields.'**
  String get customerCompleteAllRequiredAddressFields;

  /// No description provided for @customerSelectADeliveryTimeSlotBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Select a delivery time slot before saving.'**
  String get customerSelectADeliveryTimeSlotBeforeSaving;

  /// No description provided for @customerSelectADeliveryAddressOrAddANewOne.
  ///
  /// In en, this message translates to:
  /// **'Select a delivery address or add a new one.'**
  String get customerSelectADeliveryAddressOrAddANewOne;

  /// No description provided for @customerSelectADeliveryTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Select a delivery time slot.'**
  String get customerSelectADeliveryTimeSlot;

  /// No description provided for @customerEnterAZoneOrAreaToSearch.
  ///
  /// In en, this message translates to:
  /// **'Enter a zone or area to search.'**
  String get customerEnterAZoneOrAreaToSearch;

  /// No description provided for @customerNoMatchingLocationWasFound.
  ///
  /// In en, this message translates to:
  /// **'No matching location was found.'**
  String get customerNoMatchingLocationWasFound;

  /// No description provided for @customerLocationSearchIsUnavailableTryAgainOrMoveThe.
  ///
  /// In en, this message translates to:
  /// **'Location search is unavailable. Try again or move the pin.'**
  String get customerLocationSearchIsUnavailableTryAgainOrMoveThe;

  /// No description provided for @customerTurnOnLocationServicesToContinue.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to continue.'**
  String get customerTurnOnLocationServicesToContinue;

  /// No description provided for @customerLocationAccessIsBlockedEnableItInDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked. Enable it in device settings.'**
  String get customerLocationAccessIsBlockedEnableItInDeviceSettings;

  /// No description provided for @customerLocationPermissionIsNeededToFindYourCurrentAddress.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to find your current address.'**
  String get customerLocationPermissionIsNeededToFindYourCurrentAddress;

  /// No description provided for @customerFindingYourCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Finding your current location...'**
  String get customerFindingYourCurrentLocation;

  /// No description provided for @customerCouldNotDetermineYourLocationTryAgainOrMove.
  ///
  /// In en, this message translates to:
  /// **'Could not determine your location. Try again or move the pin.'**
  String get customerCouldNotDetermineYourLocationTryAgainOrMove;

  /// No description provided for @customerPinnedLocation.
  ///
  /// In en, this message translates to:
  /// **'Pinned location'**
  String get customerPinnedLocation;

  /// No description provided for @customerSearchAZone.
  ///
  /// In en, this message translates to:
  /// **'Search a Zone'**
  String get customerSearchAZone;

  /// No description provided for @customerCurrentAddress.
  ///
  /// In en, this message translates to:
  /// **'Current Address'**
  String get customerCurrentAddress;

  /// No description provided for @customerGoogleMapsIsNotConfiguredForThisIOSBuild.
  ///
  /// In en, this message translates to:
  /// **'Google Maps is not configured for this iOS build.'**
  String get customerGoogleMapsIsNotConfiguredForThisIOSBuild;

  /// No description provided for @customerAddTheIOSAPIKeyThenCleanAndRebuild.
  ///
  /// In en, this message translates to:
  /// **'Add the iOS API key, then clean and rebuild the app.'**
  String get customerAddTheIOSAPIKeyThenCleanAndRebuild;

  /// No description provided for @customerDELIVERYTIMEundefined.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY TIME *'**
  String get customerDELIVERYTIMEundefined;

  /// No description provided for @customerLoadingDeliveryTimes.
  ///
  /// In en, this message translates to:
  /// **'Loading delivery times...'**
  String get customerLoadingDeliveryTimes;

  /// No description provided for @customerNoDeliveryTimeSlotsAreCurrentlyAvailable.
  ///
  /// In en, this message translates to:
  /// **'No delivery time slots are currently available.'**
  String get customerNoDeliveryTimeSlotsAreCurrentlyAvailable;

  /// No description provided for @customerDEFAULT.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get customerDEFAULT;

  /// No description provided for @customerNoSavedAddressesYet.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses yet'**
  String get customerNoSavedAddressesYet;

  /// No description provided for @customerAddAnAddressForYourMealDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Add an address for your meal deliveries.'**
  String get customerAddAnAddressForYourMealDeliveries;

  /// No description provided for @customerAddAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get customerAddAddress;

  /// No description provided for @customerOrderSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Order Submitted'**
  String get customerOrderSubmitted;

  /// No description provided for @customerOrderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed!'**
  String get customerOrderConfirmed;

  /// No description provided for @customerYourOrderHasBeenReceivedAndIsAwaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Your order has been received and is awaiting confirmation from Diet Time. We\'ll notify you once it\'s reviewed.'**
  String get customerYourOrderHasBeenReceivedAndIsAwaitingConfirmation;

  /// No description provided for @customerGOTODASHBOARD.
  ///
  /// In en, this message translates to:
  /// **'GO TO DASHBOARD'**
  String get customerGOTODASHBOARD;

  /// No description provided for @customerORDERNUMBER.
  ///
  /// In en, this message translates to:
  /// **'ORDER NUMBER'**
  String get customerORDERNUMBER;

  /// No description provided for @customerPLAN.
  ///
  /// In en, this message translates to:
  /// **'PLAN'**
  String get customerPLAN;

  /// No description provided for @customerPAYMENT.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT'**
  String get customerPAYMENT;

  /// No description provided for @customerPACKAGE.
  ///
  /// In en, this message translates to:
  /// **'PACKAGE'**
  String get customerPACKAGE;

  /// No description provided for @customerFULFILLMENT.
  ///
  /// In en, this message translates to:
  /// **'FULFILLMENT'**
  String get customerFULFILLMENT;

  /// No description provided for @customerTakeaway.
  ///
  /// In en, this message translates to:
  /// **'Takeaway'**
  String get customerTakeaway;

  /// No description provided for @customerPLANPERIOD.
  ///
  /// In en, this message translates to:
  /// **'PLAN PERIOD'**
  String get customerPLANPERIOD;

  /// No description provided for @customerFIRSTCOLLECTION.
  ///
  /// In en, this message translates to:
  /// **'FIRST COLLECTION'**
  String get customerFIRSTCOLLECTION;

  /// No description provided for @customerFIRSTDELIVERY.
  ///
  /// In en, this message translates to:
  /// **'FIRST DELIVERY'**
  String get customerFIRSTDELIVERY;

  /// No description provided for @customerDELIVERYTO.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY TO'**
  String get customerDELIVERYTO;

  /// No description provided for @customerTOTAL.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get customerTOTAL;

  /// No description provided for @customerSTATUS.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get customerSTATUS;

  /// No description provided for @customerOrderConfirmationIsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Order confirmation is unavailable.'**
  String get customerOrderConfirmationIsUnavailable;

  /// No description provided for @customerVerifyingYourSelectedPlan.
  ///
  /// In en, this message translates to:
  /// **'Verifying your selected plan...'**
  String get customerVerifyingYourSelectedPlan;

  /// No description provided for @customerYourPlanDetails.
  ///
  /// In en, this message translates to:
  /// **'Your Plan Details'**
  String get customerYourPlanDetails;

  /// No description provided for @customerThisPackageIsAvailableForTakeawayOnly.
  ///
  /// In en, this message translates to:
  /// **'This package is available for takeaway only.'**
  String get customerThisPackageIsAvailableForTakeawayOnly;

  /// No description provided for @customerHomeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Home Delivery'**
  String get customerHomeDelivery;

  /// No description provided for @customerCOLLECTIONBRANCH.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION BRANCH'**
  String get customerCOLLECTIONBRANCH;

  /// No description provided for @customerNoTakeawayBranchesAreCurrentlyAvailable.
  ///
  /// In en, this message translates to:
  /// **'No takeaway branches are currently available.'**
  String get customerNoTakeawayBranchesAreCurrentlyAvailable;

  /// No description provided for @customerDELIVERYADDRESSTIMESLOT.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY ADDRESS & TIME SLOT'**
  String get customerDELIVERYADDRESSTIMESLOT;

  /// No description provided for @customerStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get customerStartDate;

  /// No description provided for @customerSelectYourServiceDates.
  ///
  /// In en, this message translates to:
  /// **'Select your service dates'**
  String get customerSelectYourServiceDates;

  /// No description provided for @customerOrderTotal.
  ///
  /// In en, this message translates to:
  /// **'Order Total'**
  String get customerOrderTotal;

  /// No description provided for @customerPLACEORDER.
  ///
  /// In en, this message translates to:
  /// **'PLACE ORDER'**
  String get customerPLACEORDER;

  /// No description provided for @customerPLACINGORDER.
  ///
  /// In en, this message translates to:
  /// **'PLACING ORDER...'**
  String get customerPLACINGORDER;

  /// No description provided for @customerPREPARINGORDER.
  ///
  /// In en, this message translates to:
  /// **'PREPARING ORDER...'**
  String get customerPREPARINGORDER;

  /// No description provided for @customerNoDeliveryAddressSelected.
  ///
  /// In en, this message translates to:
  /// **'No delivery address selected'**
  String get customerNoDeliveryAddressSelected;

  /// No description provided for @customerAddDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Delivery Address'**
  String get customerAddDeliveryAddress;

  /// No description provided for @customerChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get customerChange;

  /// No description provided for @customerSelectADeliveryTimeSlot2.
  ///
  /// In en, this message translates to:
  /// **'Select a delivery time slot'**
  String get customerSelectADeliveryTimeSlot2;

  /// No description provided for @customerChooseAMealPlanBeforeReviewingYourSummary.
  ///
  /// In en, this message translates to:
  /// **'Choose a meal plan before reviewing your summary.'**
  String get customerChooseAMealPlanBeforeReviewingYourSummary;

  /// No description provided for @customerBrowsePlans2.
  ///
  /// In en, this message translates to:
  /// **'Browse Plans'**
  String get customerBrowsePlans2;

  /// No description provided for @customerWeCouldNotLoadYourDashboardPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'We could not load your dashboard. Please try again.'**
  String get customerWeCouldNotLoadYourDashboardPleaseTryAgain;

  /// No description provided for @customerWeCouldNotLoadYourOrdersPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'We could not load your orders. Please try again.'**
  String get customerWeCouldNotLoadYourOrdersPleaseTryAgain;

  /// No description provided for @customerHOME.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get customerHOME;

  /// No description provided for @customerORDERS.
  ///
  /// In en, this message translates to:
  /// **'ORDERS'**
  String get customerORDERS;

  /// No description provided for @customerCALENDAR.
  ///
  /// In en, this message translates to:
  /// **'CALENDAR'**
  String get customerCALENDAR;

  /// No description provided for @customerPROFILE.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get customerPROFILE;

  /// No description provided for @customerProfileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get customerProfileUpdatedSuccessfully;

  /// No description provided for @customerUnableToLoadYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your profile.'**
  String get customerUnableToLoadYourProfile;

  /// No description provided for @customerQuestionnaireUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Questionnaire updated successfully'**
  String get customerQuestionnaireUpdatedSuccessfully;

  /// No description provided for @customerLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get customerLogout;

  /// No description provided for @customerAreYouSureYouWantToLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get customerAreYouSureYouWantToLogout;

  /// No description provided for @customerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get customerCancel;

  /// No description provided for @customerYourSessionHasExpiredPleaseSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get customerYourSessionHasExpiredPleaseSignInAgain;

  /// No description provided for @customerSIGNIN.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get customerSIGNIN;

  /// No description provided for @customerYourCustomerProfileCouldNotBeFound.
  ///
  /// In en, this message translates to:
  /// **'Your customer profile could not be found.'**
  String get customerYourCustomerProfileCouldNotBeFound;

  /// No description provided for @customerYOURACTIVEPLAN.
  ///
  /// In en, this message translates to:
  /// **'YOUR ACTIVE PLAN'**
  String get customerYOURACTIVEPLAN;

  /// No description provided for @customerMYACTIVEPLANS.
  ///
  /// In en, this message translates to:
  /// **'MY ACTIVE PLANS'**
  String get customerMYACTIVEPLANS;

  /// No description provided for @customerORDERANOTHERPLAN.
  ///
  /// In en, this message translates to:
  /// **'ORDER ANOTHER PLAN'**
  String get customerORDERANOTHERPLAN;

  /// No description provided for @customerQUICKACTIONS.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACTIONS'**
  String get customerQUICKACTIONS;

  /// No description provided for @customerPREVIOUSORDERS.
  ///
  /// In en, this message translates to:
  /// **'PREVIOUS ORDERS'**
  String get customerPREVIOUSORDERS;

  /// No description provided for @customerMYORDERS.
  ///
  /// In en, this message translates to:
  /// **'MY ORDERS'**
  String get customerMYORDERS;

  /// No description provided for @customerVIEWALL.
  ///
  /// In en, this message translates to:
  /// **'VIEW ALL'**
  String get customerVIEWALL;

  /// No description provided for @customerNOACTIVEPLAN.
  ///
  /// In en, this message translates to:
  /// **'NO ACTIVE PLAN'**
  String get customerNOACTIVEPLAN;

  /// No description provided for @customerYouDontHaveAnActiveMealPlanRightNow.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have an active meal plan right now.'**
  String get customerYouDontHaveAnActiveMealPlanRightNow;

  /// No description provided for @customerCHOOSEAPLAN.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE A PLAN'**
  String get customerCHOOSEAPLAN;

  /// No description provided for @customerScheduleReady.
  ///
  /// In en, this message translates to:
  /// **'Schedule ready'**
  String get customerScheduleReady;

  /// No description provided for @customerCollectFromDietTime.
  ///
  /// In en, this message translates to:
  /// **'Collect from Diet Time'**
  String get customerCollectFromDietTime;

  /// No description provided for @customerVIEWPLAN.
  ///
  /// In en, this message translates to:
  /// **'VIEW PLAN'**
  String get customerVIEWPLAN;

  /// No description provided for @customerDETAILS.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get customerDETAILS;

  /// No description provided for @customerMyPlan.
  ///
  /// In en, this message translates to:
  /// **'My Plan'**
  String get customerMyPlan;

  /// No description provided for @customerOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get customerOrders;

  /// No description provided for @customerNewPlan.
  ///
  /// In en, this message translates to:
  /// **'New Plan'**
  String get customerNewPlan;

  /// No description provided for @customerSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get customerSupport;

  /// No description provided for @customerSupportWillBeAvailableSoon.
  ///
  /// In en, this message translates to:
  /// **'Support will be available soon.'**
  String get customerSupportWillBeAvailableSoon;

  /// No description provided for @customerDeliveryCalendar.
  ///
  /// In en, this message translates to:
  /// **'Delivery Calendar'**
  String get customerDeliveryCalendar;

  /// No description provided for @customerNoActiveDeliveryCalendar.
  ///
  /// In en, this message translates to:
  /// **'No active delivery calendar'**
  String get customerNoActiveDeliveryCalendar;

  /// No description provided for @customerYourDeliveryDatesWillAppearHereWhenAMeal.
  ///
  /// In en, this message translates to:
  /// **'Your delivery dates will appear here when a meal plan is active.'**
  String get customerYourDeliveryDatesWillAppearHereWhenAMeal;

  /// No description provided for @customerALL.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get customerALL;

  /// No description provided for @customerMyOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get customerMyOrders;

  /// No description provided for @customerAllYourMealOrdersInOnePlace.
  ///
  /// In en, this message translates to:
  /// **'All your meal orders in one place'**
  String get customerAllYourMealOrdersInOnePlace;

  /// No description provided for @customerAllOrders.
  ///
  /// In en, this message translates to:
  /// **'All Orders'**
  String get customerAllOrders;

  /// No description provided for @customerPendingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Pending Confirmation'**
  String get customerPendingConfirmation;

  /// No description provided for @customerOnHold.
  ///
  /// In en, this message translates to:
  /// **'On Hold'**
  String get customerOnHold;

  /// No description provided for @customerRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get customerRejected;

  /// No description provided for @customerPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get customerPending;

  /// No description provided for @customerCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get customerCancelled;

  /// No description provided for @customerNoOrdersFoundForThisStatus.
  ///
  /// In en, this message translates to:
  /// **'No orders found for this status.'**
  String get customerNoOrdersFoundForThisStatus;

  /// No description provided for @customerOrderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get customerOrderPlaced;

  /// No description provided for @customerViewDetailsundefined.
  ///
  /// In en, this message translates to:
  /// **'View Details  →'**
  String get customerViewDetailsundefined;

  /// No description provided for @customerGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get customerGoodMorning;

  /// No description provided for @customerGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get customerGoodAfternoon;

  /// No description provided for @customerGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get customerGoodEvening;

  /// No description provided for @customerYourMealPlanIsActive.
  ///
  /// In en, this message translates to:
  /// **'Your meal plan is active'**
  String get customerYourMealPlanIsActive;

  /// No description provided for @customerReadyWhenYouAre.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are'**
  String get customerReadyWhenYouAre;

  /// No description provided for @customerYourMealPlansAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'Your meal plans at a glance'**
  String get customerYourMealPlansAtAGlance;

  /// No description provided for @customerMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get customerMon;

  /// No description provided for @customerTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get customerTue;

  /// No description provided for @customerWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get customerWed;

  /// No description provided for @customerThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get customerThu;

  /// No description provided for @customerFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get customerFri;

  /// No description provided for @customerSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get customerSat;

  /// No description provided for @customerSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get customerSun;

  /// No description provided for @customerWeCouldntLoadAllYourDeliveryOrders.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load all your delivery orders.'**
  String get customerWeCouldntLoadAllYourDeliveryOrders;

  /// No description provided for @customerUnableToUpdateProfilePleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Unable to update profile. Please try again.'**
  String get customerUnableToUpdateProfilePleaseTryAgain;

  /// No description provided for @customerProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get customerProfile;

  /// No description provided for @customerCustomerProfile.
  ///
  /// In en, this message translates to:
  /// **'Customer Profile'**
  String get customerCustomerProfile;

  /// No description provided for @customerViewOrUpdateYourPersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'View or update your personal information'**
  String get customerViewOrUpdateYourPersonalInformation;

  /// No description provided for @customerQuestionnaire.
  ///
  /// In en, this message translates to:
  /// **'Questionnaire'**
  String get customerQuestionnaire;

  /// No description provided for @customerCaptureYourGoalsAndFoodPreferences.
  ///
  /// In en, this message translates to:
  /// **'Capture your goals and food preferences'**
  String get customerCaptureYourGoalsAndFoodPreferences;

  /// No description provided for @customerAddOrEditYourDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Add or edit your delivery address'**
  String get customerAddOrEditYourDeliveryAddress;

  /// No description provided for @customerPleaseSignInAgainToViewYourMeals.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to view your meals.'**
  String get customerPleaseSignInAgainToViewYourMeals;

  /// No description provided for @customerWeCouldntLoadYourMealsForThisDayPlease.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load your meals for this day. Please try again.'**
  String get customerWeCouldntLoadYourMealsForThisDayPlease;

  /// No description provided for @customerTheMenuForThisDateCouldNotBeConfirmed.
  ///
  /// In en, this message translates to:
  /// **'The menu for this date could not be confirmed.'**
  String get customerTheMenuForThisDateCouldNotBeConfirmed;

  /// No description provided for @customerWeveSelectedYourMealsForThisDayYouCan.
  ///
  /// In en, this message translates to:
  /// **'We’ve selected your meals for this day. You can change them before the selection deadline.'**
  String get customerWeveSelectedYourMealsForThisDayYouCan;

  /// No description provided for @customerTheSelectionDeadlineHasPassedYourMealsAreLocked.
  ///
  /// In en, this message translates to:
  /// **'The selection deadline has passed. Your meals are locked for kitchen preparation.'**
  String get customerTheSelectionDeadlineHasPassedYourMealsAreLocked;

  /// No description provided for @customerYourMealsAreReadonlyForThisDay.
  ///
  /// In en, this message translates to:
  /// **'Your meals are read-only for this day.'**
  String get customerYourMealsAreReadonlyForThisDay;

  /// No description provided for @customerYourMealsForThisDay.
  ///
  /// In en, this message translates to:
  /// **'Your meals for this day'**
  String get customerYourMealsForThisDay;

  /// No description provided for @customerYourMealsAreBeingReviewedByOurTeamPlease.
  ///
  /// In en, this message translates to:
  /// **'Your meals are being reviewed by our team. Please check back shortly.'**
  String get customerYourMealsAreBeingReviewedByOurTeamPlease;

  /// No description provided for @customerSelectedForYou.
  ///
  /// In en, this message translates to:
  /// **'Selected for you'**
  String get customerSelectedForYou;

  /// No description provided for @customerYourChoice.
  ///
  /// In en, this message translates to:
  /// **'Your choice'**
  String get customerYourChoice;

  /// No description provided for @customerYourMealChangeHasBeenSaved.
  ///
  /// In en, this message translates to:
  /// **'Your meal change has been saved.'**
  String get customerYourMealChangeHasBeenSaved;

  /// No description provided for @customerTheSelectionDeadlineHasPassedCloseThisSheetTo.
  ///
  /// In en, this message translates to:
  /// **'The selection deadline has passed. Close this sheet to view your saved meals.'**
  String get customerTheSelectionDeadlineHasPassedCloseThisSheetTo;

  /// No description provided for @customerYourChoicesOrSelectionDeadlineHaveChangedCloseThis.
  ///
  /// In en, this message translates to:
  /// **'Your choices or selection deadline have changed. Close this sheet and refresh the day.'**
  String get customerYourChoicesOrSelectionDeadlineHaveChangedCloseThis;

  /// No description provided for @customerThatMealIsNoLongerAvailablePleaseChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'That meal is no longer available. Please choose another option or refresh the day.'**
  String get customerThatMealIsNoLongerAvailablePleaseChooseAnother;

  /// No description provided for @customerWeCouldntSaveThisChangeYourSavedMealsAre.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t save this change. Your saved meals are unchanged. Please try again.'**
  String get customerWeCouldntSaveThisChangeYourSavedMealsAre;

  /// No description provided for @customerChangeMeal.
  ///
  /// In en, this message translates to:
  /// **'Change meal'**
  String get customerChangeMeal;

  /// No description provided for @customerClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get customerClose;

  /// No description provided for @customerThereAreNoOtherEligibleDishesForThisSelection.
  ///
  /// In en, this message translates to:
  /// **'There are no other eligible dishes for this selection on this day.'**
  String get customerThereAreNoOtherEligibleDishesForThisSelection;

  /// No description provided for @customerSelectedReplacement.
  ///
  /// In en, this message translates to:
  /// **'Selected replacement'**
  String get customerSelectedReplacement;

  /// No description provided for @customerAvailableForThisDay.
  ///
  /// In en, this message translates to:
  /// **'Available for this day'**
  String get customerAvailableForThisDay;

  /// No description provided for @customerSavingChanges.
  ///
  /// In en, this message translates to:
  /// **'Saving changes…'**
  String get customerSavingChanges;

  /// No description provided for @customerSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get customerSaveChanges;

  /// No description provided for @customerChangeMeal2.
  ///
  /// In en, this message translates to:
  /// **'Change Meal'**
  String get customerChangeMeal2;

  /// No description provided for @customerLoadingMealsForTheSelectedDay.
  ///
  /// In en, this message translates to:
  /// **'Loading meals for the selected day'**
  String get customerLoadingMealsForTheSelectedDay;

  /// No description provided for @customerAutomaticallySelected.
  ///
  /// In en, this message translates to:
  /// **'Automatically Selected'**
  String get customerAutomaticallySelected;

  /// No description provided for @customerCustomized.
  ///
  /// In en, this message translates to:
  /// **'Customized'**
  String get customerCustomized;

  /// No description provided for @customerDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get customerDelivered;

  /// No description provided for @customerOurTeamIsReviewingThisDay.
  ///
  /// In en, this message translates to:
  /// **'Our team is reviewing this day'**
  String get customerOurTeamIsReviewingThisDay;

  /// No description provided for @customerEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get customerEditProfile;

  /// No description provided for @customerFullNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Full Name is required.'**
  String get customerFullNameIsRequired;

  /// No description provided for @customerFullNameMustBeAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Full Name must be at least 2 characters.'**
  String get customerFullNameMustBeAtLeast2Characters;

  /// No description provided for @customerFullNameMustBe150CharactersOrFewer.
  ///
  /// In en, this message translates to:
  /// **'Full Name must be 150 characters or fewer.'**
  String get customerFullNameMustBe150CharactersOrFewer;

  /// No description provided for @customerFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get customerFullName;

  /// No description provided for @customerMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get customerMobileNumber;

  /// No description provided for @customerContactSupportOrUseChangeMobileNumberToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Contact support or use Change Mobile Number to update your login number.'**
  String get customerContactSupportOrUseChangeMobileNumberToUpdate;

  /// No description provided for @customerDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get customerDateOfBirth;

  /// No description provided for @customerSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get customerSaving;

  /// No description provided for @customerDiscardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get customerDiscardChanges;

  /// No description provided for @customerYouHaveUnsavedChangesAreYouSureYouWant.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to leave?'**
  String get customerYouHaveUnsavedChangesAreYouSureYouWant;

  /// No description provided for @customerKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get customerKeepEditing;

  /// No description provided for @customerDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get customerDiscard;

  /// No description provided for @customerBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get customerBack;

  /// No description provided for @customerOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get customerOrderDetails;

  /// No description provided for @customerRequestCancellation.
  ///
  /// In en, this message translates to:
  /// **'Request cancellation'**
  String get customerRequestCancellation;

  /// No description provided for @customerTheOrderCouldNotBeCancelledRefreshTheOrder.
  ///
  /// In en, this message translates to:
  /// **'The order could not be cancelled. Refresh the order or contact Diet Time.'**
  String get customerTheOrderCouldNotBeCancelledRefreshTheOrder;

  /// No description provided for @customerMEALSINCLUDED.
  ///
  /// In en, this message translates to:
  /// **'MEALS INCLUDED'**
  String get customerMEALSINCLUDED;

  /// No description provided for @customerCOLLECTIONDAYS.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION DAYS'**
  String get customerCOLLECTIONDAYS;

  /// No description provided for @customerDELIVERYDAYS.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY DAYS'**
  String get customerDELIVERYDAYS;

  /// No description provided for @customerDELIVERYADDRESS.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY ADDRESS'**
  String get customerDELIVERYADDRESS;

  /// No description provided for @customerDELIVERYTIME.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY TIME'**
  String get customerDELIVERYTIME;

  /// No description provided for @customerPRICING.
  ///
  /// In en, this message translates to:
  /// **'PRICING'**
  String get customerPRICING;

  /// No description provided for @customerPAYMENTSTATUS.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT STATUS'**
  String get customerPAYMENTSTATUS;

  /// No description provided for @customerThankYouForYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your order!'**
  String get customerThankYouForYourOrder;

  /// No description provided for @customerYourPlanAndDeliveryScheduleAreConfirmedAbove.
  ///
  /// In en, this message translates to:
  /// **'Your plan and delivery schedule are confirmed above.'**
  String get customerYourPlanAndDeliveryScheduleAreConfirmedAbove;

  /// No description provided for @customerNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get customerNeedHelp;

  /// No description provided for @customerContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get customerContactSupport;

  /// No description provided for @customerWeCouldntLoadThisOrder.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this order.'**
  String get customerWeCouldntLoadThisOrder;

  /// No description provided for @customerCancelThisOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get customerCancelThisOrder;

  /// No description provided for @customerReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get customerReason;

  /// No description provided for @customerKeepOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep order'**
  String get customerKeepOrder;

  /// No description provided for @customerConfirmCancellation.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancellation'**
  String get customerConfirmCancellation;

  /// No description provided for @customerThisOrderCouldNotBeLoadedForYourAccount.
  ///
  /// In en, this message translates to:
  /// **'This order could not be loaded for your account. Refresh your dashboard or contact our team with your order reference.'**
  String get customerThisOrderCouldNotBeLoadedForYourAccount;

  /// No description provided for @customerWeCouldNotConnectToLoadYourMenuCheck.
  ///
  /// In en, this message translates to:
  /// **'We could not connect to load your menu. Check your connection and try again.'**
  String get customerWeCouldNotConnectToLoadYourMenuCheck;

  /// No description provided for @customerTheMenuServiceCouldNotLoadYourOrdersDishes.
  ///
  /// In en, this message translates to:
  /// **'The menu service could not load your order’s dishes. Please refresh or contact our team.'**
  String get customerTheMenuServiceCouldNotLoadYourOrdersDishes;

  /// No description provided for @customerConfirmYourMeals.
  ///
  /// In en, this message translates to:
  /// **'Confirm your meals'**
  String get customerConfirmYourMeals;

  /// No description provided for @customerYourSelectionsCannotBeChangedAfterConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Your selections cannot be changed after confirmation.'**
  String get customerYourSelectionsCannotBeChangedAfterConfirmation;

  /// No description provided for @customerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get customerConfirm;

  /// No description provided for @customerThe900PMDeadlineHasPassedYourAutomaticMeals.
  ///
  /// In en, this message translates to:
  /// **'The 9:00 PM deadline has passed. Your automatic meals are being finalized.'**
  String get customerThe900PMDeadlineHasPassedYourAutomaticMeals;

  /// No description provided for @customerYourMealsHaveAlreadyBeenFinalizedHereAreYour.
  ///
  /// In en, this message translates to:
  /// **'Your meals have already been finalized. Here are your saved dishes.'**
  String get customerYourMealsHaveAlreadyBeenFinalizedHereAreYour;

  /// No description provided for @customerYourSubscriptionIsNoLongerActiveForThisDelivery.
  ///
  /// In en, this message translates to:
  /// **'Your subscription is no longer active for this delivery.'**
  String get customerYourSubscriptionIsNoLongerActiveForThisDelivery;

  /// No description provided for @customerADishIsNoLongerAvailablePleaseReviewThe.
  ///
  /// In en, this message translates to:
  /// **'A dish is no longer available. Please review the refreshed menu.'**
  String get customerADishIsNoLongerAvailablePleaseReviewThe;

  /// No description provided for @customerWeCouldNotVerifyYourConfirmationPleaseCheckYour.
  ///
  /// In en, this message translates to:
  /// **'We could not verify your confirmation. Please check your connection and refresh before trying again.'**
  String get customerWeCouldNotVerifyYourConfirmationPleaseCheckYour;

  /// No description provided for @customerUnableToConfirmYourMealsPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm your meals. Please try again.'**
  String get customerUnableToConfirmYourMealsPleaseTryAgain;

  /// No description provided for @customerTomorrowsMenu.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow’s Menu'**
  String get customerTomorrowsMenu;

  /// No description provided for @customerAutomaticallyFinalized.
  ///
  /// In en, this message translates to:
  /// **'Automatically finalized'**
  String get customerAutomaticallyFinalized;

  /// No description provided for @customerHideConfirmedMeals.
  ///
  /// In en, this message translates to:
  /// **'Hide confirmed meals'**
  String get customerHideConfirmedMeals;

  /// No description provided for @customerSelectionClosesTodayAt900PMQatarTime.
  ///
  /// In en, this message translates to:
  /// **'Selection closes today at 9:00 PM Qatar time.'**
  String get customerSelectionClosesTodayAt900PMQatarTime;

  /// No description provided for @customerMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get customerMeals;

  /// No description provided for @customerSnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get customerSnacks;

  /// No description provided for @customerConfirmMyMeals.
  ///
  /// In en, this message translates to:
  /// **'Confirm My Meals'**
  String get customerConfirmMyMeals;

  /// No description provided for @customerReplaceAMeal.
  ///
  /// In en, this message translates to:
  /// **'Replace a meal'**
  String get customerReplaceAMeal;

  /// No description provided for @customerReplaceASnack.
  ///
  /// In en, this message translates to:
  /// **'Replace a snack'**
  String get customerReplaceASnack;

  /// No description provided for @customerNoEligibleDishesAreCurrentlyConfiguredOurTeamWill.
  ///
  /// In en, this message translates to:
  /// **'No eligible dishes are currently configured. Our team will review this delivery.'**
  String get customerNoEligibleDishesAreCurrentlyConfiguredOurTeamWill;

  /// No description provided for @customerUpcomingMeals.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Meals'**
  String get customerUpcomingMeals;

  /// No description provided for @customerWeCouldntLoadAllYourDeliveryMeals.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load all your delivery meals.'**
  String get customerWeCouldntLoadAllYourDeliveryMeals;

  /// No description provided for @customerMealsHaveNotBeenAssignedToThisDeliveryYet.
  ///
  /// In en, this message translates to:
  /// **'Meals have not been assigned to this delivery yet. Our team will review it.'**
  String get customerMealsHaveNotBeenAssignedToThisDeliveryYet;

  /// No description provided for @customerMealsChosenForYou.
  ///
  /// In en, this message translates to:
  /// **'Meals chosen for you'**
  String get customerMealsChosenForYou;

  /// No description provided for @customerYourChoicesConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your choices confirmed'**
  String get customerYourChoicesConfirmed;

  /// No description provided for @customerServiceDay.
  ///
  /// In en, this message translates to:
  /// **'Service day'**
  String get customerServiceDay;

  /// No description provided for @customerNonserviceDay.
  ///
  /// In en, this message translates to:
  /// **'Non-service day'**
  String get customerNonserviceDay;

  /// No description provided for @customerNonservice.
  ///
  /// In en, this message translates to:
  /// **'Non-service'**
  String get customerNonservice;

  /// No description provided for @customerAutoselected.
  ///
  /// In en, this message translates to:
  /// **'Auto-selected'**
  String get customerAutoselected;

  /// No description provided for @customerDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get customerDelivery;

  /// No description provided for @customerScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get customerScheduled;

  /// No description provided for @customerNoUpcomingDeliveriesAreScheduled.
  ///
  /// In en, this message translates to:
  /// **'No upcoming deliveries are scheduled.'**
  String get customerNoUpcomingDeliveriesAreScheduled;

  /// No description provided for @customerServiceRunsSaturdayToThursdayFridayIsANonservice.
  ///
  /// In en, this message translates to:
  /// **'Service runs Saturday to Thursday. Friday is a non-service day.'**
  String get customerServiceRunsSaturdayToThursdayFridayIsANonservice;

  /// No description provided for @customerBeingPrepared.
  ///
  /// In en, this message translates to:
  /// **'Being prepared'**
  String get customerBeingPrepared;

  /// No description provided for @customerOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get customerOnTheWay;

  /// No description provided for @customerSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get customerSkipped;

  /// No description provided for @customerChooseYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get customerChooseYourLanguage;

  /// No description provided for @customerAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get customerAll;

  /// No description provided for @customerYourDraftCouldNotBeSavedPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Your draft could not be saved. Please try again.'**
  String get customerYourDraftCouldNotBeSavedPleaseTryAgain;

  /// No description provided for @customerUnableToLoadYourSavedProfile.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your saved profile.'**
  String get customerUnableToLoadYourSavedProfile;

  /// No description provided for @customerYourProfileChangedElsewhereWeReloadedItPleaseReview.
  ///
  /// In en, this message translates to:
  /// **'Your profile changed elsewhere. We reloaded it; please review and retry.'**
  String get customerYourProfileChangedElsewhereWeReloadedItPleaseReview;

  /// No description provided for @customerCouldNotSaveYourProgressCheckYourConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not save your progress. Check your connection.'**
  String get customerCouldNotSaveYourProgressCheckYourConnection;

  /// No description provided for @customerSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get customerSelect;

  /// No description provided for @customerNoFoodPreferences.
  ///
  /// In en, this message translates to:
  /// **'No food preferences'**
  String get customerNoFoodPreferences;

  /// No description provided for @customerSearchAllergies.
  ///
  /// In en, this message translates to:
  /// **'Search allergies...'**
  String get customerSearchAllergies;

  /// No description provided for @customerPersonalized.
  ///
  /// In en, this message translates to:
  /// **'Personalized'**
  String get customerPersonalized;

  /// No description provided for @customerBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get customerBalanced;

  /// No description provided for @customerMadeForYou.
  ///
  /// In en, this message translates to:
  /// **'Made for you'**
  String get customerMadeForYou;

  /// No description provided for @customerUnableToLoadAllergens.
  ///
  /// In en, this message translates to:
  /// **'Unable to load allergens.'**
  String get customerUnableToLoadAllergens;

  /// No description provided for @customerWellAlwaysHighlightMealsThatAreSafeForYou.
  ///
  /// In en, this message translates to:
  /// **'We\'ll always highlight meals that are safe for you.'**
  String get customerWellAlwaysHighlightMealsThatAreSafeForYou;

  /// No description provided for @customerNoAllergiesFound.
  ///
  /// In en, this message translates to:
  /// **'No allergies found.'**
  String get customerNoAllergiesFound;

  /// No description provided for @customerHeresAQuickOverviewOfYou.
  ///
  /// In en, this message translates to:
  /// **'Here\'s a quick overview of you.'**
  String get customerHeresAQuickOverviewOfYou;

  /// No description provided for @customerGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get customerGoal;

  /// No description provided for @customerActivityLevel.
  ///
  /// In en, this message translates to:
  /// **'Activity Level'**
  String get customerActivityLevel;

  /// No description provided for @customerNotCalculatedYet.
  ///
  /// In en, this message translates to:
  /// **'Not calculated yet'**
  String get customerNotCalculatedYet;

  /// No description provided for @customerProteinTarget.
  ///
  /// In en, this message translates to:
  /// **'Protein target'**
  String get customerProteinTarget;

  /// No description provided for @customerPersonalizeYourDietTimeExperience.
  ///
  /// In en, this message translates to:
  /// **'personalize your Diet Time experience.'**
  String get customerPersonalizeYourDietTimeExperience;

  /// No description provided for @customerYourGoals.
  ///
  /// In en, this message translates to:
  /// **'Your goals'**
  String get customerYourGoals;

  /// No description provided for @customerYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get customerYourProfile;

  /// No description provided for @customerYourLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Your lifestyle'**
  String get customerYourLifestyle;

  /// No description provided for @customerYourFoodPreferences.
  ///
  /// In en, this message translates to:
  /// **'Your food preferences'**
  String get customerYourFoodPreferences;

  /// No description provided for @customerYourHealthAllergies.
  ///
  /// In en, this message translates to:
  /// **'Your health & allergies'**
  String get customerYourHealthAllergies;

  /// No description provided for @customerYoureAllSet.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get customerYoureAllSet;

  /// No description provided for @customerYouCanNowExploreTheDietTimeMenu.
  ///
  /// In en, this message translates to:
  /// **'You can now explore the Diet Time menu.'**
  String get customerYouCanNowExploreTheDietTimeMenu;

  /// No description provided for @customerWeCouldntLoadYourProfile.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your profile.'**
  String get customerWeCouldntLoadYourProfile;

  /// No description provided for @customerWhatShouldWeCallYou.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get customerWhatShouldWeCallYou;

  /// No description provided for @customerYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get customerYourName;

  /// No description provided for @customerUnableToSaveYourNamePleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Unable to save your name. Please try again.'**
  String get customerUnableToSaveYourNamePleaseTryAgain;

  /// No description provided for @customerYourAnswersAreKeptOnThisPhonePleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Your answers are kept on this phone. Please retry saving.'**
  String get customerYourAnswersAreKeptOnThisPhonePleaseRetry;

  /// No description provided for @customerPickHowManyMealsYoudLikeEachDay.
  ///
  /// In en, this message translates to:
  /// **'Pick how many meals you\'d like each day.'**
  String get customerPickHowManyMealsYoudLikeEachDay;

  /// No description provided for @customerSwipeToExploreMealPackagesundefined.
  ///
  /// In en, this message translates to:
  /// **'Swipe to explore meal packages →'**
  String get customerSwipeToExploreMealPackagesundefined;

  /// No description provided for @customerChooseYourDuration.
  ///
  /// In en, this message translates to:
  /// **'Choose your duration'**
  String get customerChooseYourDuration;

  /// No description provided for @customerCurrentlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Currently unavailable'**
  String get customerCurrentlyUnavailable;

  /// No description provided for @customerSwipeToExplorePackageDurationsundefined.
  ///
  /// In en, this message translates to:
  /// **'Swipe to explore package durations →'**
  String get customerSwipeToExplorePackageDurationsundefined;

  /// No description provided for @customerPricingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Pricing unavailable'**
  String get customerPricingUnavailable;

  /// No description provided for @customerYourAllergenPreferencesAreSaved.
  ///
  /// In en, this message translates to:
  /// **'Your allergen preferences are saved'**
  String get customerYourAllergenPreferencesAreSaved;

  /// No description provided for @customerWellUseYourRecordedAllergenInformationWhenShowingSuitable.
  ///
  /// In en, this message translates to:
  /// **'We’ll use your recorded allergen information when showing suitable meal choices. Please review each meal’s allergen details before ordering.'**
  String get customerWellUseYourRecordedAllergenInformationWhenShowingSuitable;

  /// No description provided for @customerPricingIsTemporarilyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Pricing is temporarily unavailable.'**
  String get customerPricingIsTemporarilyUnavailable;

  /// No description provided for @customerNoPackagesAreCurrentlyAvailableForThisMealPlan.
  ///
  /// In en, this message translates to:
  /// **'No packages are currently available for this meal plan.'**
  String get customerNoPackagesAreCurrentlyAvailableForThisMealPlan;

  /// No description provided for @customerTryAnotherPlanToFindYourDailyMealRoutine.
  ///
  /// In en, this message translates to:
  /// **'Try another plan to find your daily meal routine.'**
  String get customerTryAnotherPlanToFindYourDailyMealRoutine;

  /// No description provided for @customerChooseAnotherPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose another plan'**
  String get customerChooseAnotherPlan;

  /// No description provided for @customerNoMealPlansAreAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'No meal plans are available yet.'**
  String get customerNoMealPlansAreAvailableYet;

  /// No description provided for @customerUnableToLoadMealPlans.
  ///
  /// In en, this message translates to:
  /// **'Unable to load meal plans.'**
  String get customerUnableToLoadMealPlans;

  /// No description provided for @customerChooseANewDeliveryStartDateDeliveryCanStart.
  ///
  /// In en, this message translates to:
  /// **'Choose a new delivery start date. Delivery can start tomorrow or later.'**
  String get customerChooseANewDeliveryStartDateDeliveryCanStart;

  /// No description provided for @customerChooseYourStartDate.
  ///
  /// In en, this message translates to:
  /// **'Choose your start date'**
  String get customerChooseYourStartDate;

  /// No description provided for @customerTapToChooseAnAvailableServiceDay.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose an available service day.'**
  String get customerTapToChooseAnAvailableServiceDay;

  /// No description provided for @customerTapToChooseADifferentServiceDay.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose a different service day.'**
  String get customerTapToChooseADifferentServiceDay;

  /// No description provided for @customerContinueundefined.
  ///
  /// In en, this message translates to:
  /// **'Continue →'**
  String get customerContinueundefined;

  /// No description provided for @customerStartDate2.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get customerStartDate2;

  /// No description provided for @customerSelectADate.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get customerSelectADate;

  /// No description provided for @customerEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get customerEndDate;

  /// No description provided for @customerCalculatedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Calculated automatically'**
  String get customerCalculatedAutomatically;

  /// No description provided for @customerSelectYourStartDate.
  ///
  /// In en, this message translates to:
  /// **'Select your start date'**
  String get customerSelectYourStartDate;

  /// No description provided for @customerSelectedStartDate.
  ///
  /// In en, this message translates to:
  /// **'Selected start date'**
  String get customerSelectedStartDate;

  /// No description provided for @customerPlanEndDate.
  ///
  /// In en, this message translates to:
  /// **'Plan end date'**
  String get customerPlanEndDate;

  /// No description provided for @customerPlanServiceDay.
  ///
  /// In en, this message translates to:
  /// **'Plan service day'**
  String get customerPlanServiceDay;

  /// No description provided for @customerFridayUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Friday unavailable'**
  String get customerFridayUnavailable;

  /// No description provided for @customerSelectAStartDate.
  ///
  /// In en, this message translates to:
  /// **'Select a start date'**
  String get customerSelectAStartDate;

  /// No description provided for @customerConfirmDates.
  ///
  /// In en, this message translates to:
  /// **'Confirm Dates'**
  String get customerConfirmDates;

  /// No description provided for @customerYourSubscription.
  ///
  /// In en, this message translates to:
  /// **'Your subscription'**
  String get customerYourSubscription;

  /// No description provided for @customerActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get customerActive;

  /// No description provided for @customerCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get customerCompleted;

  /// No description provided for @customerPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get customerPaused;

  /// No description provided for @customerAwaitingActivation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Activation'**
  String get customerAwaitingActivation;

  /// No description provided for @customerUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get customerUnderReview;

  /// No description provided for @customerUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get customerUnpaid;

  /// No description provided for @customerPaymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment Pending'**
  String get customerPaymentPending;

  /// No description provided for @customerPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get customerPaid;

  /// No description provided for @customerPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get customerPaymentFailed;

  /// No description provided for @customerRefundUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Refund Under Review'**
  String get customerRefundUnderReview;

  /// No description provided for @customerRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get customerRefunded;

  /// No description provided for @customerPartiallyRefunded.
  ///
  /// In en, this message translates to:
  /// **'Partially Refunded'**
  String get customerPartiallyRefunded;

  /// No description provided for @customerPaymentUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Payment Under Review'**
  String get customerPaymentUnderReview;

  /// No description provided for @customerDietTimeIsReviewingYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Diet Time is reviewing your order.'**
  String get customerDietTimeIsReviewingYourOrder;

  /// No description provided for @customerDietTimeWillReviewYourOrderAndNotifyYou.
  ///
  /// In en, this message translates to:
  /// **'Diet Time will review your order and notify you once it is confirmed.'**
  String get customerDietTimeWillReviewYourOrderAndNotifyYou;

  /// No description provided for @customerDaysPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{count} Days / Week'**
  String customerDaysPerWeek(int count);

  /// No description provided for @customerActivePlans.
  ///
  /// In en, this message translates to:
  /// **'You have {count} active meal plans'**
  String customerActivePlans(int count);

  /// No description provided for @customerOrderReference.
  ///
  /// In en, this message translates to:
  /// **'Please reference order {reference}.'**
  String customerOrderReference(String reference);

  /// No description provided for @customerSelectionDeadline.
  ///
  /// In en, this message translates to:
  /// **'Selection deadline'**
  String get customerSelectionDeadline;

  /// No description provided for @customerQatarTime.
  ///
  /// In en, this message translates to:
  /// **'Qatar time'**
  String get customerQatarTime;

  /// No description provided for @customerOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order status'**
  String get customerOrderStatus;

  /// No description provided for @customerSelected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get customerSelected;

  /// No description provided for @customerYourOrderIsConfirmedAndAwaitingTheRequiredPayment.
  ///
  /// In en, this message translates to:
  /// **'Your order is confirmed and awaiting the required payment.'**
  String get customerYourOrderIsConfirmedAndAwaitingTheRequiredPayment;

  /// No description provided for @addressHomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addressHomeLabel;

  /// No description provided for @addressApartmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get addressApartmentLabel;

  /// No description provided for @addressOfficeLabel.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get addressOfficeLabel;

  /// No description provided for @addressOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get addressOtherLabel;

  /// No description provided for @reviewPackage.
  ///
  /// In en, this message translates to:
  /// **'Review package'**
  String get reviewPackage;

  /// No description provided for @packageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The selected meal package is unavailable. Please review your package.'**
  String get packageUnavailable;

  /// No description provided for @durationPricingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Pricing is unavailable for this duration. Please review your package.'**
  String get durationPricingUnavailable;

  /// No description provided for @planPricingMismatch.
  ///
  /// In en, this message translates to:
  /// **'The selected plan and pricing do not match. Please review your package.'**
  String get planPricingMismatch;

  /// No description provided for @planNotFound.
  ///
  /// In en, this message translates to:
  /// **'This meal plan was not found. Please choose another plan.'**
  String get planNotFound;

  /// No description provided for @planUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This meal plan is no longer available. Please choose another plan.'**
  String get planUnavailable;

  /// No description provided for @availabilityRetry.
  ///
  /// In en, this message translates to:
  /// **'We could not verify this package. Check your connection and retry.'**
  String get availabilityRetry;

  /// No description provided for @saveOrderRetry.
  ///
  /// In en, this message translates to:
  /// **'Your order could not be saved. Please retry or contact Diet Time.'**
  String get saveOrderRetry;

  /// No description provided for @menuButton.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuButton;

  /// No description provided for @dashboardMyPlans.
  ///
  /// In en, this message translates to:
  /// **'My Plans'**
  String get dashboardMyPlans;

  /// No description provided for @dashboardPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get dashboardPendingApproval;

  /// No description provided for @dashboardAwaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Diet Time confirmation'**
  String get dashboardAwaitingConfirmation;

  /// No description provided for @dashboardPlanCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 PLAN} other{{count} PLANS}}'**
  String dashboardPlanCount(int count);
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
