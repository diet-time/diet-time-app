import 'package:diet_time/features/menu/domain/meal_nutrition.dart';

class UpcomingMealDay {
  const UpcomingMealDay({
    required this.id,
    required this.date,
    required this.status,
    this.orderId,
    this.subscriptionId,
    this.planName,
    this.mealCount,
    this.snackCount,
    this.selectionStatus,
    this.selectionLocked = false,
    this.deliveryStatus = 'PLANNED',
  });
  factory UpcomingMealDay.fromJson(Map<String, dynamic> json) =>
      UpcomingMealDay(
        id: json['subscriptionServiceDayId'] as String,
        date: DateTime.parse(json['deliveryDate'] as String),
        status: json['status'] as String,
        orderId: json['orderId'] as String?,
        subscriptionId: json['subscriptionId'] as String?,
        planName: json['planName'] as String?,
        mealCount: json['mealCount'] as int?,
        snackCount: json['snackCount'] as int?,
        selectionStatus: json['selectionStatus'] as String?,
        selectionLocked: json['selectionLocked'] == true,
        deliveryStatus: json['deliveryStatus'] as String? ?? 'PLANNED',
      );
  final String id;
  final DateTime date;
  final String status;
  final String? orderId;
  final String? subscriptionId;
  final String? planName;
  final int? mealCount;
  final int? snackCount;
  final String? selectionStatus;
  final bool selectionLocked;
  final String deliveryStatus;
}

class DailyMealItem {
  const DailyMealItem({
    required this.id,
    required this.optionId,
    required this.name,
    required this.category,
    this.description,
    this.imageUrl,
    this.calories,
    MealNutrition? nutrition,
    this.quantity = 1,
  }) : _nutrition = nutrition;
  factory DailyMealItem.fromJson(Map<String, dynamic> json) => DailyMealItem(
    id: json['mealItemId'] as String,
    optionId: json['slotOptionId'] as String,
    name: json['mealName'] as String,
    category: json['category'] as String,
    description: json['description'] as String?,
    imageUrl: json['imageUrl'] as String?,
    calories: (json['calories'] as num?)?.toDouble(),
    nutrition: json['nutrition'] is Map<String, dynamic>
        ? MealNutrition.fromJson(json['nutrition'] as Map<String, dynamic>)
        : MealNutrition(calories: (json['calories'] as num?)?.toDouble()),
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  );
  final String id;
  final String optionId;
  final String name;
  final String category;
  final String? description;
  final String? imageUrl;
  final double? calories;
  final MealNutrition? _nutrition;
  MealNutrition get nutrition =>
      _nutrition ?? MealNutrition(calories: calories);
  final int quantity;
}

class AssignedDailyMeal {
  const AssignedDailyMeal({
    required this.id,
    required this.source,
    required this.meal,
    this.selectionNumber,
  });
  factory AssignedDailyMeal.fromJson(Map<String, dynamic> json) =>
      AssignedDailyMeal(
        id: json['selectionId'] as String,
        source: json['selectionSource'] as String,
        meal: DailyMealItem.fromJson(json['meal'] as Map<String, dynamic>),
        selectionNumber: json['selectionNumber'] as int?,
      );
  final String id;
  final String source;
  final DailyMealItem meal;
  final int? selectionNumber;
}

class DailyMealMenu {
  const DailyMealMenu({
    required this.dayId,
    required this.date,
    required this.mealCount,
    required this.snackCount,
    required this.status,
    required this.canEdit,
    required this.revision,
    required this.selected,
    required this.alternatives,
    this.cutoffAt,
    this.lockReason,
    this.orderId,
    this.subscriptionId,
    this.selectionStatus,
    this.selectionLocked = false,
    this.deliveryStatus = 'PLANNED',
  });
  factory DailyMealMenu.fromJson(Map<String, dynamic> json) => DailyMealMenu(
    dayId: json['subscriptionServiceDayId'] as String,
    orderId: json['orderId'] as String?,
    subscriptionId: json['subscriptionId'] as String?,
    selectionStatus: json['selectionStatus'] as String?,
    selectionLocked: json['selectionLocked'] == true,
    deliveryStatus: json['deliveryStatus'] as String? ?? 'PLANNED',
    date: DateTime.parse(json['deliveryDate'] as String),
    mealCount: json['mealCount'] as int,
    snackCount: json['snackCount'] as int,
    status: json['status'] as String,
    canEdit: json['canEdit'] == true,
    revision: json['revision'] as int,
    cutoffAt: DateTime.tryParse(json['cutoffAt']?.toString() ?? ''),
    lockReason: json['lockReason'] as String?,
    selected: (json['selectedMeals'] as List)
        .map((j) => AssignedDailyMeal.fromJson(j as Map<String, dynamic>))
        .toList(),
    alternatives: (json['availableAlternatives'] as List)
        .map((j) => DailyMealItem.fromJson(j as Map<String, dynamic>))
        .toList(),
  );
  final String dayId;
  final String? orderId;
  final String? subscriptionId;
  final String? selectionStatus;
  final bool selectionLocked;
  final String deliveryStatus;
  final DateTime date;
  final int mealCount;
  final int snackCount;
  final String status;
  final bool canEdit;
  final int revision;
  final DateTime? cutoffAt;
  final String? lockReason;
  final List<AssignedDailyMeal> selected;
  final List<DailyMealItem> alternatives;

  bool get deadlinePassed =>
      cutoffAt != null && !DateTime.now().toUtc().isBefore(cutoffAt!.toUtc());
  bool get editable =>
      canEdit &&
      !selectionLocked &&
      selectionStatus != 'CUSTOMER_CONFIRMED' &&
      selectionStatus != 'AUTO_FINALIZED' &&
      deliveryStatus != 'DELIVERED' &&
      deliveryStatus != 'CANCELLED' &&
      deliveryStatus != 'SKIPPED' &&
      !deadlinePassed;
}
