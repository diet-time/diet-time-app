abstract final class ApiEndpoints {
  static const guestHome = '/api/v1/guest/home';
  static const guestAllergens = '/api/v1/guest/allergens';
  static const customerProfile = '/api/v1/customer/profile';
  static const guestSession = '/api/v1/guest/session';
  static const guestProfile = '/api/v1/guest/profile';
  static const guestPlanRecommendations = '/api/v1/guest/plan-recommendations';
  static const linkGuestProfile = '/api/v1/customer/profile/link-guest';

  static String guestMealPlanMenu(String planCode) =>
      '/api/v1/guest/meal-plans/${Uri.encodeComponent(planCode)}/menu';

  static String mealDetails(String mealId) => '/api/v1/meals/$mealId';
}
