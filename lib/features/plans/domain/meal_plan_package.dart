class MealPlanConfiguration {
  const MealPlanConfiguration({
    required this.id,
    required this.name,
    required this.packages,
    this.description,
  });

  factory MealPlanConfiguration.fromJson(Map<String, dynamic> json) {
    final packages = _mapList(
      json['packages'] ??
          json['durations'] ??
          json['prices'] ??
          json['pricingOptions'],
    ).map(MealPlanPackage.fromJson).where((item) => item.isValid).toList();
    return MealPlanConfiguration(
      id: _text(json['id'] ?? json['mealConfigurationId'] ?? json['code']),
      name: _text(
        json['name'] ?? json['displayName'] ?? json['title'] ?? json['label'],
      ),
      description: _optionalText(
        json['description'] ?? json['mealSummary'] ?? json['includedMeals'],
      ),
      packages: packages,
    );
  }

  final String id;
  final String name;
  final String? description;
  final List<MealPlanPackage> packages;

  bool get isValid => id.isNotEmpty && name.isNotEmpty && packages.isNotEmpty;
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
    this.startDateLeadTimeDays = 0,
  });

  factory MealPlanPackage.fromJson(Map<String, dynamic> json) {
    final serviceDays =
        _integer(
          json['serviceDays'] ?? json['durationDays'] ?? json['deliveryDays'],
        ) ??
        0;
    final total =
        _number(json['totalPrice'] ?? json['amount'] ?? json['packagePrice']) ??
        0;
    final explicitDaily = _number(
      json['dailyPrice'] ??
          json['displayDailyPrice'] ??
          json['pricePerServiceDay'],
    );
    return MealPlanPackage(
      mealPlanPriceId: _text(
        json['mealPlanPriceId'] ??
            json['pricingRecordId'] ??
            json['priceId'] ??
            json['id'],
      ),
      name: _text(
        json['name'] ??
            json['durationName'] ??
            json['displayName'] ??
            json['durationLabel'] ??
            json['label'],
      ),
      serviceDays: serviceDays,
      totalPrice: total,
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
      earliestStartDate: _date(
        json['earliestStartDate'] ?? json['minimumStartDate'],
      ),
      startDateLeadTimeDays:
          _integer(json['startDateLeadTimeDays'] ?? json['leadTimeDays']) ?? 0,
    );
  }

  final String mealPlanPriceId;
  final String name;
  final int serviceDays;
  final double totalPrice;
  final double dailyPrice;
  final String currencyCode;
  final Set<int> nonDeliveryWeekdays;
  final List<DateTime> unavailableDates;
  final DateTime? earliestStartDate;
  final int startDateLeadTimeDays;

  String get selectionKey =>
      mealPlanPriceId.isNotEmpty ? mealPlanPriceId : 'duration-$serviceDays';

  bool get isValid =>
      name.isNotEmpty &&
      serviceDays > 0 &&
      totalPrice > 0 &&
      dailyPrice > 0 &&
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
