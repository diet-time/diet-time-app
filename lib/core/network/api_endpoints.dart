abstract final class ApiEndpoints {
  static const phoneOtp = '/api/v1/auth/phone-otp';
  static const refreshSession = '/api/v1/auth/refresh';
  static const guestHome = '/api/v1/guest/home';
  static const guestAllergens = '/api/v1/guest/allergens';
  static const customerProfile = '/api/v1/customer/profile';
  static const mealPlans = '/api/v1/meal-plan-categories';
  static const deliveryTimeSlots = '/api/v1/delivery-time-slots';
  static const orders = '/api/v1/orders';

  static String customerAddresses(String customerProfileId) =>
      '/api/v1/customer-profiles/${Uri.encodeComponent(customerProfileId)}/addresses';

  static String customerAddress(String customerProfileId, String addressId) =>
      '${customerAddresses(customerProfileId)}/${Uri.encodeComponent(addressId)}';

  static String customerOrders(String customerProfileId) =>
      '/api/v1/customer-profiles/${Uri.encodeComponent(customerProfileId)}/orders';

  static String order(String orderId) =>
      '$orders/${Uri.encodeComponent(orderId)}';

  static String mealPlanDetails(String mealPlanTemplateId) =>
      '/api/v1/meal-plans/${Uri.encodeComponent(mealPlanTemplateId)}';

  static String mealPlanPurchaseOptions(String mealPlanCode) =>
      '/api/v1/customer/meal-plans/${Uri.encodeComponent(mealPlanCode)}/purchase-options';

  static String guestMealPlanMenu(String planCode) =>
      '/api/v1/guest/meal-plans/${Uri.encodeComponent(planCode)}/menu';

  static String mealDetails(String mealId) => '/api/v1/meals/$mealId';
}
