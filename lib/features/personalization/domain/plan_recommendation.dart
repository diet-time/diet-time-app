class PlanRecommendation {
  const PlanRecommendation({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.imageUrl,
    this.mainBenefit,
    this.mealCount,
    this.durationDays,
    this.price,
    this.currency,
    this.isRecommended = false,
    this.isAllergenCompatible = false,
  });

  factory PlanRecommendation.fromJson(Map<String, dynamic> json) {
    return PlanRecommendation(
      id: _string(json['id'] ?? json['planId']),
      code: _string(json['code'] ?? json['planCode']),
      name: _string(json['name'] ?? json['planName']),
      description: _nullableString(json['description']),
      imageUrl: _nullableString(json['imageUrl']),
      mainBenefit: _nullableString(json['mainBenefit'] ?? json['benefit']),
      mealCount: _integer(json['mealCount'] ?? json['numberOfMeals']),
      durationDays: _integer(json['durationDays'] ?? json['duration']),
      price: _decimal(json['price'] ?? json['startingPrice']),
      currency: _nullableString(json['currency']),
      isRecommended:
          json['isRecommended'] == true || json['recommended'] == true,
      isAllergenCompatible:
          json['isAllergenCompatible'] == true ||
          json['allergenCompatible'] == true,
    );
  }

  final String id;
  final String code;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? mainBenefit;
  final int? mealCount;
  final int? durationDays;
  final double? price;
  final String? currency;
  final bool isRecommended;
  final bool isAllergenCompatible;
}

String _string(Object? value) => value?.toString().trim() ?? '';
String? _nullableString(Object? value) {
  final result = _string(value);
  return result.isEmpty ? null : result;
}

int? _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
double? _decimal(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
