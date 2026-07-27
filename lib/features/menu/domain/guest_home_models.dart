class GuestHomeResponse {
  const GuestHomeResponse({required this.data, required this.errors});

  const GuestHomeResponse.empty()
    : data = const GuestHomeData.empty(),
      errors = const [];

  factory GuestHomeResponse.fromJson(Map<String, dynamic> json) {
    return GuestHomeResponse(
      data: GuestHomeData.fromJson(_map(json['data'])),
      errors: _parseErrors(json['errors']),
    );
  }

  final GuestHomeData data;
  final List<GuestApiError> errors;
}

class GuestHomeData {
  const GuestHomeData({required this.mealPlans, required this.weeklyCalendar});

  const GuestHomeData.empty() : mealPlans = const [], weeklyCalendar = const [];

  factory GuestHomeData.fromJson(Map<String, dynamic> json) {
    final mealPlans =
        _list(json['mealPlans'])
            .map((item) => GuestMealPlan.fromJson(_map(item)))
            .toList(growable: false)
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return GuestHomeData(
      mealPlans: mealPlans,
      weeklyCalendar: _list(json['weeklyCalendar'])
          .map((item) => GuestCalendarDate.fromJson(_map(item)))
          .toList(growable: false),
    );
  }

  final List<GuestMealPlan> mealPlans;
  final List<GuestCalendarDate> weeklyCalendar;
}

class GuestMealPlan {
  const GuestMealPlan({
    required this.id,
    required this.code,
    required this.name,
    required this.displayOrder,
    required this.isSelected,
    required this.slots,
    this.description,
    this.imageUrl,
    this.iconUrl,
  });

  factory GuestMealPlan.fromJson(Map<String, dynamic> json) {
    final slots =
        _list(json['slots'])
            .map((item) => GuestHomeSlot.fromJson(_map(item)))
            .toList(growable: false)
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return GuestMealPlan(
      id: _string(json['id']) ?? '',
      code: _string(json['code']) ?? '',
      name: _string(json['name']) ?? '',
      description: _string(json['description']),
      imageUrl: _string(json['imageUrl']),
      iconUrl: _string(json['iconUrl']),
      displayOrder: _integer(json['displayOrder']),
      isSelected: json['isSelected'] == true,
      slots: slots,
    );
  }

  final String id;
  final String code;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? iconUrl;
  final int displayOrder;
  final bool isSelected;
  final List<GuestHomeSlot> slots;
}

class GuestHomeSlot {
  const GuestHomeSlot({
    required this.id,
    required this.mealTime,
    required this.displayOrder,
    required this.minimumSelection,
    required this.maximumSelection,
    required this.isRequired,
  });

  factory GuestHomeSlot.fromJson(Map<String, dynamic> json) => GuestHomeSlot(
    id: _string(json['id']) ?? '',
    mealTime: GuestMealTime.fromJson(_map(json['mealTime'])),
    displayOrder: _integer(json['displayOrder']),
    minimumSelection: _integer(json['minimumSelection']),
    maximumSelection: _integer(json['maximumSelection']),
    isRequired: json['isRequired'] == true,
  );

  final String id;
  final GuestMealTime mealTime;
  final int displayOrder;
  final int minimumSelection;
  final int maximumSelection;
  final bool isRequired;
}

class GuestCalendarDate {
  const GuestCalendarDate({
    required this.date,
    required this.dayNumber,
    required this.dayName,
    required this.shortDayName,
    required this.isToday,
    required this.isSelected,
    required this.isAvailable,
  });

  factory GuestCalendarDate.fromJson(Map<String, dynamic> json) {
    return GuestCalendarDate(
      date: DateTime.tryParse(_string(json['date']) ?? ''),
      dayNumber: _integer(json['dayNumber']),
      dayName: _string(json['dayName']) ?? '',
      shortDayName: _string(json['shortDayName']) ?? '',
      isToday: json['isToday'] == true,
      isSelected: json['isSelected'] == true,
      isAvailable: json['isAvailable'] == true,
    );
  }

  final DateTime? date;
  final int dayNumber;
  final String dayName;
  final String shortDayName;
  final bool isToday;
  final bool isSelected;
  final bool isAvailable;
}

class GuestMenuResponse {
  const GuestMenuResponse({required this.data, required this.errors});

  GuestMenuResponse.empty({required String planCode, required DateTime date})
    : data = GuestMenuData(
        planId: '',
        planCode: planCode,
        date: date,
        slots: const [],
      ),
      errors = const [];

  factory GuestMenuResponse.fromJson(Map<String, dynamic> json) {
    return GuestMenuResponse(
      data: GuestMenuData.fromJson(_map(json['data'])),
      errors: _parseErrors(json['errors']),
    );
  }

  final GuestMenuData data;
  final List<GuestApiError> errors;
}

class GuestMenuData {
  const GuestMenuData({
    required this.planId,
    required this.planCode,
    required this.date,
    required this.slots,
  });

  factory GuestMenuData.fromJson(Map<String, dynamic> json) {
    final slots =
        _list(json['slots'])
            .map((item) => GuestMenuSlot.fromJson(_map(item)))
            .toList(growable: false)
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return GuestMenuData(
      planId: _string(json['planId']) ?? '',
      planCode: _string(json['planCode']) ?? '',
      date: DateTime.tryParse(_string(json['date']) ?? ''),
      slots: slots,
    );
  }

  final String planId;
  final String planCode;
  final DateTime? date;
  final List<GuestMenuSlot> slots;

  List<GuestMeal> get meals => [for (final slot in slots) ...slot.meals];
}

class GuestMenuSlot {
  const GuestMenuSlot({
    required this.id,
    required this.mealTime,
    required this.displayOrder,
    required this.minimumSelection,
    required this.maximumSelection,
    required this.isRequired,
    required this.meals,
  });

  factory GuestMenuSlot.fromJson(Map<String, dynamic> json) {
    final mealTime = GuestMealTime.fromJson(_map(json['mealTime']));
    final meals =
        _list(json['meals'])
            .map(
              (item) =>
                  GuestMeal.fromJson(_map(item), fallbackMealTime: mealTime),
            )
            .toList(growable: false)
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return GuestMenuSlot(
      id: _string(json['id']) ?? '',
      mealTime: mealTime,
      displayOrder: _integer(json['displayOrder']),
      minimumSelection: _integer(json['minimumSelection']),
      maximumSelection: _integer(json['maximumSelection']),
      isRequired: json['isRequired'] == true,
      meals: meals,
    );
  }

  final String id;
  final GuestMealTime mealTime;
  final int displayOrder;
  final int minimumSelection;
  final int maximumSelection;
  final bool isRequired;
  final List<GuestMeal> meals;
}

class GuestMeal {
  const GuestMeal({
    required this.id,
    required this.code,
    required this.name,
    required this.mealTime,
    required this.nutrition,
    required this.tags,
    required this.allergens,
    required this.isAvailable,
    required this.displayOrder,
    this.description,
    this.imageUrl,
    this.thumbnailUrl,
  });

  factory GuestMeal.fromJson(
    Map<String, dynamic> json, {
    GuestMealTime? fallbackMealTime,
  }) => GuestMeal(
    id: _string(json['id']) ?? '',
    code: _string(json['code']) ?? '',
    name: _string(json['name']) ?? '',
    description: _string(json['description']),
    imageUrl: _string(json['imageUrl']),
    thumbnailUrl: _string(json['thumbnailUrl']),
    mealTime: _map(json['mealTime']).isNotEmpty
        ? GuestMealTime.fromJson(_map(json['mealTime']))
        : fallbackMealTime ?? const GuestMealTime(code: '', name: ''),
    nutrition: GuestMealNutrition.fromJson(_map(json['nutrition'])),
    tags: _list(
      json['tags'],
    ).map((item) => GuestMealTag.fromJson(_map(item))).toList(growable: false),
    allergens: _list(json['allergens'])
        .map((item) => GuestMealAllergen.fromJson(_map(item)))
        .toList(growable: false),
    isAvailable: json['isAvailable'] == true,
    displayOrder: _integer(json['displayOrder']),
  );

  final String id;
  final String code;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? thumbnailUrl;
  final GuestMealTime mealTime;
  final GuestMealNutrition nutrition;
  final List<GuestMealTag> tags;
  final List<GuestMealAllergen> allergens;
  final bool isAvailable;
  final int displayOrder;
}

class GuestMealTime {
  const GuestMealTime({
    required this.code,
    required this.name,
    this.id,
    this.displayOrder = 0,
  });

  factory GuestMealTime.fromJson(Map<String, dynamic> json) => GuestMealTime(
    id: _string(json['id']),
    code: _string(json['code']) ?? '',
    name: _string(json['name']) ?? '',
    displayOrder: _integer(json['displayOrder']),
  );

  final String? id;
  final String code;
  final String name;
  final int displayOrder;
}

class GuestMealNutrition {
  const GuestMealNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
  });

  factory GuestMealNutrition.fromJson(Map<String, dynamic> json) {
    return GuestMealNutrition(
      calories: _decimal(json['calories']),
      protein: _decimal(json['protein']),
      carbs: _decimal(json['carbs']),
      fat: _decimal(json['fat']),
      fiber: json['fiber'] == null ? null : _decimal(json['fiber']),
    );
  }

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
}

class GuestMealTag {
  const GuestMealTag({this.id, this.code, this.name});

  factory GuestMealTag.fromJson(Map<String, dynamic> json) => GuestMealTag(
    id: _string(json['id']),
    code: _string(json['code']),
    name: _string(json['name']),
  );

  final String? id;
  final String? code;
  final String? name;
}

class GuestMealAllergen {
  const GuestMealAllergen({this.id, this.code, this.name, this.level});

  factory GuestMealAllergen.fromJson(Map<String, dynamic> json) =>
      GuestMealAllergen(
        id: _string(json['id']),
        code: _string(json['code']),
        name: _string(json['name']),
        level: _string(
          json['level'] ?? json['severity'] ?? json['type'] ?? json['status'],
        ),
      );

  final String? id;
  final String? code;
  final String? name;
  final String? level;
}

class GuestApiError {
  const GuestApiError({this.code, this.message});

  factory GuestApiError.fromJson(Map<String, dynamic> json) => GuestApiError(
    code: _string(json['code']),
    message: _string(json['message']),
  );

  final String? code;
  final String? message;
}

List<GuestApiError> _parseErrors(Object? value) => _list(
  value,
).map((item) => GuestApiError.fromJson(_map(item))).toList(growable: false);

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

List<dynamic> _list(Object? value) => value is List<dynamic> ? value : const [];

String? _string(Object? value) => value is String ? value : null;

int _integer(Object? value) => value is num ? value.toInt() : 0;

double _decimal(Object? value) => value is num ? value.toDouble() : 0;
