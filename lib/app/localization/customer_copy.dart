import 'package:flutter/widgets.dart';
import 'package:diet_time/l10n/app_localizations.dart';

// Only catalogued static application copy is translated. Backend content is left intact.
extension CustomerCopy on BuildContext {
  String customerCopy(String value) {
    final copy = lookupAppLocalizations(Localizations.localeOf(this));
    return switch (value) {
      "Tomorrow’s Deliveries" => copy.deliveriesTitle,
      "Confirmed" => copy.deliveriesConfirmed,
      "Selection pending" => copy.deliveriesPending,
      "Ready to confirm" => copy.deliveriesReady,
      "Automatically selected" => copy.deliveriesAutomatic,
      "Locked" => copy.deliveriesLocked,
      "Review & confirm" => copy.deliveriesReviewConfirm,
      "View confirmed meals" => copy.deliveriesViewConfirmed,
      "View selected meals" => copy.deliveriesViewSelected,
      "View menu" => copy.deliveriesViewMenu,
      "Unable to load all deliveries" => copy.deliveriesUnavailable,
      "Action needed" => copy.deliveriesActionNeeded,
      "Delivery update" => copy.deliveriesWaiting,
      "View your dishes" => copy.deliveriesViewDishes,
      "Hide your dishes" => copy.deliveriesHideDishes,
      "Choose before 9:00 PM" => copy.deliveriesDeadline,
      "Choose your meals" => copy.deliveriesChoose,
      "Refresh menu" => copy.deliveriesRefresh,
      "Loading deliveries…" => copy.deliveriesLoading,
      "Meal" => copy.deliveriesMeal,
      "Snack" => copy.deliveriesSnack,
      "View Details" => copy.deliveriesViewDetails,
      "Diet Time" => copy.onboardingBrand,
      "Fuel Right. Feel Light." => copy.tagline,
      "Healthy" => copy.healthy,
      "Your journey starts here." => copy.journeyStartsHere,
      "Eat Well, Feel Great" => copy.landingTitle,
      "Discover tailored meal plans designed for flavor and health. Build lasting habits, one delicious meal at a time." =>
        copy.landingSubtitle,
      "The Plans" => copy.viewPlans,
      "Login" => copy.login,
      "Register" => copy.register,
      "Welcome Back" => copy.welcomeBack,
      "Sign in to continue your healthy journey." => copy.loginSubtitle,
      "Email / Mobile" => copy.emailOrMobile,
      "Password" => copy.password,
      "Show password" => copy.showPassword,
      "Hide password" => copy.hidePassword,
      "Forgot Password?" => copy.forgotPassword,
      "Sign In" => copy.signIn,
      "OR CONTINUE WITH" => copy.orContinueWith,
      "Continue with Apple" => copy.continueWithApple,
      "Continue with Google" => copy.continueWithGoogle,
      "or sign in with" => copy.orSignInWith,
      "Don't have an account?" => copy.noAccount,
      "Create Account" => copy.createAccount,
      "English" => copy.english,
      "العربية" => copy.arabic,
      "This field is required" => copy.requiredField,
      "Enter a valid email address or mobile number" =>
        copy.invalidEmailOrMobile,
      "Password must be at least 8 characters" => copy.passwordTooShort,
      "Home Screen" => copy.homeScreen,
      "Welcome to Diet Time" => copy.onboardingWelcomeTitle,
      "Your account is ready" => copy.postLoginAccountReady,
      "Your plan starts" => copy.postLoginTitleLead,
      "with you" => copy.postLoginTitleAccent,
      "Tell us a little about your routine, goals, and food preferences." =>
        copy.postLoginSupporting,
      "We'll use your answers to shape a plan that feels practical, balanced, and easy to follow." =>
        copy.postLoginSecondary,
      "Personalize My Plan" => copy.postLoginCta,
      "Balanced meals" => copy.postLoginMealBalanced,
      "Flexible choices" => copy.postLoginMealFlexible,
      "Built around your goals" => copy.postLoginMealGoals,
      "Coming soon" => copy.comingSoon,
      "Healthy Meals," => copy.onboardingHealthyMealsTitle,
      "Made Simple." => copy.onboardingHealthyMealsAccent,
      "Delicious, balanced meals delivered daily to support your healthy lifestyle." =>
        copy.onboardingHealthyMealsDescription,
      "Plans That Fit" => copy.onboardingPlansTitle,
      "You Perfectly" => copy.onboardingPlansAccent,
      "Tell us your goals, we'll handle the rest with personalised plans just for you." =>
        copy.onboardingPlansDescription,
      "Fresh. Clean." => copy.onboardingFreshTitle,
      "Always." => copy.onboardingFreshAccent,
      "We use real ingredients with no artificial colors, preservatives or unhealthy fillers." =>
        copy.onboardingFreshDescription,
      "Track. Improve." => copy.onboardingTrackTitle,
      "Live Better." => copy.onboardingTrackAccent,
      "Simple tracking helps you stay consistent and achieve your health goals." =>
        copy.onboardingTrackDescription,
      "Know Your BMI," => copy.onboardingBmiTitle,
      "Build a Better Plan" => copy.onboardingBmiAccent,
      "Calculate your BMI and get a plan shaped around your body and goals." =>
        copy.onboardingBmiDescription,
      "Better Together," => copy.onboardingTogetherTitle,
      "Stronger Together" => copy.onboardingTogetherAccent,
      "Invite friends, share your journey and achieve more together." =>
        copy.onboardingTogetherDescription,
      "View Menu" => copy.onboardingMenu,
      "Start your Plan" => copy.onboardingStartPlan,
      "Healthy eating made simple.\nLet's build a meal plan designed just for you." =>
        copy.onboardingWelcomeSubtitle,
      "Start My Journey" => copy.onboardingStartJourney,
      "Continue" => copy.continueLabel,
      "Previous" => copy.onboardingPrevious,
      "What would you like to achieve?" => copy.onboardingGoalTitle,
      "We'll personalize your meals around your goal." =>
        copy.onboardingGoalSubtitle,
      "Lose Weight" => copy.onboardingLoseWeight,
      "Burn fat while enjoying satisfying meals." =>
        copy.onboardingLoseWeightDescription,
      "Build Muscle" => copy.onboardingBuildMuscle,
      "Protein-focused meals to support strength." =>
        copy.onboardingBuildMuscleDescription,
      "Stay Healthy" => copy.onboardingStayHealthy,
      "Balanced nutrition for everyday wellness." =>
        copy.onboardingStayHealthyDescription,
      "Improve Fitness" => copy.onboardingImproveFitness,
      "Fuel your body for an active lifestyle." =>
        copy.onboardingImproveFitnessDescription,
      "Let's get to know you" => copy.onboardingProfileTitle,
      "A few details help us tailor every meal to you." =>
        copy.onboardingProfileSubtitle,
      "Gender" => copy.onboardingGender,
      "Age" => copy.onboardingAge,
      "Height" => copy.onboardingHeight,
      "Weight" => copy.onboardingWeight,
      "Male" => copy.onboardingMale,
      "Female" => copy.onboardingFemale,
      "Prefer not to say" => copy.onboardingPreferNotToSay,
      "Tell us about your daily routine" => copy.onboardingLifestyleTitle,
      "Choose the option that feels most like your day." =>
        copy.onboardingLifestyleSubtitle,
      "Office Work" => copy.onboardingOfficeWork,
      "Work From Home" => copy.onboardingWorkFromHome,
      "Student" => copy.onboardingStudent,
      "Active Job" => copy.onboardingActiveJob,
      "Shift Worker" => copy.onboardingShiftWorker,
      "How active are you?" => copy.onboardingActivityTitle,
      "We'll balance your meals around your energy needs." =>
        copy.onboardingActivitySubtitle,
      "Mostly Sitting" => copy.onboardingMostlySitting,
      "Light Activity" => copy.onboardingLightActivity,
      "Active Lifestyle" => copy.onboardingActiveLifestyle,
      "Athlete" => copy.onboardingAthlete,
      "What do you enjoy eating?" => copy.onboardingPreferencesTitle,
      "Select as many as you like." => copy.onboardingPreferencesSubtitle,
      "High Protein" => copy.highProtein,
      "Low Carb" => copy.onboardingLowCarb,
      "Vegetarian" => copy.onboardingVegetarian,
      "Vegan" => copy.onboardingVegan,
      "Seafood" => copy.onboardingSeafood,
      "Chicken" => copy.onboardingChicken,
      "Beef" => copy.onboardingBeef,
      "Arabic Cuisine" => copy.onboardingArabicCuisine,
      "International" => copy.onboardingInternational,
      "Mediterranean" => copy.onboardingMediterranean,
      "Healthy Snacks" => copy.onboardingHealthySnacks,
      "Breakfast Lover" => copy.onboardingBreakfastLover,
      "Any food allergies?" => copy.onboardingAllergiesTitle,
      "Select everything we should keep in mind." =>
        copy.onboardingAllergiesSubtitle,
      "Milk" => copy.onboardingMilk,
      "Egg" => copy.onboardingEgg,
      "Fish" => copy.onboardingFish,
      "Shellfish" => copy.onboardingShellfish,
      "Tree Nuts" => copy.onboardingTreeNuts,
      "Peanuts" => copy.onboardingPeanuts,
      "Soy" => copy.onboardingSoy,
      "Sesame" => copy.onboardingSesame,
      "Gluten" => copy.onboardingGluten,
      "No Allergies" => copy.onboardingNoAllergies,
      "Creating your personalized meal plan" => copy.onboardingBuildingTitle,
      "We're preparing meals that match your goals, lifestyle and preferences." =>
        copy.onboardingBuildingSubtitle,
      "View My Options" => copy.onboardingReadyAction,
      "Let's shape your plan" => copy.personalizationIntroTitle,
      "Answer a few simple questions so we can recommend meals that suit your goals, routine, and preferences." =>
        copy.personalizationIntroSubtitle,
      "Begin" => copy.personalizationBegin,
      "Not now" => copy.personalizationNotNow,
      "Choose an option to continue." => copy.personalizationSelectOption,
      "Maintain Weight" => copy.onboardingMaintainWeight,
      "Balanced meals that support your current routine." =>
        copy.onboardingMaintainWeightDescription,
      "Gain Weight" => copy.onboardingGainWeight,
      "Nourishing meals with the energy your goals need." =>
        copy.onboardingGainWeightDescription,
      "Eat Healthier" => copy.onboardingEatHealthier,
      "Make wholesome everyday choices easier." =>
        copy.onboardingEatHealthierDescription,
      "Your wellness snapshot" => copy.bmiSummaryTitle,
      "Your calculated BMI" => copy.bmiCalculatedLabel,
      "BMI is a general screening measure and does not account for muscle mass, body composition, age, or individual health conditions." =>
        copy.bmiDisclaimer,
      "Children and teenagers require age- and sex-specific assessment." =>
        copy.bmiYouthNote,
      "Below standard range" => copy.bmiBelowRange,
      "Within standard range" => copy.bmiWithinRange,
      "Above standard range" => copy.bmiAboveRange,
      "Well above standard range" => copy.bmiWellAboveRange,
      "We'll use this information to highlight meals that may not be suitable for you. Always review the meal's ingredient and allergen details before ordering." =>
        copy.allergySafetyNote,
      "A plan that fits your routine" => copy.recommendationTitle,
      "Matches your primary goal" => copy.recommendationReasonGoal,
      "Fits your activity level" => copy.recommendationReasonActivity,
      "Includes your preferred meal styles" =>
        copy.recommendationReasonPreferences,
      "Considers your recorded allergens" => copy.recommendationReasonAllergens,
      "View Recommended Plan" => copy.viewRecommendedPlan,
      "Compare All Plans" => copy.compareAllPlans,
      "Choose your Language" => copy.chooseLanguage,
      "Select your preferred language to personalize your experience." =>
        copy.languageSelectionSubtitle,
      "Language" => copy.languageLabel,
      "Unable to save language preference. Please try again." =>
        copy.languageSaveError,
      "Loading" => copy.loading,
      "Fresh choices, made for you" => copy.browseMenuTitle,
      "Explore chef-crafted meals prepared with wholesome ingredients." =>
        copy.browseMenuSubtitle,
      "Browse Menu" => copy.browseMenu,
      "Popular meals" => copy.popularMeals,
      "Herb Grilled Chicken" => copy.mealGrilledChicken,
      "Brown rice, greens & tahini" => copy.mealGrilledChickenDetail,
      "Citrus Salmon Bowl" => copy.mealSalmon,
      "Quinoa, avocado & edamame" => copy.mealSalmonDetail,
      "Keto Beef Garden" => copy.mealKeto,
      "Roasted vegetables & herbs" => copy.mealKetoDetail,
      "Choose Your Meal Plan" => copy.choosePlanTitle,
      "Pick the plan that matches your goals. You can change it anytime." =>
        copy.choosePlanSubtitle,
      "Weight Loss" => copy.weightLoss,
      "Balanced portions designed for steady, sustainable progress." =>
        copy.weightLossDescription,
      "Keto" => copy.keto,
      "Low-carb favorites rich in healthy fats and fresh produce." =>
        copy.ketoDescription,
      "Protein-forward meals to support strength and recovery." =>
        copy.highProteinDescription,
      "Balanced Diet" => copy.balancedDiet,
      "Everyday nutrition with a delicious mix of all food groups." =>
        copy.balancedDietDescription,
      "Daily price" => copy.dailyPriceLabel,
      "Daily price unavailable" => copy.dailyPriceUnavailable,
      "Let's Get Started" => copy.otpPhoneTitle,
      "Enter your mobile number to continue." => copy.otpPhoneSubtitle,
      "We will send you a 6-digit verification code." => copy.otpPhoneHelper,
      "Mobile number" => copy.otpMobileNumber,
      "Enter a valid mobile number." => copy.otpInvalidPhone,
      "Unable to send the verification code. Please try again." =>
        copy.otpRequestFailed,
      "Enter the Code" => copy.otpCodeTitle,
      "A 6-digit verification code was sent to:" => copy.otpCodeSubtitle,
      "Code sent to" => copy.otpCodeSentTo,
      "Please enter the code automatically detected or type it manually" =>
        copy.otpCodeEntryHelper,
      "Edit" => copy.otpEditPhone,
      "Didn't get the code?" => copy.otpDidntGetCode,
      "Verify Code" => copy.otpVerifyCode,
      "Resend code" => copy.otpResendCode,
      "Send via SMS" => copy.otpSendViaSms,
      "Send via WhatsApp" => copy.otpSendViaWhatsapp,
      "Resend via WhatsApp" => copy.otpResendViaWhatsapp,
      "The verification code is incorrect. Please try again." =>
        copy.otpIncorrectCode,
      "This verification code has expired. Request a new code." =>
        copy.otpExpiredCode,
      "Too many attempts. Please try again later." => copy.otpTooManyAttempts,
      "Resend is temporarily unavailable. Please try again." =>
        copy.otpResendUnavailable,
      "A new verification code has been sent." => copy.otpResendConfirmation,
      "Test code generated for WhatsApp verification." =>
        copy.otpWhatsappTestGenerated,
      "Meal Plan" => copy.mealPlanHeaderTitle,
      "Choose a plan that fits your lifestyle and goals." =>
        copy.mealPlanHeaderSubtitle,
      "Preparing your new plan" => copy.planSwitchLoadingTitle,
      "We're organizing the best meals for you..." =>
        copy.planSwitchLoadingSubtitle,
      "Cooking up something healthy!" => copy.mealContentLoadingTitle,
      "Fetching today's meals..." => copy.mealContentLoadingSubtitle,
      "Choose your plan" => copy.guestMealPlansTitle,
      "This week's menu" => copy.guestWeeklyMenuTitle,
      "Unable to load the menu." => copy.guestMenuLoadError,
      "Unable to load this meal plan." => copy.guestPlanLoadError,
      "Retry" => copy.retry,
      "No meals available for this selection." => copy.noMealsAvailable,
      "No meals available for this plan." => copy.noMealsAvailableForPlan,
      "Try another date or meal category." => copy.tryAnotherMealFilter,
      "Calories" => copy.caloriesLabel,
      "Protein" => copy.proteinLabel,
      "Carbs" => copy.carbsLabel,
      "Fat" => copy.fatLabel,
      "Ingredients" => copy.mealIngredientsTitle,
      "Allergens" => copy.mealAllergensTitle,
      "Show all" => copy.showAllIngredients,
      "No ingredient information available." => copy.noIngredientsAvailable,
      "No allergens recorded." => copy.noAllergensListed,
      "Read more" => copy.readMore,
      "Show less" => copy.showLess,
      "Micronutrients" => copy.mealMicronutrientsTitle,
      "Fiber" => copy.fiberLabel,
      "Sodium" => copy.sodiumLabel,
      "Invalid OTP. Please try again." => copy.otpInvalidCode,
      "Unable to create or access this account." => copy.otpAccountConflict,
      "Phone login is currently unavailable." => copy.otpPhoneLoginUnavailable,
      "Could not connect. Check your connection and try again." =>
        copy.otpConnectionError,
      "Something went wrong. Please try again." => copy.otpServerError,
      "Resend unavailable in test mode" => copy.otpResendTestUnavailable,
      "Explore Menu" => copy.exploreMenu,
      "Back to Dashboard" => copy.backToDashboard,
      "Daily nutrition total" => copy.dailyNutritionTotal,
      "Nutrition information unavailable" => copy.nutritionUnavailable,
      "Totals unavailable for missing nutritional values." =>
        copy.nutritionTotalsIncomplete,
      "Sugar" => copy.sugarLabel,
      "Saturated fat" => copy.saturatedFatLabel,
      "Trans fat" => copy.transFatLabel,
      "Cholesterol" => copy.cholesterolLabel,
      "Unable to sign in" => copy.customerUnableToSignIn,
      "We could not load takeaway branches. Please try again." =>
        copy.customerWeCouldNotLoadTakeawayBranchesPleaseTryAgain,
      "Choose a future delivery start date; today and Friday are unavailable." =>
        copy.customerChooseAFutureDeliveryStartDateTodayAndFriday,
      "The selected meal configuration is no longer available." =>
        copy.customerTheSelectedMealConfigurationIsNoLongerAvailable,
      "The selected plan duration is no longer available." =>
        copy.customerTheSelectedPlanDurationIsNoLongerAvailable,
      "We could not verify the selected plan. Please try again." =>
        copy.customerWeCouldNotVerifyTheSelectedPlanPleaseTry,
      "Delivery times could not be loaded. Please try again." =>
        copy.customerDeliveryTimesCouldNotBeLoadedPleaseTryAgain,
      "We could not load your customer profile. Please sign in again." =>
        copy.customerWeCouldNotLoadYourCustomerProfilePleaseSign,
      "Saved addresses could not be loaded. Please try again." =>
        copy.customerSavedAddressesCouldNotBeLoadedPleaseTryAgain,
      "Your customer profile is unavailable. Please sign in again." =>
        copy.customerYourCustomerProfileIsUnavailablePleaseSignInAgain,
      "Select an active delivery time slot before saving." =>
        copy.customerSelectAnActiveDeliveryTimeSlotBeforeSaving,
      "Your address could not be saved. Please try again." =>
        copy.customerYourAddressCouldNotBeSavedPleaseTryAgain,
      "We couldn't place your order. Please try again." =>
        copy.customerWeCouldntPlaceYourOrderPleaseTryAgain,
      "Please check your connection and try again." =>
        copy.customerPleaseCheckYourConnectionAndTryAgain,
      "The plan price has changed. Please review the updated total before placing your order." =>
        copy.customerThePlanPriceHasChangedPleaseReviewTheUpdated,
      "This order is already being processed. Please try again." =>
        copy.customerThisOrderIsAlreadyBeingProcessedPleaseTryAgain,
      "The selected plan is no longer available. Please choose another plan." =>
        copy.customerTheSelectedPlanIsNoLongerAvailablePleaseChoose,
      "The selected delivery address is no longer available." =>
        copy.customerTheSelectedDeliveryAddressIsNoLongerAvailable,
      "The selected delivery time is no longer available." =>
        copy.customerTheSelectedDeliveryTimeIsNoLongerAvailable,
      "A selected checkout option is no longer available. Please review your order." =>
        copy.customerASelectedCheckoutOptionIsNoLongerAvailablePlease,
      "Please review your selected meals." =>
        copy.customerPleaseReviewYourSelectedMeals,
      "Please review your selected service days." =>
        copy.customerPleaseReviewYourSelectedServiceDays,
      "Please select another plan start date." =>
        copy.customerPleaseSelectAnotherPlanStartDate,
      "Coupon codes are not supported yet. Remove the coupon and try again." =>
        copy.customerCouponCodesAreNotSupportedYetRemoveTheCoupon,
      "Your order response could not be confirmed. Please check your orders before trying again." =>
        copy.customerYourOrderResponseCouldNotBeConfirmedPleaseCheck,
      "Some address information was not accepted. Please review it." =>
        copy.customerSomeAddressInformationWasNotAcceptedPleaseReviewIt,
      "Your session expired. Please sign in again." =>
        copy.customerYourSessionExpiredPleaseSignInAgain,
      "We could not load your profile." =>
        copy.customerWeCouldNotLoadYourProfile,
      "TRY AGAIN" => copy.customerTRYAGAIN,
      "Browse plans" => copy.customerBrowsePlans,
      "Doha, Qatar" => copy.customerDohaQatar,
      "Customer Address" => copy.customerCustomerAddress,
      "Delivery Address" => copy.customerDeliveryAddress,
      "Choose Delivery Address" => copy.customerChooseDeliveryAddress,
      "Select where you would like your meals delivered." =>
        copy.customerSelectWhereYouWouldLikeYourMealsDelivered,
      "Loading saved addresses..." => copy.customerLoadingSavedAddresses,
      "Add Another Address" => copy.customerAddAnotherAddress,
      "Use This Address" => copy.customerUseThisAddress,
      "Address Details" => copy.customerAddressDetails,
      "Saved addresses" => copy.customerSavedAddresses,
      "SAVE AS *" => copy.customerSAVEASundefined,
      "Building No *" => copy.customerBuildingNoundefined,
      "Street *" => copy.customerStreetundefined,
      "Unit Number" => copy.customerUnitNumber,
      "Zone No *" => copy.customerZoneNoundefined,
      "Area *" => copy.customerAreaundefined,
      "Directions To Reach" => copy.customerDirectionsToReach,
      "Call me when you arrive" => copy.customerCallMeWhenYouArrive,
      "Saving Address..." => copy.customerSavingAddress,
      "Save Address" => copy.customerSaveAddress,
      "Pinned location, Qatar" => copy.customerPinnedLocationQatar,
      "Select an address type before saving." =>
        copy.customerSelectAnAddressTypeBeforeSaving,
      "Complete all required address fields." =>
        copy.customerCompleteAllRequiredAddressFields,
      "Select a delivery time slot before saving." =>
        copy.customerSelectADeliveryTimeSlotBeforeSaving,
      "Select a delivery address or add a new one." =>
        copy.customerSelectADeliveryAddressOrAddANewOne,
      "Select a delivery time slot." => copy.customerSelectADeliveryTimeSlot,
      "Enter a zone or area to search." =>
        copy.customerEnterAZoneOrAreaToSearch,
      "No matching location was found." =>
        copy.customerNoMatchingLocationWasFound,
      "Location search is unavailable. Try again or move the pin." =>
        copy.customerLocationSearchIsUnavailableTryAgainOrMoveThe,
      "Turn on location services to continue." =>
        copy.customerTurnOnLocationServicesToContinue,
      "Location access is blocked. Enable it in device settings." =>
        copy.customerLocationAccessIsBlockedEnableItInDeviceSettings,
      "Location permission is needed to find your current address." =>
        copy.customerLocationPermissionIsNeededToFindYourCurrentAddress,
      "Finding your current location..." =>
        copy.customerFindingYourCurrentLocation,
      "Could not determine your location. Try again or move the pin." =>
        copy.customerCouldNotDetermineYourLocationTryAgainOrMove,
      "Pinned location" => copy.customerPinnedLocation,
      "Search a Zone" => copy.customerSearchAZone,
      "Current Address" => copy.customerCurrentAddress,
      "Google Maps is not configured for this iOS build." =>
        copy.customerGoogleMapsIsNotConfiguredForThisIOSBuild,
      "Add the iOS API key, then clean and rebuild the app." =>
        copy.customerAddTheIOSAPIKeyThenCleanAndRebuild,
      "DELIVERY TIME *" => copy.customerDELIVERYTIMEundefined,
      "Loading delivery times..." => copy.customerLoadingDeliveryTimes,
      "No delivery time slots are currently available." =>
        copy.customerNoDeliveryTimeSlotsAreCurrentlyAvailable,
      "DEFAULT" => copy.customerDEFAULT,
      "No saved addresses yet" => copy.customerNoSavedAddressesYet,
      "Add an address for your meal deliveries." =>
        copy.customerAddAnAddressForYourMealDeliveries,
      "Add Address" => copy.customerAddAddress,
      "Order Submitted" => copy.customerOrderSubmitted,
      "Order Confirmed!" => copy.customerOrderConfirmed,
      "Your order has been received and is awaiting confirmation from Diet Time. We'll notify you once it's reviewed." =>
        copy.customerYourOrderHasBeenReceivedAndIsAwaitingConfirmation,
      "GO TO DASHBOARD" => copy.customerGOTODASHBOARD,
      "ORDER NUMBER" => copy.customerORDERNUMBER,
      "PLAN" => copy.customerPLAN,
      "PAYMENT" => copy.customerPAYMENT,
      "PACKAGE" => copy.customerPACKAGE,
      "FULFILLMENT" => copy.customerFULFILLMENT,
      "Takeaway" => copy.customerTakeaway,
      "PLAN PERIOD" => copy.customerPLANPERIOD,
      "FIRST COLLECTION" => copy.customerFIRSTCOLLECTION,
      "FIRST DELIVERY" => copy.customerFIRSTDELIVERY,
      "DELIVERY TO" => copy.customerDELIVERYTO,
      "TOTAL" => copy.customerTOTAL,
      "STATUS" => copy.customerSTATUS,
      "Order confirmation is unavailable." =>
        copy.customerOrderConfirmationIsUnavailable,
      "Verifying your selected plan..." =>
        copy.customerVerifyingYourSelectedPlan,
      "Your Plan Details" => copy.customerYourPlanDetails,
      "This package is available for takeaway only." =>
        copy.customerThisPackageIsAvailableForTakeawayOnly,
      "Home Delivery" => copy.customerHomeDelivery,
      "COLLECTION BRANCH" => copy.customerCOLLECTIONBRANCH,
      "No takeaway branches are currently available." =>
        copy.customerNoTakeawayBranchesAreCurrentlyAvailable,
      "DELIVERY ADDRESS & TIME SLOT" => copy.customerDELIVERYADDRESSTIMESLOT,
      "Start Date" => copy.customerStartDate,
      "Select your service dates" => copy.customerSelectYourServiceDates,
      "Order Total" => copy.customerOrderTotal,
      "PLACE ORDER" => copy.customerPLACEORDER,
      "PLACING ORDER..." => copy.customerPLACINGORDER,
      "PREPARING ORDER..." => copy.customerPREPARINGORDER,
      "No delivery address selected" => copy.customerNoDeliveryAddressSelected,
      "Add Delivery Address" => copy.customerAddDeliveryAddress,
      "Change" => copy.customerChange,
      "Select a delivery time slot" => copy.customerSelectADeliveryTimeSlot2,
      "Choose a meal plan before reviewing your summary." =>
        copy.customerChooseAMealPlanBeforeReviewingYourSummary,
      "Browse Plans" => copy.customerBrowsePlans2,
      "We could not load your dashboard. Please try again." =>
        copy.customerWeCouldNotLoadYourDashboardPleaseTryAgain,
      "We could not load your orders. Please try again." =>
        copy.customerWeCouldNotLoadYourOrdersPleaseTryAgain,
      "HOME" => copy.customerHOME,
      "ORDERS" => copy.customerORDERS,
      "CALENDAR" => copy.customerCALENDAR,
      "PROFILE" => copy.customerPROFILE,
      "Profile updated successfully" => copy.customerProfileUpdatedSuccessfully,
      "Unable to load your profile." => copy.customerUnableToLoadYourProfile,
      "Questionnaire updated successfully" =>
        copy.customerQuestionnaireUpdatedSuccessfully,
      "Logout" => copy.customerLogout,
      "Are you sure you want to logout?" =>
        copy.customerAreYouSureYouWantToLogout,
      "Cancel" => copy.customerCancel,
      "Your session has expired. Please sign in again." =>
        copy.customerYourSessionHasExpiredPleaseSignInAgain,
      "SIGN IN" => copy.customerSIGNIN,
      "Your customer profile could not be found." =>
        copy.customerYourCustomerProfileCouldNotBeFound,
      "YOUR ACTIVE PLAN" => copy.customerYOURACTIVEPLAN,
      "MY ACTIVE PLANS" => copy.customerMYACTIVEPLANS,
      "ORDER ANOTHER PLAN" => copy.customerORDERANOTHERPLAN,
      "QUICK ACTIONS" => copy.customerQUICKACTIONS,
      "PREVIOUS ORDERS" => copy.customerPREVIOUSORDERS,
      "MY ORDERS" => copy.customerMYORDERS,
      "VIEW ALL" => copy.customerVIEWALL,
      "NO ACTIVE PLAN" => copy.customerNOACTIVEPLAN,
      "You don't have an active meal plan right now." =>
        copy.customerYouDontHaveAnActiveMealPlanRightNow,
      "CHOOSE A PLAN" => copy.customerCHOOSEAPLAN,
      "Schedule ready" => copy.customerScheduleReady,
      "Collect from Diet Time" => copy.customerCollectFromDietTime,
      "VIEW PLAN" => copy.customerVIEWPLAN,
      "DETAILS" => copy.customerDETAILS,
      "My Plan" => copy.customerMyPlan,
      "Orders" => copy.customerOrders,
      "New Plan" => copy.customerNewPlan,
      "Support" => copy.customerSupport,
      "Support will be available soon." =>
        copy.customerSupportWillBeAvailableSoon,
      "Delivery Calendar" => copy.customerDeliveryCalendar,
      "No active delivery calendar" => copy.customerNoActiveDeliveryCalendar,
      "Your delivery dates will appear here when a meal plan is active." =>
        copy.customerYourDeliveryDatesWillAppearHereWhenAMeal,
      "ALL" => copy.customerALL,
      "My Orders" => copy.customerMyOrders,
      "All your meal orders in one place" =>
        copy.customerAllYourMealOrdersInOnePlace,
      "All Orders" => copy.customerAllOrders,
      "Pending Confirmation" => copy.customerPendingConfirmation,
      "On Hold" => copy.customerOnHold,
      "Rejected" => copy.customerRejected,
      "Pending" => copy.customerPending,
      "Cancelled" => copy.customerCancelled,
      "No orders found for this status." =>
        copy.customerNoOrdersFoundForThisStatus,
      "Order placed" => copy.customerOrderPlaced,
      "View Details  →" => copy.customerViewDetailsundefined,
      "Good morning" => copy.customerGoodMorning,
      "Good afternoon" => copy.customerGoodAfternoon,
      "Good evening" => copy.customerGoodEvening,
      "Your meal plan is active" => copy.customerYourMealPlanIsActive,
      "Ready when you are" => copy.customerReadyWhenYouAre,
      "Your meal plans at a glance" => copy.customerYourMealPlansAtAGlance,
      "Mon" => copy.customerMon,
      "Tue" => copy.customerTue,
      "Wed" => copy.customerWed,
      "Thu" => copy.customerThu,
      "Fri" => copy.customerFri,
      "Sat" => copy.customerSat,
      "Sun" => copy.customerSun,
      "We couldn’t load all your delivery orders." =>
        copy.customerWeCouldntLoadAllYourDeliveryOrders,
      "Unable to update profile. Please try again." =>
        copy.customerUnableToUpdateProfilePleaseTryAgain,
      "Profile" => copy.customerProfile,
      "Customer Profile" => copy.customerCustomerProfile,
      "View or update your personal information" =>
        copy.customerViewOrUpdateYourPersonalInformation,
      "Questionnaire" || "Adjust My Plan" => copy.customerQuestionnaire,
      "Contact Diet Time for help with your plan." =>
        copy.customerPlanSupportHelp,
      "Capture your goals and food preferences" =>
        copy.customerCaptureYourGoalsAndFoodPreferences,
      "Add or edit your delivery address" =>
        copy.customerAddOrEditYourDeliveryAddress,
      "Please sign in again to view your meals." =>
        copy.customerPleaseSignInAgainToViewYourMeals,
      "We couldn’t load your meals for this day. Please try again." =>
        copy.customerWeCouldntLoadYourMealsForThisDayPlease,
      "The menu for this date could not be confirmed." =>
        copy.customerTheMenuForThisDateCouldNotBeConfirmed,
      "We’ve selected your meals for this day. You can change them before the selection deadline." =>
        copy.customerWeveSelectedYourMealsForThisDayYouCan,
      "The selection deadline has passed. Your meals are locked for kitchen preparation." =>
        copy.customerTheSelectionDeadlineHasPassedYourMealsAreLocked,
      "Your meals are read-only for this day." =>
        copy.customerYourMealsAreReadonlyForThisDay,
      "Your meals for this day" => copy.customerYourMealsForThisDay,
      "Your meals are being reviewed by our team. Please check back shortly." =>
        copy.customerYourMealsAreBeingReviewedByOurTeamPlease,
      "Selected for you" => copy.customerSelectedForYou,
      "Your choice" => copy.customerYourChoice,
      "Your meal change has been saved." =>
        copy.customerYourMealChangeHasBeenSaved,
      "The selection deadline has passed. Close this sheet to view your saved meals." =>
        copy.customerTheSelectionDeadlineHasPassedCloseThisSheetTo,
      "Your choices or selection deadline have changed. Close this sheet and refresh the day." =>
        copy.customerYourChoicesOrSelectionDeadlineHaveChangedCloseThis,
      "That meal is no longer available. Please choose another option or refresh the day." =>
        copy.customerThatMealIsNoLongerAvailablePleaseChooseAnother,
      "We couldn’t save this change. Your saved meals are unchanged. Please try again." =>
        copy.customerWeCouldntSaveThisChangeYourSavedMealsAre,
      "Change meal" => copy.customerChangeMeal,
      "Close" => copy.customerClose,
      "There are no other eligible dishes for this selection on this day." =>
        copy.customerThereAreNoOtherEligibleDishesForThisSelection,
      "Selected replacement" => copy.customerSelectedReplacement,
      "Available for this day" => copy.customerAvailableForThisDay,
      "Saving changes…" => copy.customerSavingChanges,
      "Save Changes" => copy.customerSaveChanges,
      "Change Meal" => copy.customerChangeMeal2,
      "Loading meals for the selected day" =>
        copy.customerLoadingMealsForTheSelectedDay,
      "Automatically Selected" => copy.customerAutomaticallySelected,
      "Customized" => copy.customerCustomized,
      "Delivered" => copy.customerDelivered,
      "Our team is reviewing this day" =>
        copy.customerOurTeamIsReviewingThisDay,
      "Edit Profile" => copy.customerEditProfile,
      "Full Name is required." => copy.customerFullNameIsRequired,
      "Full Name must be at least 2 characters." =>
        copy.customerFullNameMustBeAtLeast2Characters,
      "Full Name must be 150 characters or fewer." =>
        copy.customerFullNameMustBe150CharactersOrFewer,
      "Full Name" => copy.customerFullName,
      "Mobile Number" => copy.customerMobileNumber,
      "Contact support or use Change Mobile Number to update your login number." =>
        copy.customerContactSupportOrUseChangeMobileNumberToUpdate,
      "Date of Birth" => copy.customerDateOfBirth,
      "Saving..." => copy.customerSaving,
      "Discard changes?" => copy.customerDiscardChanges,
      "You have unsaved changes. Are you sure you want to leave?" =>
        copy.customerYouHaveUnsavedChangesAreYouSureYouWant,
      "Keep Editing" => copy.customerKeepEditing,
      "Discard" => copy.customerDiscard,
      "Back" => copy.customerBack,
      "Order Details" => copy.customerOrderDetails,
      "Request cancellation" => copy.customerRequestCancellation,
      "The order could not be cancelled. Refresh the order or contact Diet Time." =>
        copy.customerTheOrderCouldNotBeCancelledRefreshTheOrder,
      "MEALS INCLUDED" => copy.customerMEALSINCLUDED,
      "COLLECTION DAYS" => copy.customerCOLLECTIONDAYS,
      "DELIVERY DAYS" => copy.customerDELIVERYDAYS,
      "DELIVERY ADDRESS" => copy.customerDELIVERYADDRESS,
      "DELIVERY TIME" => copy.customerDELIVERYTIME,
      "PRICING" => copy.customerPRICING,
      "PAYMENT STATUS" => copy.customerPAYMENTSTATUS,
      "Thank you for your order!" => copy.customerThankYouForYourOrder,
      "Your plan and delivery schedule are confirmed above." =>
        copy.customerYourPlanAndDeliveryScheduleAreConfirmedAbove,
      "Need Help?" => copy.customerNeedHelp,
      "Contact Support" => copy.customerContactSupport,
      "We couldn't load this order." => copy.customerWeCouldntLoadThisOrder,
      "Cancel this order?" => copy.customerCancelThisOrder,
      "Reason" => copy.customerReason,
      "Keep order" => copy.customerKeepOrder,
      "Confirm cancellation" => copy.customerConfirmCancellation,
      "This order could not be loaded for your account. Refresh your dashboard or contact our team with your order reference." =>
        copy.customerThisOrderCouldNotBeLoadedForYourAccount,
      "We could not connect to load your menu. Check your connection and try again." =>
        copy.customerWeCouldNotConnectToLoadYourMenuCheck,
      "The menu service could not load your order’s dishes. Please refresh or contact our team." =>
        copy.customerTheMenuServiceCouldNotLoadYourOrdersDishes,
      "Confirm your meals" => copy.customerConfirmYourMeals,
      "Your selections cannot be changed after confirmation." =>
        copy.customerYourSelectionsCannotBeChangedAfterConfirmation,
      "Confirm" => copy.customerConfirm,
      "The 9:00 PM deadline has passed. Your automatic meals are being finalized." =>
        copy.customerThe900PMDeadlineHasPassedYourAutomaticMeals,
      "Your meals have already been finalized. Here are your saved dishes." =>
        copy.customerYourMealsHaveAlreadyBeenFinalizedHereAreYour,
      "Your subscription is no longer active for this delivery." =>
        copy.customerYourSubscriptionIsNoLongerActiveForThisDelivery,
      "A dish is no longer available. Please review the refreshed menu." =>
        copy.customerADishIsNoLongerAvailablePleaseReviewThe,
      "We could not verify your confirmation. Please check your connection and refresh before trying again." =>
        copy.customerWeCouldNotVerifyYourConfirmationPleaseCheckYour,
      "Unable to confirm your meals. Please try again." =>
        copy.customerUnableToConfirmYourMealsPleaseTryAgain,
      "Tomorrow’s Menu" => copy.customerTomorrowsMenu,
      "Automatically finalized" => copy.customerAutomaticallyFinalized,
      "Hide confirmed meals" => copy.customerHideConfirmedMeals,
      "Selection closes today at 9:00 PM Qatar time." =>
        copy.customerSelectionClosesTodayAt900PMQatarTime,
      "Meals" => copy.customerMeals,
      "Snacks" => copy.customerSnacks,
      "Confirm My Meals" => copy.customerConfirmMyMeals,
      "Replace a meal" => copy.customerReplaceAMeal,
      "Replace a snack" => copy.customerReplaceASnack,
      "No eligible dishes are currently configured. Our team will review this delivery." =>
        copy.customerNoEligibleDishesAreCurrentlyConfiguredOurTeamWill,
      "Upcoming Meals" => copy.customerUpcomingMeals,
      "We couldn’t load all your delivery meals." =>
        copy.customerWeCouldntLoadAllYourDeliveryMeals,
      "Meals have not been assigned to this delivery yet. Our team will review it." =>
        copy.customerMealsHaveNotBeenAssignedToThisDeliveryYet,
      "Meals chosen for you" => copy.customerMealsChosenForYou,
      "Your choices confirmed" => copy.customerYourChoicesConfirmed,
      "Service day" => copy.customerServiceDay,
      "Non-service day" => copy.customerNonserviceDay,
      "Non-service" => copy.customerNonservice,
      "Auto-selected" => copy.customerAutoselected,
      "Delivery" => copy.customerDelivery,
      "Scheduled" => copy.customerScheduled,
      "No upcoming deliveries are scheduled." =>
        copy.customerNoUpcomingDeliveriesAreScheduled,
      "Service runs Saturday to Thursday. Friday is a non-service day." =>
        copy.customerServiceRunsSaturdayToThursdayFridayIsANonservice,
      "Being prepared" => copy.customerBeingPrepared,
      "On the way" => copy.customerOnTheWay,
      "Skipped" => copy.customerSkipped,
      "Choose your language" => copy.customerChooseYourLanguage,
      "All" => copy.customerAll,
      "Your draft could not be saved. Please try again." =>
        copy.customerYourDraftCouldNotBeSavedPleaseTryAgain,
      "Unable to load your saved profile." =>
        copy.customerUnableToLoadYourSavedProfile,
      "Your profile changed elsewhere. We reloaded it; please review and retry." =>
        copy.customerYourProfileChangedElsewhereWeReloadedItPleaseReview,
      "Could not save your progress. Check your connection." =>
        copy.customerCouldNotSaveYourProgressCheckYourConnection,
      "Select" => copy.customerSelect,
      "No food preferences" => copy.customerNoFoodPreferences,
      "Search allergies..." => copy.customerSearchAllergies,
      "Personalized" => copy.customerPersonalized,
      "Balanced" => copy.customerBalanced,
      "Made for you" => copy.customerMadeForYou,
      "Unable to load allergens." => copy.customerUnableToLoadAllergens,
      "We'll always highlight meals that are safe for you." =>
        copy.customerWellAlwaysHighlightMealsThatAreSafeForYou,
      "No allergies found." => copy.customerNoAllergiesFound,
      "Here's a quick overview of you." =>
        copy.customerHeresAQuickOverviewOfYou,
      "Goal" => copy.customerGoal,
      "Activity Level" => copy.customerActivityLevel,
      "Not calculated yet" => copy.customerNotCalculatedYet,
      "Protein target" => copy.customerProteinTarget,
      "personalize your Diet Time experience." =>
        copy.customerPersonalizeYourDietTimeExperience,
      "Your goals" => copy.customerYourGoals,
      "Your profile" => copy.customerYourProfile,
      "Your lifestyle" => copy.customerYourLifestyle,
      "Your food preferences" => copy.customerYourFoodPreferences,
      "Your health & allergies" => copy.customerYourHealthAllergies,
      "You're all set!" => copy.customerYoureAllSet,
      "You can now explore the Diet Time menu." =>
        copy.customerYouCanNowExploreTheDietTimeMenu,
      "We couldn't load your profile." => copy.customerWeCouldntLoadYourProfile,
      "What should we call you?" => copy.customerWhatShouldWeCallYou,
      "Your name" => copy.customerYourName,
      "Unable to save your name. Please try again." =>
        copy.customerUnableToSaveYourNamePleaseTryAgain,
      "Your answers are kept on this phone. Please retry saving." =>
        copy.customerYourAnswersAreKeptOnThisPhonePleaseRetry,
      "Pick how many meals you'd like each day." =>
        copy.customerPickHowManyMealsYoudLikeEachDay,
      "Swipe to explore meal packages →" =>
        copy.customerSwipeToExploreMealPackagesundefined,
      "Choose your duration" => copy.customerChooseYourDuration,
      "Currently unavailable" => copy.customerCurrentlyUnavailable,
      "Swipe to explore package durations →" =>
        copy.customerSwipeToExplorePackageDurationsundefined,
      "Pricing unavailable" => copy.customerPricingUnavailable,
      "Your allergen preferences are saved" =>
        copy.customerYourAllergenPreferencesAreSaved,
      "We’ll use your recorded allergen information when showing suitable meal choices. Please review each meal’s allergen details before ordering." =>
        copy.customerWellUseYourRecordedAllergenInformationWhenShowingSuitable,
      "Pricing is temporarily unavailable." =>
        copy.customerPricingIsTemporarilyUnavailable,
      "No packages are currently available for this meal plan." =>
        copy.customerNoPackagesAreCurrentlyAvailableForThisMealPlan,
      "Try another plan to find your daily meal routine." =>
        copy.customerTryAnotherPlanToFindYourDailyMealRoutine,
      "Choose another plan" => copy.customerChooseAnotherPlan,
      "No meal plans are available yet." =>
        copy.customerNoMealPlansAreAvailableYet,
      "Unable to load meal plans." => copy.customerUnableToLoadMealPlans,
      "Choose a new delivery start date. Delivery can start tomorrow or later." =>
        copy.customerChooseANewDeliveryStartDateDeliveryCanStart,
      "Choose your start date" => copy.customerChooseYourStartDate,
      "Tap to choose an available service day." =>
        copy.customerTapToChooseAnAvailableServiceDay,
      "Tap to choose a different service day." =>
        copy.customerTapToChooseADifferentServiceDay,
      "Continue →" => copy.customerContinueundefined,
      "Start date" => copy.customerStartDate2,
      "Select a date" => copy.customerSelectADate,
      "End date" => copy.customerEndDate,
      "Calculated automatically" => copy.customerCalculatedAutomatically,
      "Select your start date" => copy.customerSelectYourStartDate,
      "Selected start date" => copy.customerSelectedStartDate,
      "Plan end date" => copy.customerPlanEndDate,
      "Plan service day" => copy.customerPlanServiceDay,
      "Friday unavailable" => copy.customerFridayUnavailable,
      "Select a start date" => copy.customerSelectAStartDate,
      "Confirm Dates" => copy.customerConfirmDates,
      "Your subscription" => copy.customerYourSubscription,
      "Active" => copy.customerActive,
      "Completed" => copy.customerCompleted,
      "Paused" => copy.customerPaused,
      "Awaiting Activation" => copy.customerAwaitingActivation,
      "Under Review" => copy.customerUnderReview,
      "Unpaid" => copy.customerUnpaid,
      "Payment Pending" => copy.customerPaymentPending,
      "Paid" => copy.customerPaid,
      "Payment Failed" => copy.customerPaymentFailed,
      "Refund Under Review" => copy.customerRefundUnderReview,
      "Refunded" => copy.customerRefunded,
      "Partially Refunded" => copy.customerPartiallyRefunded,
      "Payment Under Review" => copy.customerPaymentUnderReview,
      "Diet Time is reviewing your order." =>
        copy.customerDietTimeIsReviewingYourOrder,
      "Diet Time will review your order and notify you once it is confirmed." =>
        copy.customerDietTimeWillReviewYourOrderAndNotifyYou,
      "Selection deadline" => copy.customerSelectionDeadline,
      "Qatar time" => copy.customerQatarTime,
      "Order status" => copy.customerOrderStatus,
      "selected" => copy.customerSelected,
      "Your order is confirmed and awaiting the required payment." =>
        copy.customerYourOrderIsConfirmedAndAwaitingTheRequiredPayment,
      'Home' => copy.addressHomeLabel,
      'Apartment' => copy.addressApartmentLabel,
      'Office' => copy.addressOfficeLabel,
      'Other' => copy.addressOtherLabel,
      "Review package" => copy.reviewPackage,
      "The selected meal package is unavailable. Please review your package." =>
        copy.packageUnavailable,
      "Pricing is unavailable for this duration. Please review your package." =>
        copy.durationPricingUnavailable,
      "The selected plan and pricing do not match. Please review your package." =>
        copy.planPricingMismatch,
      "This meal plan was not found. Please choose another plan." =>
        copy.planNotFound,
      "This meal plan is no longer available. Please choose another plan." =>
        copy.planUnavailable,
      "We could not verify this package. Check your connection and retry." =>
        copy.availabilityRetry,
      "Your order could not be saved. Please retry or contact Diet Time." =>
        copy.saveOrderRetry,
      _ => value,
    };
  }
}
