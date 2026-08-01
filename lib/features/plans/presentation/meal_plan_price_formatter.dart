import 'package:intl/intl.dart';

String formatMealPlanPriceAmount(double value, String localeName) {
  final isWholeNumber = value == value.roundToDouble();
  return NumberFormat(isWholeNumber ? '0' : '0.00', localeName).format(value);
}
