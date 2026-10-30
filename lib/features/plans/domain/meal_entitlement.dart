/// Presentation-only aggregation. Internal meal-type IDs and quantities stay unchanged.
class MealEntitlement {
  const MealEntitlement(this.meals, this.snacks);
  factory MealEntitlement.fromRows(
    Iterable<({String name, int quantity})> rows,
  ) {
    var meals = 0, snacks = 0;
    for (final row in rows) {
      if (row.quantity <= 0) continue;
      final name = row.name.toUpperCase();
      final snack =
          name.contains('SNACK') ||
          name.contains('DESSERT') ||
          name.contains('خفيف') ||
          name.contains('سناك') ||
          name.contains('حلو');
      if (snack) {
        snacks += row.quantity;
      } else {
        meals += row.quantity;
      }
    }
    return MealEntitlement(meals, snacks);
  }
  final int meals;
  final int snacks;
  String label([String language = 'en']) {
    if (meals + snacks == 0) {
      return language == 'ar' ? 'باقة الوجبات' : 'Meal package';
    }
    if (language == 'ar') {
      return [
        if (meals > 0) meals == 1 ? 'وجبة واحدة' : '$meals وجبات',
        if (snacks > 0) snacks == 1 ? 'وجبة خفيفة' : '$snacks وجبات خفيفة',
      ].join(' + ');
    }
    return [
      if (meals > 0) '$meals ${meals == 1 ? 'Meal' : 'Meals'}',
      if (snacks > 0) '$snacks ${snacks == 1 ? 'Snack' : 'Snacks'}',
    ].join(' + ');
  }
}
