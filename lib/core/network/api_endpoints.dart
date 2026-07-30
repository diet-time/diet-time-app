abstract final class ApiEndpoints {
  static const guestHome = '/api/v1/guest/home';
  static const guestAllergens = '/api/v1/guest/allergens';
  static const customerProfile = '/api/v1/customer/profile';

  static String guestMealPlanMenu(String planCode) =>
      '/api/v1/guest/meal-plans/${Uri.encodeComponent(planCode)}/menu';

  static String mealDetails(String mealId) => '/api/v1/meals/$mealId';
}
