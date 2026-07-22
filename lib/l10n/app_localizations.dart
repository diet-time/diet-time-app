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

  /// The heading shown above the language choices.
  String get chooseLanguage;

  /// Explains why the user is choosing a language.
  String get languageSelectionSubtitle;

  /// Label for the language choice card.
  String get languageLabel;
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
