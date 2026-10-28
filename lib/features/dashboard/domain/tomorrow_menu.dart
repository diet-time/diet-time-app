import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';

enum TomorrowDeliveryState {
  selectionPending,
  readyToConfirm,
  confirmed,
  automaticallySelected,
  locked,
  unavailable,
}

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
    this.orderStatus,
    this.orderStartDate,
    this.firstDeliveryDate,
    this.emptyReason,
    this.orderNumber,
    this.planId,
    this.planImageUrl,
    this.planVersion,
    this.selectedMealCount,
    this.selectedSnackCount,
    this.customerConfirmedAt,
    this.autoFinalizedAt,
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
      orderNumber: json['orderNumber'] as String?,
      planId: json['mealPlanTemplateId'] as String?,
      planImageUrl: json['mealPlanImageUrl'] as String?,
      planVersion: json['mealPlanVersion'] as int?,
      selectedMealCount: json['selectedMealCount'] as int?,
      selectedSnackCount: json['selectedSnackCount'] as int?,
      customerConfirmedAt: DateTime.tryParse(
        json['customerConfirmedAt']?.toString() ?? '',
      ),
      autoFinalizedAt: DateTime.tryParse(
        json['autoFinalizedAt']?.toString() ?? '',
      ),
      mealCount: json['mealCount'] as int,
      snackCount: json['snackCount'] as int,
      status: json['selectionStatus'] as String,
      locked: json['selectionLocked'] == true,
      canConfirm: json['canConfirm'] == true,
      cutoffAt: DateTime.parse(json['cutoffAt'] as String),
      serverNow: DateTime.parse(json['serverNow'] as String),
      reviewReason: json['reviewReason'] as String?,
      orderStatus: json['orderStatus'] as String?,
      orderStartDate: DateTime.tryParse(
        json['orderStartDate']?.toString() ?? '',
      ),
      firstDeliveryDate: DateTime.tryParse(
        json['firstDeliveryDate']?.toString() ?? '',
      ),
      emptyReason: json['emptyReason'] as String?,
      selected: items('selectedMeals'),
      meals: items('availableMeals'),
      snacks: items('availableSnacks'),
    );
  }

  final String subscriptionId;
  final String? dayId;
  final DateTime deliveryDate;
  final String planName;
  final String? orderNumber;
  final String? planId;
  final String? planImageUrl;
  final int? planVersion;
  final int? selectedMealCount;
  final int? selectedSnackCount;
  final DateTime? customerConfirmedAt;
  final DateTime? autoFinalizedAt;
  final int mealCount;
  final int snackCount;
  final String status;
  final bool locked;
  final bool canConfirm;
  final DateTime cutoffAt;
  final DateTime serverNow;
  final String? reviewReason;
  final String? orderStatus;
  final DateTime? orderStartDate;
  final DateTime? firstDeliveryDate;
  final String? emptyReason;
  final List<DailyMealItem> selected;
  final List<DailyMealItem> meals;
  final List<DailyMealItem> snacks;

  bool get finalized =>
      status == 'CUSTOMER_CONFIRMED' ||
      status == 'AUTO_FINALIZED' ||
      customerConfirmedAt != null ||
      autoFinalizedAt != null;

  bool get readOnly => finalized || locked || status == 'LOCKED';

  bool get scheduledForTomorrow =>
      dayId != null ||
      const {
        'SERVICE_DAYS_MISSING',
        'SERVICE_DAY_INCOMPLETE',
        'MENU_NOT_CONFIGURED',
        'FINALIZATION_PENDING',
        'NEEDS_REVIEW',
        'LOCKED',
        'CUSTOMER_CONFIRMED',
        'AUTO_FINALIZED',
      }.contains(status);

  int get savedMealCount =>
      selectedMealCount ??
      selected
          .where((item) => item.category == 'meal')
          .map((item) => item.id)
          .toSet()
          .length;
  int get savedSnackCount =>
      selectedSnackCount ??
      selected
          .where((item) => item.category == 'snack')
          .map((item) => item.id)
          .toSet()
          .length;

  TomorrowDeliveryState deliveryState({
    int? mealsSelected,
    int? snacksSelected,
    bool expired = false,
  }) {
    if (customerConfirmedAt != null || status == 'CUSTOMER_CONFIRMED') {
      return TomorrowDeliveryState.confirmed;
    }
    if (autoFinalizedAt != null || status == 'AUTO_FINALIZED') {
      return TomorrowDeliveryState.automaticallySelected;
    }
    if (readOnly) return TomorrowDeliveryState.locked;
    if (!canConfirm || expired) return TomorrowDeliveryState.unavailable;
    return (mealsSelected ?? savedMealCount) == mealCount &&
            (snacksSelected ?? savedSnackCount) == snackCount &&
            mealCount + snackCount > 0
        ? TomorrowDeliveryState.readyToConfirm
        : TomorrowDeliveryState.selectionPending;
  }

  String get statusMessage => switch (status) {
    'NO_ORDER' => 'No order is linked to your account.',
    'PENDING_ACTIVATION' =>
      'Your order is saved and is waiting for activation.',
    'NOT_STARTED' =>
      'Your plan starts soon. Selection opens the day before your first delivery.',
    'NO_DELIVERY' => 'No delivery is scheduled for tomorrow.',
    'SERVICE_DAYS_MISSING' =>
      'Your order is saved, but its delivery schedule needs to be initialized by our team.',
    'SERVICE_DAY_INCOMPLETE' =>
      'Your delivery details need review by our team.',
    'SCHEDULE_NOT_CONFIGURED' =>
      'Your order’s delivery weekdays need review by our team.',
    'MENU_NOT_CONFIGURED' =>
      'Your order is saved. Tomorrow’s dishes have not been configured yet.',
    'SELECTION_NOT_OPEN' => 'Selection opens the day before your delivery.',
    'FINALIZATION_PENDING' =>
      'The 9:00 PM selection window has closed. Your automatic meals are being finalized.',
    'INACTIVE_ORDER' => 'This order is not active for meal selection.',
    'LOCKED' => 'Your meal selections are locked for preparation.',
    'NEEDS_REVIEW' =>
      'Our team needs to review suitable dishes for your package.',
    _ => 'Please choose your meals for tomorrow.',
  };
}

/// Local drafts never write to the API. Dish identity is shared across categories.
class TomorrowMealDraft {
  TomorrowMealDraft(this.menu) {
    for (final item in menu.selected) {
      final options = item.category == 'meal' ? menu.meals : menu.snacks;
      if (options.any((option) => option.id == item.id)) _toggle(item);
    }
  }

  final TomorrowMenu menu;
  final Set<String> mealIds = {};
  final Set<String> snackIds = {};

  bool get complete =>
      mealIds.length == menu.mealCount && snackIds.length == menu.snackCount;
  bool contains(String id) => mealIds.contains(id) || snackIds.contains(id);

  bool replace(DailyMealItem item, String previousId) {
    if (menu.readOnly || contains(item.id)) return false;
    final ids = item.category == 'meal' ? mealIds : snackIds;
    final options = item.category == 'meal' ? menu.meals : menu.snacks;
    if (!ids.contains(previousId) ||
        !options.any(
          (option) => option.id == item.id && option.category == item.category,
        )) {
      return false;
    }
    ids
      ..remove(previousId)
      ..add(item.id);
    return true;
  }

  bool toggle(DailyMealItem item) {
    if (menu.readOnly) return false;
    return _toggle(item);
  }

  bool _toggle(DailyMealItem item) {
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
