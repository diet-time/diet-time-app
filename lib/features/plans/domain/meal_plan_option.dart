class MealPlanOption {
  const MealPlanOption({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.imageUrl,
    this.dailyCaloriesKcal,
    this.startingPrice,
    this.currencyCode,
    this.priceDurationDays,
  });

  factory MealPlanOption.fromJson(Map<String, dynamic> json) {
    return MealPlanOption(
      id: _text(json['id']),
      code: _text(json['code']),
      name: _text(json['name']),
      description: _optionalText(json['description']),
      imageUrl: _optionalText(json['imageUrl']),
      dailyCaloriesKcal: _number(json['dailyCaloriesKcal']),
      startingPrice: _number(json['startingPrice']),
      currencyCode: _optionalText(json['currencyCode']),
      priceDurationDays: _integer(json['priceDurationDays']),
    );
  }

  final String id;
  final String code;
  final String name;
  final String? description;
  final String? imageUrl;
  final double? dailyCaloriesKcal;
  final double? startingPrice;
  final String? currencyCode;
  final int? priceDurationDays;
}

String _text(Object? value) => value?.toString().trim() ?? '';

String? _optionalText(Object? value) {
  final text = _text(value);
  return text.isEmpty ? null : text;
}

double? _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

int? _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
