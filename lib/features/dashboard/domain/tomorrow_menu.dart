import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';

class TomorrowMenu {
  const TomorrowMenu({
    required this.subscriptionId,
    required this.dayId,
    required this.deliveryDate,
    required this.planName,
    required this.mealCount,
    required this.snackCount,
    required this.status,
    required this.locked,
    required this.canConfirm,
    required this.cutoffAt,
    required this.serverNow,
    required this.selected,
    required this.meals,
    required this.snacks,
    this.reviewReason,
  });

  factory TomorrowMenu.fromJson(Map<String, dynamic> json) {
    List<DailyMealItem> items(String key) => (json[key] as List)
        .map((item) => DailyMealItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    return TomorrowMenu(
      subscriptionId: json['subscriptionId'] as String,
      dayId: json['subscriptionServiceDayId'] as String?,
      deliveryDate: DateTime.parse(json['deliveryDate'] as String),
      planName: json['mealPlanName'] as String,
      mealCount: json['mealCount'] as int,
      snackCount: json['snackCount'] as int,
      status: json['selectionStatus'] as String,
      locked: json['selectionLocked'] == true,
      canConfirm: json['canConfirm'] == true,
      cutoffAt: DateTime.parse(json['cutoffAt'] as String),
      serverNow: DateTime.parse(json['serverNow'] as String),
      reviewReason: json['reviewReason'] as String?,
      selected: items('selectedMeals'),
      meals: items('availableMeals'),
      snacks: items('availableSnacks'),
    );
  }

  final String subscriptionId;
  final String? dayId;
  final DateTime deliveryDate;
  final String planName;
  final int mealCount;
  final int snackCount;
  final String status;
  final bool locked;
  final bool canConfirm;
  final DateTime cutoffAt;
  final DateTime serverNow;
  final String? reviewReason;
  final List<DailyMealItem> selected;
  final List<DailyMealItem> meals;
  final List<DailyMealItem> snacks;

  bool get finalized =>
      status == 'CUSTOMER_CONFIRMED' || status == 'AUTO_FINALIZED';
}

/// Local drafts never write to the API. Dish identity is shared across categories.
class TomorrowMealDraft {
  TomorrowMealDraft(this.menu) {
    for (final item in menu.selected) {
      final options = item.category == 'meal' ? menu.meals : menu.snacks;
      if (options.any((option) => option.id == item.id)) toggle(item);
    }
  }

  final TomorrowMenu menu;
  final Set<String> mealIds = {};
  final Set<String> snackIds = {};

  bool get complete =>
      mealIds.length == menu.mealCount && snackIds.length == menu.snackCount;
  bool contains(String id) => mealIds.contains(id) || snackIds.contains(id);

  bool toggle(DailyMealItem item) {
    if (item.category != 'meal' && item.category != 'snack') return false;
    final ids = item.category == 'meal' ? mealIds : snackIds;
    if (ids.remove(item.id)) return true;
    if (contains(item.id)) return false;
    final options = item.category == 'meal' ? menu.meals : menu.snacks;
    if (!options.any((option) => option.id == item.id)) return false;
    final limit = item.category == 'meal' ? menu.mealCount : menu.snackCount;
    if (ids.length >= limit) return false;
    ids.add(item.id);
    return true;
  }
}
