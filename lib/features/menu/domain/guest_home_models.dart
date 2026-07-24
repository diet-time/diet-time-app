class GuestHomeResponse {
  const GuestHomeResponse({required this.data, required this.errors});

  factory GuestHomeResponse.fromJson(Map<String, dynamic> json) {
    return GuestHomeResponse(
      data: GuestHomeData.fromJson(_map(json['data'])),
      errors: _list(json['errors'])
          .map((item) => GuestApiError.fromJson(_map(item)))
          .toList(growable: false),
    );
  }

  final GuestHomeData data;
  final List<GuestApiError> errors;
}

class GuestHomeData {
  const GuestHomeData({
    required this.hero,
    required this.mealPlans,
    required this.menus,
    required this.weeklyCalendar,
    required this.mealTimeFilters,
    required this.meals,
    required this.pagination,
  });

  factory GuestHomeData.fromJson(Map<String, dynamic> json) {
    final mealPlans = _list(
      json['mealPlans'],
    ).map((item) => GuestMealPlan.fromJson(_map(item))).toList(growable: false);
    final selectedPlan =
        mealPlans.where((plan) => plan.isSelected).firstOrNull ??
        mealPlans.firstOrNull;
    final weeklyCalendar = _list(json['weeklyCalendar'])
        .map((item) => GuestCalendarDate.fromJson(_map(item)))
        .toList(growable: false);
    final parsedMenus = _list(
      json['menus'],
    ).map((item) => GuestMenuDay.fromJson(_map(item))).toList(growable: false);
    final selectedDate = weeklyCalendar
        .where((date) => date.isSelected)
        .firstOrNull
        ?.date;
    final menus = parsedMenus.isNotEmpty
        ? parsedMenus
        : selectedPlan != null && selectedDate != null
        ? [
            GuestMenuDay(
              planCode: selectedPlan.code,
              date: selectedDate,
              slots: selectedPlan.slots,
            ),
          ]
        : const <GuestMenuDay>[];
    final heroJson = _map(json['hero']);
    final topLevelMeals = _list(
      json['meals'],
    ).map((item) => GuestMeal.fromJson(_map(item))).toList(growable: false);
    return GuestHomeData(
      hero: heroJson.isNotEmpty
          ? GuestHero.fromJson(heroJson)
          : GuestHero(
              title: selectedPlan?.name,
              subtitle: selectedPlan?.description,
              bannerImageUrl: selectedPlan?.imageUrl,
            ),
      mealPlans: mealPlans,
      menus: menus,
      weeklyCalendar: weeklyCalendar,
      mealTimeFilters: _list(json['mealTimeFilters'])
          .map((item) => GuestMealTimeFilter.fromJson(_map(item)))
          .toList(growable: false),
      meals: json.containsKey('meals')
          ? topLevelMeals
          : selectedPlan?.slots
                    .expand((slot) => slot.meals)
                    .toList(growable: false) ??
                const [],
      pagination: GuestPagination.fromJson(_map(json['pagination'])),
    );
  }

  final GuestHero hero;
  final List<GuestMealPlan> mealPlans;
  final List<GuestMenuDay> menus;
  final List<GuestCalendarDate> weeklyCalendar;
  final List<GuestMealTimeFilter> mealTimeFilters;
  final List<GuestMeal> meals;
  final GuestPagination pagination;
}

class GuestMenuDay {
  const GuestMenuDay({
    required this.planCode,
    required this.date,
    required this.slots,
  });

  factory GuestMenuDay.fromJson(Map<String, dynamic> json) => GuestMenuDay(
    planCode: _string(json['planCode']) ?? '',
    date: DateTime.tryParse(_string(json['date']) ?? ''),
    slots: _list(json['slots'])
        .map((item) => GuestMealPlanSlot.fromJson(_map(item)))
        .toList(growable: false),
  );

  final String planCode;
  final DateTime? date;
  final List<GuestMealPlanSlot> slots;
}

class GuestHero {
  const GuestHero({this.title, this.subtitle, this.bannerImageUrl});

  factory GuestHero.fromJson(Map<String, dynamic> json) => GuestHero(
    title: _string(json['title']),
    subtitle: _string(json['subtitle']),
    bannerImageUrl: _string(json['bannerImageUrl']),
  );

  final String? title;
  final String? subtitle;
  final String? bannerImageUrl;
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
  });

  factory GuestMealPlan.fromJson(Map<String, dynamic> json) => GuestMealPlan(
    id: _string(json['id']) ?? '',
    code: _string(json['code']) ?? '',
    name: _string(json['name']) ?? '',
    description: _string(json['description']),
    imageUrl: _string(json['imageUrl']),
    displayOrder: _integer(json['displayOrder']),
    isSelected: json['isSelected'] == true,
    slots: _list(json['slots'])
        .map((item) => GuestMealPlanSlot.fromJson(_map(item)))
        .toList(growable: false),
  );

  final String id;
  final String code;
  final String name;
  final String? description;
  final String? imageUrl;
  final int displayOrder;
  final bool isSelected;
  final List<GuestMealPlanSlot> slots;
}

class GuestMealPlanSlot {
  const GuestMealPlanSlot({
    required this.id,
    required this.mealTime,
    required this.displayOrder,
    required this.minimumSelection,
    required this.maximumSelection,
    required this.isRequired,
    required this.meals,
  });

  factory GuestMealPlanSlot.fromJson(Map<String, dynamic> json) {
    final mealTime = GuestMealTime.fromJson(_map(json['mealTime']));
    return GuestMealPlanSlot(
      id: _string(json['id']) ?? '',
      mealTime: mealTime,
      displayOrder: _integer(json['displayOrder']),
      minimumSelection: _integer(json['minimumSelection']),
      maximumSelection: _integer(json['maximumSelection']),
      isRequired: json['isRequired'] == true,
      meals: _list(json['meals'])
          .map(
            (item) =>
                GuestMeal.fromJson(_map(item), fallbackMealTime: mealTime),
          )
          .toList(growable: false),
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

class GuestMealTimeFilter {
  const GuestMealTimeFilter({
    required this.code,
    required this.name,
    required this.displayOrder,
    required this.isSelected,
    this.id,
  });

  factory GuestMealTimeFilter.fromJson(Map<String, dynamic> json) {
    return GuestMealTimeFilter(
      id: _string(json['id']),
      code: _string(json['code']) ?? '',
      name: _string(json['name']) ?? '',
      displayOrder: _integer(json['displayOrder']),
      isSelected: json['isSelected'] == true,
    );
  }

  final String? id;
  final String code;
  final String name;
  final int displayOrder;
  final bool isSelected;
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
  const GuestMealAllergen({this.id, this.code, this.name});

  factory GuestMealAllergen.fromJson(Map<String, dynamic> json) =>
      GuestMealAllergen(
        id: _string(json['id']),
        code: _string(json['code']),
        name: _string(json['name']),
      );

  final String? id;
  final String? code;
  final String? name;
}

class GuestPagination {
  const GuestPagination({
    required this.page,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory GuestPagination.fromJson(Map<String, dynamic> json) {
    return GuestPagination(
      page: _integer(json['page']),
      pageSize: _integer(json['pageSize']),
      totalRecords: _integer(json['totalRecords']),
      totalPages: _integer(json['totalPages']),
      hasNextPage: json['hasNextPage'] == true,
      hasPreviousPage: json['hasPreviousPage'] == true,
    );
  }

  final int page;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
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

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

List<dynamic> _list(Object? value) => value is List<dynamic> ? value : const [];

String? _string(Object? value) => value is String ? value : null;

int _integer(Object? value) => value is num ? value.toInt() : 0;

double _decimal(Object? value) => value is num ? value.toDouble() : 0;

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
