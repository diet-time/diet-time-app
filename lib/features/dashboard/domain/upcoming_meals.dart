class UpcomingMealDay {
  const UpcomingMealDay({
    required this.id,
    required this.date,
    required this.status,
  });
  factory UpcomingMealDay.fromJson(Map<String, dynamic> json) =>
      UpcomingMealDay(
        id: json['subscriptionServiceDayId'] as String,
        date: DateTime.parse(json['deliveryDate'] as String),
        status: json['status'] as String,
      );
  final String id;
  final DateTime date;
  final String status;
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
  });
  factory DailyMealItem.fromJson(Map<String, dynamic> json) => DailyMealItem(
    id: json['mealItemId'] as String,
    optionId: json['slotOptionId'] as String,
    name: json['mealName'] as String,
    category: json['category'] as String,
    description: json['description'] as String?,
    imageUrl: json['imageUrl'] as String?,
    calories: (json['calories'] as num?)?.toDouble(),
  );
  final String id;
  final String optionId;
  final String name;
  final String category;
  final String? description;
  final String? imageUrl;
  final double? calories;
}

class AssignedDailyMeal {
  const AssignedDailyMeal({
    required this.id,
    required this.source,
    required this.meal,
  });
  factory AssignedDailyMeal.fromJson(Map<String, dynamic> json) =>
      AssignedDailyMeal(
        id: json['selectionId'] as String,
        source: json['selectionSource'] as String,
        meal: DailyMealItem.fromJson(json['meal'] as Map<String, dynamic>),
      );
  final String id;
  final String source;
  final DailyMealItem meal;
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
  });
  factory DailyMealMenu.fromJson(Map<String, dynamic> json) => DailyMealMenu(
    dayId: json['subscriptionServiceDayId'] as String,
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
  bool get editable => canEdit && !deadlinePassed;
}
