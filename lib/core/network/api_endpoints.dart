abstract final class ApiEndpoints {
  static const guestHome = '/api/v1/guest/home';

  static String mealDetails(String mealId) => '/api/v1/meals/$mealId';
}
