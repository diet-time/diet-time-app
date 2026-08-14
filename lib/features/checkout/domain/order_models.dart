class PlaceOrderMealRequest {
  const PlaceOrderMealRequest({
    required this.mealTypeId,
    required this.quantity,
  });

  final String mealTypeId;
  final int quantity;

  Map<String, dynamic> toJson() => {
    'mealTypeId': mealTypeId,
    'quantity': quantity,
  };
}

class PlaceOrderRequest {
  const PlaceOrderRequest({
    required this.customerProfileId,
    required this.mealPlanTemplateId,
    required this.mealPlanPriceId,
    required this.customerAddressId,
    required this.deliveryTimeSlotId,
    required this.startDate,
    required this.deliveryDays,
    required this.meals,
    this.couponCode,
  });

  final String customerProfileId;
  final String mealPlanTemplateId;
  final String mealPlanPriceId;
  final String customerAddressId;
  final String deliveryTimeSlotId;
  final DateTime startDate;
  final List<int> deliveryDays;
  final List<PlaceOrderMealRequest> meals;
  final String? couponCode;

  Map<String, dynamic> toJson() => {
    'customerProfileId': customerProfileId,
    'mealPlanTemplateId': mealPlanTemplateId,
    'mealPlanPriceId': mealPlanPriceId,
    'customerAddressId': customerAddressId,
    'deliveryTimeSlotId': deliveryTimeSlotId,
    'startDate': _date(startDate),
    'deliveryDays': deliveryDays,
    'meals': meals.map((meal) => meal.toJson()).toList(growable: false),
    'couponCode': _nullableText(couponCode),
  };
}

class CustomerOrderSummary {
  const CustomerOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.planName,
    required this.planDurationName,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.currencyCode,
    required this.startDate,
    required this.endDate,
    required this.placedAt,
  });

  factory CustomerOrderSummary.fromJson(Map<String, dynamic> json) =>
      CustomerOrderSummary(
        id: _text(json['id'] ?? json['orderId']),
        orderNumber: _text(json['orderNumber']),
        planName: _text(json['planName'] ?? json['name']),
        planDurationName: _text(
          json['planDurationName'] ?? json['durationName'],
        ),
        status: _text(json['status']).toUpperCase(),
        paymentStatus: _text(json['paymentStatus']).toUpperCase(),
        totalAmount: _number(json['totalAmount']),
        currencyCode: _text(json['currencyCode']),
        startDate: _dateTime(json['startDate']),
        endDate: _dateTime(json['endDate']),
        placedAt: _dateTime(json['placedAt']),
      );

  final String id;
  final String orderNumber;
  final String planName;
  final String planDurationName;
  final String status;
  final String paymentStatus;
  final double totalAmount;
  final String currencyCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? placedAt;

  bool get isValid => id.isNotEmpty && orderNumber.isNotEmpty;
  bool get isCurrent =>
      const {'CONFIRMED', 'ACTIVE', 'PAUSED'}.contains(status);
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
}

class CustomerOrdersPage {
  const CustomerOrdersPage({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  factory CustomerOrdersPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException(
        'Customer orders response has no items list.',
      );
    }
    final pageNumber = _integer(json['pageNumber']);
    final pageSize = _integer(json['pageSize']);
    final totalCount = _integer(json['totalCount']);
    if (pageNumber == null || pageSize == null || totalCount == null) {
      throw const FormatException(
        'Customer orders response has invalid pagination fields.',
      );
    }
    return CustomerOrdersPage(
      items: rawItems
          .map((item) {
            if (item is! Map) {
              throw const FormatException('Customer order item is invalid.');
            }
            final order = CustomerOrderSummary.fromJson(
              Map<String, dynamic>.from(item),
            );
            if (!order.isValid) {
              throw const FormatException('Customer order item is incomplete.');
            }
            return order;
          })
          .toList(growable: false),
      pageNumber: pageNumber,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }

  final List<CustomerOrderSummary> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
}

class OrderConfirmation {
  const OrderConfirmation({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.plan,
    required this.meals,
    required this.delivery,
    required this.pricing,
    required this.placedAt,
  });

  factory OrderConfirmation.fromJson(Map<String, dynamic> json) =>
      OrderConfirmation(
        id: _text(json['id'] ?? json['orderId']),
        orderNumber: _text(json['orderNumber']),
        status: _text(json['status']),
        paymentStatus: _text(json['paymentStatus']),
        plan: OrderPlan.fromJson(_map(json['plan'])),
        meals: _list(
          json['meals'],
        ).map(OrderMeal.fromJson).toList(growable: false),
        delivery: OrderDelivery.fromJson(_map(json['delivery'])),
        pricing: OrderPricing.fromJson(_map(json['pricing'])),
        placedAt: _dateTime(json['placedAt']),
      );

  final String id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final OrderPlan plan;
  final List<OrderMeal> meals;
  final OrderDelivery delivery;
  final OrderPricing pricing;
  final DateTime? placedAt;

  bool get isValid => id.isNotEmpty && orderNumber.isNotEmpty;
}

class OrderPlan {
  const OrderPlan({
    required this.mealPlanTemplateId,
    required this.mealPlanPriceId,
    required this.name,
    required this.durationName,
  });

  factory OrderPlan.fromJson(Map<String, dynamic> json) => OrderPlan(
    mealPlanTemplateId: _text(json['mealPlanTemplateId']),
    mealPlanPriceId: _text(json['mealPlanPriceId']),
    name: _text(json['name']),
    durationName: _text(json['durationName']),
  );

  final String mealPlanTemplateId;
  final String mealPlanPriceId;
  final String name;
  final String durationName;
}

class OrderMeal {
  const OrderMeal({
    required this.mealTypeId,
    required this.name,
    required this.quantity,
  });

  factory OrderMeal.fromJson(Map<String, dynamic> json) => OrderMeal(
    mealTypeId: _text(json['mealTypeId'] ?? json['id']),
    name: _text(json['name']),
    quantity: _integer(json['quantity']) ?? 0,
  );

  final String mealTypeId;
  final String name;
  final int quantity;
}

class OrderDelivery {
  const OrderDelivery({
    required this.daysPerWeek,
    required this.days,
    required this.startDate,
    required this.endDate,
    required this.timeSlot,
    required this.address,
  });

  factory OrderDelivery.fromJson(Map<String, dynamic> json) => OrderDelivery(
    daysPerWeek: _integer(json['daysPerWeek']) ?? 0,
    days: (json['days'] is List ? json['days'] as List : const [])
        .map(_integer)
        .whereType<int>()
        .toList(growable: false),
    startDate: _dateTime(json['startDate']),
    endDate: _dateTime(json['endDate']),
    timeSlot: OrderTimeSlot.fromJson(_map(json['timeSlot'])),
    address: OrderAddress.fromJson(_map(json['address'])),
  );

  final int daysPerWeek;
  final List<int> days;
  final DateTime? startDate;
  final DateTime? endDate;
  final OrderTimeSlot timeSlot;
  final OrderAddress address;
}

class OrderTimeSlot {
  const OrderTimeSlot({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  factory OrderTimeSlot.fromJson(Map<String, dynamic> json) => OrderTimeSlot(
    id: _text(json['id'] ?? json['deliveryTimeSlotId']),
    name: _text(json['name']),
    startTime: _text(json['startTime']),
    endTime: _text(json['endTime']),
  );

  final String id;
  final String name;
  final String startTime;
  final String endTime;
}

class OrderAddress {
  const OrderAddress({
    required this.addressId,
    required this.addressName,
    required this.addressType,
    required this.buildingNo,
    required this.streetNo,
    required this.zoneNo,
    required this.area,
    required this.formattedAddress,
    this.unitNumber,
    this.directions,
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) => OrderAddress(
    addressId: _text(json['addressId'] ?? json['id']),
    addressName: _text(json['addressName'] ?? json['name']),
    addressType: _text(json['addressType']),
    buildingNo: _text(json['buildingNo']),
    streetNo: _text(json['streetNo']),
    unitNumber: _nullableText(json['unitNumber']),
    zoneNo: _text(json['zoneNo']),
    area: _text(json['area']),
    directions: _nullableText(json['directions']),
    formattedAddress: _text(json['formattedAddress']),
  );

  final String addressId;
  final String addressName;
  final String addressType;
  final String buildingNo;
  final String streetNo;
  final String? unitNumber;
  final String zoneNo;
  final String area;
  final String? directions;
  final String formattedAddress;

  String get displayName => addressName.isEmpty ? addressType : addressName;
  String get streetLine =>
      'Building $buildingNo, Street $streetNo, Zone $zoneNo';
}

class OrderPricing {
  const OrderPricing({
    required this.subtotal,
    required this.discountAmount,
    required this.deliveryCharge,
    required this.totalAmount,
    required this.currencyCode,
  });

  factory OrderPricing.fromJson(Map<String, dynamic> json) => OrderPricing(
    subtotal: _number(json['subtotal']),
    discountAmount: _number(json['discountAmount']),
    deliveryCharge: _number(json['deliveryCharge']),
    totalAmount: _number(json['totalAmount']),
    currencyCode: _text(json['currencyCode']),
  );

  final double subtotal;
  final double discountAmount;
  final double deliveryCharge;
  final double totalAmount;
  final String currencyCode;
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _text(Object? value) => value?.toString().trim() ?? '';

String? _nullableText(Object? value) {
  final valueText = _text(value);
  return valueText.isEmpty ? null : valueText;
}

int? _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse(_text(value));

double _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(_text(value)) ?? 0;

DateTime? _dateTime(Object? value) => DateTime.tryParse(_text(value));

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

List<Map<String, dynamic>> _list(Object? value) => value is List
    ? value.whereType<Map<String, dynamic>>().toList(growable: false)
    : const [];
