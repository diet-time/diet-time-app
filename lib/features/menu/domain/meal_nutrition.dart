/// Values are per configured serving. Never assume a 100 g reference or fill gaps with zero.
class MealNutrition {
  const MealNutrition({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.saturatedFat,
    this.transFat,
    this.cholesterol,
    this.servingQuantity,
    this.servingUnit,
  });

  factory MealNutrition.fromJson(Map<String, dynamic> json) {
    double? value(String key) => (json[key] as num?)?.toDouble();
    return MealNutrition(
      calories: value('caloriesKcal'),
      protein: value('proteinGrams'),
      carbs: value('carbohydratesGrams'),
      fat: value('fatGrams'),
      fiber: value('fiberGrams'),
      sugar: value('sugarGrams'),
      sodium: value('sodiumMg'),
      saturatedFat: value('saturatedFatGrams'),
      transFat: value('transFatGrams'),
      cholesterol: value('cholesterolMg'),
      servingQuantity: value('servingQuantity'),
      servingUnit: json['servingUnit'] as String?,
    );
  }

  final double? calories,
      protein,
      carbs,
      fat,
      fiber,
      sugar,
      sodium,
      saturatedFat,
      transFat,
      cholesterol,
      servingQuantity;
  final String? servingUnit;
  bool get hasValues =>
      [calories, protein, carbs, fat].any((value) => value != null);
  bool get complete =>
      [calories, protein, carbs, fat].every((value) => value != null);

  /// A total is unknown when any selected serving lacks that nutrient.
  static MealNutrition total(
    Iterable<({MealNutrition nutrition, int quantity})> servings,
  ) {
    final items = servings.toList();
    double? sum(double? Function(MealNutrition) read) {
      if (items.isEmpty || items.any((item) => read(item.nutrition) == null)) {
        return null;
      }
      return items.fold<double>(
        0,
        (total, item) => total + read(item.nutrition)! * item.quantity,
      );
    }

    return MealNutrition(
      calories: sum((n) => n.calories),
      protein: sum((n) => n.protein),
      carbs: sum((n) => n.carbs),
      fat: sum((n) => n.fat),
    );
  }
}
