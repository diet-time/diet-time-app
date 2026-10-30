import 'package:diet_time/features/plans/domain/meal_entitlement.dart';

class MealPlanConfiguration {
  const MealPlanConfiguration({
    required this.id,
    required this.name,
    required this.packages,
    this.description,
    this.selectedMeals = const [],
    this.mealCount,
    this.snackCount,
  });

  factory MealPlanConfiguration.fromJson(Map<String, dynamic> json) {
    final packages = _mapList(
      json['packages'] ??
          json['durations'] ??
          json['prices'] ??
          json['pricingOptions'],
    ).map(MealPlanPackage.fromJson).where((item) => item.isValid).toList();
    return MealPlanConfiguration(
      id: _text(
        json['packageOptionId'] ??
            json['id'] ??
            json['mealConfigurationId'] ??
            json['code'] ??
            _configurationId(json),
      ),
      name: _text(
        json['packageOptionName'] ??
            json['name'] ??
            json['displayName'] ??
            json['title'] ??
            json['label'],
      ),
      description: _optionalText(
        json['description'] ??
            json['mealSummary'] ??
            json['includedMeals'] ??
            json['includedText'],
      ),
      mealCount: _integer(json['mealsPerDay'] ?? json['mealCount']),
      snackCount: _integer(json['snacksPerDay'] ?? json['snackCount']),
      selectedMeals:
          _mapList(json['selectedMeals'] ?? json['meals'] ?? json['mealTypes'])
              .map(MealPlanMealSelection.fromJson)
              .where((item) => item.isValid)
              .toList(growable: false),
      packages: json['isActive'] == false || json['isAvailable'] == false
          ? const []
          : packages,
    );
  }

  final String id;
  final String name;
  final String? description;
  final int? mealCount;
  final int? snackCount;
  final List<MealPlanMealSelection> selectedMeals;
  String displayName([String language = 'en']) =>
      RegExp(r'Meal\s*\d+\s*[×x]', caseSensitive: false).hasMatch(name)
      ? entitlementLabel(language)
      : name;
  String entitlementLabel([String language = 'en']) => mealCount != null
      ? MealEntitlement(mealCount!, snackCount ?? 0).label(language)
      : selectedMeals.isEmpty
      ? name
      : MealEntitlement.fromRows(
          selectedMeals.map((m) => (name: m.name, quantity: m.quantity)),
        ).label(language);
  final List<MealPlanPackage> packages;

  bool get isValid => id.isNotEmpty && name.isNotEmpty && packages.isNotEmpty;
}

class MealPlanMealSelection {
  const MealPlanMealSelection({
    required this.mealTypeId,
    required this.name,
    this.quantity = 1,
  });

  factory MealPlanMealSelection.fromJson(Map<String, dynamic> json) =>
      MealPlanMealSelection(
        mealTypeId: _text(json['mealTypeId'] ?? json['id']),
        name: _text(json['name'] ?? json['mealTypeName'] ?? json['label']),
        quantity: _integer(json['quantity'] ?? json['count']) ?? 1,
      );

  final String mealTypeId;
  final String name;
  final int quantity;

  bool get isValid => mealTypeId.isNotEmpty && quantity > 0;
  String get displayName => name.isEmpty ? 'Meal' : name;
}

class MealPlanPackage {
  const MealPlanPackage({
    required this.mealPlanPriceId,
    required this.name,
    required this.serviceDays,
    required this.totalPrice,
    required this.dailyPrice,
    required this.currencyCode,
    this.nonDeliveryWeekdays = const {DateTime.friday},
    this.unavailableDates = const [],
    this.earliestStartDate,
    this.serverNow,
    this.serverReceivedAt,
    this.startDateLeadTimeDays = 0,
    this.regularPrice,
    this.discountedPrice,
    this.serverDiscountPercentage,
    this.isDeliveryEnabled = true,
  });

  factory MealPlanPackage.fromJson(Map<String, dynamic> json) {
    final serviceDays =
        _integer(
          json['serviceDays'] ?? json['durationDays'] ?? json['deliveryDays'],
        ) ??
        0;
    final total =
        _number(
          json['effectivePrice'] ??
              json['discountedPrice'] ??
              json['totalPrice'] ??
              json['amount'] ??
              json['packagePrice'],
        ) ??
        0;
    final explicitDaily = _number(
      json['dailyPrice'] ??
          json['displayDailyPrice'] ??
          json['pricePerServiceDay'],
    );
    return MealPlanPackage(
      mealPlanPriceId: json['isActive'] == false || json['isAvailable'] == false
          ? ''
          : _text(
              json['mealPlanPriceId'] ??
                  json['pricingRecordId'] ??
                  json['priceId'] ??
                  json['id'],
            ),
      name: _text(
        json['durationName'] ??
            json['packageName'] ??
            json['name'] ??
            json['durationName'] ??
            json['displayName'] ??
            json['durationLabel'] ??
            json['label'],
      ),
      serviceDays: serviceDays,
      isDeliveryEnabled: json['isDeliveryEnabled'] != false,
      totalPrice: total,
      regularPrice:
          _number(json['regularPrice'] ?? json['originalPrice']) ?? total,
      discountedPrice: _number(json['discountedPrice']),
      serverDiscountPercentage: _number(json['discountPercentage']),
      dailyPrice: explicitDaily ?? (serviceDays > 0 ? total / serviceDays : 0),
      currencyCode: _text(json['currencyCode'] ?? json['currency']),
      nonDeliveryWeekdays: _weekdays(
        json['nonDeliveryWeekdays'] ??
            json['nonDeliveryDays'] ??
            json['unavailableWeekdays'],
      ),
      unavailableDates: _dates(
        json['unavailableDates'] ??
            json['nonDeliveryDates'] ??
            json['holidays'],
      ),
      serverNow: DateTime.tryParse(json['serverNow']?.toString() ?? ''),
      serverReceivedAt: DateTime.now().toUtc(),
      earliestStartDate: _date(
        json['earliestStartDate'] ?? json['minimumStartDate'],
      ),
      startDateLeadTimeDays:
          _integer(json['startDateLeadTimeDays'] ?? json['leadTimeDays']) ?? 0,
    );
  }

  final bool isDeliveryEnabled;
  final String mealPlanPriceId;
  final String name;
  final int serviceDays;
  final double totalPrice;
  final double dailyPrice;
  final double? regularPrice;
  final double? discountedPrice;
  final double? serverDiscountPercentage;
  double get originalPrice => regularPrice ?? totalPrice;
  bool get hasDiscount =>
      discountedPrice != null &&
      discountedPrice! >= 0 &&
      originalPrice > totalPrice;
  double get discountAmount => hasDiscount
      ? ((originalPrice * 100).round() - (totalPrice * 100).round()) / 100
      : 0;
  double get discountPercentage => !hasDiscount
      ? 0
      : serverDiscountPercentage ??
            ((discountAmount * 100 / originalPrice * 100).round() / 100);
  final String currencyCode;
  final Set<int> nonDeliveryWeekdays;
  final List<DateTime> unavailableDates;
  final DateTime? earliestStartDate;
  final DateTime? serverNow;
  final DateTime? serverReceivedAt;
  final int startDateLeadTimeDays;

  String get selectionKey =>
      mealPlanPriceId.isNotEmpty ? mealPlanPriceId : 'duration-$serviceDays';

  bool get isValid =>
      mealPlanPriceId.isNotEmpty &&
      name.isNotEmpty &&
      serviceDays > 0 &&
      (totalPrice > 0 || hasDiscount && totalPrice == 0) &&
      (dailyPrice > 0 || hasDiscount && totalPrice == 0 && dailyPrice == 0) &&
      currencyCode.isNotEmpty;
}

List<Map<String, dynamic>> _mapList(Object? value) => value is List
    ? value.whereType<Map<String, dynamic>>().toList(growable: false)
    : const [];

String _text(Object? value) => value?.toString().trim() ?? '';

String? _optionalText(Object? value) {
  final result = _text(value);
  return result.isEmpty ? null : result;
}

double? _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

int? _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

String? _configurationId(Map<String, dynamic> json) {
  final meals = _integer(json['mealsPerDay']);
  final snacks = _integer(json['snacksPerDay']);
  return meals == null || snacks == null ? null : '$meals-$snacks';
}

DateTime? _date(Object? value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

List<DateTime> _dates(Object? value) => value is List
    ? value.map(_date).whereType<DateTime>().toList(growable: false)
    : const [];

Set<int> _weekdays(Object? value) {
  if (value is! List) return const {DateTime.friday};
  final result = value.map(_weekday).whereType<int>().toSet();
  return result;
}

int? _weekday(Object? value) {
  if (value is num && value >= 1 && value <= 7) return value.toInt();
  const names = {
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };
  return names[value?.toString().trim().toLowerCase()];
}
