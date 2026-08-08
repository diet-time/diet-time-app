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
            json['displayName'] ??
            json['durationLabel'] ??
            json['label'],
      ),
      serviceDays: serviceDays,
      totalPrice: total,
      dailyPrice: explicitDaily ?? (serviceDays > 0 ? total / serviceDays : 0),
      currencyCode: _text(json['currencyCode'] ?? json['currency']),
    );
  }

  final String mealPlanPriceId;
  final String name;
  final int serviceDays;
  final double totalPrice;
  final double dailyPrice;
  final String currencyCode;

  bool get isValid =>
      mealPlanPriceId.isNotEmpty &&
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
