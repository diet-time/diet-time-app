abstract final class ApiEndpoints {
  static const phoneOtp = '/api/v1/auth/phone-otp';
  static const guestHome = '/api/v1/guest/home';
  static const guestAllergens = '/api/v1/guest/allergens';
  static const customerProfile = '/api/v1/customer/profile';
  static const mealPlans = '/api/v1/meal-plan-categories';

  static String mealPlanDetails(String mealPlanTemplateId) =>
      '/api/v1/meal-plans/${Uri.encodeComponent(mealPlanTemplateId)}';

  static String guestMealPlanMenu(String planCode) =>
      '/api/v1/guest/meal-plans/${Uri.encodeComponent(planCode)}/menu';

  static String mealDetails(String mealId) => '/api/v1/meals/$mealId';
}
